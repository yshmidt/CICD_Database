CREATE TABLE [dbo].[APCHKMST] (
    [APCHK_UNIQ]      CHAR (10)       CONSTRAINT [DF__APCHKMST__APCHK___3F115E1A] DEFAULT ('') NOT NULL,
    [BATCH_DATE]      SMALLDATETIME   NULL,
    [CHECKNO]         CHAR (10)       CONSTRAINT [DF__APCHKMST__CHECKN__40058253] DEFAULT ('') NOT NULL,
    [CHECKDATE]       SMALLDATETIME   NULL,
    [CHECKAMT]        NUMERIC (12, 2) CONSTRAINT [DF__APCHKMST__CHECKA__41EDCAC5] DEFAULT ((0)) NOT NULL,
    [BK_ACCT_NO]      CHAR (15)       CONSTRAINT [DF__APCHKMST__BK_ACC__43D61337] DEFAULT ('') NOT NULL,
    [PMT_TYPE]        CHAR (15)       CONSTRAINT [DF__APCHKMST__PMT_TY__44CA3770] DEFAULT ('') NOT NULL,
    [STATUS]          CHAR (15)       CONSTRAINT [DF__APCHKMST__STATUS__45BE5BA9] DEFAULT ('') NOT NULL,
    [ReconcileDate]   SMALLDATETIME   NULL,
    [CHECKNOTE]       TEXT            CONSTRAINT [DF__APCHKMST__CHECKN__46B27FE2] DEFAULT ('') NOT NULL,
    [VOIDDATE]        SMALLDATETIME   NULL,
    [AMT1099]         NUMERIC (12, 2) CONSTRAINT [DF__APCHKMST__AMT109__47A6A41B] DEFAULT ((0)) NOT NULL,
    [IS_REL_GL]       BIT             CONSTRAINT [DF__APCHKMST__IS_REL__489AC854] DEFAULT ((0)) NOT NULL,
    [IS_PRINTED]      BIT             CONSTRAINT [DF__APCHKMST__IS_PRI__498EEC8D] DEFAULT ((0)) NOT NULL,
    [SAVEINIT]        CHAR (8)        CONSTRAINT [DF__APCHKMST__SAVEIN__4A8310C6] DEFAULT ('') NOT NULL,
    [TRANS_NO]        NUMERIC (10)    CONSTRAINT [DF__APCHKMST__TRANS___4B7734FF] DEFAULT ((0)) NOT NULL,
    [BKLASTSAVE]      CHAR (10)       CONSTRAINT [DF__APCHKMST__BKLAST__4C6B5938] DEFAULT ('') NOT NULL,
    [UNIQSUPNO]       CHAR (10)       CONSTRAINT [DF__APCHKMST__UNIQSU__4D5F7D71] DEFAULT ('') NOT NULL,
    [BK_UNIQ]         CHAR (10)       CONSTRAINT [DF__APCHKMST__BK_UNI__4E53A1AA] DEFAULT ('') NOT NULL,
    [R_LINK]          CHAR (10)       CONSTRAINT [DF__APCHKMST__R_LINK__4F47C5E3] DEFAULT ('') NOT NULL,
    [BATCHUNIQ]       CHAR (10)       CONSTRAINT [DF__APCHKMST__BATCHU__503BEA1C] DEFAULT ('') NOT NULL,
    [LAPPREPAY]       BIT             CONSTRAINT [DF__APCHKMST__LAPPRE__51300E55] DEFAULT ((0)) NOT NULL,
    [ReconcileStatus] CHAR (1)        CONSTRAINT [DF_APCHKMST_ReconCileStatus] DEFAULT (' ') NOT NULL,
    [ReconUniq]       CHAR (10)       CONSTRAINT [DF_APCHKMST_ReconUniq] DEFAULT ('') NOT NULL,
    [RecVer]          ROWVERSION      NOT NULL,
    [CHECKAMTFC]      NUMERIC (12, 2) CONSTRAINT [DF__APCHKMST__CHECKA__3C0D3642] DEFAULT ((0)) NOT NULL,
    [AMT1099FC]       NUMERIC (12, 2) CONSTRAINT [DF__APCHKMST__AMT109__3D015A7B] DEFAULT ((0)) NOT NULL,
    [PMTTYPE]         VARCHAR (50)    CONSTRAINT [DF__APCHKMST__PMTTYP__3DF57EB4] DEFAULT ('') NOT NULL,
    [FCUSED_UNIQ]     CHAR (10)       CONSTRAINT [DF__APCHKMST__FCUSED__3EE9A2ED] DEFAULT ('') NOT NULL,
    [FCHIST_KEY]      CHAR (10)       CONSTRAINT [DF__APCHKMST__FCHIST__3FDDC726] DEFAULT ('') NOT NULL,
    [CHECKAMTPR]      NUMERIC (12, 2) CONSTRAINT [DF__APCHKMST__CHECKA__1999B95B] DEFAULT ((0)) NOT NULL,
    [AMT1099PR]       NUMERIC (12, 2) CONSTRAINT [DF__APCHKMST__AMT109__1A8DDD94] DEFAULT ((0)) NOT NULL,
    [PRFCUSED_UNIQ]   CHAR (10)       CONSTRAINT [DF__APCHKMST__PRFCUS__1B8201CD] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)       CONSTRAINT [DF__APCHKMST__FUNCFC__1C762606] DEFAULT ('') NOT NULL,
    CONSTRAINT [APCHKMST_PK] PRIMARY KEY CLUSTERED ([APCHK_UNIQ] ASC)
);


