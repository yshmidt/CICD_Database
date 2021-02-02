CREATE TABLE [dbo].[PORECLOC] (
    [UNIQDETNO]     CHAR (10)       CONSTRAINT [DF__PORECLOC__UNIQDE__207893B8] DEFAULT ('') NOT NULL,
    [ACCPTQTY]      NUMERIC (10, 2) CONSTRAINT [DF__PORECLOC__ACCPTQ__216CB7F1] DEFAULT ((0)) NOT NULL,
    [LOC_UNIQ]      CHAR (10)       CONSTRAINT [DF__PORECLOC__LOC_UN__2260DC2A] DEFAULT ('') NOT NULL,
    [RECEIVERNO]    CHAR (10)       CONSTRAINT [DF__PORECLOC__RECEIV__23550063] DEFAULT ('') NOT NULL,
    [SDET_UNIQ]     CHAR (10)       CONSTRAINT [DF__PORECLOC__SDET_U__2449249C] DEFAULT ('') NOT NULL,
    [SINV_UNIQ]     CHAR (10)       CONSTRAINT [DF__PORECLOC__SINV_U__253D48D5] DEFAULT ('') NOT NULL,
    [REJQTY]        NUMERIC (10, 2) CONSTRAINT [DF__PORECLOC__REJQTY__26316D0E] DEFAULT ((0)) NOT NULL,
    [FK_UNIQRECDTL] CHAR (10)       CONSTRAINT [DF__PORECLOC__FK_UNI__27259147] DEFAULT ('') NOT NULL,
    [UNIQWH]        CHAR (10)       CONSTRAINT [DF__PORECLOC__UNIQWH__2819B580] DEFAULT ('') NOT NULL,
    [LOCATION]      NVARCHAR (200)  CONSTRAINT [DF__PORECLOC__LOCATI__290DD9B9] DEFAULT ('') NOT NULL,
    [sourceDev]     CHAR (1)        CONSTRAINT [DF_PORECLOC_sourceDev] DEFAULT (' ') NOT NULL,
    [IsReturn]      BIT             CONSTRAINT [DF__PORECLOC__IsRetu__2D4D42FB] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PORECLOC_PK] PRIMARY KEY CLUSTERED ([LOC_UNIQ] ASC)
);


GO
CREATE NONCLUSTERED INDEX [FKUNQRCDTL]
    ON [dbo].[PORECLOC]([FK_UNIQRECDTL] ASC);


GO
CREATE NONCLUSTERED INDEX [RECEIVERNO]
    ON [dbo].[PORECLOC]([RECEIVERNO] ASC);


GO
CREATE NONCLUSTERED INDEX [SINV_UNIQ]
    ON [dbo].[PORECLOC]([SINV_UNIQ] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQDETNO]
    ON [dbo].[PORECLOC]([UNIQDETNO] ASC);


GO
CREATE NONCLUSTERED INDEX [UnrecQty]
    ON [dbo].[PORECLOC]([SINV_UNIQ] ASC, [ACCPTQTY] ASC);


GO

