
-- =============================================
-- Author:		Debbie
-- Create date: 04/10/2012
-- Description:	This Stored Procedure was created for the Work Order Schedule & WIP Report by Customer
-- Reports Using Stored Procedure:  wipdell3.rpt//wipdel_l.rpt//wipdel_w.rpt//wip_l3.rpt//wip_l2.rpt//wip_w2.rpt
-- Modifications: 05/30/2014 DRP:  This procedure was created in order to work with WebManex QuickView only at this time. 
--				01/06/2015 DRP:  Added @customerStatus Filter --11/18/15 DRP:  removed and manually populated it within the selection statement that calls for it. 
--				08/14/15 YS/DRP:  changed Wono/Sono to be WoNum/SoNum, it was found if the user happend to also name Dept_ID with Sono/Wono that it would break the pivot table.
--				11/18/15 DRP:	  Added the @userId, /*CUSTOMER LIST*/.  Added @lcIsReport so I could use that to display the QuickView Results or Report results.  
--				They have to be different because we can not predict how many Depts they have setup within the system.
--				04/05/16 DRP:	was informed that the customer parameter selection was not working properly.  Needed to change the filter below to select from the @Customer instead of @TCustomer.  
-- 07/10/19 VL fixed if the dept_id has special character like '&' it didn't work right for the dept_id column name
-- 09/14/20 VL Added priority column of production scheduling, CAPA 3050, data type tWip was changed to add Priority numeric(7,3) column
-- 09/29/20 VL Added JobType column, CAPA 3105, data type tWip was changed to add JobType char(10)
-- =============================================

CREATE PROCEDURE [dbo].[rptWipWM]
--declare
		@lcCustNo as varchar(max) = ''
		,@lcIsReport as char(3) = 'Yes'		--11/18/15 DRP:  added so I could call results for either QuickView or Report form. Yes = report form results, No = QuickView Results
		,@userId uniqueidentifier= null
		
		

as
begin
		
/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	
		
		IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)
		ELSE

		IF  @lcCustNo='All'	
		BEGIN
			INSERT INTO @Customer SELECT CustNo FROM @tCustomer
		END

--select * from @Customer		

/*populating the @results with the system type tWip*/
declare @results as tWip

insert into @results
select	woentry.WONO,due_date,Woentry.OPENCLOS,CUSTNAME,woentry.UNIQ_KEY,PART_NO,REVISION,inventor.PROD_ID,PART_CLASS,PART_TYPE,kit,sono,bldqty, BLDQTY-COMPLETE as BalQty
		,case when(BLDQTY-COMPLETE)-(dbo.fn_buildable(WOENTRY.wono))< 0.00 then 0.00 else(BLDQTY-COMPLETE)-(dbo.fn_buildable(WOENTRY.wono))end  as Buildable,dept_qty.DEPT_ID
		,depts.NUMBER,dept_qty.CURR_QTY,R.runtime,R.setuptime
		-- 09/14/20 VL added Priority column of production scheduling
		,CASE COALESCE(NULLIF(prt.pri,0), 0)  
			WHEN 0 THEN COALESCE(NULLIF(pd.SLACKPRI,0), 0)    
			ELSE COALESCE(NULLIF(prt.pri,0), 0) END AS Priority
		-- 09/29/20 VL Added JobType column
		,Jobtype
from	WOENTRY
		inner join customer on woentry.CUSTNO = customer.CUSTNO
		inner join INVENTOR on woentry.UNIQ_KEY = inventor.UNIQ_KEY
		inner join DEPT_QTY on WOENTRY.WONO = dept_qty.wono
		inner join DEPTS on depts.DEPT_ID = dept_qty.DEPT_ID
		CROSS APPLY (SELECT *  from  dbo.fn_buildhours(woentry.uniq_key)) R
		-- 09/14/20 VL added Priority column of production scheduling
		LEFT JOIN PROD_DTS pd ON pd.WONO = WOENTRY.WONO    
		OUTER APPLY (SELECT TOP 1 DEPT_PRI AS pri FROM DEPT_QTY WHERE CURR_QTY > 0 AND WONO = WOENTRY.WONO ORDER BY NUMBER) prt    

where	woentry.OPENCLOS not in ('Closed','Cancel','ARCHIVED')
		--and 1 = case when Customer.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
		--and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=woentry.custno)	--04/05/16 DRP:  changed it to pull from the @customer instead of @TCustomer
		and exists (select 1 from @Customer t inner join customer c on t.custno=c.custno where c.custno=woentry.custno)
order by CUSTNAME,WONO,number
--select * from @results




/*STING FOR THE NAMES OF THE COLUMNS BASED ON THE DEPTID*/
DECLARE @DeptId nvarchar(max)
-- 07/10/19 VL fixed if the dept_id has special character like '&' it didn't work right for the dept_id column name
--SELECT @DeptId =
--  STUFF(
--  (
--    select ',[' + D.Dept_id  + ']'
--    from DEPTS D where DEPT_ID in (select dept_id from @results)  ORDER BY Number
--    for xml path('')  ),  1,1,'')
SELECT @DeptId =
 STUFF((select N',[' + D.Dept_id  + ']'
    from DEPTS D  where DEPT_ID in (select dept_id from @results)  ORDER BY Number
    for xml path, TYPE).value(N'.[1]',
 N'nvarchar(max)'), 1, 1, N'')
-- 07/10/19 VL End}
    
    
/*USE SQL TO ASSIGN DEPTID AS THE COLUMN NAMES WITHIN PIVOT TABLE*/
/*Please note:  that at this point in time it is only setup to work with Quick View only.  They way it is setup now it will not work with MRT designer.  If we need to created the MRT report later we can reference what we did on the rptArAgeDetailWM procedure*/
--08/14/15 YS/DRP:  changed Wono/Sono to be WoNum/SoNum, it was found if the user happend to also name Dept_ID with Sono/Wono that it would break the pivot table.  
DECLARE @SQL nvarchar(max)

if (@lcIsReport = 'No')
		Begin
			-- 09/29/20 VL Added Priority and Jobtype
			SELECT @SQL = N'
						SELECT * 
						FROM ( SELECT Wono as [WONUM],Due_Date,OpenClos,CustName,Uniq_key,part_no,revision,Prod_id ,Part_Class ,Part_type,Kit as IsKit,SONO as [SONUM],BldQty,BalQty ,Buildable,Dept_id 
								,Curr_Qty,RunTime,SetupTime,Priority,JobType 
								from @results
								group by WoNo,Due_Date,OpenClos,CustName,Uniq_key,part_no,revision,Prod_id ,Part_Class ,Part_type,Kit,SoNo,BldQty,BalQty ,Buildable,Dept_id 
								,Curr_Qty,RunTime,SetupTime,Priority,JobType
								)  tData  
						PIVOT (SUM(Curr_qty) FOR Dept_id in ('+@DeptID+')) tPivot'

						/*--sp_executesql procedure will take second parameter as User defined table type (UDTT) and we will pass @result table variable */
						exec sp_executesql @SQL,N'@results tWip READONLY',@results 
		End	--(@lcIsReport = 'No') 

else if (@lcIsReport = 'Yes')
		Begin
			select * from @results
		End

end