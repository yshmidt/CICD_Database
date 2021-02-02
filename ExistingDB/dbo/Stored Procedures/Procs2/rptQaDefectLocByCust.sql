

	-- =============================================
	-- Author:			Debbie
	-- Create date:		05/01/2014
	-- Description:		Compiles the details for the Defect Location Report by Customer by Assembly
	-- Used On:			qaloc
	-- Modifications:	03/01/04 VL added Wono per EMI's request -- they need to use this field in XLS file. Also added Revision
	--					06/05/2014 DRP:  found that I forgot to added the date filter to the Where section. 
	--					01/06/2015 DRP:  Added @customerStatus Filter
	-- =============================================
	CREATE PROCEDURE  [dbo].[rptQaDefectLocByCust]


	@lcCustNo as varchar(max) = 'All'
	,@lcDateStart as smalldatetime = null
	,@lcDateEnd as smalldatetime = null
	,@lcDeptId as varchar(max) = 'All'
	,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
	,@userId uniqueidentifier= null

as
begin

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
SELECT	Customer.CustName,Inventor.Part_no,Inventor.Revision,Qadef.DefDate,Qadefloc.Def_code,Support.Text3 AS Def_desc,
 		Qadefloc.LocQty,Qadefloc.Location,Depts.Dept_name,Qadef.Wono,Depts.Number 

FROM	Customer, Inventor, Qadef, Support, Qadefloc, Woentry, Depts 

WHERE	Customer.Custno = Woentry.Custno 
		AND Woentry.Uniq_key = Inventor.Uniq_key 
		AND Woentry.Wono = Qadef.Wono 
		AND Qadef.Locseqno = Qadefloc.Locseqno 
		AND Qadefloc.Def_code = LEFT(Support.Text2,10) 
		AND Support.Fieldname = 'DEF_CODE' 
		AND Qadefloc.ChgDept_id = Depts.Dept_id 
		and 1= case WHEN woentry.custNO IN (SELECT custno FROM @CUSTOMER) THEN 1 ELSE 0  END 
		AND 1 = CASE WHEN QADEFLOC.CHGDEPT_ID IN(SELECT DEPT_ID FROM @Depts) THEN 1 ELSE 0 END
		aND DEFDATE >= @lcDateStart AND DEFDATE < dateadd(day,1,@lcDateEnd ) /*06/05/2014 DRP:  added*/


ORDER BY CustName, Depts.Number, Part_no, Revision, Def_code 
	
end