CREATE TABLE [dbo].[PLMAIN] (
    [SONO]            CHAR (10)        CONSTRAINT [DF__PLMAIN__SONO__11A0647C] DEFAULT ('') NOT NULL,
    [CUSTNO]          CHAR (10)        CONSTRAINT [DF__PLMAIN__CUSTNO__129488B5] DEFAULT ('') NOT NULL,
    [PACKLISTNO]      CHAR (10)        CONSTRAINT [DF__PLMAIN__PACKLIST__1388ACEE] DEFAULT ('') NOT NULL,
    [INVDATE]         SMALLDATETIME    NULL,
    [SAVEINIT]        NVARCHAR (256)   NULL,
    [WAYBILL]         CHAR (20)        CONSTRAINT [DF__PLMAIN__WAYBILL__1570F560] DEFAULT ('') NOT NULL,
    [LINKADD]         CHAR (10)        CONSTRAINT [DF__PLMAIN__LINKADD__16651999] DEFAULT ('') NOT NULL,
    [FREIGHTAMT]      NUMERIC (10, 2)  CONSTRAINT [DF__PLMAIN__FREIGHTA__184D620B] DEFAULT ((0)) NOT NULL,
    [SHIPDATE]        SMALLDATETIME    NULL,
    [SHIPCHARGE]      CHAR (15)        CONSTRAINT [DF__PLMAIN__SHIPCHAR__19418644] DEFAULT ('') NOT NULL,
    [FOB]             CHAR (15)        CONSTRAINT [DF__PLMAIN__FOB__1A35AA7D] DEFAULT ('') NOT NULL,
    [IS_REL_GL]       BIT              CONSTRAINT [DF__PLMAIN__IS_REL_G__1B29CEB6] DEFAULT ((0)) NOT NULL,
    [SHIPVIA]         CHAR (15)        CONSTRAINT [DF__PLMAIN__SHIPVIA__1E063B61] DEFAULT ('') NOT NULL,
    [TERMS]           CHAR (15)        CONSTRAINT [DF__PLMAIN__TERMS__24B338F0] DEFAULT ('') NOT NULL,
    [FRT_TXBLE]       BIT              CONSTRAINT [DF__PLMAIN__FRT_TXBL__2D487EF1] DEFAULT ((0)) NOT NULL,
    [TOTTAXE]         NUMERIC (17, 2)  CONSTRAINT [DF__PLMAIN__TOTTAXE__320D340E] DEFAULT ((0)) NOT NULL,
    [INVTOTAL]        NUMERIC (20, 2)  CONSTRAINT [DF__PLMAIN__INVTOTAL__33015847] DEFAULT ((0)) NOT NULL,
    [INV_FOOT]        TEXT             CONSTRAINT [DF__PLMAIN__INV_FOOT__35DDC4F2] DEFAULT ('') NOT NULL,
    [PACK_FOOT]       TEXT             CONSTRAINT [DF__PLMAIN__PACK_FOO__36D1E92B] DEFAULT ('') NOT NULL,
    [BLINKADD]        CHAR (10)        CONSTRAINT [DF__PLMAIN__BLINKADD__37C60D64] DEFAULT ('') NOT NULL,
    [CREDITOK]        CHAR (10)        CONSTRAINT [DF__PLMAIN__CREDITOK__38BA319D] DEFAULT ('') NOT NULL,
    [IS_INVPOST]      BIT              CONSTRAINT [DF__PLMAIN__IS_INVPO__3E730AF3] DEFAULT ((0)) NOT NULL,
    [COG_GL_NBR]      CHAR (13)        CONSTRAINT [DF__PLMAIN__COG_GL_N__49E4BD9F] DEFAULT ('') NOT NULL,
    [WIP_GL_NBR]      CHAR (13)        CONSTRAINT [DF__PLMAIN__WIP_GL_N__4AD8E1D8] DEFAULT ('') NOT NULL,
    [AL_GL_NO]        CHAR (13)        CONSTRAINT [DF__PLMAIN__AL_GL_NO__4BCD0611] DEFAULT ('') NOT NULL,
    [CUDEPGL_NO]      CHAR (13)        CONSTRAINT [DF__PLMAIN__CUDEPGL___4CC12A4A] DEFAULT ('') NOT NULL,
    [OT_GL_NO]        CHAR (13)        CONSTRAINT [DF__PLMAIN__OT_GL_NO__4DB54E83] DEFAULT ('') NOT NULL,
    [FRT_GL_NO]       CHAR (13)        CONSTRAINT [DF__PLMAIN__FRT_GL_N__4EA972BC] DEFAULT ('') NOT NULL,
    [FC_GL_NO]        CHAR (13)        CONSTRAINT [DF__PLMAIN__FC_GL_NO__4F9D96F5] DEFAULT ('') NOT NULL,
    [DISC_GL_NO]      CHAR (13)        CONSTRAINT [DF__PLMAIN__DISC_GL___5091BB2E] DEFAULT ('') NOT NULL,
    [AR_GL_NO]        CHAR (13)        CONSTRAINT [DF__PLMAIN__AR_GL_NO__5185DF67] DEFAULT ('') NOT NULL,
    [PRINTED]         BIT              CONSTRAINT [DF__PLMAIN__PRINTED__527A03A0] DEFAULT ((0)) NOT NULL,
    [INVOICENO]       CHAR (10)        CONSTRAINT [DF__PLMAIN__INVOICEN__536E27D9] DEFAULT ('') NOT NULL,
    [PRINT_INVO]      BIT              CONSTRAINT [DF__PLMAIN__PRINT_IN__54624C12] DEFAULT ((0)) NOT NULL,
    [INV_INIT]        CHAR (8)         CONSTRAINT [DF__PLMAIN__INV_INIT__5556704B] DEFAULT ('') NULL,
    [TOTEXTEN]        NUMERIC (20, 2)  CONSTRAINT [DF__PLMAIN__TOTEXTEN__564A9484] DEFAULT ((0)) NOT NULL,
    [TOTTAXF]         NUMERIC (17, 2)  CONSTRAINT [DF__PLMAIN__TOTTAXF__573EB8BD] DEFAULT ((0)) NOT NULL,
    [FIRSTPRINT]      BIT              CONSTRAINT [DF__PLMAIN__FIRSTPRI__5832DCF6] DEFAULT ((0)) NOT NULL,
    [INV_DUPL]        BIT              CONSTRAINT [DF__PLMAIN__INV_DUPL__5927012F] DEFAULT ((0)) NOT NULL,
    [ATTENTION]       CHAR (10)        CONSTRAINT [DF__PLMAIN__ATTENTIO__5A1B2568] DEFAULT ('') NOT NULL,
    [DSCTAMT]         NUMERIC (17, 2)  CONSTRAINT [DF__PLMAIN__DSCTAMT__5B0F49A1] DEFAULT ((0)) NOT NULL,
    [IS_PKPRINT]      BIT              CONSTRAINT [DF__PLMAIN__IS_PKPRI__5C036DDA] DEFAULT ((0)) NOT NULL,
    [IS_INPRINT]      BIT              CONSTRAINT [DF__PLMAIN__IS_INPRI__5CF79213] DEFAULT ((0)) NOT NULL,
    [PRINTPRDT]       BIT              CONSTRAINT [DF__PLMAIN__PRINTPRD__5DEBB64C] DEFAULT ((0)) NOT NULL,
    [FRT_LINK]        CHAR (10)        CONSTRAINT [DF__PLMAIN__FRT_LINK__5EDFDA85] DEFAULT ('') NOT NULL,
    [AR_LINK]         CHAR (10)        CONSTRAINT [DF__PLMAIN__AR_LINK__5FD3FEBE] DEFAULT ('') NOT NULL,
    [ADDRUSER]        CHAR (8)         CONSTRAINT [DF__PLMAIN__ADDRUSER__60C822F7] DEFAULT ('') NOT NULL,
    [ADDRDTTM]        SMALLDATETIME    NULL,
    [PTAX]            NUMERIC (17, 2)  CONSTRAINT [DF__PLMAIN__PTAX__61BC4730] DEFAULT ((0)) NOT NULL,
    [STAX]            NUMERIC (17, 2)  CONSTRAINT [DF__PLMAIN__STAX__62B06B69] DEFAULT ((0)) NOT NULL,
    [BILLACOUNT]      CHAR (20)        CONSTRAINT [DF__PLMAIN__BILLACOU__63A48FA2] DEFAULT ('') NOT NULL,
    [RecVer]          ROWVERSION       NOT NULL,
    [PKPOSTDATE]      SMALLDATETIME    NULL,
    [INVPOSTDATE]     SMALLDATETIME    NULL,
    [saveUserId]      UNIQUEIDENTIFIER NULL,
    [FREIGHTAMTFC]    NUMERIC (10, 2)  CONSTRAINT [DF_PLMAIN_FREIGHTAMTFC] DEFAULT ((0.0)) NOT NULL,
    [TOTTAXEFC]       NUMERIC (17, 2)  CONSTRAINT [DF_PLMAIN_TOTTAXEFC] DEFAULT ((0.0)) NOT NULL,
    [INVTOTALFC]      NUMERIC (20, 2)  CONSTRAINT [DF_PLMAIN_INVTOTALFC] DEFAULT ((0.00)) NOT NULL,
    [TOTEXTENFC]      NUMERIC (20, 2)  CONSTRAINT [DF_PLMAIN_TOTEXTENFC] DEFAULT ((0.00)) NOT NULL,
    [TOTTAXFFC]       NUMERIC (17, 2)  CONSTRAINT [DF_PLMAIN_TOTTAXFFC] DEFAULT ((0.00)) NOT NULL,
    [DSCTAMTFC]       NUMERIC (17, 2)  CONSTRAINT [DF_PLMAIN_DSCTAMTFC] DEFAULT ((0.00)) NOT NULL,
    [PTAXFC]          NUMERIC (17, 2)  CONSTRAINT [DF_PLMAIN_] DEFAULT ((0.00)) NOT NULL,
    [STAXFC]          NUMERIC (17, 2)  CONSTRAINT [DF_PLMAIN__1] DEFAULT ((0.00)) NOT NULL,
    [FCHIST_KEY]      CHAR (10)        CONSTRAINT [DF_PLMAIN_FCHIST_KEY] DEFAULT ('') NOT NULL,
    [FCUSED_UNIQ]     CHAR (10)        CONSTRAINT [DF_PLMAIN_FCUSED_UNIQ] DEFAULT ('') NOT NULL,
    [etaDate]         SMALLDATETIME    NULL,
    [plType]          NVARCHAR (50)    CONSTRAINT [DF_PLMAIN_plType] DEFAULT ('') NOT NULL,
    [FREIGHTAMTPR]    NUMERIC (10, 2)  CONSTRAINT [DF__PLMAIN__FREIGHTA__0A027010] DEFAULT ((0)) NOT NULL,
    [TOTTAXEPR]       NUMERIC (17, 2)  CONSTRAINT [DF__PLMAIN__TOTTAXEP__0AF69449] DEFAULT ((0)) NOT NULL,
    [INVTOTALPR]      NUMERIC (20, 2)  CONSTRAINT [DF__PLMAIN__INVTOTAL__0BEAB882] DEFAULT ((0)) NOT NULL,
    [TOTEXTENPR]      NUMERIC (20, 2)  CONSTRAINT [DF__PLMAIN__TOTEXTEN__0CDEDCBB] DEFAULT ((0)) NOT NULL,
    [TOTTAXFPR]       NUMERIC (17, 2)  CONSTRAINT [DF__PLMAIN__TOTTAXFP__0DD300F4] DEFAULT ((0)) NOT NULL,
    [DSCTAMTPR]       NUMERIC (17, 2)  CONSTRAINT [DF__PLMAIN__DSCTAMTP__0EC7252D] DEFAULT ((0)) NOT NULL,
    [PTAXPR]          NUMERIC (17, 2)  CONSTRAINT [DF__PLMAIN__PTAXPR__0FBB4966] DEFAULT ((0)) NOT NULL,
    [STAXPR]          NUMERIC (17, 2)  CONSTRAINT [DF__PLMAIN__STAXPR__10AF6D9F] DEFAULT ((0)) NOT NULL,
    [PRFcused_Uniq]   CHAR (10)        CONSTRAINT [DF__PLMAIN__PRFcused__11A391D8] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)        CONSTRAINT [DF__PLMAIN__FUNCFCUS__138BDA4A] DEFAULT ('') NOT NULL,
    [InvoiceType]     NVARCHAR (20)    CONSTRAINT [DF__PLMAIN__InvoiceT__2EB59D29] DEFAULT ('') NOT NULL,
    [PONO]            CHAR (20)        CONSTRAINT [DF__PLMAIN__PONO__61D619D3] DEFAULT ('') NULL,
    CONSTRAINT [PLMAIN_PK] PRIMARY KEY CLUSTERED ([PACKLISTNO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [CUSTNO]
    ON [dbo].[PLMAIN]([CUSTNO] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [INVOICENO]
    ON [dbo].[PLMAIN]([INVOICENO] ASC);


GO
CREATE NONCLUSTERED INDEX [PRINT_INVO]
    ON [dbo].[PLMAIN]([PRINT_INVO] ASC);


GO
CREATE NONCLUSTERED INDEX [PRINTED]
    ON [dbo].[PLMAIN]([PRINTED] ASC);


GO
CREATE NONCLUSTERED INDEX [SONO]
    ON [dbo].[PLMAIN]([SONO] ASC);


GO
CREATE NONCLUSTERED INDEX [SHIPDATE]
    ON [dbo].[PLMAIN]([SHIPDATE] ASC)
    INCLUDE([SONO], [PACKLISTNO]);


GO

-- =============================================
-- Author:		Satish B
-- Create date: 08/10/2017
--- Added error handling 11/04/2020 YS
-- Description:	Update Plmain table for Foreign currency
-- =============================================
CREATE TRIGGER [dbo].[Plmain_Insert]
   ON [dbo].[PLMAIN]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--11/04/20 YS added error handling
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	--11/04/20 YS added error handling
	BEGIN TRY
	BEGIN TRANSACTION
		DECLARE @custFcUniq char(10),@fCInstalled bit,@funcFcUsedUniq char(10),@prFcUsedUniq char(10),@fcHistKey char(10),@blinkadd char(10)
	    SET @blinkadd=(SELECT BLINKADD FROM Inserted)  
		IF @blinkadd IS NULL -- For manual part the blinkadd is empty
			BEGIN
			--Get FcUsed_uniq from customer
				SELECT @custFcUniq = FcUsed_uniq
			    FROM CUSTOMER
				WHERE CUSTNO = (SELECT CUSTNO FROM Inserted)
			END
		ELSE
			BEGIN
				--Get FcUsed_uniq from Shipbill
   				SELECT @custFcUniq = FcUsed_uniq
				FROM SHIPBILL
				WHERE LINKADD = @blinkadd
			END

		SELECT @fCInstalled = dbo.fn_IsFCInstalled()  --Check for fc setting
		IF @fCInstalled=1
			BEGIN
				SET @funcFcUsedUniq=(SELECT CAST(dbo.fn_GetFunctionalCurrency() AS Char(10)))
				SET @prFcUsedUniq=(SELECT CAST(dbo.fn_GetPresentationCurrency() AS Char(10)))
			--Get FCHIST_KEY
				SET @fcHistKey = (SELECT CAST(dbo.getLatestExchangeRate(@custFcUniq) AS Char(10)))
			--Update PLMAIN table
				UPDATE PLMAIN
				SET FCUSED_UNIQ=@custFcUniq
					,PRFcused_Uniq=@prFcUsedUniq
					,FUNCFCUSED_UNIQ=@funcFcUsedUniq
					,FCHIST_KEY=@fcHistKey
				WHERE PACKLISTNO=(SELECT PACKLISTNO FROM Inserted)
			END
		--11/04/20 YS added error handling
		IF @@TRANCOUNT>0
		COMMIT

	END TRY
	--11/04/20 YS added error handling
	BEGIN CATCH
		IF @@TRANCOUNT>0
		ROLLBACK
		SELECT @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();
		RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
	END CATCH
END
GO
-- =============================================
-- Author:		David Sharp
-- Create date: 12/12/2012
-- Description:	Notify subscribers when a Packing List is printed
-- 01/15/14 YS added new column notificationType varchar(20)
--- coud have 'N' - for notification
---			  'E' - for email
---			  'N,E' - for both
--- open for future methods of notification
-- =============================================
CREATE TRIGGER [dbo].[NOTICE_PLPrinted_Update]
   ON  [dbo].[PLMAIN] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    --Insert statements for trigger here

    DECLARE @PACKLISTNO varchar(20),@triggerId uniqueidentifier='23b783d2-1057-4d95-b710-fc3babdac7a8',@userInt varchar(10)
    SELECT @PACKLISTNO=i.PACKLISTNO,@userInt=i.SAVEINIT FROM deleted d INNER JOIN inserted i ON d.PACKLISTNO=i.PACKLISTNO WHERE d.IS_PKPRINT=0 AND i.IS_PKPRINT=1
    --SELECT @PACKLISTNO=PACKLISTNO,@userInt=SAVEINIT FROM inserted WHERE PRINTED=1
    IF @PACKLISTNO<>''
    BEGIN
		INSERT INTO dbo.wmTriggerNotification(noticeType,recipientId,[subject],body,triggerId,dateAdded)
		SELECT 'Subscribe',fkUserId,'Packing List Printed','<p>PL: <b>'+@PACKLISTNO+'</b> was just printed by '+@userInt+'.</p>',
				@triggerId,GETDATE()
			FROM wmTriggersActionSubsc 
			WHERE fkActTriggerId=@triggerId
			-- 01/15/14 YS added new column notificationType varchar(20)
			and charindex('N',notificationType)<>0
    END


END