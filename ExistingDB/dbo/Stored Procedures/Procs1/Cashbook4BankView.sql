CREATE PROCEDURE [dbo].[Cashbook4BankView] 
	-- Add the parameters for the stored procedure here
	@Bk_Uniq as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- 04/26/17 VL added functional currency fields
	SELECT CBUnique, Bk_Uniq, StmtDate, FiscalYr, Period, Perstart, Perend, BegBkBal, BegBkBalFC, BkDepCleared, BkDepClearedFC, BkCksCleared, BkCksClearedFC,
		BkTrfrDebitCl, BkTrfrDebitCLFC, BkTrfrCreditCl, BkTrfrCreditClFC, EndBal, EndBalFC,
		BegBkBalPR, BkDepClearedPR, BkCksClearedPR, BkTrfrDebitClPR, BkTrfrCreditClPR, EndBalPR, PRFcused_uniq, FuncFcused_uniq
		FROM CashBook
		WHERE Bk_uniq = @Bk_Uniq
		ORDER BY FISCALYR DESC, Period DESC
END