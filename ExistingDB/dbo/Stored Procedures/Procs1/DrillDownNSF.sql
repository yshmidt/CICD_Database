-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/31/2011
-- Description:	Drill Down NSF 
-- Modification:
--	09/21/15 VL Added FC fields
-- 05/27/16 VL: added if FC installed or not to separate the SQL because FC requires to join with Fcused to get currency
-- 12/13/16 VL: added functional and presentation currency fields
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownNSF]
	-- Add the parameters for the stored procedure here
	@UniqRetno char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
-- 05/27/16 VL added to check if FC is installed or not, if yes, need to get the currency 
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
    -- Insert statements for procedure here
   SELECT Ret_date as Trans_dt, ArretCk.UniqRetno,ArretCk.Custno,ArretCk.Dep_No,Customer.CUSTNAME , 
		  ARRETDET.Rec_Amount, ARRETDET.DISC_TAKEN, ARRETDET.Rec_AmountFC, ARRETDET.DISC_TAKENFC
	FROM ArretCk INNER JOIN ArretDet ON ArretCk.UniqRetno=ArretDet.UNIQRETNO 
	INNER JOIN CUSTOMER on customer.CUSTNO =ARRETCK.custno 
	WHERE ArretCk.UniqRetno=@UniqRetno
ELSE	
    -- Insert statements for procedure here
	-- 12/13/16 VL: added functional and presentation currency fields
   SELECT Ret_date as Trans_dt, ArretCk.UniqRetno,ArretCk.Custno,ArretCk.Dep_No,Customer.CUSTNAME , 
		  ARRETDET.Rec_Amount, ARRETDET.DISC_TAKEN, FF.Symbol AS Functional_Currency,
		  ARRETDET.Rec_AmountFC, ARRETDET.DISC_TAKENFC, TF.Symbol AS Transaction_Currenccy,
		  ARRETDET.Rec_AmountPR, ARRETDET.DISC_TAKENPR, PF.Symbol AS Presentation_Currenccy
	FROM ArretCk
		INNER JOIN Fcused TF ON ArretCk.Fcused_uniq = TF.Fcused_uniq
		INNER JOIN Fcused PF ON ArretCk.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON ArretCk.FuncFcused_uniq = FF.Fcused_uniq
	INNER JOIN ArretDet ON ArretCk.UniqRetno=ArretDet.UNIQRETNO 
	INNER JOIN CUSTOMER on customer.CUSTNO =ARRETCK.custno 
	WHERE ArretCk.UniqRetno=@UniqRetno	
END