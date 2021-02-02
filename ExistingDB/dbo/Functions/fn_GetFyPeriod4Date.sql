-- =============================================
-- Author:		<Vicky Lu>
-- Create date: <2019/06/18>
-- Description:	<Function to get FY/Period of a date>
-- =============================================
CREATE FUNCTION [dbo].[fn_GetFyPeriod4Date] 
(	
	@ldDate smalldatetime
)

RETURNS TABLE 
AS
RETURN
(

	WITH ZStartYr AS
	(
		SELECT TOP 1 FiscalYr FROM GlFiscalYrs order by FiscalYr
	),
	ZStartSequenceNumber AS
	(
		SELECT B.sequenceNumber
			FROM (
		SELECT TOP 1 * FROM
			(SELECT  y2.SequenceNumber FROM glfiscalyrs y2 WHERE exists (SELECT 1 FROM glfiscalyrs y1, ZStartYr WHERE y1.FiscalYr=ZStartYr.FiscalYr 
				AND y2.SequenceNumber=y1.SequenceNumber-1)
				UNION 
			SELECT y.SequenceNumber FROM glfiscalyrs y, ZStartYr WHERE y.FiscalYr = ZStartYr.FiscalYr ) strartY ORDER BY sequenceNumber)  B
	),
	Fy AS
	(
		SELECT Y.FiscalYr,D1.Fk_fy_uniq,D1.Period,Y.sequenceNumber,d1.enddate, D1.FYDTLUNIQ,ROW_NUMBER() OVER (order by Y.sequencenumber,period) as rn
			FROM glfyrsdetl D1 INNER JOIN glfiscalyrs Y ON D1.Fk_fy_uniq=Y.Fy_uniq, ZStartSequenceNumber
			where Y.sequenceNumber >= ZStartSequenceNumber.SequenceNumber
	),
	ZAllFYPeriods AS
	(
	SELECT fy.FiscalYr,fy.Fk_fy_uniq,fy.Period,
			CASE WHEN Sub.StartDate IS NOT NULL THEN  Sub.StartDate ELSE dateadd(day,-(Day(fy.ENDDATE)-1), fy.ENDDATE) END as StartDate,
			fy.enddate,
			fy.FYDTLUNIQ,fy.RN,fy.sequenceNumber
		From 
			FY 
			Outer Apply (Select dateadd(day,1,[EndDate]) as StartDate From FY As SubQry Where FY.RN-1 = SubQry.RN) As Sub
			--order by sequenceNumber,period
	)
	SELECT FiscalYr AS Fy,Period,fyDtlUniq
		FROM ZAllFYPeriods
		WHERE CAST(@ldDate as date) BETWEEN CAST(startDate as date) and  CAST(EndDate as date)
)


