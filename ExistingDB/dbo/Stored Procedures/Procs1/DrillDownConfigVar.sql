-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <10/26/2011>
-- Description:	<get drill down information for Configuration Variance>
-- Modification:
-- 12/13/16 VL: added functional and presentation currency fields and separate FC and non FC
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownConfigVar]
	-- Add the parameters for the stored procedure here
	@UniqConf as char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

-- 12/13/16 VL separate FC and non FC
IF @lFCInstalled = 0
    -- Insert statements for procedure here
	SELECT Confgvar.wono, Confgvar.uniq_key, Confgvar.cnfg_gl_nb,
		Confgvar.wip_gl_nbr, ConfgVar.UNIQCONF ,
		CASE WHEN SIGN(Confgvar.Variance)=SIGN(Confgvar.StdCost-Confgvar.WipCost) 
			THEN Confgvar.qtytransf
			ELSE -Confgvar.qtytransf END as QtyTransf, 
		Confgvar.stdcost, Confgvar.wipcost, Confgvar.variance, totalvar,
		Confgvar.datetime as Trans_dt,
		Confgvar.invtxfer_n, Confgvar.transftble
		FROM CONFGVAR WHERE UNIQCONF=@UNIQCONF
ELSE
    -- Insert statements for procedure here
	SELECT Confgvar.wono, Confgvar.uniq_key, Confgvar.cnfg_gl_nb,
		Confgvar.wip_gl_nbr, ConfgVar.UNIQCONF ,
		CASE WHEN SIGN(Confgvar.Variance)=SIGN(Confgvar.StdCost-Confgvar.WipCost) 
			THEN Confgvar.qtytransf
			ELSE -Confgvar.qtytransf END as QtyTransf, 
		Confgvar.stdcost, Confgvar.wipcost, Confgvar.variance, totalvar, FF.Symbol AS Functional_Currency,
		Confgvar.datetime as Trans_dt,
		Confgvar.invtxfer_n, Confgvar.transftble,
		Confgvar.stdcostPR, Confgvar.wipcostPR, Confgvar.variancePR, totalvarPR, PF.Symbol AS Presentation_Currency
		FROM CONFGVAR 
				INNER JOIN Fcused PF ON CONFGVAR.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON CONFGVAR.FuncFcused_uniq = FF.Fcused_uniq
		WHERE UNIQCONF=@UNIQCONF

END