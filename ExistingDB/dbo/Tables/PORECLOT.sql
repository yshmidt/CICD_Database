CREATE TABLE [dbo].[PORECLOT] (
    [LOC_UNIQ]    CHAR (10)       CONSTRAINT [DF__PORECLOT__LOC_UN__2BEA4664] DEFAULT ('') NOT NULL,
    [REFERENCE]   CHAR (12)       CONSTRAINT [DF__PORECLOT__REFERE__2CDE6A9D] DEFAULT ('') NOT NULL,
    [LOTCODE]     NVARCHAR (25)   CONSTRAINT [DF__PORECLOT__LOTCOD__2DD28ED6] DEFAULT ('') NOT NULL,
    [EXPDATE]     SMALLDATETIME   NULL,
    [LOTQTY]      NUMERIC (12, 2) CONSTRAINT [DF__PORECLOT__LOTQTY__2EC6B30F] DEFAULT ((0)) NOT NULL,
    [LOT_UNIQ]    CHAR (10)       CONSTRAINT [DF__PORECLOT__LOT_UN__2FBAD748] DEFAULT ('') NOT NULL,
    [RECEIVERNO]  CHAR (10)       CONSTRAINT [DF__PORECLOT__RECEIV__30AEFB81] DEFAULT ('') NOT NULL,
    [REJLOTQTY]   NUMERIC (12, 2) CONSTRAINT [DF__PORECLOT__REJLOT__31A31FBA] DEFAULT ((0)) NOT NULL,
    [sourceDev]   CHAR (1)        CONSTRAINT [DF_PORECLOT_sourceDev] DEFAULT (' ') NOT NULL,
    [checkReject] CHAR (1)        NULL,
    CONSTRAINT [PORECLOT_PK] PRIMARY KEY CLUSTERED ([LOT_UNIQ] ASC)
);


GO
CREATE NONCLUSTERED INDEX [LOC_UNIQ]
    ON [dbo].[PORECLOT]([LOC_UNIQ] ASC);


GO
 --=========================================================================================================
 --Author:		Shivshankar P
 --Create date: 2/23/2017
 --Description:	Update Trigger for INVTLOT table
 --05/03/2017  Satish B : Check weather the update operation is from Buyer Action.If Yes then avoid INVTLOT updation.
 --05/03/2017  Satish B : If Update operation from Buyer Action then reset 'checkReject' column to empty.
 --05/17/2017 Shivshankar P : Removed multiple TRANSACTION,INSTEAD OF UPDATE ,COMMIT TRANSACTION and modified 'INVTLOT' table update query 
 --08/08/2017 Shivshankar P : Updated Lot code details which not in 'MRB','WIP'  and 'WO-WIP' warehouse and Returned Error Message
 --10/13/2017 Shivshankar P : Qty Converted in UOM 
 --=========================================================================================================
CREATE TRIGGER [dbo].[PORECLOT_UPDATE]
   ON  [dbo].[PORECLOT] 
   
   -- INSTEAD OF UPDATE  -- 05/17/2017 Shivshankar P : Removed 
  AFTER UPDATE
