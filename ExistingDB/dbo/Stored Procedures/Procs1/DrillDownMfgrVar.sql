-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <10/31/2011>
-- Description:	<get drill down information for Manufacturing Variance>
-- Modified : 
-- 12/13/16 VL: added functional and presentation currency fields and separate FC and non FC
-- 04/13/17 VL: Fixed presentation_currency field
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownMfgrVar]
	-- Add the parameters for the stored procedure here
	@UniqMfgVar as char(10)=' '
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
	SELECT MFGRVAR.wono, MFGRVAR.uniq_key, MFGRVAR.MAN_GL_NBR, 
		MFGRVAR.wip_gl_nbr, UNIQMFGVAR  ,
		BomCost,IssueCost,totalvar,
		datetime as Trans_dt
		FROM MFGRVAR WHERE UNIQMfgVar=@UniqMfgVar
ELSE
	-- 12/13/16 VL: added functional and presentation currency fields
	SELECT MFGRVAR.wono, MFGRVAR.uniq_key, MFGRVAR.MAN_GL_NBR, 
		MFGRVAR.wip_gl_nbr, UNIQMFGVAR  ,
		BomCost,IssueCost,totalvar,FF.Symbol AS Functional_Currency,
		datetime as Trans_dt,
		BomCostPR,IssueCostPR,totalvarPR,PF.Symbol AS Presentation_Currency
		FROM MFGRVAR 
			INNER JOIN Fcused PF ON MFGRVAR.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON MFGRVAR.FuncFcused_uniq = FF.Fcused_uniq	
		WHERE UNIQMfgVar=@UniqMfgVar
END