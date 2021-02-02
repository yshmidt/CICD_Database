CREATE TABLE [dbo].[ARCREDIT] (
    [DEP_NO]          CHAR (10)       CONSTRAINT [DF__ARCREDIT__DEP_NO__22FF2F51] DEFAULT ('') NOT NULL,
    [CUSTNO]          CHAR (10)       CONSTRAINT [DF__ARCREDIT__CUSTNO__23F3538A] DEFAULT ('') NOT NULL,
    [INVNO]           CHAR (10)       CONSTRAINT [DF__ARCREDIT__INVNO__24E777C3] DEFAULT ('') NOT NULL,
    [UNIQLNNO]        CHAR (10)       CONSTRAINT [DF__ARCREDIT__UNIQLN__25DB9BFC] DEFAULT ('') NOT NULL,
    [UNIQDETNO]       CHAR (10)       CONSTRAINT [DF__ARCREDIT__UNIQDE__26CFC035] DEFAULT ('') NOT NULL,
    [REC_DATE]        SMALLDATETIME   NULL,
    [REC_TYPE]        CHAR (13)       CONSTRAINT [DF__ARCREDIT__REC_TY__27C3E46E] DEFAULT ('') NOT NULL,
    [REC_ADVICE]      CHAR (10)       CONSTRAINT [DF__ARCREDIT__REC_AD__28B808A7] DEFAULT ('') NOT NULL,
    [REC_AMOUNT]      NUMERIC (12, 2) CONSTRAINT [DF__ARCREDIT__REC_AM__29AC2CE0] DEFAULT ((0)) NOT NULL,
    [DISC_TAKEN]      NUMERIC (12, 2) CONSTRAINT [DF__ARCREDIT__DISC_T__2AA05119] DEFAULT ((0)) NOT NULL,
    [GL_NBR]          CHAR (13)       CONSTRAINT [DF__ARCREDIT__GL_NBR__2B947552] DEFAULT ('') NOT NULL,
    [REC_NOTE]        TEXT            CONSTRAINT [DF__ARCREDIT__REC_NO__2C88998B] DEFAULT ('') NOT NULL,
    [BANKCODE]        CHAR (10)       CONSTRAINT [DF__ARCREDIT__BANKCO__2D7CBDC4] DEFAULT ('') NOT NULL,
    [DESCRIPT]        CHAR (25)       CONSTRAINT [DF__ARCREDIT__DESCRI__2E70E1FD] DEFAULT ('') NOT NULL,
    [uniquear]        CHAR (10)       CONSTRAINT [DF_ARCREDIT_uniquear] DEFAULT ('') NOT NULL,
    [reconcilestatus] CHAR (1)        CONSTRAINT [DF_ARCREDIT_reconcilestatus] DEFAULT (' ') NOT NULL,
    [reconciledate]   SMALLDATETIME   NULL,
    [reconuniq]       CHAR (10)       CONSTRAINT [DF_ARCREDIT_reconuniq] DEFAULT ('') NOT NULL,
    [REC_AMOUNTFC]    NUMERIC (12, 2) CONSTRAINT [DF__ARCREDIT__REC_AM__43195B2D] DEFAULT ((0)) NOT NULL,
    [REC_AMOUNTBK]    NUMERIC (12, 2) CONSTRAINT [DF__ARCREDIT__REC_AM__440D7F66] DEFAULT ((0)) NOT NULL,
    [DISC_TAKENFC]    NUMERIC (12, 2) CONSTRAINT [DF__ARCREDIT__DISC_T__4501A39F] DEFAULT ((0)) NOT NULL,
    [DISC_TAKENBK]    NUMERIC (12, 2) CONSTRAINT [DF__ARCREDIT__DISC_T__45F5C7D8] DEFAULT ((0)) NOT NULL,
    [FCUSED_UNIQ]     CHAR (10)       CONSTRAINT [DF__ARCREDIT__FCUSED__46E9EC11] DEFAULT ('') NOT NULL,
    [FCHIST_KEY]      CHAR (10)       CONSTRAINT [DF__ARCREDIT__FCHIST__47DE104A] DEFAULT ('') NOT NULL,
    [ORIG_FCHIST_KEY] CHAR (10)       CONSTRAINT [DF__ARCREDIT__ORIG_F__48D23483] DEFAULT ('') NOT NULL,
    [REC_AMOUNTPR]    NUMERIC (12, 2) CONSTRAINT [DF__ARCREDIT__REC_AM__62B398C5] DEFAULT ((0)) NOT NULL,
    [DISC_TAKENPR]    NUMERIC (12, 2) CONSTRAINT [DF__ARCREDIT__DISC_T__63A7BCFE] DEFAULT ((0)) NOT NULL,
    [PRFCUSED_UNIQ]   CHAR (10)       CONSTRAINT [DF__ARCREDIT__PRFCUS__64F0E6F2] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)       CONSTRAINT [DF__ARCREDIT__FUNCFC__65E50B2B] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_ARCREDIT] PRIMARY KEY CLUSTERED ([UNIQDETNO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ArCredit4Recon]
    ON [dbo].[ARCREDIT]([reconcilestatus] ASC)
    INCLUDE([DEP_NO], [CUSTNO], [INVNO], [UNIQDETNO], [REC_ADVICE], [REC_AMOUNT], [reconciledate]);


GO
CREATE NONCLUSTERED INDEX [CUSTINVNO]
    ON [dbo].[ARCREDIT]([CUSTNO] ASC, [INVNO] ASC);


GO
CREATE NONCLUSTERED INDEX [DEP_NO]
    ON [dbo].[ARCREDIT]([DEP_NO] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_reconuniq]
    ON [dbo].[ARCREDIT]([reconuniq] ASC);


GO
CREATE NONCLUSTERED INDEX [REC_ADVICE]
    ON [dbo].[ARCREDIT]([REC_ADVICE] ASC);


GO
CREATE NONCLUSTERED INDEX [REC_DATE]
    ON [dbo].[ARCREDIT]([REC_DATE] ASC);


GO
CREATE NONCLUSTERED INDEX [REC_DATE2]
    ON [dbo].[ARCREDIT]([REC_DATE] ASC);


GO
-- =======================================================================================================================================
-- Author:		Yelena Shmidt	
-- Create date: 10/07/2015
-- Description:	Update acctsrec table when arcredit is created by deposit, will deal with CM and prePay later
-- Modification:
--	07/12/16	VL	Added to update FC fields:ArCreditsFC
--	10/26/16	VL	Added to update PR fields:ArCreditsPR
--	09/05/18	Nilesh Sa  : Added to update DiscTaken fields:DiscTaken,DiscTakenFc,DiscTakenPr
--  09/11/18    Nilesh Sa  : Modified for deposite against credit memo 
-- =======================================================================================================================================
CREATE TRIGGER [dbo].[arCredit_INSERT] 
   ON  [dbo].[ARCREDIT]
   AFTER  INSERT
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
	--	07/12/16	VL	Added to update FC fields:ArCreditsFC
	--	10/26/16	VL	Added to update PR fields:ArCreditsPR
	UPDATE AcctsRec
		SET arcredits = ArCredits + Inserted.Rec_Amount + Inserted.Disc_Taken,
			arcreditsFC = ArCreditsFC + Inserted.Rec_AmountFC + Inserted.Disc_TakenFC,
			arcreditsPR = ArCreditsPR + Inserted.Rec_AmountPR + Inserted.Disc_TakenPR,
			--	09/05/18	Nilesh Sa	Added to update DiscTaken fields:DiscTaken,DiscTakenFc,DiscTakenPr
			AcctsRec.DiscTaken = AcctsRec.DiscTaken +  Inserted.Disc_Taken,
			AcctsRec.DiscTakenFc = AcctsRec.DiscTakenFc + Inserted.Disc_TakenFC,
			AcctsRec.DiscTakenPr = AcctsRec.DiscTakenPr + Inserted.Disc_TakenPR
		FROM Inserted WHERE AcctsRec.Uniquear = Inserted.UniqueAr AND inserted.REC_TYPE NOT LIKE 'PrePay'  AND inserted.REC_TYPE NOT LIKE 'Credit Memo' --  09/11/18 Nilesh Sa : Modified for deposite against credit memo 
		AND inserted.DEP_NO<>' '       
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT<>0
		ROLLBACK
		SELECT @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();
		RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
	END CATCH
	IF @@TRANCOUNT<>0
	COMMIT
END