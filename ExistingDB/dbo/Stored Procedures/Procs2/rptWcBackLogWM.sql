
-- =============================================
-- Author:		Debbie
-- Create date: 04/25/2012
-- Description:	This Stored Procedure was created for the Backlog Report by Work Center report
-- Reports:		bklgwc.rpt
-- Modified:	11/02/2012 DRP:  I had to add the @lcDeptId parameter to the stored procedure
--				01/06/2015 DRP:  Added @userId to work with the Cloud Reports and parameters.  changed @lcDeptId from char(4) to be varchar(max).  Also added the Department List section
-- 08/17/20 VL added customer filter
-- =============================================

CREATE PROCEDURE [dbo].[rptWcBackLogWM]
--declare
		@lcDeptId as varchar(max) = 'All'
		 , @userId uniqueidentifier = null

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

	-- 08/17/20 VL added customer filter
	DECLARE  @tCustomer as tCustomer    
	INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;  

/*SELECT STATEMENT*/
select	due_date,CUSTNAME,woentry.UNIQ_KEY,PART_NO,REVISION,PART_CLASS,PART_TYPE,DEPT_QTY.WONO,dept_qty.DEPT_ID,DEPT_NAME,CURR_QTY,depts.NUMBER
from	DEPT_QTY
		inner join WOENTRY on dept_qty.WONO = WOENTRY.WONO
		inner join CUSTOMER on WOENTRY.custno = customer.CUSTNO
		inner join inventor on woentry.UNIQ_KEY = inventor.UNIQ_KEY
		inner join DEPTS on depts.DEPT_ID = dept_qty.DEPT_ID
where	woentry.OPENCLOS not in ('Closed','Cancel','ARCHIVED')
		and CURR_QTY <> 0.00
		AND 1 = CASE WHEN depts.DEPT_ID IN(SELECT DEPT_ID FROM @Depts) THEN 1 ELSE 0 END
		-- 08/17/20 VL added customer filter
		AND EXISTS (SELECT 1 FROM @tCustomer T WHERE T.Custno = Customer.Custno)
Order by depts.NUMBER,DUE_DATE,dept_qty.WONO,PART_NO,revision
end		