CREATE TABLE [dbo].[GLJEDET] (
    [UNIQJEHEAD]      CHAR (10)       CONSTRAINT [DF__GLJEDET__UNIQJEH__19169DBB] DEFAULT ('') NOT NULL,
    [UNIQJEDET]       CHAR (10)       CONSTRAINT [DF__GLJEDET__UNIQJED__1A0AC1F4] DEFAULT ('') NOT NULL,
    [GL_NBR]          CHAR (13)       CONSTRAINT [DF__GLJEDET__GL_NBR__1AFEE62D] DEFAULT ('') NOT NULL,
    [DEBIT]           NUMERIC (14, 2) CONSTRAINT [DF__GLJEDET__DEBIT__1BF30A66] DEFAULT ((0)) NOT NULL,
    [CREDIT]          NUMERIC (14, 2) CONSTRAINT [DF__GLJEDET__CREDIT__1CE72E9F] DEFAULT ((0)) NOT NULL,
    [ReconcileStatus] CHAR (1)        CONSTRAINT [DF_GLJEDET_ReconsileStatus] DEFAULT ('') NOT NULL,
    [ReconcileDate]   SMALLDATETIME   NULL,
    [ReconUniq]       CHAR (10)       CONSTRAINT [DF_GLJEDET_ReconUniq] DEFAULT ('') NOT NULL,
    [DEBITPR]         NUMERIC (14, 2) CONSTRAINT [DF__GLJEDET__DEBITPR__09635192] DEFAULT ((0)) NOT NULL,
    [CREDITPR]        NUMERIC (14, 2) CONSTRAINT [DF__GLJEDET__CREDITP__0A5775CB] DEFAULT ((0)) NOT NULL,
    [DEBITFC]         NUMERIC (14, 2) CONSTRAINT [DF__GLJEDET__DEBITFC__0528AC5A] DEFAULT ((0)) NOT NULL,
    [CREDITFC]        NUMERIC (14, 2) CONSTRAINT [DF__GLJEDET__CREDITF__061CD093] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [GLJEDET_PK] PRIMARY KEY CLUSTERED ([UNIQJEDET] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Gl_NBR_DEBIT>]
    ON [dbo].[GLJEDET]([GL_NBR] ASC, [DEBIT] ASC);


GO
CREATE NONCLUSTERED INDEX [reconciledt]
    ON [dbo].[GLJEDET]([ReconcileDate] ASC);


GO
CREATE NONCLUSTERED INDEX [reconcilest]
    ON [dbo].[GLJEDET]([ReconcileStatus] ASC);


GO
CREATE NONCLUSTERED INDEX [ReconUniq]
    ON [dbo].[GLJEDET]([ReconUniq] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQJEHEAD]
    ON [dbo].[GLJEDET]([UNIQJEHEAD] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 01/27/2015
-- Description:	Insert trigger for GlJeDET table will check if the gl_nbr matching any banks gl_nbr and update that bank balance accordingly
-- Modification:
-- 04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 01/13/17 VL Added functional currency fields
-- 03/31/17 VL use DebitFC and CreditFC from GlJedet, not Currtrfr
-- 10/16/17 YS The bank balance will be calculated wrong if more than one record is inserted into gljedet with the same gl_nbr. Need to use SUM 
-- 10/16/17 VL added new code for updating FC and PR debit/credit
-- =============================================
CREATE TRIGGER [dbo].[GlJeDet_Insert]
   ON  [dbo].[GLJEDET] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION
		BEGIN TRY
			--UPDATE Banks SET BANK_BAL=BANK_BAL+Inserted.DEBIT-Inserted.Credit from Inserted where Inserted.GL_NBR=Banks.GL_NBR
			-- 10/16/17 YS The bank balance will be calculated wrong if more than one record is inserted into gljedet with the same gl_nbr. Need to use SUM  
			UPDATE Banks SET BANK_BAL=BANK_BAL+i.debit-i.credit
			from 
			(select inserted.gl_nbr,sum(Inserted.DEBIT) as Debit,sum(Inserted.Credit) as Credit FROM
			Inserted group by gl_nbr) I where I.GL_NBR=Banks.GL_NBR

			-- 10/27/15 VL changed, if FC is installed and it's from currency transfer, need to find FC value to update Bank_BalFC
			-- 10/27/15 VL separate code for FC
			-- 01/13/17 VL Added functional currency fields
			-- 10/16/17 VL comment out the code that update FC part, will use similar code like above to update FC and PR debit/credit
			--DECLARE @lFCInstalled bit, @Jehokey char(10), @gl_nbr char(13), @DebitFC numeric(14,2), @CreditFC numeric(14,2), @Sundry char(15), @DebitPR numeric(14,2), @CreditPR numeric(14,2)
			---- 04/08/16 VL changed to get FC installed from function
			--SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
			--IF @lFCInstalled = 1
			--	BEGIN
			--		-- 01/13/17 VL Added functional currency fields
			--		-- 03/31/17 VL use DebitFC and CreditFC from GlJedet, not Currtrfr
			--		SELECT @DebitFC = Inserted.DebitFC, @CreditFC = Inserted.CreditFC, @Sundry = Sundry, @DebitPR = Inserted.DebitPR, @CreditPR = Inserted.CreditPR
			--			FROM Currtrfr, Inserted
			--			WHERE JEOHKEY = Inserted.UniqJEhead
			--			AND Currtrfr.Gl_nbr = Inserted.Gl_nbr
			--		IF @@ROWCOUNT > 0	-- did find Currtrfr record
			--			BEGIN
			--				-- 01/13/17 VL Added functional currency fields
			--				UPDATE Banks SET BANK_BALFC=BANK_BALFC+@DebitFC-@CreditFC, BANK_BALPR=BANK_BALPR+@DebitPR-@CreditPR from Inserted where Inserted.GL_NBR=Banks.GL_NBR
			--		END
			--	END
			---- 10/27/15 VL End}
			-- 10/16/17 VL added new code for updating FC and PR debit/credit
			IF dbo.fn_IsFCInstalled() = 1
				BEGIN

				UPDATE Banks SET BANK_BALFC=BANK_BALFC+i.debitFC-i.creditFC, BANK_BALPR=BANK_BALPR+i.debitPR-i.creditPR 
					FROM
					(SELECT Inserted.gl_nbr,SUM(CurrTrfr.DEBITFC) AS DebitFC,SUM(CurrTrfr.CreditFC) AS CreditFC,
							SUM(CurrTrfr.DEBITPR) AS DebitPR, SUM(CurrTrfr.CreditPR) AS CreditPR 
							FROM Inserted INNER JOIN CurrTrfr 
							ON CurrTrfr.Jeohkey = Inserted.UniqJehead
							AND CurrTrfr.Gl_nbr = Inserted.Gl_nbr
						GROUP BY inserted.gl_nbr) I WHERE I.GL_NBR=Banks.GL_NBR

			END
			-- 10/16/17 VL End}
		END TRY
		BEGIN CATCH
		IF @@TRANCOUNT>0
			ROLLBACK
		END CATCH

		-- Insert statements for trigger here
	IF @@TRANCOUNT<>0
	COMMIT
END