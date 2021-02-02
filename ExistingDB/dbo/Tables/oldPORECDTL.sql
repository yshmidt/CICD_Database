CREATE TABLE [dbo].[oldPORECDTL] (
    [TRANSNO]         NUMERIC (8)      CONSTRAINT [DF__oldPORECDTL__TRANSN__06B8C1B5] DEFAULT ((0)) NOT NULL,
    [UNIQLNNO]        CHAR (10)        CONSTRAINT [DF__oldPORECDTL__UNIQLN__07ACE5EE] DEFAULT ('') NOT NULL,
    [RECVDATE]        SMALLDATETIME    NULL,
    [PORECPKNO]       CHAR (15)        CONSTRAINT [DF_oldPORECDTL_PORECPKNO] DEFAULT ('') NOT NULL,
    [REJQTY]          NUMERIC (10, 2)  CONSTRAINT [DF__oldPORECDTL__REJQTY__09952E60] DEFAULT ((0)) NOT NULL,
    [REJREASON]       CHAR (15)        CONSTRAINT [DF__oldPORECDTL__REJREA__0A895299] DEFAULT ('') NOT NULL,
    [ACCPTQTY]        NUMERIC (10, 2)  CONSTRAINT [DF__oldPORECDTL__ACCPTQ__0B7D76D2] DEFAULT ((0)) NOT NULL,
    [RECVQTY]         NUMERIC (10, 2)  CONSTRAINT [DF__oldPORECDTL__RECVQT__0C719B0B] DEFAULT ((0)) NOT NULL,
    [DATECODE]        CHAR (10)        CONSTRAINT [DF__oldPORECDTL__DATECO__0D65BF44] DEFAULT ('') NOT NULL,
    [U_OF_MEAS]       CHAR (4)         CONSTRAINT [DF__oldPORECDTL__U_OF_M__0E59E37D] DEFAULT ('') NOT NULL,
    [PUR_UOFM]        CHAR (4)         CONSTRAINT [DF__oldPORECDTL__PUR_UO__0F4E07B6] DEFAULT ('') NOT NULL,
    [IS_PRINTED]      BIT              CONSTRAINT [DF__oldPORECDTL__IS_PRI__10422BEF] DEFAULT ((0)) NOT NULL,
    [IS_LABELS]       BIT              CONSTRAINT [DF__oldPORECDTL__IS_LAB__11365028] DEFAULT ((0)) NOT NULL,
    [RECEIVERNO]      CHAR (10)        CONSTRAINT [DF__oldPORECDTL__RECEIV__122A7461] DEFAULT ('') NOT NULL,
    [DOCK_UNIQ]       CHAR (10)        CONSTRAINT [DF__oldPORECDTL__DOCK_U__131E989A] DEFAULT ('') NOT NULL,
    [UNIQRECDTL]      CHAR (10)        CONSTRAINT [DF__oldPORECDTL__UNIQRE__1412BCD3] DEFAULT ('') NOT NULL,
    [RECINIT]         CHAR (8)         CONSTRAINT [DF__oldPORECDTL__RECINI__1506E10C] DEFAULT ('') NULL,
    [EDITINIT]        CHAR (8)         CONSTRAINT [DF__oldPORECDTL__EDITIN__15FB0545] DEFAULT ('') NULL,
    [EDITDATE]        SMALLDATETIME    NULL,
    [FRSTARTCHK]      BIT              CONSTRAINT [DF__oldPORECDTL__FRSTAR__16EF297E] DEFAULT ((0)) NOT NULL,
    [INSPCHK]         BIT              CONSTRAINT [DF__oldPORECDTL__INSPCH__17E34DB7] DEFAULT ((0)) NOT NULL,
    [CERTCHK]         BIT              CONSTRAINT [DF__oldPORECDTL__CERTCH__18D771F0] DEFAULT ((0)) NOT NULL,
    [FRSTARTNOTE]     TEXT             CONSTRAINT [DF__oldPORECDTL__FRSTAR__19CB9629] DEFAULT ('') NOT NULL,
    [FRSTARTDISP]     CHAR (15)        CONSTRAINT [DF__oldPORECDTL__FRSTAR__1ABFBA62] DEFAULT ('') NOT NULL,
    [UNIQMFGRHD]      CHAR (10)        CONSTRAINT [DF__oldPORECDTL__UNIQMF__1BB3DE9B] DEFAULT ('') NOT NULL,
    [PARTMFGR]        CHAR (8)         CONSTRAINT [DF__oldPORECDTL__PARTMF__1CA802D4] DEFAULT ('') NOT NULL,
    [MFGR_PT_NO]      CHAR (30)        CONSTRAINT [DF__oldPORECDTL__MFGR_P__1D9C270D] DEFAULT ('') NOT NULL,
    [sourceDev]       CHAR (1)         CONSTRAINT [DF_oldPORECDTL_updateMode] DEFAULT ('') NOT NULL,
    [fk_Recuserid]    UNIQUEIDENTIFIER NULL,
    [fk_Edituserid]   UNIQUEIDENTIFIER NULL,
    [ReceivingStatus] VARCHAR (20)     CONSTRAINT [DF_oldPORECDTL_ReceivingStatus] DEFAULT ('') NOT NULL,
    CONSTRAINT [oldPORECDTL_PK] PRIMARY KEY CLUSTERED ([UNIQRECDTL] ASC)
);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/10/10
-- Description:	Delete trigger for the porecdtl
-- =============================================
CREATE TRIGGER [dbo].[oldPoRecDtl_Delete]
   ON  [dbo].[oldPORECDTL]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    DELETE FROM PoRecLoc WHERE PoRecloc.Fk_UniqRecDtl in (SELECT UniqRecdtl FROM Deleted)
