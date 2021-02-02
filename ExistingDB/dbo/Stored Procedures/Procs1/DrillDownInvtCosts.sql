-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <10/28/2011>
-- Description:	<get drill down information for Other Inventory Costs>
-- Modification:
-- 12/13/16 VL: added functional and presentation currency fields
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownInvtCosts]
	-- Add the parameters for the stored procedure here
	@UniqConf as char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- 12/13/16 VL added to check if FC is installed or not, if yes, need to get the currency 
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
    -- Insert statements for procedure here
	SELECT Confgvar.wono, Confgvar.uniq_key, ConfgVar.UNIQCONF ,
		CASE WHEN SIGN(Confgvar.Variance)=SIGN(Confgvar.StdCost-Confgvar.WipCost) 
			THEN Confgvar.qtytransf
			ELSE -Confgvar.qtytransf END as QtyTransf, ConfgVar.VARTYPE ,
		Confgvar.variance, totalvar,
		Confgvar.datetime as Trans_dt,
		Confgvar.invtxfer_n, Confgvar.transftble
		FROM CONFGVAR WHERE UNIQCONF=@UNIQCONF
ELSE
	-- 12/13/16 VL: added functional and presentation currency fields
	SELECT Confgvar.wono, Confgvar.uniq_key, ConfgVar.UNIQCONF ,
		CASE WHEN SIGN(Confgvar.Variance)=SIGN(Confgvar.StdCost-Confgvar.WipCost) 
			THEN Confgvar.qtytransf
			ELSE -Confgvar.qtytransf END as QtyTransf, ConfgVar.VARTYPE ,
		Confgvar.variance, totalvar, FF.Symbol AS Functional_Currency,
		Confgvar.datetime as Trans_dt,
		Confgvar.invtxfer_n, Confgvar.transftble,
		Confgvar.variancePR, totalvarPR, PF.Symbol AS Presentation_Currency
		FROM CONFGVAR 
			INNER JOIN Fcused PF ON CONFGVAR.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON CONFGVAR.FuncFcused_uniq = FF.Fcused_uniq		
		WHERE UNIQCONF=@UNIQCONF
END