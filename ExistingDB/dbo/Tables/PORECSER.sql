CREATE TABLE [dbo].[PORECSER] (
    [POSERUNIQUE]   CHAR (10) CONSTRAINT [DF__PORECSER__POSERU__6ADB9D16] DEFAULT ('') NOT NULL,
    [LOC_UNIQ]      CHAR (10) CONSTRAINT [DF__PORECSER__LOC_UN__6BCFC14F] DEFAULT ('') NOT NULL,
    [LOT_UNIQ]      CHAR (10) CONSTRAINT [DF__PORECSER__LOT_UN__6CC3E588] DEFAULT ('') NOT NULL,
    [serialno]      CHAR (30) CONSTRAINT [DF_PORECSER_serialno] DEFAULT ('') NOT NULL,
    [RECEIVERNO]    CHAR (10) CONSTRAINT [DF__PORECSER__RECEIV__6DB809C1] DEFAULT ('') NOT NULL,
    [SERIALREJ]     BIT       CONSTRAINT [DF__PORECSER__SERIAL__6EAC2DFA] DEFAULT ((0)) NOT NULL,
    [FK_SERIALUNIQ] CHAR (10) CONSTRAINT [DF__PORECSER__FK_SER__6FA05233] DEFAULT ('') NOT NULL,
    [sourcedev]     CHAR (1)  CONSTRAINT [DF_PORECSER_sourcedev] DEFAULT (' ') NOT NULL,
    [ipkeyunique]   CHAR (10) CONSTRAINT [DF_PORECSER_ipkeyunique] DEFAULT ('') NOT NULL,
    CONSTRAINT [PORECSER_PK] PRIMARY KEY CLUSTERED ([POSERUNIQUE] ASC)
);


GO
CREATE NONCLUSTERED INDEX [FK_SERIALU]
    ON [dbo].[PORECSER]([FK_SERIALUNIQ] ASC);


GO
CREATE NONCLUSTERED INDEX [LOC_UNIQ]
    ON [dbo].[PORECSER]([LOC_UNIQ] ASC);


GO
CREATE NONCLUSTERED INDEX [LOCLOT]
    ON [dbo].[PORECSER]([LOC_UNIQ] ASC, [LOT_UNIQ] ASC);


GO
CREATE NONCLUSTERED INDEX [LOT_UNIQ]
    ON [dbo].[PORECSER]([LOT_UNIQ] ASC);


GO
CREATE NONCLUSTERED INDEX [RECEIVERNO]
    ON [dbo].[PORECSER]([RECEIVERNO] ASC);


GO
CREATE NONCLUSTERED INDEX [ipkey]
    ON [dbo].[PORECSER]([ipkeyunique] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/12/14
-- Description:	Insert trigger for PoRecSer table
-- 07/23/14 YS added column ReceivingStatus 
-- Values 'Complete' or 'Inspection'. If ReceivingStatus ='Inspection' - do not run any tables updates other than Porecdtl itself)
-- 07/31/14 YS more changes for new 'Inspection' module
	--08/18/14 YS make sure that instore items are not updating invtlot
	-- 04/14/15 YS Location length is changed to varchar(256)
