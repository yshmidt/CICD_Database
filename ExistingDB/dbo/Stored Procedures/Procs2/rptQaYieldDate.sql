-- =============================================
-- Author:		Debbie
-- Create date: 07/10/2014
-- Description:	
-- Used On:		yielddt
-- Modified:	09/02/2014 DRP:  Yelena helped me determine that we needed to add @OpenWo to this procedure in order to use it to make sure that the results passed the correct Work order based on the Open WO selection
--								 otherwise if the user selected ALL in the parameter for open Only it was still incorrectly including closed work orders in the results.  
--				10/13/2014 DRP:  With Yelena's help we needed to make changes to how the Yield was caclulated.  Previously it was calculating each individual records, but in cases when SN are processed they would not get a true Yeild. 
--				01/06/2015 DRP:  Added @customerStatus Filter
-- 08/14/17 DRP:  I need to add nullif to the 5 formulas because some users were getting an "Divide by zero error"
-- =============================================
CREATE PROCEDURE [dbo].[rptQaYieldDate]

--declare
	@lcDateStart as smalldatetime = null		
	,@lcDateEnd as smalldatetime = null
	,@lcWoNo as varchar(max) = 'All'				
	,@lcDeptId as varchar(max) = 'All'
	,@lcCustNo as varchar(max) = 'All'
	,@openWo bit = 1					-- default 1 to select make parts with open jobs only, if 0 select parts with any job status --09/02/2014 DRP:  Added
	,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
	,@userId uniqueidentifier= null
	
as
begin
	
/*WORK ORDER LIST*/
	declare @WoNo table(WoNo char(10))
		if @lcWoNo is not null and @lcWoNo <> ''
			insert into @WoNo select * from dbo.[fn_simpleVarcharlistToTable](@lcWoNo,',')

/*CUSTOMER LIST*/
	DECLARE  @tCustomer as tCustomer
			DECLARE @Customer TABLE (custno char(10))
		-- get list of Customers for @userid with access
		INSERT INTO @tCustomer EXEC aspmnxSP_Getcustomers4user @userid,null,@customerStatus ;
		--SELECT * FROM @tCustomer	
		IF @lcCustno is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select Custno from @tCustomer)
		ELSE

		IF  @lccustNo='All'	
		BEGIN
			INSERT INTO @Customer SELECT Custno FROM @tCustomer
		END

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
		
/*SELECT STATEMENT*/

/*10/13/2014 DRP:  replaced by select statement below
--SELECT	Custname, Qainsp.Wono, Part_no, Revision, LotSize, InspQty, FailQty, PassQty, Yield, Dept_name, Date, Qaseqmain AS QALink 
--FROM	Qainsp, Woentry, Inventor, Customer, Depts 
--WHERE	Inventor.Uniq_key = Woentry.Uniq_key 
--		AND Woentry.Custno = Customer.Custno 
--		AND Qainsp.Wono = Woentry.Wono 
--		AND Qainsp.Dept_id = Depts.Dept_id 
--		AND Date >= @lcDateStart AND Date <= @lcDateEnd 
--		AND 1 = CASE WHEN QAINSP.DEPT_ID IN(SELECT DEPT_ID FROM @Depts) THEN 1 ELSE 0 END
--		and 1= case WHEN woentry.custNO IN (SELECT custno FROM @CUSTOMER) THEN 1 ELSE 0  END 
--		and 1 = case when @lcWono = 'All' then 1 when woentry.WONO IN(select WONO from @WoNo) then 1 else 0 end
--		and 1=CASE WHEN @OpenWo=0 OR (@OpenWo=1 AND woentry.OpenClos<>'Closed' and Woentry.OpenClos<>'Cancel') THEN 1 ELSE 0 END  --09/02/2014 DRP:  Added
--ORDER BY Date, Custname, Part_no 
10/13/2014 DRP: Replace end*/

select	custname,Wono,Part_no,Revision,lotsize,inspqty,failqty,passqty,Dept_name,[date],UNIQ_KEY
		,SUM(passqty) over (partition by Custname ) as passqtyforCustomer,SUM(inspqty) over (partition by Custname ) as inspqtyperCustomer
		--,100*SUM(passqty) over (partition by Custname )/SUM(inspqty) over (partition by Custname ) as YieldByCust	--08/14/17 DRP:  the below 5 fields were replaced by the below 
		--,100*SUM(passqty) over (partition by wono )/SUM(inspqty) over (partition by wono ) as YieldByWono
		--,100*SUM(passqty) over (partition by uniq_key )/SUM(inspqty) over (partition by uniq_key ) as YieldByProduct
		--,100*SUM(passqty) over (partition by dept_name )/SUM(inspqty) over (partition by dept_name ) as YieldByWorkCenter
		--,100*SUM(passqty) over (partition by [date] )/SUM(inspqty) over (partition by [date] ) as YieldByDate
		,100*SUM(passqty) over (partition by Custname )/SUM(nullif(inspqty,0)) over (partition by Custname ) as YieldByCust
		,100*SUM(passqty) over (partition by wono )/SUM(nullif(inspqty,0)) over (partition by wono ) as YieldByWono
		,100*SUM(passqty) over (partition by uniq_key )/SUM(nullif(inspqty,0)) over (partition by uniq_key ) as YieldByProduct
		,100*SUM(passqty) over (partition by dept_name )/SUM(nullif(inspqty,0)) over (partition by dept_name ) as YieldByWorkCenter
		,100*SUM(passqty) over (partition by [date] )/SUM(nullif(inspqty,0)) over (partition by [date] ) as YieldByDate
 
FROM	(SELECT	Custname,Qainsp.Wono,Part_no,Revision,sum(LotSize) as lotsize,sum(InspQty) as inspqty,sum(FailQty) as failqty
				,sum(PassQty) as passqty,Dept_name,cast([date] as date) as [date],woentry.UNIQ_KEY
		 FROM	Qainsp, Woentry, Inventor, Customer, Depts 
		 WHERE	Inventor.Uniq_key = Woentry.Uniq_key 
				AND Woentry.Custno = Customer.Custno 
				AND Qainsp.Wono = Woentry.Wono 
				AND Qainsp.Dept_id = Depts.Dept_id 
				AND DATEDIFF(day, @lcDateStart,Date) >=0 AND DATEDIFF(day,Date,@lcDateEnd )>=0
				AND 1 = CASE WHEN QAINSP.DEPT_ID IN(SELECT DEPT_ID FROM @Depts) THEN 1 ELSE 0 END
				and 1= case WHEN woentry.custNO IN (SELECT custno FROM @CUSTOMER) THEN 1 ELSE 0  END 
				and 1 = case when @lcWono = 'All' then 1 when woentry.WONO IN(select WONO from @WoNo) then 1 else 0 end
				and 1=CASE WHEN @OpenWo=0 OR (@OpenWo=1 AND woentry.OpenClos<>'Closed' and Woentry.OpenClos<>'Cancel') THEN 1 ELSE 0 END  --09/02/2014 DRP:  Added
		 group by Custname, Qainsp.Wono, Part_no, Revision,Dept_name, cast([date] as date),woentry.UNIQ_KEY) A

ORDER BY custname,wono

end