-- =========================================================================================================
-- Author:		Yelena Shmidt
-- Create date: 05/08/2014
-- Description:	Insert Trigger for porec_loc table
--- for now skip the code if update from desk top
-- 07/23/14 YS added column ReceivingStatus 
-- Values 'Complete' or 'Inspection'. If ReceivingStatus ='Inspection' - do not update any tables
-- 07/31/14 YS some more changes for new 'inspection'; added new column to invtmfgr, 'mrbType'
-- 08/18/14 YS remove 'Serices', 'MRO', and 'In Store' items when updating Invtmfgr
-- 04/14/15 YS Location length is changed to varchar(256) 
-- 03/28/16 Nitesh B: Modify the trigger with receiverheader & receiverdetail table.
-- 06/30/2016 Nitesh B: Note - Part Request allocation needs to be done. 
-- 04/20/17 VL added functional currency code
-- 03/16/2018  Shivshankar P: Replaced  'RH.recStatus' by rd.isCompleted=1
-- 02/06/2019 Satish B: Update COMPLETEDT when all schedule qty is received
-- 08/07/2019 Rajendra K : Changed location datatype varchar to nvarchar
-- 03/04/20 Shivshankar P : Get the Gl NBR for In Store PO item when we receive the In Store PO created from In Plant PO module
-- =========================================================================================================
CREATE TRIGGER [dbo].[PorecLoc_Insert]
   ON  [dbo].[PORECLOC] 
   AFTER  INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN
		DECLARE @ErrorMsg VARCHAR(MAX), @ErrorNumber INT, @ErrorProc sysname, @ErrorLine INT 
		-- Not in use
		--DECLARE @uniqMrbWh char(10)=' ',@MRBWH_GL_NBR char(13)=' '
        DECLARE @requestTp VARCHAR(50), @lcInStoreGlNbr char(13)

		-- 04/14/15 YS Location length is changed to varchar(256)
		--08/07/2019 Rajendra K : Changed location datatype varchar to nvarchar
		DECLARE @tporecloc table (uniqdetno char(10),uniq_key char(10),uniqmfgrhd char(10),w_key char(10),location NVARCHAR(256),Uniqwh char(10),Uniqlnno char(10),
						Ponum char(17),	requestTp char(10),WoPrjNumber char(10),Saveinit char(8),ACCPTQTY numeric(10,2),REJQTY numeric(10,2),
						U_OF_MEAS char(4),PUR_UOFM char(4),Loc_uniq char(10),poittype char(9),fkUserId uniqueidentifier)
		--- !!! check if Porecdtl is visisble from this transaction and MPN can be used, if modified from the original in the poitems. 
			
		--select * from PORecLoc
		-- if not will have to use poitems.uniqmfgrhd for now and check our options
		INSERT INTO @tporecloc (uniqdetno ,uniq_key,UNIQMFGRHD,location ,Uniqwh ,Uniqlnno ,Ponum,
				requestTp ,WoPrjNumber,
				ACCPTQTY,REJQTY,U_OF_MEAS,PUR_UOFM,Loc_uniq,PoitType,fkUserId)
				SELECT Inserted.uniqdetno ,Poitems.uniq_key,PoRecdtl.UNIQMFGRHD ,Inserted.location ,Inserted.Uniqwh ,Poitschd.Uniqlnno ,Poitems.Ponum,
					Poitschd.requestTp ,Poitschd.WoPrjNumber,
					Inserted.ACCPTQTY ,Inserted.REJQTY,
					Porecdtl.U_OF_MEAS,Porecdtl.PUR_UOFM ,Inserted.LOC_UNIQ  ,Poitems.POITTYPE,Porecdtl.Edituserid
				FROM inserted 
							INNER JOIN POITSCHD on Inserted.UNIQDETNO = poitschd.UNIQDETNO 
							INNER JOIN Poitems on poitschd.UNIQLNNO=poitems.uniqlnno
							INNER JOIN Porecdtl on Porecdtl.uniqrecdtl=Inserted.Fk_Uniqrecdtl
							INNER JOIN receiverDetail RD on Porecdtl.receiverdetId = RD.receiverDetId
						    INNER JOIN receiverHeader RH on RD.receiverHdrId = RH.receiverHdrId
				-- 07/23/14 YS added column ReceivingStatus 
				-- Values 'Complete' or 'Inspection'. If ReceivingStatus ='Inspection' - do not run any tables updates other than Porecdtl itself)
			   WHERE rd.isCompleted=1  -- 03/16/2018  Shivshankar P: Replaced  'RH.recStatus' by rd.isCompleted=1
		-- 07/23/14 YS -- continue if receiver was completed
		
		IF @@ROWCOUNT <> 0
		BEGIN
		-- Not in use
			--SELECT @uniqMrbWh = UniqWH , @MRBWH_GL_NBR = wh_gl_nbr
			--	FROM WAREHOUS where  Warehouse='MRB'
			-- update poitschd table
			BEGIN TRANSACTION
			BEGIN TRY
				UPDATE POITSCHD SET RecdQty = (POITSCHD.RecdQty + Inserted.ACCPTQTY),
									Balance = (POITSCHD.Schd_Qty - POITSCHD.RecdQty - Inserted.ACCPTQTY),
									COMPLETEDT = CASE WHEN (POITSCHD.RecdQty + Inserted.ACCPTQTY) = POITSCHD.Schd_Qty then GETDATE() ELSE COMPLETEDT END -- 02/06/2019 Satish B: Update COMPLETEDT when all schedule qty is received
									From inserted  WHERE POITSCHD.Uniqdetno = Inserted.UNIQDETNO
				--UPDATE POITSCHD SET COMPLETEDT = CASE WHEN POITSCHD.RecdQty = POITSCHD.RECDQTY then GETDATE() ELSE COMPLETEDT END From inserted  WHERE POITSCHD.Uniqdetno = Inserted.UNIQDETNO
			END TRY
			BEGIN CATCH
				IF @@TRANCOUNT > 0
					SELECT @ErrorMsg = ERROR_MESSAGE(), @ErrorNumber = ERROR_NUMBER(), @ErrorProc = ERROR_PROCEDURE(), @ErrorLine = ERROR_LINE();
						RAISERROR (@ErrorMsg,16,1);
				ROLLBACK TRANSACTION ;
				RETURN
			END CATCH
			-- find invtmfgr record; if exists and deleted set is_deleted=0, if not exists insert a new one
			BEGIN TRY
			-- 04/14/15 YS Location length is changed to varchar(256)
				DECLARE @KeyUpdated TABLE (Uniq_key char(10),UniqMfgrHd char(10),Location NVARCHAR(256),UniqWh char(10),W_key char(10))
				-- 08/18/14 YS remove 'Serices', 'MRO', and 'In Store' items when updating Invtmfgr 
				MERGE InvtMfgr As T
					USING (SELECT p.Uniq_key,p.Uniqmfgrhd,1 as Netable,p.Location,p.UniqWH
								FROM @tporecloc P inner join Inserted on p.uniqdetno=Inserted.uniqdetno 
									where p.uniq_key<>' ' and p.uniqmfgrhd<>' ' and p.poittype<>'Service' and p.poittype<>'MRO' and p.poittype<>'In Store') as S
						ON (S.Uniq_key=T.Uniq_key AND S.Uniqmfgrhd=T.Uniqmfgrhd AND T.Location=S.Location and T.UniqWh=S.UniqWh and t.instore=0) 
						WHEN MATCHED THEN UPDATE SET T.IS_DELETED=0
						WHEN NOT MATCHED BY TARGET THEN 
							INSERT (Uniq_key,UniqMfgrHd,Netable,Location,UniqWh,W_key) 
							VALUES (S.Uniq_key,S.UniqMfgrHd,S.Netable,S.Location,S.UniqWh,dbo.fn_GenerateUniqueNumber()) 
							OUTPUT Inserted.Uniq_key,Inserted.UniqMfgrHd,Inserted.Location,Inserted.UniqWh,Inserted.W_key
								into @KeyUpdated;

			END TRY	
			BEGIN CATCH
				IF @@TRANCOUNT <>0
					ROLLBACK TRAN ;
			END CATCH
			-- now populate w_key in @tporecloc
			-- 08/18/14 YS remove 'Serices', 'MRO', and 'In Store' items when updating Invtmfgr 
			UPDATE @tporecloc SET t.w_key = k.W_key 
				from @KeyUpdated K inner join @tporecloc t on  k.Uniq_key=t.uniq_key
				and k.UniqMfgrHd = t.uniqmfgrhd  and k.UniqWh = t.Uniqwh 
				and k.Location = t.location where t.uniq_key <>' ' and t.uniqmfgrhd <>' '
				and t.poittype<>'Service' and t.poittype<>'MRO' and t.poittype<>'In Store'
			-- Update qty_oh 
			BEGIN TRY

				UPDATE INVTMFGR Set QTY_OH=QTY_OH+ dbo.fn_ConverQtyUOM(t.PUR_UOFM, t.U_of_meas,t.AccptQty) 
					FROM @tporecloc t where t.w_key=Invtmfgr.w_key and t.ACCPTQTY <>0.00 
					and t.poittype<>'Service' and t.poittype<>'MRO' and t.poittype<>'In Store'
			END TRY
			BEGIN CATCH
				IF @@TRANCOUNT <>0
					ROLLBACK TRAN ;
			END CATCH
		
			-- check if any quantities has to be reserved to a work order or a job
		
			-- check if any allocations
			-- 08/18/14 YS remove 'Serices', 'MRO', and 'In Store' items when updating Invtmfgr 
			
			-- 07/25/16 Adding from code
			--IF EXISTS(SELECT 1 from @tporecloc where uniq_key<>' ' and WoPrjNumber <>' ' and poittype<>'Service' and poittype<>'MRO' and poittype<>'In Store')
			--BEGIN 
			--	-- first check if part is not lot code and is not serialized, otherwise allocation will take place in the poreclot or porecser insert trigger
			--	IF EXISTS(SELECT 1 
			--		FROM INVENTOR INNER JOIN PARTTYPE on Inventor.PART_CLASS=parttype.PART_CLASS and inventor.PART_TYPE=parttype.PART_TYPE  
			--		INNER JOIN @tporecloc t ON Inventor.UNIQ_KEY=t.uniq_key
			--		where t.WoPrjNumber<>' '
			--		and PartType.LOTDETAIL =0
			--		and Inventor.SERIALYES = 0)	
			--	BEGIN	
			--		BEGIN TRY
			--		SELECT @requestTp= RequestTp from @tporecloc
			--			IF @requestTp = 'WO Alloc'
			--			BEGIN
			--			--- allocated to a work order
			--			INSERT INTO Invt_res (W_key, Uniq_key, QtyAlloc, Saveinit,Wono,INVTRES_NO,fk_userid) 
			--				SELECT  t.W_key, t.Uniq_key,  dbo.fn_ConverQtyUOM(t.PUR_UOFM, t.U_of_meas,t.AccptQty),
			--				'',t.woprjnumber,dbo.fn_GenerateUniqueNumber() ,t.fkUserId
			--					FROM @tporecloc t where t.RequestTp='WO Alloc'
   --                    END
			--		END TRY
			--		BEGIN CATCH
			--			IF @@TRANCOUNT >0
			--			SELECT @ErrorMsg = ERROR_MESSAGE(), @ErrorNumber = ERROR_NUMBER(), @ErrorProc = ERROR_PROCEDURE(), @ErrorLine = ERROR_LINE();
			--			RAISERROR (@ErrorMsg,16,1);
			--			ROLLBACK TRANSACTION ;
			--			---- !!! raise an error	
			--		END CATCH
			--		BEGIN TRY
			--			--- allocated to a project
			--			SELECT @requestTp= RequestTp from @tporecloc
			--			IF @requestTp = 'Prj Alloc'
			--			BEGIN
			--			INSERT INTO Invt_res (W_key, Uniq_key, QtyAlloc, Saveinit,Wono,INVTRES_NO,fk_userid) 
			--				SELECT  t.W_key, t.Uniq_key,  dbo.fn_ConverQtyUOM(t.PUR_UOFM, t.U_of_meas,t.AccptQty),
			--				'',t.woprjnumber,dbo.fn_GenerateUniqueNumber() ,t.fkUserId
			--					FROM @tporecloc t INNER JOIN PjctMain ON t.woprjnumber=Pjctmain.PRJNUMBER  
			--					where t.RequestTp='Prj Alloc'
			--					END
			--		END TRY
			--		BEGIN CATCH
			--			-- !!! raise an error
			--			SELECT @ErrorMsg = ERROR_MESSAGE(), @ErrorNumber = ERROR_NUMBER(), @ErrorProc = ERROR_PROCEDURE(), @ErrorLine = ERROR_LINE();
			--			RAISERROR (@ErrorMsg,16,1);
			--			--RollBack Tran;
			--		END CATCH
				
			--	END -- first check if part is not lot code and is not serialized, otherwise allocation will take place in the poreclot or porecser insert trigger	 
			--END  -- EXISTS(SELECT 1 from @tporecloc where uniq_key<>' ' and WoPrjNumber <>' ')
			--- insert record into porecrelgl (unreconciles records - to hold the value untill invoice is created 
		
			-- Accepted : Debit inventory account, credit un-reconcile acount . Quantities are saved in stock UOM
			--08/18/14 YS  I am not sure what to do with Service and MRO once they are part of the inventory, for now will remove it from here
			BEGIN TRY
			-- 03/04/20 Shivshankar P : Get the Gl NBR for In Store PO item when we receive the In Store PO created from In Plant PO module
			SELECT @lcInStoreGlNbr = ISNULL(Inst_Gl_No,SPACE(13)) from InvSetup;
			INSERT INTO PorecRelGL (Loc_uniq,Raw_gl_nbr,Unrecon_gl_nbr,DebitRawAcct,Trans_date,TransInit,
					TransQty,StdCost,TotalCost, 
					-- 04/20/17 VL added functional currency code, PRFcused_uniq and FuncFcused_uniq will be updated in PorecRelgl insert trigger
					StdCostPR,TotalCostPR)  
					SELECT t.Loc_uniq,
								CASE WHEN t.poittype = 'In Store' THEN @lcInStoreGlNbr ELSE W.Wh_Gl_nbr END,
								InvSetup.unrecon_gl_no,1,GETDATE(),t.saveinit, 
								dbo.fn_ConverQtyUOM(t.PUR_UOFM, t.U_of_meas,t.AccptQty),
								Inventor.StdCost,ROUND(dbo.fn_ConverQtyUOM(t.PUR_UOFM, t.U_of_meas,t.AccptQty)*Inventor.StdCost,2),
								-- 04/20/17 VL added functional currency code
								Inventor.StdCostPR,ROUND(dbo.fn_ConverQtyUOM(t.PUR_UOFM, t.U_of_meas,t.AccptQty)*Inventor.StdCostPR,2)
					FROM @tporecloc t inner join INVENTOR on Inventor.UNIQ_KEY=t.uniq_key
					INNER JOIN WAREHOUS W on w.UNIQWH=t.Uniqwh 
					CROSS JOIN INVSETUP
					WHERE t.ACCPTQTY <>0.00 
					and t.poittype<>'Service' and t.poittype<>'MRO'
			END TRY
			BEGIN CATCH
				IF @@TRANCOUNT >0
				ROLLBACK TRANSACTION ;
				-- !!! raise an error
			END CATCH	 			
			-- Rejected : debit mrb warehouse gl nbr, credit un-reconsile account
			--08/18/14 YS  I am not sure what to do with Service and MRO once they are part of the inventory, for now will remove it from here
			-- 06/30/2016 MRB WH no longer in use
			--BEGIN TRY
			--INSERT INTO PorecRelGL (Loc_uniq,Raw_gl_nbr,Unrecon_gl_nbr,DebitRawAcct,Trans_date,TransInit,
			--		TransQty,StdCost,TotalCost)  
			--		SELECT t.Loc_uniq,
			--					@MRBWH_GL_NBR,InvSetup.unrecon_gl_no,1,GETDATE(),t.saveinit, 
			--					dbo.fn_ConverQtyUOM(t.PUR_UOFM, t.U_of_meas,t.RejQty),
			--					Inventor.StdCost,ROUND(dbo.fn_ConverQtyUOM(t.PUR_UOFM, t.U_of_meas,t.REJQTY)*Inventor.StdCost,2)
			--		FROM @tporecloc t inner join INVENTOR on Inventor.UNIQ_KEY=t.uniq_key
			--		CROSS JOIN INVSETUP
			--		WHERE t.REJQTY  <>0.00 
			--		and t.poittype<>'Service' and t.poittype<>'MRO'
			--END TRY		
			--BEGIN CATCH
			--	IF @@TRANCOUNT >0
			--		ROLLBACK TRANSACTION ;
			--		-- !!! raise an error
			--END CATCH
			
			IF @@TRANCOUNT >0
				COMMIT TRANSACTION ;
		END --- -- 07/23/14 YS -- continue if receiver was completed
	END
END
GO

  
-- =========================================================================================================  
-- Author:  Shivshankar P  
-- Create date: 1/27/2014  
-- Description: Insert Trigger for porec_loc table  
-- 05/31/2017 Shivshankar P :  Update Current Qty increase/decrease  
-- 09/19/2017 Shivshankar P :  Update QTY_OH by Current Qty even ACCPTQTY 0  
-- 10/27/2017 Shivshankar P : Can not be reduce more than reserved qty  
-- 03/16/2018  Shivshankar P: Replaced  'RH.recStatus' by rd.isCompleted=1  
-- 02/06/2019 Satish B: Update COMPLETEDT when all schedule qty is received  
-- 08/07/2019 Rajendra K : Changed location datatype varchar to nvarchar  
---11/14/19 YS this is an update trigger. When PO is reconciled only sinv_uniq and sinvdet_uniq are populated  
   --- in this case no need to insert a new record into porecrelgl and no need to update any other tables.   
-- 03/04/20 Shivshankar P : Get the Gl NBR for In Store PO item when we receive the In Store PO created from In Plant PO module  
-- 08/26/2020 Rajendra K : Added "IsReturn" and "RECEIVERNO" column into @tporecloc and added Update statement to get MRB WH/LOC W_key from invtmfgr table for updating invtmfgr table
--01/14/2021 DastanT : Added to error message "You cannot reduce more than avaialble" Par Number and Mfgr Part Number
 -- 02/01/21 YS changed INNER JON with Inventor table to OUTER JOIN. Otherwise we will lose all the MRO and Service parts
-- =========================================================================================================  
CREATE TRIGGER [dbo].[PorecLoc_UPDATE]  
   ON  [dbo].[PORECLOC]   
   AFTER UPDATE  
AS   
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 BEGIN  
  DECLARE @ErrorMsg VARCHAR(MAX), @ErrorNumber INT, @ErrorProc sysname, @ErrorLine INT   
  -- Not in use  
  
  --DECLARE @uniqMrbWh char(10)=' ',@MRBWH_GL_NBR char(13)=' '  
     -- 03/04/20 Shivshankar P : Get the Gl NBR for In Store PO item when we receive the In Store PO created from In Plant PO module  
  DECLARE @accptyQty numeric(10,2)=0, @lcInStoreGlNbr char(13)=''  
  -- 04/14/15 YS Location length is changed to varchar(256)  
  --08/07/2019 Rajendra K : Changed location datatype varchar to nvarchar  
  DECLARE @tporecloc table (uniqdetno char(10),uniq_key char(10),uniqmfgrhd char(10),w_key char(10),location NVARCHAR(256),Uniqwh char(10),Uniqlnno char(10),  
      Ponum char(17), requestTp char(10),WoPrjNumber char(10),Saveinit char(8),ACCPTQTY numeric(10,2),REJQTY numeric(10,2),  
      ---01/14/21 Dastan added the Mfgr_pt_no and Part_no columns
	 U_OF_MEAS char(4),PUR_UOFM char(4),Loc_uniq char(10),poittype char(9),fkUserId uniqueidentifier,IsReturn BIT,RECEIVERNO CHAR(10),MFGR_PT_NO char(30),PART_NO char(35))
	-- 08/26/2020 Rajendra K : Added "IsReturn" and "RECEIVERNO" column into @tporecloc and added Update statement to get MRB WH/LOC W_key from invtmfgr table for updating invtmfgr table
  --- !!! check if Porecdtl is visisble from this transaction and MPN can be used, if modified from the original in the poitems.   
     
  --select * from PORecLoc  
  -- if not will have to use poitems.uniqmfgrhd for now and check our options  
  INSERT INTO @tporecloc (uniqdetno ,uniq_key,UNIQMFGRHD,location ,Uniqwh ,Uniqlnno ,Ponum,  
    requestTp ,WoPrjNumber,  
    ACCPTQTY,REJQTY,U_OF_MEAS,PUR_UOFM,Loc_uniq,PoitType,fkUserId,IsReturn,RECEIVERNO,MFGR_PT_NO,PART_NO)  
    SELECT Inserted.uniqdetno ,Poitems.uniq_key,PoRecdtl.UNIQMFGRHD ,Inserted.location ,Inserted.Uniqwh ,Poitschd.Uniqlnno ,Poitems.Ponum,  
     Poitschd.requestTp ,Poitschd.WoPrjNumber,  
     Inserted.ACCPTQTY ,Inserted.REJQTY,  
     Porecdtl.U_OF_MEAS,Porecdtl.PUR_UOFM ,Inserted.LOC_UNIQ  ,Poitems.POITTYPE,Porecdtl.Edituserid,Inserted.IsReturn,inserted.RECEIVERNO,
	 -- 08/26/2020 Rajendra K : Added "IsReturn" and "RECEIVERNO" column into @tporecloc and added Update statement to get MRB WH/LOC W_key from invtmfgr table for updating invtmfgr table  
    ---01/14/21 Dastan added the Mfgr_pt_no and Part_no columns
	---02/01/21 YS check for the null values in case of the MRO parts
	isnull(Poitems.MFGR_PT_NO,space(30)) as Mfgr_pt_no,isnull(I.PART_NO,space(35)) as Part_no
	FROM inserted   
       INNER JOIN POITSCHD on Inserted.UNIQDETNO = poitschd.UNIQDETNO   
       INNER JOIN Poitems on poitschd.UNIQLNNO=poitems.uniqlnno  
       INNER JOIN Porecdtl on Porecdtl.uniqrecdtl=Inserted.Fk_Uniqrecdtl  
       INNER JOIN receiverDetail RD on Porecdtl.receiverdetId = RD.receiverDetId  
          INNER JOIN receiverHeader RH on RD.receiverHdrId = RH.receiverHdrId  
    -- 07/23/14 Shivshankar P added column ReceivingStatus   
    -- Values 'Complete' or 'Inspection'. If ReceivingStatus ='Inspection' - do not run any tables updates other than Porecdtl itself)  
      ---01/14/21 Dastan added the Mfgr_pt_no and Part_no columns
	  -- 02/01/21 YS changed INNER JON with Inventor table to OUTER JOIN. Otherwise we will lose all the MRO and Service parts
	  --INNER JOIN INVENTOR I ON Poitems.UNIQ_KEY=I.UNIQ_KEY
	  LEFT OUTER JOIN INVENTOR I ON Poitems.UNIQ_KEY=I.UNIQ_KEY
	  WHERE rd.isCompleted=1  -- 03/16/2018  Shivshankar P: Replaced  'RH.recStatus' by rd.isCompleted=1  
  -- 07/23/14 YS -- continue if receiver was completed  
    
  --- 11/14/19 YS check if any quantities changes. if not, no need for the following code  
  IF @@ROWCOUNT <> 0 and (select inserted.ACCPTQTY-deleted.ACCPTQTY  from inserted inner join deleted on inserted.LOC_UNIQ=deleted.LOC_UNIQ)<>0  
  BEGIN  
  -- Not in use  
   --SELECT @uniqMrbWh = UniqWH , @MRBWH_GL_NBR = wh_gl_nbr  
   -- FROM WAREHOUS where  Warehouse='MRB'  
   -- update poitschd table  
   BEGIN TRANSACTION  
   BEGIN TRY  
  
    -- 05/31/2017 Shivshankar P :  Update Current Qty increase/decrease  
       select  @accptyQty =inserted.ACCPTQTY -deleted.ACCPTQTY  from inserted,deleted    
  
    UPDATE POITSCHD SET RecdQty = RecdQty +( @accptyQty),Balance = (POITSCHD.Balance - (@accptyQty)),  
    COMPLETEDT = CASE WHEN (POITSCHD.RecdQty + Inserted.ACCPTQTY) = POITSCHD.Schd_Qty then GETDATE() ELSE COMPLETEDT END FROM --02/06/2019 Satish B:Update COMPLETEDT when all schedule qty is received  
    POITSCHD JOIN Inserted ON POITSCHD.Uniqdetno = Inserted.UNIQDETNO   
    --UPDATE POITSCHD SET COMPLETEDT = CASE WHEN POITSCHD.RecdQty = POITSCHD.RECDQTY then GETDATE() ELSE COMPLETEDT END  
    --FROM POITSCHD JOIN Inserted on POITSCHD.Uniqdetno = Inserted.UNIQDETNO   
  
  
   END TRY  
   BEGIN CATCH  
    IF @@TRANCOUNT > 0  
     SELECT @ErrorMsg = ERROR_MESSAGE(), @ErrorNumber = ERROR_NUMBER(), @ErrorProc = ERROR_PROCEDURE(), @ErrorLine = ERROR_LINE();  
      RAISERROR (@ErrorMsg,16,1);  
    ROLLBACK TRANSACTION ;  
    RETURN  
   END CATCH  
   -- find invtmfgr record; if exists and deleted set is_deleted=0, if not exists insert a new one  
   BEGIN TRY  
   -- 04/14/15 YS Location length is changed to varchar(256)  
    DECLARE @KeyUpdated TABLE (Uniq_key char(10),UniqMfgrHd char(10),Location nvarchar(256),UniqWh char(10),W_key char(10))  
    -- 08/18/14 YS remove 'Serices', 'MRO', and 'In Store' items when updating Invtmfgr   
    MERGE InvtMfgr As T  
     USING (SELECT p.Uniq_key,p.Uniqmfgrhd,1 as Netable,p.Location,p.UniqWH  
        FROM @tporecloc P inner join Inserted on p.uniqdetno=Inserted.uniqdetno   
         where p.uniq_key<>' ' and p.uniqmfgrhd<>' ' and p.poittype<>'Service' and p.poittype<>'MRO' and p.poittype<>'In Store') as S  
      ON (S.Uniq_key=T.Uniq_key AND S.Uniqmfgrhd=T.Uniqmfgrhd AND T.Location=S.Location and T.UniqWh=S.UniqWh and t.instore=0)   
      WHEN MATCHED THEN UPDATE SET T.IS_DELETED=0  
      WHEN NOT MATCHED BY TARGET THEN   
       INSERT (Uniq_key,UniqMfgrHd,Netable,Location,UniqWh,W_key)   
       VALUES (S.Uniq_key,S.UniqMfgrHd,S.Netable,S.Location,S.UniqWh,dbo.fn_GenerateUniqueNumber())   
       OUTPUT Inserted.Uniq_key,Inserted.UniqMfgrHd,Inserted.Location,Inserted.UniqWh,Inserted.W_key  
        into @KeyUpdated;  
  
   END TRY   
   BEGIN CATCH  
    IF @@TRANCOUNT <>0  
     ROLLBACK TRAN ;  
   END CATCH  
   --select * from @tporecloc  
   -- now populate w_key in @tporecloc  
   -- 08/18/14 YS remove 'Serices', 'MRO', and 'In Store' items when updating Invtmfgr   
   UPDATE @tporecloc SET t.w_key = k.W_key   
    from @KeyUpdated K inner join @tporecloc t on  k.Uniq_key=t.uniq_key  
    and k.UniqMfgrHd = t.uniqmfgrhd  and k.UniqWh = t.Uniqwh   
    and k.Location = t.location where t.uniq_key <>' ' and t.uniqmfgrhd <>' '  
    and t.poittype<>'Service' and t.poittype<>'MRO' and t.poittype<>'In Store'  
   -- Update qty_oh 
   
   -- 08/26/2020 Rajendra K : Added "IsReturn" and "RECEIVERNO" column into @tporecloc and added Update statement to get MRB WH/LOC W_key from invtmfgr table for updating invtmfgr table
   UPDATE t SET t.W_key = mf.w_key,t.UNIQWH = mf.UNIQWH,t.location = mf.LOCATION
   FROM @tporecloc t  
   INNER JOIN receiverHeader rh ON rh.receiverno = t.RECEIVERNO
   INNER JOIN receiverDetail rd ON rd.receiverHdrId = rh.receiverHdrId
   INNER JOIN inspectionHeader ih ON ih.receiverDetId = rd.receiverDetId
   INNER JOIN INVTMFGR mf ON t.uniqmfgrhd = mf.UNIQMFGRHD AND t.uniq_key = mf.UNIQ_KEY AND mf.LOCATION = ih.inspHeaderId
   INNER JOIN WAREHOUS w ON w.UNIQWH = mf.UNIQWH AND WAREHOUSE = 'MRB'
   WHERE t.IsReturn = 1
    
   BEGIN TRY  
   -- 10/27/2017 Shivshankar P : Can not be reduce more than reserved qty  
    IF  EXISTS((select  1 FROM @tporecloc t INNER JOIN INVTMFGR ON t.w_key=Invtmfgr.w_key   
     and t.poittype<>'Service' and t.poittype<>'MRO' and t.poittype<>'In Store' WHERE Invtmfgr.QTY_OH + (@accptyQty) < Invtmfgr.RESERVED))  
    BEGIN  
	--14/01/2021 DastanT Added to error message Part Number and Mfgr Part Number
	DECLARE @part_no char(30),@MFGR_PT_NO char(35),@error_ char(300);

	select  @part_no=T.PART_NO,@MFGR_PT_NO=T.MFGR_PT_NO  FROM @tporecloc t INNER JOIN INVTMFGR ON t.w_key=Invtmfgr.w_key   
     and t.poittype<>'Service' and t.poittype<>'MRO' and t.poittype<>'In Store'  WHERE Invtmfgr.QTY_OH + (@accptyQty) < Invtmfgr.RESERVED;
	 set @error_='You cannot reduce more than avaialble quantity in the respective warehouse, Part Number='+ @part_no+' MFGR Part Number='+@MFGR_PT_NO;
      RAISERROR(@error_,1,1)    
      ROLLBACK TRANSACTION ;  
      RETURN   
   END --- IF  EXISTS((select  1 FROM @tporecloc t INNER JOIN INVTMFGR ...  
      
           -- 05/31/2017 Shivshankar P :  Update Current Qty increase/decrease  
     UPDATE INVTMFGR Set QTY_OH= QTY_OH + (dbo.fn_ConverQtyUOM(t.PUR_UOFM, t.U_of_meas,@accptyQty))   
     FROM @tporecloc t where t.w_key=Invtmfgr.w_key --and t.ACCPTQTY <>0.00    -- 09/19/2017 Shivshankar P :  Update QTY_OH by Current Qty even ACCPTQTY 0  
     and t.poittype<>'Service' and t.poittype<>'MRO' and t.poittype<>'In Store'  
        
   END TRY  
   BEGIN CATCH  
    IF @@TRANCOUNT <>0  
     ROLLBACK TRAN ;  
   END CATCH    
     
   BEGIN TRY  
      -- 03/04/20 Shivshankar P : Get the Gl NBR for In Store PO item when we receive the In Store PO created from In Plant PO module  
   SELECT @lcInStoreGlNbr = ISNULL(Inst_Gl_No,SPACE(13)) from InvSetup;  
     
   ---11/14/19 YS this is an update trigger. When PO is reconciled only sinv_uniq and sinvdet_uniq are populated  
   --- in this case no need to insert a new record into porecrelgl and no need to update any other tables.   
   INSERT INTO PorecRelGL (Loc_uniq,Raw_gl_nbr,Unrecon_gl_nbr,DebitRawAcct,Trans_date,TransInit,  
     TransQty,StdCost,TotalCost)    
     SELECT t.Loc_uniq,  
        CASE WHEN t.poittype = 'In Store' THEN @lcInStoreGlNbr ELSE W.Wh_Gl_nbr END,  
        InvSetup.unrecon_gl_no,1,GETDATE(),t.saveinit,   
        dbo.fn_ConverQtyUOM(t.PUR_UOFM, t.U_of_meas,@accptyQty), -- 05/31/2017 Shivshankar P :  Update Current Qty increase/decrease  
        Inventor.StdCost,  
        ---11/14/19 YS check for @accptyQty<>0.00 in calculation  
        --ROUND(dbo.fn_ConverQtyUOM(t.PUR_UOFM, t.U_of_meas,t.AccptQty)*Inventor.StdCost,2)  
        ROUND(dbo.fn_ConverQtyUOM(t.PUR_UOFM, t.U_of_meas,@accptyQty)*Inventor.StdCost,2)  
     FROM @tporecloc t inner join INVENTOR on Inventor.UNIQ_KEY=t.uniq_key  
     INNER JOIN WAREHOUS W on w.UNIQWH=t.Uniqwh   
     CROSS JOIN INVSETUP  
     ---11/14/19 YS check for @accptyQty<>0.00  
     --WHERE t.ACCPTQTY <>0.00   
     where @accptyQty<>0.00  
     and t.poittype<>'Service' and t.poittype<>'MRO'  
          
     ---11/14/19 YS code replaced in the above statement     
     /*  
        ROUND(dbo.fn_ConverQtyUOM(t.PUR_UOFM, t.U_of_meas,t.AccptQty)*Inventor.StdCost,2)  
     FROM @tporecloc t inner join INVENTOR on Inventor.UNIQ_KEY=t.uniq_key  
     INNER JOIN WAREHOUS W on w.UNIQWH=t.Uniqwh   
     CROSS JOIN INVSETUP  
     WHERE t.ACCPTQTY <>0.00   
     and t.poittype<>'Service' and t.poittype<>'MRO'  
     */  
   END TRY  
   BEGIN CATCH  
    IF @@TRANCOUNT >0  
    ROLLBACK TRANSACTION ;  
    -- !!! raise an error  
   END CATCH       
    
   IF @@TRANCOUNT >0  
    COMMIT TRANSACTION ;  
  END   
 END  
END  
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER dbo.PoRecLoc_Delete
   ON  PoRecLoc 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	DELETE FROM PoRecSer WHERE Loc_uniq IN (SELECT Loc_uniq FROM Deleted)
    DELETE FROM PoReclot WHERE Loc_uniq IN (SELECT Loc_uniq FROM Deleted )
END