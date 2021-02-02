
-- =============================================
-- Author:			<Debbie>
-- Create date:		<07/31/2014>
-- Description:		<Compiles the DPMO by Employee>
-- Used On:			QADPMOEM
-- Modifications:	08/01/2014 DRP:  Changed the filter to go off of the userid instead of the left(qainsp.INSPBY,3)
--					09/22/2014 DRP:  in the situation that the divisor was 0.00, change:
--					ROUND(SUM(Qty)*1000000/SUM(Inspqty*PartPerUnt),3) as DPMO to ROUND(SUM(Qty)*1000000/nullif(SUM(Inspqty*PartPerUnt),0),3) as DPMO 
--05/23/17 YS Penang data had qainsp.INSPBY that is more than 8 characters
-- =============================================
CREATE PROCEDURE [dbo].[rptQaDpmoByEmployee]

	@lcDateStart as smalldatetime = null
	,@lcDateEnd as smalldatetime = null
	,@lcDeptId as varchar(max) = 'All'
	,@lcUser as varchar (max) = 'All'
	,@userId uniqueidentifier= null
	
as
begin

/*DEPARTMENT LIST*/		
	DECLARE  @tDepts as tDepts
		DECLARE @Depts TABLE (dept_id char(4))
		-- get list of Departments for @userid with access
		INSERT INTO @tDepts (Dept_id,Dept_name,[Number]) EXEC DeptsView @userid ;

		IF @lcDeptId is not null and @lcDeptId <>'' and @lcDeptId<>'All'
			insert into @Depts select * from dbo.[fn_simpleVarcharlistToTable](@lcDeptId,',')
					where CAST (id as CHAR(4)) in (select Dept_id from @tDepts)
		ELSE

		IF  @lcDeptId='All'	
		BEGIN
			INSERT INTO @Depts SELECT Dept_id FROM @tDepts
		END
	
/*USER LIST*/
--05/23/17 YS Penang data had qainsp.INSPBY that is more than 8 characters
	DECLARE @Users table (UserId char(8))
	
	if (@lcUser is not null and @lcUser <> '' and @lcUser <>'All')
		insert into @Users select * from dbo.[fn_simpleVarcharlistToTable](@lcUser,',') 	
	else
	if @lcUser = 'All'
	Begin
		--05/23/17 YS Penang data had qainsp.INSPBY that is more than 8 characters
		insert into @Users select DISTINCT left(qainsp.INSPBY,8) from QAINSP --08/01/2014 DRP:  changed this to pull from the qainsp instead of the user table, just so you get users that actually processed QA instead of all.
	end
	--select * from @Users

/*BEGINNING OF SELECT STATEMENT*/
;
with 
ztemp1 as (
		/*Select all inspections for all customers with defects*/
		--05/23/17 YS modified SQL
		SELECT	Qainsp.Wono,Qadefloc.Locqty AS QTY,Qainsp.Inspqty,Qainsp.Date
				,Qainsp.Qaseqmain, Qadefloc.ChgDept_id AS Dept_id,USERS.UserID, rtrim(USERS.Name)+', '+rtrim(users.FIRSTNAME) as Name, users.Initials
		FROM	Qadef INNER JOIN Qainsp on Qadef.Qaseqmain = Qainsp.Qaseqmain
				inner join QadefLoc on Qadefloc.LocSeqNo=Qadef.LocSeqNo
				INNER JOIN USERS ON qainsp.INSPBY = users.userid
		WHERE	Qainsp.Inspqty <> 0 
				AND INSPBY IN (SELECT userid FROM @Users) 
				aND [DATE] >= @lcDateStart AND [DATE] < dateadd(day,1,@lcDateEnd )
				and ChgDept_id IN (SELECT DEPT_ID FROM @Depts) 

		union all
		/*Select all inspections for all customers without defects*/
		--05/23/17 YS modified SQL
		SELECT	Qainsp.Wono, cast (0 as numeric(4,0)) AS QTY, Qainsp.Inspqty,Qainsp.Date
				,Qainsp.Qaseqmain,Qainsp.Dept_id, Users.UserID, rtrim(USERS.Name)+', '+rtrim(users.FIRSTNAME) as Name, Users.Initials 
		FROM	Qainsp left outer join Users on qainsp.INSPBY = users.USERID  
		WHERE	Qainsp.Inspqty <> 0
				aND [DATE] >= @lcDateStart AND [DATE] < dateadd(day,1,@lcDateEnd ) 
				and QAINSP.QASEQMAIN not IN (SELECT QASEQMAIN from QADEFLOC)
				AND QAinsp.INSPBY IN (SELECT userid FROM @Users) 
				and qainsp.Dept_id IN (SELECT DEPT_ID FROM @Depts)  
		)

,
ztemp7 as (
		SELECT	WOENTRY.WONO,Qty,CASE WHEN ROW_NUMBER() OVER(Partition by qaseqmain Order by date)=1 Then InspQty ELSE CAST(0 as Numeric(12)) END AS InspQty
				,Date as [Date],Ztemp1.Dept_id,PartPerUnt, Qaseqmain, UserId, Name, Initials 
		FROM	Ztemp1,Woentry,Quotdept
		WHERE	Woentry.Wono=Ztemp1.Wono
				AND Quotdept.Uniq_key=Woentry.Uniq_key
				AND Quotdept.Dept_id=Ztemp1.Dept_id
				--AND PartPerUnt<>0
 
)
--select * from ztemp7

SELECT	 Name,SUM(Qty) AS DefectQty,SUM(Inspqty*PartPerUnt) AS Opportunities
		--,ROUND(SUM(Qty)*1000000/SUM(Inspqty*PartPerUnt),3) as DPMO --09/22/2014 DRP:  replaced by the below for situations wher divisor was 0.00 
		,ROUND(SUM(Qty)*1000000/nullif(SUM(Inspqty*PartPerUnt),0),3) as DPMO,UserId,Initials 
FROM	ZTemp7 
GROUP BY UserId, Name, Initials 
ORDER BY  Name, Initials  

end