GO
CREATE NONCLUSTERED INDEX [AMT1099]
    ON [dbo].[APCHKMST]([AMT1099] ASC);


GO
CREATE NONCLUSTERED INDEX [BATCH_DATE]
    ON [dbo].[APCHKMST]([BATCH_DATE] ASC);


GO
CREATE NONCLUSTERED INDEX [BK_ACCT_NO]
    ON [dbo].[APCHKMST]([BK_ACCT_NO] ASC);


GO
CREATE NONCLUSTERED INDEX [BKLASTSAVE]
    ON [dbo].[APCHKMST]([BKLASTSAVE] ASC);


GO
CREATE NONCLUSTERED INDEX [BkUniq4Recon]
    ON [dbo].[APCHKMST]([BK_UNIQ] ASC, [ReconcileStatus] ASC)
    INCLUDE([APCHK_UNIQ], [CHECKNO], [CHECKDATE], [CHECKAMT], [STATUS], [ReconcileDate], [R_LINK]);


GO
CREATE NONCLUSTERED INDEX [BKUNIQCKNO]
    ON [dbo].[APCHKMST]([BK_UNIQ] ASC, [CHECKNO] ASC);


GO
CREATE NONCLUSTERED INDEX [CHECKAMT]
    ON [dbo].[APCHKMST]([CHECKAMT] ASC);


GO
CREATE NONCLUSTERED INDEX [CHECKDATE]
    ON [dbo].[APCHKMST]([CHECKDATE] ASC);


GO
CREATE NONCLUSTERED INDEX [CHECKNO]
    ON [dbo].[APCHKMST]([CHECKNO] ASC, [BK_ACCT_NO] ASC);


GO
CREATE NONCLUSTERED INDEX [IS_PRINTED]
    ON [dbo].[APCHKMST]([IS_PRINTED] ASC);


GO
CREATE NONCLUSTERED INDEX [IS_REL_GL]
    ON [dbo].[APCHKMST]([IS_REL_GL] ASC);


GO
CREATE NONCLUSTERED INDEX [PMT_TYPE]
    ON [dbo].[APCHKMST]([PMT_TYPE] ASC);


GO
CREATE NONCLUSTERED INDEX [reconDate]
    ON [dbo].[APCHKMST]([ReconcileDate] ASC);


GO
CREATE NONCLUSTERED INDEX [reconstatus]
    ON [dbo].[APCHKMST]([ReconcileStatus] ASC);


GO
CREATE NONCLUSTERED INDEX [ReconUniq]
    ON [dbo].[APCHKMST]([ReconUniq] ASC);