AS 
BEGIN
     -- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	BEGIN TRANSACTION
			-- 05/03/2017  Satish B : Check weather the update operation is from Buyer Action. If Yes then avoid INVTLOT updation
			IF ((SELECT INSERTED.checkReject FROM INSERTED) IS NULL OR (SELECT INSERTED.checkReject FROM INSERTED)<>'B')    -- B : Rejection From Production (From Buyer Action)
				--BEGIN TRANSACTION   -- 05/24/2017 Shivshankar P : No need to use multiple TRANSACTION and COMMIT TRANSACTION
				BEGIN TRY

				    -- 05/24/2017 Shivshankar P : Removed INSTEAD OF update so far modified the query 
					UPDATE INVTLOT SET LOTCODE=Inserted.LOTCODE,REFERENCE=Inserted.REFERENCE,EXPDATE=Inserted.EXPDATE, 
					LOTQTY=CASE WHEN Inserted.LOTQTY  >  Deleted.LOTQTY 
					 THEN INVTLOT.LOTQTY + dbo.fn_ConverQtyUOM(porecdtl.pur_uofm,porecdtl.U_of_meas,(Inserted.LOTQTY - Deleted.LOTQTY))
					  ELSE INVTLOT.LOTQTY - dbo.fn_ConverQtyUOM(porecdtl.pur_uofm,porecdtl.U_of_meas,(Deleted.LOTQTY - Inserted.LOTQTY)) END
					FROM Inserted,Deleted,receiverheader,INVTMFGR, WAREHOUS,porecdtl ,PORECLOC      -- 10/13/2017 Shivshankar P : Qty Converted in UOM 
					 WHERE  INVTLOT.LOTCODE = Deleted.LOTCODE AND INVTLOT.EXPDATE =Deleted.EXPDATE 
					        AND INVTLOT.REFERENCE=Deleted.REFERENCE AND Deleted.RECEIVERNO=receiverheader.RECEIVERNO AND
					        INVTLOT.PONUM=receiverheader.PONUM and INVTMFGR.W_KEY = INVTLOT.W_KEY and 
				            WAREHOUS.UNIQWH = INVTMFGR.UNIQWH and WAREHOUSE <> 'MRB'   and WAREHOUSE <> 'WIP'  and WAREHOUSE <> 'WO-WIP' 
							AND porecdtl.uniqrecdtl = PORECLOC.FK_UNIQRECDTL and Inserted.LOC_UNIQ=PORECLOC.LOC_UNIQ 

				END TRY	
				BEGIN CATCH
					IF @@TRANCOUNT <>0
						ROLLBACK TRAN ;
							SELECT @ErrorMessage = ERROR_MESSAGE(),
							   @ErrorSeverity = ERROR_SEVERITY(),
							   @ErrorState = ERROR_STATE();
						RAISERROR (@ErrorMessage, -- Message text.
								   @ErrorSeverity, -- Severity.
								   @ErrorState -- State.
								   );
				END CATCH	
			
               -- 05/24/2017 Shivshankar P :  Need not to use multiple COMMIT TRANSACTION  
				--IF @@TRANCOUNT>0
				--COMMIT TRANSACTION
			
			-- 05/03/2017  Satish B : If Update operation from Buyer Action then reset 'checkReject' column to empty
			ELSE
			--	BEGIN TRANSACTION   -- 05/24/2017 Shivshankar P :  Set the TRANSACTION at the top
					BEGIN TRY
						UPDATE PORECLOT SET checkReject='' WHERE LOT_UNIQ=(SELECT LOT_UNIQ FROM INSERTED)
					END TRY	
					
					BEGIN CATCH
						IF @@TRANCOUNT <>0
							ROLLBACK TRAN ;
								SELECT @ErrorMessage = ERROR_MESSAGE(),
							   @ErrorSeverity = ERROR_SEVERITY(),
							   @ErrorState = ERROR_STATE();
						RAISERROR (@ErrorMessage, -- Message text.
								   @ErrorSeverity, -- Severity.
								   @ErrorState -- State.
								   );
					END CATCH	
			
				
		--END 
		IF @@TRANCOUNT>0
				COMMIT TRANSACTION				 		
	END
	
GO
-- =========================================================================================================
-- Author:		Shivshankar P
-- Create date: 03/03/2017
-- Description:	Update Trigger for INVTLOT table
-- =========================================================================================================
CREATE TRIGGER [dbo].[PORECLOT_DELETE]
   ON  [dbo].[PORECLOT] 
   AFTER DELETE
