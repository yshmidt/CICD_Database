CREATE TABLE [dbo].[AROFFSET] (
    [UNIQ_AROFF]      CHAR (10)        CONSTRAINT [DF__AROFFSET__UNIQ_A__38EE7070] DEFAULT ('') NOT NULL,
    [DATE]            SMALLDATETIME    CONSTRAINT [DF_AROFFSET_DATE] DEFAULT (getdate()) NULL,
    [CUSTNO]          CHAR (10)        CONSTRAINT [DF__AROFFSET__CUSTNO__39E294A9] DEFAULT ('') NOT NULL,
    [INVNO]           CHAR (10)        CONSTRAINT [DF__AROFFSET__INVNO__3AD6B8E2] DEFAULT ('') NOT NULL,
    [AMOUNT]          NUMERIC (15, 2)  CONSTRAINT [DF__AROFFSET__AMOUNT__3BCADD1B] DEFAULT ((0)) NOT NULL,
    [INITIALS]        CHAR (8)         CONSTRAINT [DF__AROFFSET__INITIA__3CBF0154] DEFAULT ('') NOT NULL,
    [OFFNOTE]         TEXT             CONSTRAINT [DF__AROFFSET__OFFNOT__3DB3258D] DEFAULT ('') NOT NULL,
    [IS_REL_GL]       BIT              CONSTRAINT [DF__AROFFSET__IS_REL__3EA749C6] DEFAULT ((0)) NOT NULL,
    [CTRANSACTION]    CHAR (10)        CONSTRAINT [DF__AROFFSET__CTRANS__408F9238] DEFAULT ('') NOT NULL,
    [uniquear]        CHAR (10)        CONSTRAINT [DF_AROFFSET_uniquear] DEFAULT ('') NOT NULL,
    [AMOUNTFC]        NUMERIC (15, 2)  CONSTRAINT [DF__AROFFSET__AMOUNT__0F64ACFD] DEFAULT ((0)) NOT NULL,
    [CFCGROUP]        CHAR (10)        CONSTRAINT [DF__AROFFSET__CFCGRO__1058D136] DEFAULT ('') NOT NULL,
    [FCUSED_UNIQ]     CHAR (10)        CONSTRAINT [DF__AROFFSET__FCUSED__114CF56F] DEFAULT ('') NOT NULL,
    [FCHIST_KEY]      CHAR (10)        CONSTRAINT [DF__AROFFSET__FCHIST__124119A8] DEFAULT ('') NOT NULL,
    [ORIG_FCHIST_KEY] CHAR (10)        CONSTRAINT [DF__AROFFSET__ORIG_F__13353DE1] DEFAULT ('') NOT NULL,
    [AMOUNTPR]        NUMERIC (15, 2)  CONSTRAINT [DF__AROFFSET__AMOUNT__13E0E005] DEFAULT ((0)) NOT NULL,
    [PRFCUSED_UNIQ]   CHAR (10)        CONSTRAINT [DF__AROFFSET__PRFCUS__14D5043E] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)        CONSTRAINT [DF__AROFFSET__FUNCFC__15C92877] DEFAULT ('') NOT NULL,
    [CreatedUserId]   UNIQUEIDENTIFIER NULL,
    [DiscTaken]       NUMERIC (20, 2)  CONSTRAINT [DF__AROFFSET__DiscTa__5619830D] DEFAULT ((0.00)) NOT NULL,
    [DiscTakenFc]     NUMERIC (20, 2)  CONSTRAINT [DF__AROFFSET__DiscTa__570DA746] DEFAULT ((0.00)) NOT NULL,
    [DiscTakenPr]     NUMERIC (20, 2)  CONSTRAINT [DF__AROFFSET__DiscTa__5801CB7F] DEFAULT ((0.00)) NOT NULL,
    [AmountBk]        NUMERIC (20, 2)  CONSTRAINT [DF__AROFFSET__Amount__35D79C04] DEFAULT ((0.00)) NOT NULL,
    CONSTRAINT [AROFFSET_PK] PRIMARY KEY CLUSTERED ([UNIQ_AROFF] ASC)
);


GO
CREATE NONCLUSTERED INDEX [CTRANSACTION]
    ON [dbo].[AROFFSET]([CTRANSACTION] ASC);


GO
CREATE NONCLUSTERED INDEX [CUSTINV]
    ON [dbo].[AROFFSET]([CUSTNO] ASC, [INVNO] ASC);


GO
CREATE NONCLUSTERED INDEX [IS_REL_GL]
    ON [dbo].[AROFFSET]([IS_REL_GL] ASC);


GO
CREATE NONCLUSTERED INDEX [IS_REL_GL_INCLUDE]
    ON [dbo].[AROFFSET]([IS_REL_GL] ASC)
    INCLUDE([DATE], [INVNO], [AMOUNT], [CTRANSACTION], [uniquear]);


GO
CREATE NONCLUSTERED INDEX [uniquear]
    ON [dbo].[AROFFSET]([uniquear] ASC);


GO

-- =============================================
-- Author:		Nilesh sa
-- Create date: 31/08/2018
-- Description:	Update acctsrec table when Aroffset table record is created & will deal with credit memo and prePay
-- 09/06/18	Nilesh Sa : Added to update DiscTaken fields:DiscTaken,DiscTakenFc,DiscTakenPr
-- 09/11/18 Nilesh Sa : Modified with adding a discount to AcctsRec.ArCredits columns and for credit memo
-- =============================================
CREATE TRIGGER [dbo].[AROFFSET_INSERT] 
   ON  [dbo].[AROFFSET]
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

		-- Reduce AcctsRec.ArCredits,ArcreditsFC,ArcreditsPR value for prepay
		UPDATE AcctsRec
		SET arcredits = ArCredits - Inserted.AMOUNT,
		arcreditsFC = ArCreditsFC - Inserted.AMOUNTFC ,
		arcreditsPR = ArCreditsPR - Inserted.AMOUNTPR
		FROM Inserted 
		WHERE AcctsRec.Uniquear = Inserted.UniqueAr AND (AcctsRec.lPrepay = 1 OR AcctsRec.isManualCm = 1) -- 09/11/18 Nilesh Sa : Modified with adding a discount to AcctsRec.ArCredits columns and for credit memo

		-- Increase AcctsRec.ArCredits,ArcreditsFC,AarcreditsPR value for invoices
		UPDATE AcctsRec
		SET arcredits = ArCredits + ABS(Inserted.AMOUNT) +  Inserted.DiscTaken,
		arcreditsFC = ArCreditsFC + ABS(Inserted.AMOUNTFC) + Inserted.DiscTakenFc,
		arcreditsPR = ArCreditsPR + ABS(Inserted.AMOUNTPR) + Inserted.DiscTakenPr,
		--	09/06/18	Nilesh Sa	Added to update DiscTaken fields:DiscTaken,DiscTakenFc,DiscTakenPr
		-- 09/11/18 Nilesh Sa : Modified with adding a discount to AcctsRec.ArCredits columns and for credit memo
		DiscTaken = AcctsRec.DiscTaken +  Inserted.DiscTaken,
		DiscTakenFc = AcctsRec.DiscTakenFc + Inserted.DiscTakenFc,
		DiscTakenPr = AcctsRec.DiscTakenPr + Inserted.DiscTakenPr
		FROM Inserted 
		WHERE AcctsRec.Uniquear = Inserted.UniqueAr AND AcctsRec.lPrepay = 0 AND AcctsRec.isManualCm = 0 -- 09/11/18 Nilesh Sa : Modified with adding a discount to AcctsRec.ArCredits columns and for credit memo

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