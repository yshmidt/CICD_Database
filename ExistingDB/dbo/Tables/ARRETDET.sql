CREATE TABLE [dbo].[ARRETDET] (
    [DEP_NO]          CHAR (10)       CONSTRAINT [DF__ARRETDET__DEP_NO__4FD1D5C8] DEFAULT ('') NOT NULL,
    [UNIQRETNO]       CHAR (10)       CONSTRAINT [DF__ARRETDET__UNIQRE__50C5FA01] DEFAULT ('') NOT NULL,
    [CUSTNO]          CHAR (10)       CONSTRAINT [DF__ARRETDET__CUSTNO__51BA1E3A] DEFAULT ('') NOT NULL,
    [INVNO]           CHAR (10)       CONSTRAINT [DF__ARRETDET__INVNO__52AE4273] DEFAULT ('') NOT NULL,
    [UNIQLNNO]        CHAR (10)       CONSTRAINT [DF__ARRETDET__UNIQLN__53A266AC] DEFAULT ('') NOT NULL,
    [UNIQDETNO]       CHAR (10)       CONSTRAINT [DF__ARRETDET__UNIQDE__54968AE5] DEFAULT ('') NOT NULL,
    [REC_DATE]        SMALLDATETIME   NULL,
    [REC_TYPE]        CHAR (13)       CONSTRAINT [DF__ARRETDET__REC_TY__558AAF1E] DEFAULT ('') NOT NULL,
    [REC_ADVICE]      CHAR (10)       CONSTRAINT [DF__ARRETDET__REC_AD__567ED357] DEFAULT ('') NOT NULL,
    [REC_AMOUNT]      NUMERIC (12, 2) CONSTRAINT [DF__ARRETDET__REC_AM__5772F790] DEFAULT ((0)) NOT NULL,
    [DISC_TAKEN]      NUMERIC (12, 2) CONSTRAINT [DF__ARRETDET__DISC_T__58671BC9] DEFAULT ((0)) NOT NULL,
    [GL_NBR]          CHAR (13)       CONSTRAINT [DF__ARRETDET__GL_NBR__595B4002] DEFAULT ('') NOT NULL,
    [REC_NOTE]        TEXT            CONSTRAINT [DF__ARRETDET__REC_NO__5A4F643B] DEFAULT ('') NOT NULL,
    [BANKCODE]        CHAR (10)       CONSTRAINT [DF__ARRETDET__BANKCO__5B438874] DEFAULT ('') NOT NULL,
    [DESCRIPT]        CHAR (25)       CONSTRAINT [DF__ARRETDET__DESCRI__5C37ACAD] DEFAULT ('') NOT NULL,
    [ARRETDETUNIQ]    CHAR (10)       CONSTRAINT [DF__ARRETDET__ARRETD__5D2BD0E6] DEFAULT ('') NOT NULL,
    [Reconcilestatus] CHAR (1)        CONSTRAINT [DF_ARRETDET_Reconcilestatus] DEFAULT (' ') NOT NULL,
    [ReconcileDate]   SMALLDATETIME   NULL,
    [ReconUniq]       CHAR (10)       CONSTRAINT [DF_ARRETDET_ReconUniq] DEFAULT ('') NOT NULL,
    [REC_AMOUNTFC]    NUMERIC (12, 2) CONSTRAINT [DF__ARRETDET__REC_AM__7510A974] DEFAULT ((0)) NOT NULL,
    [DISC_TAKENFC]    NUMERIC (12, 2) CONSTRAINT [DF__ARRETDET__DISC_T__7604CDAD] DEFAULT ((0)) NOT NULL,
    [FCHIST_KEY]      CHAR (10)       CONSTRAINT [DF__ARRETDET__FCHIST__67A19FBD] DEFAULT ('') NOT NULL,
    [ORIG_FCHIST_KEY] CHAR (10)       CONSTRAINT [DF__ARRETDET__ORIG_F__6895C3F6] DEFAULT ('') NOT NULL,
    [REC_AMOUNTPR]    NUMERIC (12, 2) CONSTRAINT [DF__ARRETDET__REC_AM__32656725] DEFAULT ((0)) NOT NULL,
    [DISC_TAKENPR]    NUMERIC (12, 2) CONSTRAINT [DF__ARRETDET__DISC_T__33598B5E] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [ARRETDET_PK] PRIMARY KEY CLUSTERED ([ARRETDETUNIQ] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ReconStat]
    ON [dbo].[ARRETDET]([Reconcilestatus] ASC);


GO
CREATE NONCLUSTERED INDEX [ReconUniq]
    ON [dbo].[ARRETDET]([ReconUniq] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQDETNO]
    ON [dbo].[ARRETDET]([UNIQDETNO] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQRETNO]
    ON [dbo].[ARRETDET]([UNIQRETNO] ASC);


GO
-- =============================================
-- Author:  	Yelena Shmidt
-- Create date: 
-- Description: arretdet insert trigger 
-- Modified: 
--	02/20/14	YS	Ardep table keeps prepy records only and Dep_credit column has to be increased by the amount returned to decrease available amount to use
--	07/12/16	VL	Added to update FC fields:ArCreditsFC and DepCredit
--	01/13/17	VL	Added functional currency fields
-- =============================================
CREATE TRIGGER [dbo].[ArRetDet_Insert]
   ON  [dbo].[ARRETDET]
   AFTER Insert
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for trigger here
	BEGIN TRANSACTION
	--02/20/14 YS Ardep table keeps prepy records only and Dep_credit column has to be increased by the amount returned to decrease available amount to use
	-- i know makes no sense
	--	07/12/16 VL	update FC fields DepCredit
	--	01/13/17	VL	Added functional currency fields
	UPDATE ArDep SET Dep_Credit = ArDep.Dep_Credit + Inserted.Rec_Amount,
					Dep_CreditFC = ArDep.Dep_CreditFC + Inserted.Rec_AmountFC,
					--	01/13/17	VL	Added functional currency fields
					Dep_CreditPR = ArDep.Dep_CreditPR + Inserted.Rec_AmountPR
		FROM Inserted WHERE Inserted.InvNo=Ardep.Invno and 
		(Inserted.Rec_Type = 'PrePay' OR Inserted.Rec_Type = 'Apply PPay')
	--09/13/12 YS aadded code to update acctsrec here instead of the form
	--	07/12/16 VL	update FC fields:ArCreditsFC
	--	01/13/17	VL	Added functional currency fields
	UPDATE ACCTSREC SET ArCredits =ArCredits-(Inserted.Rec_amount+Inserted.Disc_Taken),
						ArCreditsFC =ArCreditsFC-(Inserted.Rec_amountFC+Inserted.Disc_TakenFC),
						--	01/13/17	VL	Added functional currency fields  
						ArCreditsPR =ArCreditsPR-(Inserted.Rec_amountPR+Inserted.Disc_TakenPR)
			FROM inserted WHERE Inserted.Invno=Acctsrec.Invno and inserted.CUSTNO =Acctsrec.CUSTNO and Inserted.REC_TYPE<> 'Other'
	
	COMMIT
END