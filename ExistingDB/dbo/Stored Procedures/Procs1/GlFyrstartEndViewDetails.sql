-- =============================================
-- Author:		<Nilesh S>
-- Create date: <11/29/2017>
-- Description:	<View of all the FY (on or after given year @lcYear), Periods with the start and end dates for the period>
-- [GlFyrstartEndViewDetails] '2017'
-- =============================================
CREATE PROCEDURE [dbo].[GlFyrstartEndViewDetails]
@lcYear CHAR(4) =' ' 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		If (@lcYear=' ') or not exists (SELECT 1 FROM GlFiscalYrs WHERE FiscalYr=@lcYear)
		BEGIN
		  SELECT @lcYear = A.FiscalYr from (SELECT TOP 1 FiscalYr FROM GlFiscalYrs ORDER BY FiscalYr) A
		END 

		DECLARE  @startSequenceNumber INT

		SELECT @startSequenceNumber=B.sequenceNumber
		FROM 
		(
			SELECT TOP 1 * FROM		
			(
				 SELECT  y2.sequenceNumber FROM glfiscalyrs y2 WHERE EXISTS (SELECT 1 FROM glfiscalyrs y1 WHERE y1.FiscalYr=@lcYear AND y2.SequenceNumber=y1.SequenceNumber-1)
				UNION 
				 SELECT y.sequenceNumber FROM glfiscalyrs y WHERE y.FiscalYr=@lcYear
			) strartY ORDER BY sequenceNumber
		)B	
				
		;WITH fy
		as
		(
			SELECT Y.FiscalYr,D1.Fk_fy_uniq,D1.Period,Y.sequenceNumber,d1.enddate,
			D1.FYDTLUNIQ,ROW_NUMBER() OVER (ORDER BY sequencenumber,period) AS rn,nQtr AS [Quarter]
			FROM glfyrsdetl D1 INNER JOIN glfiscalyrs Y ON D1.Fk_fy_uniq=Y.Fy_uniq
			WHERE Y.sequenceNumber >= @startSequenceNumber	
		)

		SELECT fy.FiscalYr,fy.Fk_fy_uniq,fy.Period,CASE WHEN Sub.StartDate IS NOT NULL THEN  Sub.StartDate ELSE DATEADD(DAY,-(DAY(fy.ENDDATE)-1), fy.ENDDATE) END AS StartDate,
		fy.enddate,fy.FYDTLUNIQ,fy.RN,fy.sequenceNumber,[Quarter]
		FROM FY 
		Outer Apply (SELECT DATEADD(DAY,1,[EndDate]) AS StartDate FROM FY AS SubQry WHERE FY.RN-1 = SubQry.RN) AS Sub
		ORDER BY sequenceNumber,period
END