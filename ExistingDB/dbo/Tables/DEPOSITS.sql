CREATE TABLE [dbo].[DEPOSITS] (
    [DATE]            SMALLDATETIME    CONSTRAINT [DF_DEPOSITS_DATE] DEFAULT (getdate()) NULL,
    [BK_ACCT_NO]      CHAR (50)        CONSTRAINT [DF__DEPOSITS__BK_ACC__1DF06171] DEFAULT ('') NULL,
    [TOT_DEP]         NUMERIC (12, 2)  CONSTRAINT [DF__DEPOSITS__TOT_DE__1EE485AA] DEFAULT ((0)) NOT NULL,
    [DEP_NO]          CHAR (10)        CONSTRAINT [DF__DEPOSITS__DEP_NO__1FD8A9E3] DEFAULT ('') NOT NULL,
    [IS_REL_GL]       BIT              CONSTRAINT [DF__DEPOSITS__IS_REL__21C0F255] DEFAULT ((0)) NOT NULL,
    [STATUS]          CHAR (10)        CONSTRAINT [DF__DEPOSITS__STATUS__22B5168E] DEFAULT ('') NOT NULL,
    [BKLASTSAVE]      CHAR (10)        CONSTRAINT [DF__DEPOSITS__BKLAST__23A93AC7] DEFAULT ('') NOT NULL,
    [BK_UNIQ]         CHAR (10)        CONSTRAINT [DF__DEPOSITS__BK_UNI__249D5F00] DEFAULT ('') NOT NULL,
    [cInitials]       CHAR (8)         CONSTRAINT [DF_DEPOSITS_cInitials] DEFAULT ('') NOT NULL,
    [dDepDate]        SMALLDATETIME    CONSTRAINT [DF_DEPOSITS_dDepDate] DEFAULT (getdate()) NOT NULL,
    [TOT_DEPFC]       NUMERIC (12, 2)  CONSTRAINT [DF__DEPOSITS__TOT_DE__693F0415] DEFAULT ((0)) NOT NULL,
    [TOT_DEPBK]       NUMERIC (12, 2)  CONSTRAINT [DF__DEPOSITS__TOT_DE__6A33284E] DEFAULT ((0)) NOT NULL,
    [FCUSED_UNIQ]     CHAR (10)        CONSTRAINT [DF__DEPOSITS__FCUSED__6E03B932] DEFAULT ('') NOT NULL,
    [FCHIST_KEY]      CHAR (10)        CONSTRAINT [DF__DEPOSITS__FCHIST__6EF7DD6B] DEFAULT ('') NOT NULL,
    [TOT_DEPPR]       NUMERIC (12, 2)  CONSTRAINT [DF__DEPOSITS__TOT_DE__5FD72C1A] DEFAULT ((0)) NOT NULL,
    [PRFcused_Uniq]   CHAR (10)        CONSTRAINT [DF__DEPOSITS__PRFcus__60CB5053] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)        CONSTRAINT [DF__DEPOSITS__FUNCFC__61BF748C] DEFAULT ('') NOT NULL,
    [CreatedUserId]   UNIQUEIDENTIFIER NULL,
    [PaymentType]     NVARCHAR (400)   CONSTRAINT [DF__DEPOSITS__Paymen__5D0677BE] DEFAULT ('') NOT NULL,
    CONSTRAINT [DEPOSITS_PK] PRIMARY KEY CLUSTERED ([DEP_NO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [BKLASTSAVE]
    ON [dbo].[DEPOSITS]([BKLASTSAVE] ASC);


GO
CREATE NONCLUSTERED INDEX [DATE]
    ON [dbo].[DEPOSITS]([DATE] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 04/01/2016
-- Description:	Insert trigger for deposits to update banks balance
-- Modification:
--	08/02/2016	VL	Changed updating bank_balfc from using inserted.tot_depfc to inserted.tot_depbk because if bank currency is different from the deposit currency, tot_depfc would have the value in deposit currency, should use tot_depbk
--	01/13/2017	VL	Added functional currency fields
-- =============================================
CREATE TRIGGER [dbo].[Deposits_insert]
   ON  [dbo].[DEPOSITS]
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
		-- 08/02/16 VL changed to update Bank_balFC from Tot_depbk, not tot_depfc
		--	01/13/2017	VL	Added functional currency fields
		update Banks set BANK_BAL = Bank_bal + Inserted.TOT_DEP , Bank_balfc=Bank_balfc+Inserted.TOT_DEPBK, Bank_balPR=Bank_balPR+Inserted.TOT_DEPPR
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