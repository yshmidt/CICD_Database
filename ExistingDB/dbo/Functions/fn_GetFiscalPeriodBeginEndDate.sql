-- =============================================
-- Author:		<Vicky Lu>
-- Create date: <11/17/2015>
-- Description:	<Get all period begin/end dates for selected year from GLFYRSDETL table>
-- =============================================
CREATE FUNCTION [dbo].[fn_GetFiscalPeriodBeginEndDate]
(
	-- Add the parameters for the function here
	@FY char(4)
)
RETURNS TABLE 
AS
RETURN
(

WITH ZLastYear12 AS 
(SELECT 1 AS Period, EndDate+1 AS BegDate--, --@ThisYear1stPeriodKey AS FyDtlUniq 
	FROM GLFYRSDETL 
	WHERE Fk_Fy_Uniq IN 
		(SELECT Fy_Uniq 
			FROM GlFiscalyrs 
			WHERE Fiscalyr = STR(CAST(@FY AS int)-1,4))
	AND Period = 12
),
ZThisYear As
(
SELECT Period, EndDate, Fk_Fy_Uniq 
	FROM GLFYRSDETL
	WHERE FK_FY_UNIQ IN
	(SELECT Fy_Uniq 
			FROM GlFiscalyrs 
			WHERE Fiscalyr = @FY)
),
ZThisYearAll AS
(
SELECT Period, BegDate FROM ZLastYear12
UNION ALL
SELECT Period+1 AS period, Enddate+1 AS BEGDATE 
	FROM ZThisYear
	WHERE Period <> 12
)

SELECT ZThisYearAll.*, Enddate, @FY AS FiscalYr 
	FROM ZThisYearAll, ZThisYear
	WHERE ZThisYearAll.Period = ZThisYear.Period 
)