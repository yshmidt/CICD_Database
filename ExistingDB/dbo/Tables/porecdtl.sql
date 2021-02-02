CREATE TABLE [dbo].[porecdtl] (
    [uniqrecdtl]      CHAR (10)        CONSTRAINT [DF_porecdtl_uniqrecdtl] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    [receiverdetId]   CHAR (10)        CONSTRAINT [DF_porecdtl_receiverdetId] DEFAULT ('') NOT NULL,
    [uniqlnno]        CHAR (10)        CONSTRAINT [DF_porecdtl_uniqlnno] DEFAULT ('') NOT NULL,
    [recvdate]        SMALLDATETIME    NULL,
    [porecpkno]       CHAR (15)        CONSTRAINT [DF_porecdtl_porecpkno] DEFAULT ('') NOT NULL,
    [ReceivedQty]     NUMERIC (12, 2)  CONSTRAINT [DF_porecdtl_ReceivedQty] DEFAULT ((0.00)) NOT NULL,
    [FailedQty]       NUMERIC (12, 2)  CONSTRAINT [DF_porecdtl_FailedQty] DEFAULT ((0.00)) NOT NULL,
    [AcceptedQty]     NUMERIC (12, 2)  CONSTRAINT [DF_porecdtl_AcceptedQty] DEFAULT ((0.00)) NOT NULL,
    [U_of_meas]       CHAR (4)         CONSTRAINT [DF_porecdtl_U_of_meas] DEFAULT ('') NOT NULL,
    [pur_uofm]        CHAR (4)         CONSTRAINT [DF_porecdtl_pur_uofm] DEFAULT ('') NOT NULL,
    [receiverno]      CHAR (10)        CONSTRAINT [DF_porecdtl_receiverno] DEFAULT ('') NOT NULL,
    [uniqmfgrhd]      CHAR (10)        CONSTRAINT [DF_porecdtl_uniqmfgrhd] DEFAULT ('') NOT NULL,
    [partmfgr]        CHAR (8)         CONSTRAINT [DF_porecdtl_partmfgr] DEFAULT ('') NOT NULL,
    [mfgr_pt_no]      CHAR (35)        CONSTRAINT [DF_porecdtl_mfgr_pt_no] DEFAULT ('') NOT NULL,
    [IS_PRINTED]      BIT              CONSTRAINT [DF__porecdtl__IS_PRI__6C1C3C17] DEFAULT ((0)) NOT NULL,
    [IS_LABELS]       BIT              CONSTRAINT [DF__porecdtl__IS_LAB__6D106050] DEFAULT ((0)) NOT NULL,
    [EDITDATE]        SMALLDATETIME    NULL,
    [Edituserid]      UNIQUEIDENTIFIER NULL,
    [sourceDev]       CHAR (1)         CONSTRAINT [DF_porecdtl_sourceDev] DEFAULT ('') NOT NULL,
    [FcUsed_uniq]     CHAR (10)        CONSTRAINT [DF_porecdtl_FcUsed_uniq] DEFAULT ('') NOT NULL,
    [Fchist_key]      CHAR (10)        CONSTRAINT [DF_porecdtl_Fchist_key] DEFAULT ('') NOT NULL,
    [PRFcused_Uniq]   CHAR (10)        CONSTRAINT [DF__porecdtl__PRFcus__4305E342] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)        CONSTRAINT [DF__porecdtl__FUNCFC__43FA077B] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_porecdtl] PRIMARY KEY CLUSTERED ([uniqrecdtl] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_porecdtl]
    ON [dbo].[porecdtl]([receiverdetId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_porecdtl_1]
    ON [dbo].[porecdtl]([uniqlnno] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_porecdtl_2]
    ON [dbo].[porecdtl]([uniqmfgrhd] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_porecdtl_3]
    ON [dbo].[porecdtl]([recvdate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_porecdtl_4]
    ON [dbo].[porecdtl]([partmfgr] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_porecdtl_5]
    ON [dbo].[porecdtl]([mfgr_pt_no] ASC);


GO
-- ====================================================================================
-- Author:		Nitesh B
-- Create date: 05/14/2016
-- Description: Update The POitems Quantity if record inserted to PoRecDtl table
-- 6/10/2016 Nitesh B: updating the PO receiving detail  information w r to Uniqrecdtl
--                     Update the POMAIN.POSTATUS When balance is 0 or less.  
-- 01/25/2017 VL:	   added functional currency code to update functional and presentation currency fields
-- 12/14/2017 Shiv:	   Added functional currency code to update functional and presentation currency fields (FcUsed_uniq,Fchist_key) 
                       --FROM SUPINFO
-- 02/06/2018 Satish B: Added for update closedate when balance is zero or less
-- 10/15/2020 Shivshankar P : Change condition in where from AND to OR (receiverHeader.recStatus ='Complete' OR receiverDetail.isCompleted = 1) 
-- ====================================================================================
CREATE TRIGGER [dbo].[PoRecDtl_INSERT]
   ON  [dbo].[porecdtl]
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
		BEGIN TRANSACTION
			-- Chcek if any line items cancelled
			IF EXISTS (SELECT 1 from POITEMS inner join Inserted ON Poitems.UNIQLNNO =Inserted.Uniqlnno where Poitems.LCANCEL = 1 ) 
			BEGIN
				RAISERROR('Purchase Order Line Item was Cancelled. Please check the purchase order.',1,1)
				ROLLBACK TRANSACTION ;
				RETURN 
			END
			IF EXISTS (SELECT 1 from inserted where (Inserted.AcceptedQty + Inserted.FailedQty) <> Inserted.ReceivedQty)
			BEGIN
				--- just update recv qty with the correct value
				BEGIN TRY
				-- 6/10/2016 Nitesh B: updating the PO receiving detail  information w r to Uniqrecdtl
				UPDATE PORECDTL SET ReceivedQty= (Inserted.AcceptedQty+Inserted.FailedQty) FROM Inserted WHERE PORECDTL.Uniqrecdtl=Inserted.uniqrecdtl 
				END TRY
				BEGIN CATCH
					IF @@TRANCOUNT > 0
						ROLLBACK TRANSACTION ;
						SELECT @ErrorMessage = ERROR_MESSAGE(),
							   @ErrorSeverity = ERROR_SEVERITY(),
							   @ErrorState = ERROR_STATE();
						RAISERROR (@ErrorMessage, -- Message text.
								   @ErrorSeverity, -- Severity.
								   @ErrorState -- State.
								   );
						RETURN
				END CATCH
			END
			
			BEGIN TRY
			-- 6/10/2016 Nitesh B: Updating the PO items information w r to receiverno & pack list number
			-- 10/15/2020 Shivshankar P : Change condition in where from AND to OR (receiverHeader.recStatus ='Complete' OR receiverDetail.isCompleted = 1) 
			UPDATE Poitems SET Poitems.ACPT_QTY= (Poitems.ACPT_QTY + Inserted.AcceptedQty), 
						Poitems.REJ_QTY = (Poitems.Rej_qty + Inserted.FailedQty),  
					 	Poitems.RECV_QTY = (Poitems.RECV_QTY+Inserted.AcceptedQty+Inserted.FailedQty)
					FROM inserted
					inner join receiverDetail on inserted.receiverdetId = receiverDetail.receiverDetId
					inner join receiverHeader on receiverDetail.receiverHdrId =  receiverHeader.receiverHdrId
					WHERE Inserted.uniqlnno=Poitems.Uniqlnno and receiverHeader.recPklNo = Inserted.porecpkno 
					and receiverHeader.receiverno = inserted.receiverno and (receiverHeader.recStatus ='Complete' OR receiverDetail.isCompleted = 1)
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
					RETURN
			END CATCH

		-- {01/25/17 VL added to update functional and presentation currency key
		BEGIN TRY
		IF dbo.fn_IsFCInstalled() = 1
			BEGIN
			DECLARE @FCUsedUniq CHAR(10) 	-- 12/14/2017 Shiv:	   Added functional currency code to update functional and presentation currency fields (FcUsed_uniq,Fchist_key) 
                                                                    --FROM SUPINFO
			SELECT @FCUsedUniq =SUPINFO.Fcused_Uniq FROM SUPINFO JOIN RECEIVERHEADER ON SENDERID=UNIQSUPNO JOIN INSERTED ON  RECEIVERHEADER.RECEIVERNO = INSERTED.RECEIVERNO
			UPDATE Porecdtl SET PRFCUSED_UNIQ = dbo.fn_GetPresentationCurrency(),
								FUNCFCUSED_UNIQ = dbo.fn_GetFunctionalCurrency(),
								FcUsed_uniq =  @FCUsedUniq,
					            Fchist_key  =dbo.getLatestExchangeRate(@FCUsedUniq)
					FROM inserted
					WHERE inserted.UniqRecdtl = Porecdtl.UniqRecdtl

		END
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT <>0
				ROLLBACK TRAN ;
				RETURN
		END CATCH
		-- 01/25/17 VL End}

		BEGIN TRY
		;with items
		as 
	   (select ponum, sum(ord_qty-acpt_qty) as balance  
		from POITEMS where PONUM In (SELECT  Poitems.PONUM 
				FROM inserted inner join POITEMS on poitems.UNIQLNNO=inserted.UNIQLNNO) group by ponum 
	   ) 
	   -- 6/10/2016 Nitesh B: Update the POMAIN.POSTATUS When balance is 0 or less.
	   UPDATE POMAIN set POSTATUS = CASE WHEN items.balance <= 0 then 'CLOSED' ELSE POSTATUS end,
	   CLOSDDATE= CASE WHEN items.balance <= 0 then GETDATE() ELSE CLOSDDATE -- 02/06/2018 Satish B: Added for update closedate when balance is zero or less
	    end from items where items.PONUM = pomain.ponum
	  -- UPDATE POMAIN set CLOSDDATE = CASE WHEN items.balance <= 0 then GETDATE() ELSE CLOSDDATE end from items where items.PONUM = pomain.ponum
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
		 RETURN
	   END CATCH

	IF @@TRANCOUNT>0
		COMMIT TRANSACTION
END
GO
-- ====================================================================================
-- Author:		Shivshankar P
-- Create date: 04/25/2017
-- Description: Update The POitems Quantity if record inserted to PoRecDtl table
-- 08/24/17 Shivshankar P :  Returned ErrorMessage  from exception
-- 11/02/17 Shivshankar P :  Change PO Status Closed to Open when balance > 0
-- 02/06/2018 Satish B: Added for update closedate when balance is zero or less
-- 10/15/2020 Shivshankar P : Change condition in where from AND to OR (receiverHeader.recStatus ='Complete' OR receiverDetail.isCompleted = 1) 
-- ====================================================================================
CREATE  TRIGGER [dbo].[PoRecDtl_UPDATE]
   ON  [dbo].[porecdtl]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	-- Insert statements for trigger here
		BEGIN TRANSACTION
			-- Chcek if any line items cancelled
			IF EXISTS (SELECT 1 from POITEMS inner join Inserted ON Poitems.UNIQLNNO =Inserted.Uniqlnno where Poitems.LCANCEL = 1 ) 
			BEGIN
				RAISERROR('Purchase Order Line Item was Cancelled. Please check the purchase order.',1,1)
				ROLLBACK TRANSACTION ;
				RETURN 
			END
			IF EXISTS (SELECT 1 from inserted where (Inserted.AcceptedQty + Inserted.FailedQty) <> Inserted.ReceivedQty)
			BEGIN
				--- just update recv qty with the correct value
				BEGIN TRY
				UPDATE PORECDTL SET ReceivedQty= (Inserted.AcceptedQty+Inserted.FailedQty) FROM Inserted WHERE PORECDTL.Uniqrecdtl=Inserted.uniqrecdtl 
				END TRY
				BEGIN CATCH
					IF @@TRANCOUNT > 0
						ROLLBACK TRANSACTION ;
						SELECT @ErrorMessage = ERROR_MESSAGE(),
							   @ErrorSeverity = ERROR_SEVERITY(),
							   @ErrorState = ERROR_STATE();
						RAISERROR (@ErrorMessage, -- Message text.
								   @ErrorSeverity, -- Severity.
								   @ErrorState -- State.
								   );
						RETURN
				END CATCH
			END
			-- 10/15/2020 Shivshankar P : Change condition in where from AND to OR (receiverHeader.recStatus ='Complete' OR receiverDetail.isCompleted = 1) 
			BEGIN TRY
	        		UPDATE Poitems SET Poitems.ACPT_QTY= poi.acceptQty,
						Poitems.REJ_QTY = poi.failQty,  
					 	Poitems.RECV_QTY = poi.recQty
					FROM inserted
					inner join receiverDetail on inserted.receiverdetId = receiverDetail.receiverDetId
					inner join receiverHeader on receiverDetail.receiverHdrId =  receiverHeader.receiverHdrId
					OUTER APPLY (Select SUM(AcceptedQty) as acceptQty,SUM(ReceivedQty) as recQty,sum(FailedQty) as failQty,uniqlnno  from porecdtl where porecdtl.uniqlnno = inserted.uniqlnno Group by uniqlnno) poi
					WHERE Inserted.uniqlnno=Poitems.Uniqlnno and receiverHeader.recPklNo = Inserted.porecpkno 
					and receiverHeader.receiverno = inserted.receiverno and (receiverHeader.recStatus ='Complete' OR receiverDetail.isCompleted = 1)

				
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
					RETURN
			END CATCH
		BEGIN TRY
		;with items
		as 
	   (select ponum, sum(ord_qty-acpt_qty) as balance  
		from POITEMS where PONUM In (SELECT  Poitems.PONUM 
				FROM inserted inner join POITEMS on poitems.UNIQLNNO=inserted.UNIQLNNO) group by ponum 
	   ) 
	   UPDATE POMAIN set POSTATUS = CASE WHEN items.balance <= 0 then 'CLOSED' WHEN items.balance > 0 then 'OPEN' ELSE POSTATUS end,  -- 11/02/17 Shivshankar P :  Change PO Status Closed to Open when balance > 0
	   CLOSDDATE= CASE WHEN items.balance <= 0 then GETDATE() ELSE CLOSDDATE end  -- 02/06/2018 Satish B: Added for update closedate when balance is zero or less
	   from items where items.PONUM = pomain.ponum
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
		 RETURN
	   END CATCH

	IF @@TRANCOUNT>0
		COMMIT TRANSACTION
END