

	-- =============================================
	-- Author:			Debbie
	-- Create date:		05/02/2014
	-- Description:		Compiles the details for the Yield Report by Customer by Assembly
	-- Used On:			qayield
	-- Modifications:	09/30/2014 DRP:  with Yelena she discovered that most of the Selection statements used were not really needed and was slowing down the results.  we also had to make changes to how the Yeild was calculated. 
    -- 08/14/17 DRP:  I need to add nullif to the Yeidl formula because some users were getting an "Divide by zero error"
-- 11/17/20 VL: changed the date range, so it will also include the record if the record is entered on the same date 
	-- =============================================
	CREATE PROCEDURE  [dbo].[rptQaYield]

--declare
	@lcDateStart as smalldatetime = null
	,@lcDateEnd as smalldatetime = null
	,@lcDeptId as varchar(max) = 'All'
	,@userId uniqueidentifier= null

as
begin
	
/*DEPARTMENT LIST*/		
	DECLARE  @tDepts as tDepts
		DECLARE @Depts TABLE (dept_id char(4))
		-- get list of Departments for @userid with access
		INSERT INTO @tDepts (Dept_id,Dept_name,[Number]) EXEC DeptsView @userid ;
		--SELECT * FROM @tDepts	
		IF @lcDeptId is not null and @lcDeptId <>'' and @lcDeptId<>'All'
			insert into @Depts select * from dbo.[fn_simpleVarcharlistToTable](@lcDeptId,',')
					where CAST (id as CHAR(4)) in (select Dept_id from @tDepts)
		ELSE

		IF  @lcDeptId='All'	
		BEGIN
			INSERT INTO @Depts SELECT Dept_id FROM @tDepts
		END


	SELECT	Custname, Part_no,Revision, SUM(Lotsize) AS LotSize,SUM(Inspqty) AS InspQty,SUM(PassQty) AS PassQty
			,SUM(FailQty) AS FailQty,Date,Inspby,
			--100*SUM(PassQty)/SUM(InspQty) AS Yield	--08/14/17 DRP:  replaced with the below 
			100*SUM(PassQty)/SUM(nullif(InspQty,0)) AS Yield 
	FROM	Qainsp, Woentry, Inventor, Customer 
	WHERE	Inventor.Uniq_key = Woentry.Uniq_key 
			AND Customer.Custno = Woentry.Custno 
			AND Qainsp.Wono = Woentry.Wono 
			-- 11/17/20 VL: changed the date range, so it will also include the record if the record is entered on the same date 
			--AND Date >= @lcDateStart AND Date <= @lcDateEnd 
			AND DATEDIFF(day, @lcDateStart,Date) >=0 AND DATEDIFF(day,Date,@lcDateEnd )>=0
			AND 1 = CASE WHEN QAinsp.DEPT_ID IN(SELECT DEPT_ID FROM @Depts) THEN 1 ELSE 0 END
	GROUP BY CustName,Part_No,Revision,Date,InspBy


/*09/30/2014 DRP:  with Yelena she discovered that all of the below was not really needed and was slowing down the results.  we also had to make changes to how the Yeild was calculated. 
--/*USED TO GATHER THE GROUPED AND SUM TOTALS*/
--declare @tQaYield1 as table (Custname Char(35),Part_no Char(25),Revision Char(8),LotSize Numeric(16,0),InspQty Numeric(16,0)
--							,PassQty Numeric(16,0),FailQty Numeric(16,0),[Date] smalldatetime,Inspby Char(10))

--/*USED TO GATHER DETAILED YIELD DATA*/
--declare @tQaYieldD as table (Custname Char(35),Part_no char(25),Revision char(8),Lotsize numeric(16,0),InspQty numeric(16,0)
--							,PassQty numeric(16,0),FailQty numeric(16,0),[Date] smalldatetime,Inspby char(10),Qaseqmain char(10))


--insert into @tQaYieldD 
--	select	Custname,Part_no,Revision, Qainsp.Lotsize,InspQty,PassQty,FailQty,qainsp.Date,Inspby,Qainsp.Qaseqmain 
--	FROM	Qainsp, Woentry, Inventor,Customer
--	WHERE	Inventor.Uniq_key = Woentry.Uniq_key 
--			AND Customer.Custno = Woentry.Custno 
--			AND Qainsp.Wono = Woentry.Wono 
--			AND Date >= @lcDateStart AND Date <= @lcDateEnd 
--			AND 1 = CASE WHEN QAinsp.DEPT_ID IN(SELECT DEPT_ID FROM @Depts) THEN 1 ELSE 0 END


--insert into @tQaYield1 
--	SELECT	Custname,Part_no,Revision,SUM(Lotsize) AS LotSize,SUM(Inspqty) AS InspQty,SUM(PassQty) AS PassQty
--			,SUM(FailQty) AS FailQty,Date,Inspby 
--	FROM	@tQaYieldD 
--	GROUP BY CustName,Part_No,Revision,Date,InspBy

--insert into @tQaYield1
--	SELECT	Custname, Part_no,Revision, SUM(Lotsize) AS LotSize,SUM(Inspqty) AS InspQty,SUM(PassQty) AS PassQty
--			,SUM(FailQty) AS FailQty,Date,Inspby 
--	FROM	Qainsp, Woentry, Inventor, Customer 
--	WHERE	Inventor.Uniq_key = Woentry.Uniq_key 
--			AND Customer.Custno = Woentry.Custno 
--			AND Qainsp.Wono = Woentry.Wono 
--			AND Date >= @lcDateStart AND Date <= @lcDateEnd 
--			AND 1 = CASE WHEN QAinsp.DEPT_ID IN(SELECT DEPT_ID FROM @Depts) THEN 1 ELSE 0 END
--			AND qainsp.qaseqmain NOT IN (SELECT qaseqmain FROM @tQaYieldD) 
--	GROUP BY CustName,Part_No,Revision,Date,InspBy



--/*FINAL RESULTS*/
--	SELECT	Custname, Part_no,Revision, SUM(Lotsize) AS LotSize,SUM(Inspqty) AS InspQty,SUM(PassQty) AS PassQty
--			,SUM(FailQty) AS FailQty,(100*SUM(PassQty)/SUM(InspQty)) AS Yield,Date,Inspby
--	FROM	@tQaYield1 
--	GROUP BY CustName,Part_No,Revision,Date,InspBy
--	ORDER BY CustName,Part_no,Revision,Date,InspBy
09/30/2014 DRP:  Removal End. */



end