AS 
BEGIN
     -- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
	    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	BEGIN
			BEGIN TRANSACTION
			BEGIN TRY

			DELETE INVTLOT  FROM INVTLOT , Inserted,Deleted,receiverheader,receiverDetail
			WHERE  INVTLOT.LOTCODE = Deleted.LOTCODE AND Deleted.EXPDATE =Deleted.EXPDATE AND INVTLOT.REFERENCE=Deleted.REFERENCE
			 AND Deleted.RECEIVERNO=receiverheader.RECEIVERNO AND
			INVTLOT.PONUM=receiverheader.PONUM 

			END TRY	
			BEGIN CATCH
				IF @@TRANCOUNT <>0
					ROLLBACK TRAN ;
						SELECT @ErrorMessage = ERROR_MESSAGE(),
							   @ErrorSeverity = ERROR_SEVERITY(),
							   @ErrorState = ERROR_STATE();
						RAISERROR (@ErrorMessage, -- Message text.
								   @ErrorSeverity, -- Severity.
								   @ErrorState -- State.
								   );
			END CATCH	
			
			IF @@TRANCOUNT>0
			COMMIT TRANSACTION
		END 				 		
	END
GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/12/14
-- Description:	Insert trigger for PoReclot table
-- 07/23/14 YS added column ReceivingStatus 
-- Values 'Complete' or 'Inspection'. If ReceivingStatus ='Inspection' - do not run any tables updates other than Porecdtl itself)
-- 07/31/14 YS more changes for new 'Inspection' module
-- 08/18/14 YS make sure that instore items are not updating invtlot
-- 04/14/15 YS Location length is changed to varchar(256)
-- 06/28/16 Nitesh B Modify the trigger with receiverheader & receiverdetail table 
-- 07/11/16 Nitesh B  Remove all ReceivingStatus=' ' not possible with new structure
-- 07/12/16 Nitesh B  Not using MRB warehouse anymore
-- 07/28/2013 Nitesh B Not Using this code Handling from code
-- 05/31/2017 Shivshankar P : Reference column value compared with InvtLot
-- 08/24/2017 Shivshankar P : Retunred Error Message from exception
-- 03/02/18 YS changed lotcode size to 25 
-- 08/07/2019 Rajendra K : Changed location datatype varchar to nvarchar
-- 05/14/2020 Shivshankar P : Get isCompleted from receiverdetail table to Update/Insert InvtLot when we are process multiple line item receiving in one PO receipt  
-- =============================================
CREATE TRIGGER [dbo].[PoRecLot_insert]
   ON  [dbo].[PORECLOT]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    -- Insert statements for trigger here
	-- make sure it is not from the desktop
	BEGIN
		DECLARE @errorCode int
		-- 07/12/16 Nitesh B  Not using MRB warehouse anymore
		--DECLARE @uniqMrbWh char(10)=' ',@MRBWH_GL_NBR char(13)=' '
		-- 07/31/14 YS added receivingStatus
		-- 04/14/15 YS Location length is changed to varchar(256)
		--03/02/18 YS changed lotcode size to 25
		--08/07/2019 Rajendra K : Changed location datatype varchar to nvarchar
		DECLARE @tporeclot table (Lot_uniq char(10),uniq_key char(10),uniqmfgrhd char(10),w_key char(10),location nvarchar(256),Uniqwh char(10),Uniqlnno char(10),
						Ponum char(17),	requestTp char(10),WoPrjNumber char(10),Saveinit char(8),LotQTy numeric(10,2),REJLotQTY numeric(10,2),
						U_OF_MEAS char(4),PUR_UOFM char(4),Loc_uniq char(10),LotCode nvarchar(25),ExpDate smalldatetime , reference char(12),
						poittype char(9),ReceivingStatus varchar(20), RecCompleted bit)
		--07/31/14 YS change to insert all records from inserted 'complete' and 'inspection'. Have to have data entered into invtlot
		--08/18/14 YS make sure that instore items are not updating invtlot
		-- 05/14/2020 Shivshankar P : Get isCompleted from receiverdetail table to Update/Insert InvtLot when we are process multiple line item receiving in one PO receipt
		INSERT INTO @tporeclot 	(Lot_uniq ,uniq_key ,uniqmfgrhd ,location ,Uniqwh ,Uniqlnno ,
						Ponum ,	requestTp ,WoPrjNumber ,LotQty ,REJLotQTY,
						U_OF_MEAS ,PUR_UOFM ,Loc_uniq,LotCode,ExpDate, reference,poittype ,ReceivingStatus, RecCompleted)
						SELECT I.Lot_uniq ,RD.Uniq_key ,d.uniqmfgrhd ,L.location ,L.Uniqwh ,d.Uniqlnno ,
						P.Ponum ,	S.requestTp ,S.WoPrjNumber ,
						i.LOTQTY ,i.REJLOTQTY,
						d.U_OF_MEAS ,d.PUR_UOFM ,i.Loc_uniq,
						I.LotCode,I.ExpDate, I.reference ,p.POITTYPE,RH.recStatus, RD.isCompleted
						FROM INSERTED I INNER JOIN PORECLOC L on l.LOC_UNIQ = i.loc_uniq
						INNER JOIN PORECDTL D on l.FK_UNIQRECDTL = D.UNIQRECDTL 
						INNER JOIN POITEMS P on P.UNIQLNNO=D.UNIQLNNO
						INNER JOIN POITSCHD S on S.uniqdetno=L.UNIQDETNO 
						INNER JOIN receiverDetail RD on D.receiverdetId = RD.receiverDetId
						INNER JOIN receiverHeader RH on RD.receiverHdrId = RH.receiverHdrId
						where (i.LOTQTY <> 0.00 or i.REJLOTQTY <> 0.00);
					
		-- 07/23/14 YS -- continue if receiver was completed
		IF @@ROWCOUNT <> 0
		BEGIN
		    -- 07/12/16 Nitesh B  Not using MRB warehouse anymore
			--SELECT @uniqMrbWh = UniqWH ,
			--	@MRBWH_GL_NBR = wh_gl_nbr
			--	FROM WAREHOUS where  Warehouse='MRB'
							
			BEGIN TRANSACTION
			--08/18/14 YS make sure that instore items are not updating invtlot
			UPDATE @tporeclot SET W_KEY = M.W_key 
				from INVTMFGR M inner join @tporeclot t on m.UNIQMFGRHD = t.uniqmfgrhd 
				 			and m.UNIQWH=t.Uniqwh and m.LOCATION=t.location 
				 			and m.INSTORE=0 where t.lotqty<> 0.00
							and t.poittype<>'In Store'
		

			-- update/insert into InvtLot for accepted qty
			-- 07/31/14 YS update InvtLot table for ReceivingStatus="Complete' 
			-- 05/14/2020 Shivshankar P : Get isCompleted from receiverdetail table to Update/Insert InvtLot when we are process multiple line item receiving in one PO receipt
			BEGIN TRY
				--08/18/14 YS make sure that instore items are not updating invtlot
				MERGE InvtLot As T
				USING (SELECT l.W_key,l.Lotcode,l.ExpDate,l.Reference,l.ponum,l.LotQty,PUR_UOFM,U_of_meas
						FROM @tporeclot l where l.LotQty <> 0.00 and (ReceivingStatus = 'Complete' OR RecCompleted = 1) and  l.poittype<>'In Store') as S
				ON (S.w_key=T.w_key AND S.LotCode=T.LotCode AND s.expdate=t.expdate and s.Ponum=t.ponum and s.Reference=t.Reference)  -- 05/31/2017 Shivshankar P : Reference column value compared with InvtLot
				WHEN MATCHED THEN UPDATE SET T.LotQty=t.LotQty+dbo.fn_ConverQtyUOM(S.PUR_UOFM,s.U_of_meas,s.LotQty)
				WHEN NOT MATCHED BY TARGET THEN 
					INSERT (W_key,LotCode,Expdate,Reference,Ponum,LotQty,UNIQ_LOT) 
					VALUES (S.W_key,S.LotCode,S.Expdate,S.Reference,S.Ponum,dbo.fn_ConverQtyUOM(S.PUR_UOFM,s.U_of_meas,s.LotQty),
							dbo.fn_GenerateUniqueNumber()) ;
			END TRY	
			BEGIN CATCH
				IF @@TRANCOUNT <>0
					ROLLBACK TRAN ;
						SELECT @ErrorMessage = ERROR_MESSAGE(),
							   @ErrorSeverity = ERROR_SEVERITY(),
							   @ErrorState = ERROR_STATE();
						RAISERROR (@ErrorMessage, -- Message text.
								   @ErrorSeverity, -- Severity.
								   @ErrorState -- State.
								   );
			END CATCH	
			
			-- 07/12/16 Nitesh B  Not using MRB warehouse anymore
			/*	
				-- 07/31/14 update/insert into InvtLot for received qty when ReceivingStatus="Inspection' . MRB location should be already created by insert for the porecdtl
				-- find MRB Location for inspection in Invtmfgr table
				BEGIN TRY
					--08/18/14 YS make sure that instore items are not updating invtlot
					MERGE InvtLot As T
					USING (SELECT M.W_key,l.Lotcode,l.ExpDate,l.Reference,l.ponum,l.LotQty,PUR_UOFM,U_of_meas
							FROM @tporeclot l INNER JOIN Invtmfgr M on l.Uniqmfgrhd=M.Uniqmfgrhd and m.Uniqwh=@uniqMrbWh and m.Location='PO'+l.Ponum
							WHERE l.ReceivingStatus='Inspection' and M.mrbType='I' and l.Poittype<>'In Store') as S
					ON (S.w_key=T.w_key AND S.LotCode=T.LotCode AND s.expdate=t.expdate and s.Ponum=t.ponum)
					WHEN MATCHED THEN UPDATE SET T.LotQty=t.LotQty+dbo.fn_ConverQtyUOM(S.PUR_UOFM,s.U_of_meas,s.LotQty)
					WHEN NOT MATCHED BY TARGET THEN 
						INSERT (W_key,LotCode,Expdate,Reference,Ponum,LotQty,UNIQ_LOT) 
						VALUES (S.W_key,S.LotCode,S.Expdate,S.Reference,S.Ponum,dbo.fn_ConverQtyUOM(S.PUR_UOFM,s.U_of_meas,s.LotQty),
								dbo.fn_GenerateUniqueNumber()) ; 
				END TRY	
				BEGIN CATCH
					IF @@TRANCOUNT <>0
						ROLLBACK TRAN ;
				END CATCH	

		
				--07/31/14 YS check for new column  (M.mrbType='R' or M.mrbType=' ') 'R'- for 'rejected' and ready fro DMR, empty string for backward compatibility 		
				--- if anything was rejected
				BEGIN TRY
					--08/18/14 YS make sure that instore items are not updating invtlot
					MERGE InvtLot As T
					USING (SELECT M.W_key,l.Lotcode,l.ExpDate,l.Reference,l.ponum,l.RejLotQty,PUR_UOFM,U_of_meas
							FROM @tporeclot l INNER JOIN Invtmfgr M on l.Uniqmfgrhd=M.Uniqmfgrhd and m.Uniqwh=@uniqMrbWh and m.Location='PO'+l.Ponum
							WHERE (M.mrbType='R' or M.mrbType=' ') and  l.RejLotQty<>0.00 and (ReceivingStatus='Complete') and l.poittype<>'In Store') as S
					ON (S.w_key=T.w_key AND S.LotCode=T.LotCode AND s.expdate=t.expdate and s.Ponum=t.ponum)
					WHEN MATCHED THEN UPDATE SET T.LotQty=t.LotQty+dbo.fn_ConverQtyUOM(S.PUR_UOFM,s.U_of_meas,s.RejLotQty)
					WHEN NOT MATCHED BY TARGET THEN 
						INSERT (W_key,LotCode,Expdate,Reference,Ponum,LotQty,UNIQ_LOT) 
						VALUES (S.W_key,S.LotCode,S.Expdate,S.Reference,S.Ponum,dbo.fn_ConverQtyUOM(S.PUR_UOFM,s.U_of_meas,s.RejLotQty),
								dbo.fn_GenerateUniqueNumber()) ; 
				END TRY
				BEGIN CATCH
					IF @@TRANCOUNT <>0
						ROLLBACK TRAN ;
				END CATCH
			*/	


			--- check if allocated
			-- 07/31/14 YS do not do anyhing if parts are waiting for inspection
			-- check if any allocations
			--08/18/14 YS make sure that instore items are not updating invtlot
			-- 07/28/2013 Nitesh B Not Using this code Handling from code
			/*
			IF EXISTS(SELECT 1 from @tporeclot where uniq_key<>' ' and WoPrjNumber <>' ' and (ReceivingStatus ='Complete'))
			BEGIN 
				-- first check if part is not  serialized, otherwise allocation will take place in the porecser insert trigger
				-- 07/31/14 YS do not do anyhing if parts are waiting for inspection
				IF EXISTS(SELECT 1 
					FROM INVENTOR  
					INNER JOIN @tporeclot t ON Inventor.UNIQ_KEY=t.uniq_key
					where t.WoPrjNumber<>' '
					and Inventor.SERIALYES = 0
					and (ReceivingStatus ='Complete') and t.poittype<>'In Store')	
				BEGIN
					BEGIN TRY
						--- allocated to a work order
						-- 07/31/14 YS do not do anyhing if parts are waiting for inspection
						INSERT INTO Invt_res (W_key, Uniq_key, QtyAlloc, Saveinit,Wono,LotCode,ExpDate,Reference,Ponum,INVTRES_NO) 
							SELECT  t.W_key, t.Uniq_key,  dbo.fn_ConverQtyUOM(t.PUR_UOFM, t.U_of_meas,t.LotQty),
							t.saveinit,t.woprjnumber,t.LotCode,t.ExpDate,t.Reference,t.Ponum,dbo.fn_GenerateUniqueNumber() 
								FROM @tporeclot t where t.RequestTp='WO Alloc' and (ReceivingStatus ='Complete')
					END TRY
					BEGIN CATCH
						IF @@TRANCOUNT >0
						ROLLBACK TRANSACTION ;
						-- !!! raise an error
					END CATCH
					BEGIN TRY
						--- allocated to a project
						-- 07/31/14 YS do not do anyhing if parts are waiting for inspection
						INSERT INTO Invt_res (W_key, Uniq_key, QtyAlloc, Saveinit,Fk_PrjUnique,INVTRES_NO,LotCode,ExpDate,Reference,Ponum) 
							SELECT  t.W_key, t.Uniq_key, dbo.fn_ConverQtyUOM(t.PUR_UOFM, t.U_of_meas,t.LotQty),
							t.saveinit,PRJUNIQUE,dbo.fn_GenerateUniqueNumber(),t.LotCode,t.ExpDate,t.Reference,t.Ponum 
								FROM @tporeclot t INNER JOIN PjctMain ON t.woprjnumber=Pjctmain.PRJNUMBER  
								where t.RequestTp='Prj Alloc' and (ReceivingStatus ='Complete')
					END TRY
					BEGIN CATCH
						IF @@TRANCOUNT >0
						ROLLBACK TRANSACTION ;
						-- !!! raise an error
					END CATCH
				
						
				END -- first check if part is not  serialized, otherwise allocation will take place in the porecser insert trigger
			END -- IF EXISTS(SELECT 1 from @tporeclot where uniq_key<>' ' and WoPrjNumber <>' ')
			*/
			IF @@TRANCOUNT>0
			COMMIT TRANSACTION
		END ---- 07/23/14 YS -- continue if receiver was completed		 				 		
	END --- IF NOT EXISTS(SELECT 1 from inserted where sourceDev='D')
END