GO
CREATE NONCLUSTERED INDEX [SAVEINIT]
    ON [dbo].[APCHKMST]([SAVEINIT] ASC);


GO
CREATE NONCLUSTERED INDEX [STATUS]
    ON [dbo].[APCHKMST]([STATUS] ASC);


GO
CREATE NONCLUSTERED INDEX [TRANS_NO]
    ON [dbo].[APCHKMST]([TRANS_NO] ASC);


GO
CREATE NONCLUSTERED INDEX [VOIDDATE]
    ON [dbo].[APCHKMST]([VOIDDATE] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 04/01/2016
-- Description:	Insert trigger for apchkmst to update banks balance
-- 04/07/16 YS modified to update lastckno
-- 04/07/16 VL IF FC is installed, payment type='Check' or banks.Fcused_uniq=ApChkMst.Fcused_uniq or Banks.Fcused_Uniq = home currency, just update Bank_balFC with ank_balFC-Inserted.CheckAmtFC
--				Otherwise, it means the bank currency is different from the check currency, has to convert from home currency value to bank currency value to update Bank_balFC
-- 04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 01/11/17 VL added one more parameter for dbo.fn_Convert4FCHC()
-- 01/12/17 VL added presentation currency fields
-- 03/24/17 YS check for 'Auto Ded' in the inserted.checkno, if  'Auto Ded' do not update lastckno
-- =============================================
CREATE TRIGGER [dbo].[ApChkMst_insert]
   ON  [dbo].[APCHKMST]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for trigger here
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	BEGIN TRY
	BEGIN TRANSACTION

	-- 04/07/16 VL added to get if FC is installed
	-- 01/12/17 VL changed from home currency to functional currency
	DECLARE @lFCInstalled bit, @FunctionalCurrency char(10)
	-- 04/08/16 VL changed to get FC installed from function
	SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
	SELECT @FunctionalCurrency = dbo.fn_GetFunctionalCurrency()

		update Banks set BANK_BAL = Bank_bal - Inserted.CheckAmt,
					--Bank_balFC=Bank_balFC-Inserted.CheckAmtFC,
					-- FC installed, pmttype not 'check' not empty, bank currency is different from check currency, or bank currency is not home currency
					Bank_balFC=Bank_balFC - 
						(CASE WHEN @lFCInstalled = 1 AND Inserted.pmttype <> 'check' AND Inserted.pmttype<>'' 
							AND banks.Fcused_uniq<>Inserted.Fcused_uniq AND banks.Fcused_uniq<>@FunctionalCurrency
							THEN dbo.fn_Convert4FCHC('H',banks.fcused_uniq,Inserted.CheckAmt,dbo.fn_GetFunctionalCurrency(),'')
							ELSE Inserted.CheckAmtFC
							END),
					-- 01/12/17 VL added presentation currency, checkamtPR is converted from checkamt to checkamtFC, then checkamtFC to checkamtPR
					Bank_BalPR=Bank_BalPR - 
						(CASE WHEN @lFCInstalled = 1 AND Inserted.pmttype <> 'check' AND Inserted.pmttype<>'' 
							AND banks.Fcused_uniq<>Inserted.Fcused_uniq AND banks.Fcused_uniq<>@FunctionalCurrency
							THEN dbo.fn_Convert4FCHC('H',banks.fcused_uniq,dbo.fn_Convert4FCHC('H',banks.fcused_uniq,Inserted.CheckAmt,dbo.fn_GetFunctionalCurrency(),''),dbo.fn_GetPresentationCurrency(),'')
							ELSE Inserted.CheckAmtPR
							END),
					-- 03/24/17 YS check for 'Auto Ded' in the inserted.checkno, if  'Auto Ded' do not update lastckno
					lastckNo = 
					case when banks.xxcknosys=1 and inserted.checkno<>banks.lastckno and inserted.CHECKNO <>'Auto Ded' then inserted.checkno else banks.lastckNo END
				from Inserted where Inserted.BK_UNIQ=Banks.BK_UNIQ

	END TRY
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

	IF @@TRANCOUNT>0
	COMMIT




END