-- 06/30/16 Nitesh B: Modify the trigger with receiverheader & receiverdetail table 
-- 7/01/16 Nitesh B: Display the serial number which already exists
-- 7/12/16 Nitesh B: Not using MRB anymore
-- 7/19/16 Nitesh B: Check for RequestTp
-- 2/6/2019 Nitesh B : If lot is existing then use lot unique generated 
--08/07/2019 Rajendra K : Changed location datatype varchar to nvarchar
-- =============================================
CREATE TRIGGER [dbo].[PoRecSer_insert]
   ON  [dbo].[PORECSER]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @ErrorMsg VARCHAR(MAX), @ErrorNumber INT, @ErrorProc sysname, @ErrorLine INT ;
	DECLARE @requestTp VARCHAR(50);
    -- Insert statements for trigger here
	-- make sure it is not from the desktop
	BEGIN
		DECLARE @errorCode int
		DECLARE @tserial table (SerialUniq char(10),Serialno char(30),uniqmfgrhd char(10),IpKeyUnique char(10))   -- use this to save serialuniq for inserted/updated values
		-- 7/12/16 Nitesh B Not using MRB anymore
		-- DECLARE @uniqMrbWh char(10)=' ',@MRBWH_GL_NBR char(13)=' ' 
		-- 08/18/14 YS added poittype to remove in store items from updting invtser
		-- 04/14/15 YS Location length is changed to varchar(256)
		--08/07/2019 Rajendra K : Changed location datatype varchar to nvarchar
		DECLARE @tporecser table (serialno char(30),SerialUniq char(30),Lot_uniq char(10) default '',uniq_key char(10),uniqmfgrhd char(10),w_key char(10),location nvarchar(256),Uniqwh char(10),
						Uniqlnno char(10),Ponum char(17),requestTp char(10),WoPrjNumber char(10),LotQTy numeric(10,2),REJLotQTY numeric(10,2),
						U_OF_MEAS char(4),PUR_UOFM char(4),Loc_uniq char(10),LotCode char(15),ExpDate smalldatetime , reference char(12),SerialRej bit,PoSeruniq char(10),
						Uniq_lot char(10) default '',PoitType char(9),ReceivingStatus varchar(20),IpKeyUnique char(10),uniqRecDtl char(10))
		--07/31/14 YS added ReceivingStatus column. Will have to identify records that are in inspection
		-- 08/18/14 YS added poittype to remove in store items from updting invtser
		INSERT INTO @tporecser 	(serialno,Lot_uniq ,uniq_key ,uniqmfgrhd ,location ,Uniqwh ,Uniqlnno ,
						Ponum ,	requestTp ,WoPrjNumber ,LotQty ,REJLotQTY,
						U_OF_MEAS ,PUR_UOFM ,Loc_uniq,LotCode,ExpDate, reference,SerialRej ,PoSeruniq,poittype,ReceivingStatus,uniqRecDtl,IpKeyUnique)
						SELECT I.Serialno,I.LOT_UNIQ ,p.uniq_key ,d.uniqmfgrhd ,L.location ,L.Uniqwh ,d.Uniqlnno ,
						P.Ponum ,S.requestTp ,S.WoPrjNumber ,
						CASE WHEN i.Lot_uniq=' ' THEN 0.0 else lt.LOTQTY END  ,
						CASE WHEN i.Lot_uniq=' ' THEN 0.0  else Lt.REJLOTQTY END,
						d.U_OF_MEAS ,d.PUR_UOFM ,i.Loc_uniq,
						CASE WHEN i.Lot_uniq=' ' THEN ' ' else  lt.LotCode end ,
						lt.ExpDate, CASE WHEN i.Lot_uniq=' ' THEN ' ' else lt.reference END,
						i.SERIALREJ,i.POSERUNIQUE,p.poittype ,RH.recStatus,D.uniqrecdtl,i.ipkeyunique
						FROM INSERTED I INNER JOIN PORECLOC L on l.LOC_UNIQ = i.loc_uniq
						LEFT OUTER JOIN Poreclot LT on I.LOT_UNIQ=LT.LOT_UNIQ 
						INNER JOIN PORECDTL D on l.FK_UNIQRECDTL = D.UNIQRECDTL 
						INNER JOIN POITEMS P on P.UNIQLNNO=D.UNIQLNNO
						INNER JOIN POITSCHD S on S.uniqdetno=L.UNIQDETNO
		                INNER JOIN receiverDetail RD on D.receiverdetId = RD.receiverDetId
						INNER JOIN receiverHeader RH on RD.receiverHdrId = RH.receiverHdrId
		-- 07/23/14 YS -- continue if receiver was completed
		IF @@ROWCOUNT <> 0
		BEGIN

     		-- 7/12/16 Nitesh B Not using MRB anymore
			--SELECT @uniqMrbWh = UniqWH ,
			--	@MRBWH_GL_NBR = wh_gl_nbr
			--	FROM WAREHOUS where  Warehouse='MRB'
							
			BEGIN TRANSACTION
				BEGIN TRY
					--07/31/14 YS update with inventory location only if complete 
					UPDATE @tporecSer SET W_KEY = M.W_key 
					from INVTMFGR M inner join @tporecSer t on m.UNIQMFGRHD = t.uniqmfgrhd 
				 			and m.UNIQWH=t.Uniqwh and m.LOCATION=t.location 
				 			and m.INSTORE=0 where t.SerialRej =0 and (t.ReceivingStatus='Complete')
				   /*
				    --07/12/16 Nitesh B Not using MRB anymore
					--07/31/14 YS update with mrb location ready for DMR only if complete 
					UPDATE @tporecSer SET W_KEY = M.W_key 
					from INVTMFGR M inner join @tporecSer t on m.UNIQMFGRHD = t.uniqmfgrhd 
				 			and m.UNIQWH=@uniqMrbWh and m.LOCATION='PO'+t.Ponum 
				 			and m.INSTORE=0 where t.SerialRej =1 and M.mrbType='R' and (t.ReceivingStatus='Complete')

					--07/31/14 YS update with mrb location waiting for inspection only if 'inspection'
					UPDATE @tporecSer SET W_KEY = M.W_key 
					from INVTMFGR M inner join @tporecSer t on m.UNIQMFGRHD = t.uniqmfgrhd 
				 			and m.UNIQWH=@uniqMrbWh and m.LOCATION='PO'+t.Ponum 
				 			and m.INSTORE=0 and m.mrbType='I' where  t.ReceivingStatus='Inspection'
                */
				
					UPDATE @tporecser set uniq_lot=CASE WHEN t.lot_uniq=' ' then ' ' else ISNULL(Lot.Uniq_lot,t.lot_uniq) end--- , 
					-- 2/6/2019 Nitesh B : If lot is existing then use lot unique generated  
						FROM @tporecser t LEFT OUTER JOIN InvtLot lot ON t.w_key =lot.w_key
						and t.LotCode=lot.lotcode and t.ExpDate=lot.expdate and t.Reference=lot.reference and t.Ponum = lot.PONUM 
								
				END TRY
				BEGIN CATCH
					print error_message()
					if @@TRANCOUNT>0
					ROLLBACK TRANSACTION ;
					RETURN 
				END CATCH

				-- 7/01/2016 Nitesh B: Display the serial number which already exists
				DECLARE @duplicateSerialNumber char(30),@errorMessage VARCHAR(MAX)
				-- check if serial number exists and not DMR
				-- 08/18/14 YS added poittype to remove in store items from updting invtser
				set @duplicateSerialNumber = (select S.serialno from InvtSer S inner join @tporecser I on s.Serialno=i.serialno and s.UNIQMFGRHD =i.uniqmfgrhd where S.Id_key<>'DMR_NO' and i.poittype<>'In Store')
				IF @duplicateSerialNumber IS NOT NULL
				begin
					--problem have to exit with some sort of code and show the list of the issues
					--- 07/23/14 added error handling 
					--- 7/01/2016 Nitesh B: Display message with serial number
					set @errorMessage = CONCAT('Duplicate Serial Number. Cannot Proceed. ',dbo.fRemoveLeadingZeros(@duplicateSerialNumber))
					RAISERROR(@errorMessage ,1,1) ;
					ROLLBACK TRANSACTION ;
					RETURN 
				end
				-- if DMR update record in Invtser
				-- !!! check if output works correctly
				--UPDATE InvtSer SET id_key='W_KEY' ,
				--					id_value=t.w_key 
				--					OUTPUT INSERTED.Serialuniq,t.serialno INTO @tserial
				--					from @tporecSer t where t.uniqmfgrhd =Invtser.UNIQMFGRHD and t.SerialRej =0 and t.serialno = invtser.serialno and invtser.id_key='DMR'
				-- if new serial number insert
				BEGIN TRY
				    -- Nitesh B : Using WAITFOR DELAY dbo.fn_GenerateUniqueNumber generates the different keys 
					WAITFOR DELAY '00:00:00.100';
					-- 08/18/14 YS added poittype to remove in store items from updting invtser
					MERGE InvtSer T
					USING (SELECT Serialno,Uniq_key,Uniqmfgrhd,w_key,SerialRej,LotCode,Reference,ExpDate,uniq_lot,Ponum ,PoSeruniq,IpKeyUnique
					FROM @tporecSer where poittype<>'In Store') S ON (t.uniqmfgrhd=s.uniqmfgrhd and t.serialno = s.serialno and t.id_key='DMR')
					WHEN MATCHED THEN UPDATE SET t.id_key='W_KEY',t.id_value=s.w_key,t.uniq_lot=s.uniq_lot,
					t.LotCode=s.lotcode,t.expdate=s.expdate,t.reference=s.reference,t.ponum=case when s.uniq_lot<>' ' then s.ponum else ' ' end
					WHEN NOT MATCHED BY TARGET THEN
					INSERT (SerialNo,Uniq_key,UniqMfgrHd,Id_key,Id_value,SaveDtTm,Uniq_lot,
											LotCode,ExpDate,Reference,Ponum,SerialUniq,ipkeyunique) VALUES
							(s.SerialNo,s.Uniq_key,s.UniqMfgrHd,'W_KEY',s.w_key,GETDATE(),s.Uniq_lot,
											s.LotCode,s.ExpDate,s.Reference,
											case when s.uniq_lot<>' ' then s.ponum else ' ' end,dbo.fn_generateUniqueNumber(),isnull(s.IpKeyUnique,''))
					OUTPUT Inserted.SerialUniq,INSERTED.Serialno,s.uniqmfgrhd,s.IpKeyUnique INTO @tserial;
				END TRY
				BEGIN CATCH
					--print error_message()
					IF @@TRANCOUNT >0
						-- !!! raise an error
						SELECT @ErrorMsg = ERROR_MESSAGE();
						RAISERROR (@ErrorMsg,16,1);
						ROLLBACK TRANSACTION ;
					RETURN 
				END CATCH
				
				-- update SeiaUniq
				BEGIN TRY
				-- Nitesh B : update porecser.IpKeyUnique column with Ipkey.IpKeyUnique
				UPDATE @tporecser set serialuniq=s.serialuniq ,IpKeyUnique=s.IpKeyUnique from @tserial s inner join @tporecser t on s.Serialno=t.serialno and s.uniqmfgrhd = t.uniqmfgrhd 
				update porecser set FK_SERIALUNIQ=t.serialuniq ,ipkeyunique = t.IpKeyUnique from @tporecser t where t.PoSeruniq= porecser.POSERUNIQUE	
				END TRY
				BEGIN CATCH
					--print error_message()
					IF @@TRANCOUNT >0
						SELECT @ErrorMsg = ERROR_MESSAGE();
						RAISERROR (@ErrorMsg,16,1);
						ROLLBACK TRANSACTION ;
						RETURN
				END CATCH
				-- allocation
				--07/31/14 YS remove parts waiting for inspection
				-- 08/18/14 YS added poittype to remove in store items from updting invtser
				-- 07/28/16 Nitesh B Not using here Handling by code
				/*
				IF EXISTS(SELECT 1 from @tporecser where uniq_key<>' ' and WoPrjNumber <>' ' and (ReceivingStatus='Complete') and poittype<>'In Store')
				BEGIN 	
				SELECT @requestTp= RequestTp from @tporecser  -- 7/19/16 Nitesh B:Check for RequestTp
					BEGIN TRY
					IF @requestTp = 'WO Alloc'
						BEGIN
							INSERT INTO Invt_res (W_key, Uniq_key, QtyAlloc, Wono, Saveinit,LotCode,ExpDate,Reference,Ponum,INVTRES_NO) 
							SELECT W_key,Uniq_key, 1,woprjnumber,'',LotCode,ExpDate,Reference,case when lotcode<>' ' THEN Ponum ELSE ' ' END,
							dbo.fn_GenerateUniqueNumber()
							FROM @tporecser t where t.SerialRej=0 and woprjnumber<>' '	and  RequestTp='WO Alloc' and (t.ReceivingStatus='Complete')	
						END
					END TRY
					BEGIN CATCH
					IF @@TRANCOUNT >0
						SELECT @ErrorMsg = ERROR_MESSAGE();
						RAISERROR (@ErrorMsg,16,1);
						ROLLBACK TRANSACTION ;
						RETURN
						-- !!! raise an error
					END CATCH
					BEGIN TRY	
					BEGIN	
						IF @requestTp = 'Prj Alloc' -- 7/19/16 Nitesh B:Check for RequestTp
							INSERT INTO Invt_res (W_key, Uniq_key, QtyAlloc, Fk_PrjUnique, LotCode,ExpDate,Reference,Ponum,INVTRES_NO) 
							SELECT W_key,Uniq_key, 1,PRJUNIQUE,LotCode,ExpDate,Reference,case when lotcode<>' ' THEN Ponum ELSE ' ' END,
							dbo.fn_GenerateUniqueNumber()
							FROM @tporecser t inner join PJCTMAIN on t.WoPrjNumber=PJCTMAIN.PRJNUMBER  where t.SerialRej=0 and woprjnumber<>' '	and  RequestTp='Prj Alloc' and  (t.ReceivingStatus='Complete'	or t.ReceivingStatus=' ')																							
						END
					END TRY
					BEGIN CATCH
					IF @@TRANCOUNT >0
					    SELECT @ErrorMsg = ERROR_MESSAGE();
						RAISERROR (@ErrorMsg,16,1);
						ROLLBACK TRANSACTION ;
						-- !!! raise an error
					END CATCH
				END -- IF EXISTS(SELECT 1 from @tporecser where uniq_key<>' ' and WoPrjNumber <>' ' and (t.ReceivingStatus='Complete'	or t.ReceivingStatus=' ')	)
				*/
			IF @@TRANCOUNT>0	
				COMMIT TRANSACTION
	
		end -- -- 07/23/14 YS -- continue if receiver was completed
	END 
