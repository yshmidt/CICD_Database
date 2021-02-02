-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <11/01/2011>
-- Description:	<get drill down information for Scrap >
-- Modification:
-- 12/13/16 VL: added functional and presentation currency fields and separate FC and non FC
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownScrap]
	-- Add the parameters for the stored procedure here
	@Trans_no as char(10)=' '
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
	SELECT Scraprel.wono, scraprel.uniq_key, scraprel.SHRI_GL_NO as Scrap_gl_nbr, 
		SCRAPREL.WIP_GL_NBR, trans_no  ,
		scraprel.QTYTRANSF ,scraprel.STDCOST,ROUND(qtytransf*stdcost,2) as Total_scrap,
		scraprel.DATETIME as Trans_dt
		FROM scraprel WHERE Trans_no=@Trans_no 
ELSE
	-- 12/13/16 VL added presentation and functional currency fields
	SELECT Scraprel.wono, scraprel.uniq_key, scraprel.SHRI_GL_NO as Scrap_gl_nbr, 
		SCRAPREL.WIP_GL_NBR, trans_no  ,
		scraprel.QTYTRANSF ,scraprel.STDCOST,ROUND(qtytransf*stdcost,2) as Total_scrap, FF.Symbol AS Functional_Currency,
		scraprel.DATETIME as Trans_dt,
		scraprel.STDCOSTPR,ROUND(qtytransf*stdcostPR,2) as Total_scrapPR, PF.Symbol AS Presentation_Currency
		FROM scraprel 
			INNER JOIN Fcused PF ON scraprel.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON scraprel.FuncFcused_uniq = FF.Fcused_uniq	
		WHERE Trans_no=@Trans_no 
END