END

GO

-- =============================================
-- Author:		David Sharp
-- Create date: 11/17/2012
-- Description:	notify users when a specific part is received
-- 01/15/14 YS added new column notificationType varchar(20)
--- coud have 'N' - for notification
---			  'E' - for email
---			  'N,E' - for both
--- open for future methods of notification
--- Modified: 05/06/2014 YS renamed the trigger from [NOTICE_MfgReceived]
-- and add the code to update all appropriate tables when inserting a record from the web
-- added column to Porecdtl "sourceDev" , if value='D' then update all the appropriate records.
-- 07/23/14 YS added column ReceivingStatus 
-- Values 'Complete' or 'Inspection'. If ReceivingStatus ='Inspection' - do not run any tables updates other than Porecdtl itself)
-- 07/31/14 YS some more changes for the new inspection design
-- 08/12/14 DS fixed notification string to add the missing ' before the part number
-- 08/18/14 YS remove 'Serices', 'MRO', and 'In Store' items when updating Invtmfgr 
--09/10/14 YS update po status
-- 10/09/14 YS removed Invtmfhd table and replaced with 2 new tables
-- =============================================
CREATE TRIGGER [dbo].[oldPoRecDtl_INSERT]
   ON  [dbo].[oldPORECDTL]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for trigger here
	-- new 05/06/14 YS code for the insert 
	-- Check if from desktop skip this code
	DECLARE @errorCode int,
		@MRBUniqWH char(10)=' ',
		@NoMrbWH bit = 0
		
	

	-- 07/23/14 YS added column ReceivingStatus 
	IF NOT EXISTS(Select 1 from Inserted where Inserted.sourceDev='D')
	BEGIN
		--- Tables to update when records are inserted into PoRecdtl table
		--1. Poitems
		-- get Mrb warehouse just in case
		BEGIN TRANSACTION
			SELECT @MRBUniqWH = UniqWH FROM WAREHOUS where  Warehouse='MRB'
			SELECT @NoMrbWH = CASE WHEN @MRBUniqWH=' ' THEN 1 ELSE 0 END
			declare @poitems table (uniqlnno char(10),PoItType char(9),uniq_key char(10),uniqmfgrhd char(10),ponum char(15))
			INSERT INTO @poitems 
			SELECT Inserted.Uniqlnno,Poitems.PoItType,Poitems.UNIQ_KEY,Inserted.UniqMfgrhd,Poitems.PONUM 
				FROM inserted inner join POITEMS on poitems.UNIQLNNO=inserted.UNIQLNNO 
			IF @@ROWCOUNT = 0
			BEGIN
				--- 07/23/14 added error handling 
				RAISERROR('System failed to locate original record in Poitems table. 
				Please contact ManEx with detailed information of the action prior to this message.',1,1) ;
				ROLLBACK TRANSACTION ;
				RETURN 
			END
		 		
			-- check if any line items cancelled
			IF EXISTS (SELECT 1 from POITEMS inner join Inserted ON Poitems.UNIQLNNO =Inserted.Uniqlnno where Poitems.LCANCEL = 1 ) 
			BEGIN
				--- 07/23/14 added error handling 
				RAISERROR('Purchase Order Line Item was Cancelled. Please check the purchase order.',1,1)
				ROLLBACK TRANSACTION ;
				RETURN 
			END
			-- check if recvqty=rejqty+accptqty
			IF EXISTS (SELECT * from inserted where Inserted.ACCPTQTY + Inserted.REJQTY <> Inserted.RECVQTY) 
			BEGIN
				
				--- just update recv qty with the correct value
				BEGIN TRY
				UPDATE oldPORECDTL SET RECVQTY=Inserted.ACCPTQTY+Inserted.REJQTY FROM Inserted WHERE oldPorecdtl.UNIQLNNO =Inserted.uniqlnno  ;
				END TRY
				BEGIN CATCH
					IF @@TRANCOUNT >0
						ROLLBACK TRANSACTION ;
						RETURN
				END CATCH
			END
			
			-- check if reject qty make sure MRB location exists
			--07/23/14 YS do not update Invtmfgr if status of the receiver is not complete
			--07/31/14 YS place it under MRB , location PO and update new mrbType column with 'I' for waiting for incoming inspection
			if EXISTS(SELECT 1 from inserted where Inserted.ReceivingStatus='Inspection')
			BEGIN
				-- check if mrb wh exists
				if @NoMrbWH = 1
				BEGIN
					
					--- 07/23/14 added error handling 
					RAISERROR('Cannot find MRB warehouse in the Warehous Table. Please check warehouse setup.',1,1)
					ROLLBACK TRANSACTION ;
					RETURN 
				END -- if @NoMrbWH = 1

				-- find  MRB locations and if is_deleted then set is_deleted to 0, if missing insert. Update qty
				-- 08/18/14 YS remove 'Serices', 'MRO', and 'In Store' items 
				BEGIN TRY
					MERGE InvtMfgr As T
					USING (SELECT Uniq_key,Inserted.Uniqmfgrhd,0 as Netable,'PO'+P.Ponum as Location,@MRBUniqWH as UniqWH,Inserted.U_OF_MEAS,Inserted.PUR_UOFM,
							Inserted.recvqty
							FROM @poitems P inner join Inserted on p.uniqlnno=Inserted.uniqlnno where p.uniq_key<>' ' and inserted.uniqmfgrhd<>' '
							and inserted.recvqty<>0 and Inserted.ReceivingStatus='Inspection' and p.PoitType<>'Services' and p.PoitType<>'MRO' and p.PoitType<>'In Store') as S
					ON (S.Uniq_key=T.Uniq_key AND S.Uniqmfgrhd=T.Uniqmfgrhd AND T.Location=S.Location and T.UniqWh=S.UniqWh and t.instore=0 and t.mrbType='I')
					WHEN MATCHED THEN UPDATE SET T.IS_DELETED=0,qty_oh=qty_oh+dbo.fn_ConverQtyUOM(S.PUR_UOFM,s.U_of_meas,s.RecvQty)
					WHEN NOT MATCHED BY TARGET THEN 
						INSERT (Uniq_key,UniqMfgrHd,Netable,Location,UniqWh,W_key,Qty_oh,mrbType) 
						VALUES (S.Uniq_key,S.UniqMfgrHd,S.Netable,S.Location,S.UniqWh,dbo.fn_GenerateUniqueNumber(),
						dbo.fn_ConverQtyUOM(S.PUR_UOFM,s.U_of_meas,s.RecvQty),'I') ;

				END TRY	
				BEGIN CATCH
				IF @@TRANCOUNT <>0
					ROLLBACK TRAN ;
					RETURN
				END CATCH

			END -- if EXISTS(SELECT 1 from inserted where Inserted.ReceivingStatus='Inspection')
			-- 07/31/14 YS in case there are multiple records in a batch, "inserted" will have multiple records, some of which might be 'Complete',
			-- have to run through the following 'IF'
			IF EXISTS(SELECT 1 from inserted where REJQTY<>0 and Inserted.ReceivingStatus<>'Inspection')
			BEGIN
				-- check if mrb wh exists
				if @NoMrbWH = 1
				BEGIN
					
					--- 07/23/14 added error handling 
					RAISERROR('Cannot find MRB warehouse in the Warehous Table. Please check warehouse setup.',1,1)
					ROLLBACK TRANSACTION ;
					RETURN 
				END -- if @NoMrbWH = 1
				-- find  MRB locations and if is_deleted then set is_deleted to 0, if missing insert. Update qty
				--07/31/14 YS added (Inserted.ReceivingStatus ='Complete' or Inserted.ReceivingStatus =' ') added code for mrbtype
				BEGIN TRY
					-- 08/18/14 YS remove  'MRO' items 
					MERGE InvtMfgr As T
					USING (SELECT Uniq_key,Inserted.Uniqmfgrhd,0 as Netable,'PO'+P.Ponum as Location,@MRBUniqWH as UniqWH,Inserted.U_OF_MEAS,Inserted.PUR_UOFM,
							Inserted.RejQty
							FROM @poitems P inner join Inserted on p.uniqlnno=Inserted.uniqlnno where p.uniq_key<>' ' and inserted.uniqmfgrhd<>' '
							and inserted.RejQty<>0 and (Inserted.ReceivingStatus ='Complete' or Inserted.ReceivingStatus =' ') and P.PoitType<>'MRO') as S
					ON (S.Uniq_key=T.Uniq_key AND S.Uniqmfgrhd=T.Uniqmfgrhd AND T.Location=S.Location and T.UniqWh=S.UniqWh and t.instore=0 and (t.mrbType='R' OR t.mrbType=' '))
					WHEN MATCHED THEN UPDATE SET T.IS_DELETED=0,qty_oh=qty_oh+dbo.fn_ConverQtyUOM(S.PUR_UOFM,s.U_of_meas,s.RejQty)
					WHEN NOT MATCHED BY TARGET THEN 
						INSERT (Uniq_key,UniqMfgrHd,Netable,Location,UniqWh,W_key,Qty_oh,mrbType) 
						VALUES (S.Uniq_key,S.UniqMfgrHd,S.Netable,S.Location,S.UniqWh,dbo.fn_GenerateUniqueNumber(),
						dbo.fn_ConverQtyUOM(S.PUR_UOFM,s.U_of_meas,s.RejQty),'R') ;

				END TRY	
				BEGIN CATCH
				IF @@TRANCOUNT <>0
					ROLLBACK TRAN ;
					RETURN
				END CATCH
				-- insert repcord into PoRecMrb
				
				BEGIN TRY
					INSERT INTO PoRecMrb (Transno,Rej_Date, Fk_UniqRecdtl,DMRUNIQUE) 
						SELECT Inserted.Transno,Inserted.RECVDATE,Inserted.UniqRecdtl,dbo.fn_GenerateUniqueNumber() 
						-- 07/23/14 YS this has to be done only when recever is complete
							FROM Inserted where (Inserted.ReceivingStatus ='Complete' or Inserted.ReceivingStatus =' ') ;
				END TRY
				BEGIN CATCH
				IF @@TRANCOUNT <>0
					ROLLBACK TRAN ;
					RETURN
				END CATCH
			END  --- IF EXISTS(SELECT 1 from inserted where REJQTY<>0 and Inserted.ReceivingStatus<>'Inspection')
			BEGIN TRY
			-- item exists and was not cancelled
			UPDATE Poitems SET Poitems.ACPT_QTY=Poitems.ACPT_QTY+Inserted.AccptQty, 
						Poitems.REJ_QTY = Poitems.Rej_qty+Inserted.RejQty,  
					 	Poitems.RECV_QTY = Poitems.RECV_QTY+Inserted.ACCPTQTY+Inserted.REJQTY 
						-- 07/23/14 YS this has to be done only when recever is complete
					FROM inserted WHERE Inserted.uniqlnno=Poitems.Uniqlnno 
					and  (Inserted.ReceivingStatus ='Complete' or Inserted.ReceivingStatus =' ') ;
					
			END TRY
			BEGIN CATCH
				IF @@TRANCOUNT <>0
					ROLLBACK TRAN ;
					RETURN
			END CATCH
		--09/10/14 YS update po status
		BEGIN TRY
		;with items
		as 
	   (select ponum, sum(ord_qty-acpt_qty) as balance  
		from POITEMS where PONUM In (select ponum from @poitems ) group by ponum 
	   ) 
	   UPDATE POMAIN set POSTATUS = CASE WHEN items.balance =0 then 'CLOSED' ELSE POSTATUS end from items where items.PONUM=pomain.ponum
	   END TRY
	   BEGIN CATCH
		IF @@TRANCOUNT <>0
		 ROLLBACK TRAN ;
		 RETURN
	   END CATCH


	IF @@TRANCOUNT>0
		COMMIT TRANSACTION
	END ----IF NOT EXISTS(Select 1 from Inserted where Inserted.sourceDev='D')
	
	
	--- from here down code by David
	-- 10/09/14 YS removed Invtmfhd table and replaced with 2 new tables
	DECLARE @notificationValue varchar(MAX)
	SELECT @notificationValue='{''mfgr_pt_no'':'''+CAST(a.MFGR_PT_NO as varchar(50))+''',''ponum'':'''+CAST(RTRIM(p.PONUM)as varchar(50))+
				''',''part_no'':'''+RTRIM(i.PART_NO)+''',''partmfgr'':'''+RTRIM(a.PARTMFGR)+''',''accptqty'':'+CAST(RTRIM(n.ACCPTQTY) as varchar(50))+
				CASE WHEN n.REJQTY>0 
					THEN ',''rejqty'':'+CAST(RTRIM(n.REJQTY) as varchar(50))+',''rejreason'':'''+RTRIM(n.REJREASON)+'''}'
					ELSE '}'
					END
		FROM wmTriggersActionSubsc s 
			INNER JOIN inserted n ON n.UNIQMFGRHD=s.recordLink 
			---- 10/09/14 YS removed Invtmfhd table and replaced with 2 new tables
			--INNER JOIN INVTMFHD a ON n.UNIQMFGRHD=a.UNIQMFGRHD
			INNER JOIN InvtMPNLink L ON n.UNIQMFGRHD=L.UNIQMFGRHD
			INNER JOIN MfgrMaster a ON l.mfgrMasterId=a.MfgrMasterId
			INNER JOIN INVENTOR i ON i.UNIQ_KEY=l.UNIQ_KEY
			INNER JOIN POITEMS p ON n.UNIQLNNO=p.UNIQLNNO
		WHERE linkType='UNIQMFGRHD'
	
	-- 10/09/14 YS removed Invtmfhd table and replaced with 2 new tables
	INSERT INTO wmTriggerNotification(noticeType,recipientId,[subject],notificationValues,dateAdded,triggerId)
	SELECT 'Subscribe',fkUserId,'MPN Receipt: '+CAST(a.MFGR_PT_NO as varchar(50)),
			@notificationValue,	GETDATE(),fkActTriggerId
		FROM wmTriggersActionSubsc s 
			INNER JOIN inserted n ON n.UNIQMFGRHD=s.recordLink 
			-- 10/09/14 YS removed Invtmfhd table and replaced with 2 new tables
			---INNER JOIN INVTMFHD a ON n.UNIQMFGRHD=a.UNIQMFGRHD
			INNER JOIN InvtMPNLink L ON n.UNIQMFGRHD=l.UNIQMFGRHD
			INNER JOIN MfgrMaster a ON l.mfgrMasterId=a.MfgrMasterId
			INNER JOIN INVENTOR i ON i.UNIQ_KEY=L.UNIQ_KEY
			INNER JOIN POITEMS p ON n.UNIQLNNO=p.UNIQLNNO
		WHERE linkType='UNIQMFGRHD'
		-- 01/15/14 YS added new column notificationType varchar(20)
		and charindex('N',notificationType)<>0
		
		
 
END