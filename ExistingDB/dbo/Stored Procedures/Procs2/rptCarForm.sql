-- =============================================
-- Author:		Debbie Peltier
-- Create date: 06/06/17
-- Description:	<Corrective Action Request Form> car.mrt
-- Modified:	-- 06/06/17 VL added AvgPr to show average progress
-- 03/16/18 VL changed AvgPr from CROSS APPLY TO LEFT OUTER JOIN, so even no team is assigned, the CAR still shows on the report with 0 AvgPr
-- 03/16/18 VL Also found if user select all carno, the @lcCarNo is not saving all the carno, it's saving 'All', so change the code to get all open car
-- =============================================
CREATE procedure [dbo].[rptCarForm]

--DECLARE	
@lcCarNo varchar(max) = null
,@userId uniqueidentifier= null

as 
begin


/*CUSTOMER LIST*/		
DECLARE  @tCustomer as tCustomer
	--DECLARE @Customer TABLE (custno char(10))`--10/28/15 DRP:  we declared this but never really used it. 
	-- get list of customers for @userid with access
	INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
	--SELECT * FROM @tCustomer

/*SUPPLIER LIST*/
-- get list of approved suppliers for this user
DECLARE @tSupplier tSupplier
	declare @tSupNo as table (Uniqsupno char (10))
	INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, 'All';
	--select * from @tSupplier


-- {03/16/18 VL changed to get all car if user selects all
--SET @lcCarNo=dbo.PADL(@lcCarNo,10,'0')

/*CAR LIST*/
--DECLARE  @tCarNo as table (CarNo char (10))
--		insert into @tCarNo select dbo.PADL(RTRIM(id),10,'0')  from dbo.[fn_simpleVarcharlistToTable](@lcCarNo,',')
		--select * from @tCarNo
		
/*CAR LIST*/		
DECLARE  @tCarNo as table (CarNo char (10), CompDate smalldatetime)
DECLARE @CarNo table(CarNo char(10))
INSERT INTO @tCarNo SELECT CarNo, Compdate FROM Craction
		IF @lcCarNo IS NOT NULL AND @lcCarNo <>'' and @lcCarNo<>'All'
			INSERT INTO @CarNo SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcCarNo,',')
					WHERE CAST (id as CHAR(15)) IN (SELECT CarNo from @tCarNo)
		ELSE

		IF  @lcCarNo='All'	
		BEGIN
			INSERT INTO @CarNo SELECT CarNo FROM @tCarNo WHERE CompDate IS NULL		-- show only open ones
		END
-- 03/16/18 VL End}

select	R.CARNO,R.CAR_DATE,R.NEWDUE_DT,R.DESCRIPT,R.PROB_TYPE,R.NO_TYPE,R.NUMBER
		,CASE WHEN RTRIM(R.PROB_TYPE) = 'SUPPLIER' THEN ISNULL(S.SUPNAME,'') ELSE
			CASE WHEN RTRIM(R.PROB_TYPE) = 'CUSTOMER' THEN ISNULL(C.CUSTNAME,'') ELSE
				CASE WHEN RTRIM(R.PROB_TYPE) = 'WORK CENTER/DEPT' THEN ISNULL(D.DEPT_NAME,'') ELSE '' END  END END AS APPNAME
		,R.CUSTNO,ISNULL(R.UniqSupno,'') AS UNIQSUPNO,R.DEPT_ID
		,R.MAJMIN,R.[BY]
		,isnull(dbo.FnCarMember(r.CARNO),'') as CRMEMBER,R.CONDITION,R.APP_CAUSE
		,R.ACT_CAUSE,R.PROBVERFBY,R.PROBVERFDT
		,R.COR_ACTION,R.APPROVE_BY,R.APPROVE_DT
		,R.CAR_NOTE,R.FOLLOWUPBY,R.FOLLOWUPDT
		,R.COMPLETEBY,R.COMPDATE,ISNULL(T.AvgPr,0.00) AS AvgPr
from	CRACTION R
		LEFT OUTER JOIN CUSTOMER C ON R.CUSTNO = C.CUSTNO
		LEFT OUTER JOIN SUPINFO S ON R.UniqSupno = S.UNIQSUPNO 
		LEFT OUTER JOIN DEPTS D ON R.DEPT_ID = D.DEPT_ID
		-- 06/06/17 VL added AvgPr to show average progress
		-- 03/16/18 VL changed AvgPr from CROSS APPLY TO LEFT OUTER JOIN, so even no team is assigned, the CAR still shows on the report with 0 AvgPr
		--CROSS APPLY (SELECT Carno, SUM(Proj_stat)/COUNT(*) AS AvgPr FROM CRAC_DET WHERE Crac_det.Carno = R.Carno GROUP BY Carno) T 
		LEFT OUTER JOIN (SELECT Carno, SUM(Proj_stat)/COUNT(*) AS AvgPr FROM CRAC_DET GROUP BY Carno) T ON R.Carno = T.Carno
where	exists (select 1 from @CarNo p  where p.CarNo=R.CARNO)
		and (1 = case when R.CUSTNO in (select CUSTNO from @Tcustomer ) then 1 else 0 end or 1 = case when R.UniqSupno in (select UniqSupno from @tSupplier ) then 1 else 0 end)

end