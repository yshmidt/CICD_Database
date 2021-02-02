-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <01/14/2010>
-- Description:	<View of all the FY (on or after given year @lcYear), Periods with the start and end dates for the period>
-- modified: 06/22/15 YS added sequencial number to FiscalYr table allows us to have any combination of characters in the FY column
-- will arrange by sequence number 
-- Modified : 02/25/16 YS check if the @lcYear passed as a parameter exists, if not use the same code as when @lcYear is empty
-- =============================================
CREATE PROCEDURE [dbo].[GlFyrstartEndView]
@lcYear char(4) =' ' 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--06/22/15 YS changes in how fy are sorted, added new column sequenceNumber to glfiscalyrs table 
	
	 --   select glfiscalyrs.FiscalYr,D1.Fk_fy_uniq,D1.Period,
	--		CASE WHEN D2.EndDate IS NOT NULL THEN DATEADD(Day,1,D2.EndDate) 
	--		WHEN D3.EndDate IS NOT NULL THEN DATEADD(Day,1,D3.EndDate)	 
	--		ELSE  CAST(convert(char(2),DATEPART(month,D1.EndDate))+'/01/'+convert(char(4),DATEPART(Year,D1.EndDate)) as smalldatetime) END as StartDate,
	--		D1.EndDate  , D1.FYDTLUNIQ
	--from glfyrsdetl D1 INNER JOIN glfiscalyrs ON D1.Fk_fy_uniq=glfiscalyrs.Fy_uniq
	--	LEFT OUTER JOIN glfyrsdetl D2 ON D1.Fk_Fy_uniq=D2.Fk_fy_uniq and D1.Period=D2.Period+1
	--	LEFT OUTER JOIN (SELECT glfiscalyrs.FiscalYr,DS.EndDate FROM  glfyrsdetl DS , glfiscalyrs where glfiscalyrs.fy_uniq=DS.Fk_fy_uniq AND DS.Period=12) D3 
	--	ON glfiscalyrs.FiscalYr=D3.FiscalYr+1 where glfiscalyrs.FiscalYr>=@lcYear ORDER BY glfiscalyrs.FiscalYr,D1.Period


		--06/22/15 YS changes in how fy are sorted, added new column sequenceNumber to glfiscalyrs table
		--02/25/16 YS check if the @lcYear passed as a parameter exists, if not use the same code as when @lcYear is empty
		If (@lcYear=' ') or not exists (select 1 from GlFiscalYrs where FiscalYr=@lcYear)
		BEGIN
		select @lcYear = A.FiscalYr from (select top 1 FiscalYr FROM GlFiscalYrs order by FiscalYr) A
		END 
		declare  @startSequenceNumber Int
		select @startSequenceNumber=B.sequenceNumber
		from (
		select top 1 * from
		(select  y2.sequenceNumber from glfiscalyrs y2 where exists (select 1 from glfiscalyrs y1 where y1.FiscalYr=@lcYear 
			and y2.SequenceNumber=y1.SequenceNumber-1)
			UNION 
		SELECT y.sequenceNumber from glfiscalyrs y where y.FiscalYr=@lcYear) strartY order by sequenceNumber)  B
			
	
		;with fy
		as
		(
		--declare @lcYear char(4) ='2013'
		 select Y.FiscalYr,D1.Fk_fy_uniq,D1.Period,Y.sequenceNumber,d1.enddate,
			D1.FYDTLUNIQ,ROW_NUMBER() OVER (order by sequencenumber,period) as rn
			--ROW_NUMBER() OVER (partition by Y.FiscalYr order by sequencenumber,period) as rn
			from glfyrsdetl D1 INNER JOIN glfiscalyrs Y ON D1.Fk_fy_uniq=Y.Fy_uniq
			where Y.sequenceNumber >= @startSequenceNumber
	
		)

		SELECT fy.FiscalYr,fy.Fk_fy_uniq,fy.Period,
			CASE WHEN Sub.StartDate IS NOT NULL THEN  Sub.StartDate ELSE dateadd(day,-(Day(fy.ENDDATE)-1), fy.ENDDATE) END as StartDate,
			fy.enddate,
			fy.FYDTLUNIQ,fy.RN,fy.sequenceNumber
		From 
			FY 
			Outer Apply (Select dateadd(day,1,[EndDate]) as StartDate From FY As SubQry Where FY.RN-1 = SubQry.RN) As Sub
			order by sequenceNumber,period
END