-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/27/2011
-- Description:	Drill Down AR Deposits
-- Modification:
-- 09/15/15 VL Added FC fields
-- 05/27/16 VL: added if FC installed or not to separate the SQL because FC requires to join with Fcused to get currency
-- 12/13/16 VL: added functional and presentation currency fields
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownDep]
	-- Add the parameters for the stored procedure here
	@Dep_no char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
-- 05/27/16 VL added to check if FC is installed or not, if yes, need to get the currency 
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
   SELECT Deposits.Date as Trans_Dt,
		Deposits.Dep_no,Banks.BANK,
		ArCredit.Rec_Amount,arcredit.rec_type,ArCredit.DISC_TAKEN,Arcredit.CUSTNO,Customer.Custname,
		arcredit.UniqDetno,arcredit.INVNO,arcredit.REC_ADVICE ,arcredit.BANKCODE, arcredit.uniquear,
		ArCredit.Rec_AmountFC, ArCredit.DISC_TAKENFC
    FROM Deposits inner join Banks ON DEPOSITS.BK_UNIQ = BANKS.BK_UNIQ  
    inner join  ArCredit on Deposits.DEP_NO =ArCredit.DEP_NO 
    inner join customer on arcredit.custno=customer.CUSTNO
    where Deposits.DEP_NO=@Dep_no 
ELSE
	-- 12/13/16 VL: added functional and presentation currency fields
   SELECT Deposits.Date as Trans_Dt,
		Deposits.Dep_no,Banks.BANK,
		ArCredit.Rec_Amount,arcredit.rec_type,ArCredit.DISC_TAKEN,Arcredit.CUSTNO,Customer.Custname,
		arcredit.UniqDetno,arcredit.INVNO,arcredit.REC_ADVICE ,arcredit.BANKCODE, arcredit.uniquear,FF.Symbol AS Functional_Currency,
		ArCredit.Rec_AmountFC, ArCredit.DISC_TAKENFC, TF.Symbol AS Transaction_Currency,
		ArCredit.Rec_AmountPR, ArCredit.DISC_TAKENPR, PF.Symbol AS Presentation_Currency
    FROM Deposits
				INNER JOIN Fcused TF ON Deposits.Fcused_uniq = TF.Fcused_uniq
				INNER JOIN Fcused PF ON Deposits.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON Deposits.FuncFcused_uniq = FF.Fcused_uniq
	inner join Banks ON DEPOSITS.BK_UNIQ = BANKS.BK_UNIQ  
    inner join  ArCredit on Deposits.DEP_NO =ArCredit.DEP_NO 
    inner join customer on arcredit.custno=customer.CUSTNO
    where Deposits.DEP_NO=@Dep_no 
	 
END