END -- end of insert trigger
GO
-- =============================================
-- Author:		Nitesh B
-- Create date: 07/19/2016
-- Description:	Delete the invtser records
-- =============================================
CREATE TRIGGER [dbo].[PoRecSer_Delete]
   ON  [dbo].PoRecSer 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @ErrorMsg VARCHAR(MAX);
	BEGIN TRANSACTION
		BEGIN TRY
		-- Insert statements for trigger here
		DELETE FROM INVTSER WHERE SERIALUNIQ IN (SELECT FK_SERIALUNIQ FROM Deleted)
		END TRY
		BEGIN CATCH
				IF @@TRANCOUNT >0
					SELECT @ErrorMsg = ERROR_MESSAGE();
					RAISERROR (@ErrorMsg,16,1);
					ROLLBACK TRANSACTION ;
					RETURN
		END CATCH
    IF @@TRANCOUNT>0	
		COMMIT TRANSACTION
END
GO

-- =============================================
-- Author:  Shivshankar P
-- Create date: 06/29/17
-- Description:	Insert trigger for PoRecSer table to update INVTSER ipkeyunique
-- =============================================
CREATE TRIGGER [dbo].[PoRecSer_Update]
   ON  [dbo].[PORECSER]
   AFTER UPDATE
AS 
BEGIN
	SET NOCOUNT ON;
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	BEGIN TRANSACTION
	        	BEGIN TRY
	       
		             UPDATE INVTSER SET ipkeyunique = inserted.ipkeyunique FROM inserted ,INVTSER 
					 WHERE  inserted.FK_SERIALUNIQ = INVTSER.SERIALUNIQ
	
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
	

