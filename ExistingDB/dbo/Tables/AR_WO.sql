CREATE TABLE [dbo].[AR_WO] (
    [WODATE]          SMALLDATETIME   CONSTRAINT [DF_AR_WO_WODATE] DEFAULT (getdate()) NULL,
    [WO_AMT]          NUMERIC (10, 2) CONSTRAINT [DF__AR_WO__WO_AMT__1387E197] DEFAULT ((0)) NOT NULL,
    [INITIALS]        CHAR (8)        CONSTRAINT [DF__AR_WO__INITIALS__147C05D0] DEFAULT ('') NOT NULL,
    [IS_REL_GL]       BIT             CONSTRAINT [DF__AR_WO__IS_REL_GL__15702A09] DEFAULT ((0)) NOT NULL,
    [WO_REASON]       TEXT            CONSTRAINT [DF__AR_WO__WO_REASON__16644E42] DEFAULT ('') NOT NULL,
    [ARWOUNIQUE]      CHAR (10)       CONSTRAINT [DF__AR_WO__ARWOUNIQU__1758727B] DEFAULT ('') NOT NULL,
    [UniqueAR]        CHAR (10)       CONSTRAINT [DF_AR_WO_UniqueAR] DEFAULT ('') NOT NULL,
    [WO_AMTFC]        NUMERIC (10, 2) CONSTRAINT [DF__AR_WO__WO_AMTFC__7763063A] DEFAULT ((0)) NOT NULL,
    [FCUSED_UNIQ]     CHAR (10)       CONSTRAINT [DF__AR_WO__FCUSED_UN__78572A73] DEFAULT ('') NOT NULL,
    [FCHIST_KEY]      CHAR (10)       CONSTRAINT [DF__AR_WO__FCHIST_KE__794B4EAC] DEFAULT ('') NOT NULL,
    [WO_AMTPR]        NUMERIC (10, 2) CONSTRAINT [DF__AR_WO__WO_AMTPR__16BD4CB0] DEFAULT ((0)) NOT NULL,
    [PRFCUSED_UNIQ]   CHAR (10)       CONSTRAINT [DF__AR_WO__PRFCUSED___17B170E9] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)       CONSTRAINT [DF__AR_WO__FUNCFCUSE__18A59522] DEFAULT ('') NOT NULL,
    CONSTRAINT [AR_WO_PK] PRIMARY KEY CLUSTERED ([ARWOUNIQUE] ASC)
);


GO
CREATE NONCLUSTERED INDEX [UniqueAR]
    ON [dbo].[AR_WO]([UniqueAR] ASC);


GO
CREATE NONCLUSTERED INDEX [WODATE]
    ON [dbo].[AR_WO]([WODATE] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/06/2015
-- Description:	Create Insert trigger to update Acctsrec here in stead of in the write off screen
-- Modification:
--	07/12/16	VL	Added to update FC fields:ArCreditsFC
--	01/13/17	VL	Added functional currency code
-- =============================================
CREATE TRIGGER [dbo].[AR_WO_Insert]
   ON  [dbo].[AR_WO]
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
	BEGIN TRY
	BEGIN TRANSACTION
	IF EXISTS(select 1 from ACCTSREC inner join Inserted on Inserted.UniqueAR=ACCTSREC.UNIQUEAR where ACCTSREC.ArCredits + Inserted.Wo_Amt>ACCTSREC.invtotal)
	begin
		RAISERROR ('Write off ammount cannot be more than Invoice balance.', -- Message text.
               16, -- Severity.
               1 -- State.
               );

	end
	--	07/12/16	VL	Added to update FC fields:ArCreditsFC
	--	01/13/17	VL	Added functional currency code
	update ACCTSREC set ArCredits = ArCredits + Inserted.Wo_Amt, ArCreditsFC = ArCreditsFC + Inserted.Wo_AmtFC, ArCreditsPR = ArCreditsPR + Inserted.Wo_AmtPR from Inserted where Inserted.UniqueAR=ACCTSREC.UNIQUEAR
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