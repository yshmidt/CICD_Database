
-- =============================================
-- Author:		Debbie
-- Create date: 05/10/2012
-- Description:	This Stored Procedure was created for the Serial Number List by Work Centers Report
-- Reports:		serlwowc
-- Modified:	11/12/15 DRP:	added the @userId, /*CUSTOMER LIST*/, /*DEPARTMENT LIST*/ In order to work with the WebManex
-- =============================================

CREATE PROCEDURE [dbo].[rptSerialByWoWc]
--declare
		@lcWono as char (10) = ''
		,@lcDeptId as varchar(max) = 'All'
		,@userId uniqueidentifier = null
		
as
begin


/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'Active' ;
		--SELECT * FROM @tCustomer	

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

/*RECORD SELECTION SECTION*/		

--This section gathers serial number information within Work Centers and Activities that are not in FGI
select	dept_qty.WONO,woentry.bldqty,dept_qty.DEPT_ID,depts.DEPT_NAME,cast(dbo.fremoveLeadingZeros(SERIALNO) as varchar(MAx)) as SerialNo,dept_qty.NUMBER,invtser.ACTVKEY,dept_qty.DEPTKEY
		,ISNULL(ACTV_QTY.NUMBERA,0)AS NUMBERA,ISNULL(actv_qty.ACTIV_ID,'')ACTIV_ID,ISNULL(activity.ACTIV_NAME,'') AS ACTIV_NAME

from	dept_Qty
		INNER JOIN DEPTS ON DEPT_QTY.DEPT_ID = DEPTS.DEPT_ID
		INNER JOIN INVTSER ON DEPT_QTY.DEPTKEY = INVTSER.ID_VALUE AND DEPT_qTY.WONO = INVTSER.WONO
		left outer join ACTV_QTY on INVTSER.ACTVKEY = ACTV_qTY.ACTVKEY
		left outer join ACTIVITY on actv_qty.ACTIV_ID = activity.ACTIV_ID
		LEFT OUTER JOIN QUOTDPDT ON ACTV_QTY.ACTVKEY = QUOTDPDT.UNIQNBRA
		inner join WOENTRY on DEPT_qty.WONO = woentry.WONO

where	invtser.WONO <> ''
		and invtser.ID_KEY = 'DEPTKEY'
		and dept_qty.WONO = dbo.padl(@lcWoNo,10,'0')
		--and DEPTS.DEPT_id like case when @lcDeptId ='*' then '%' else @lcDeptId + '%' end	--11/12/15 DRP:  replaced with below
		and (@lcDeptId='All' OR exists (select 1 from @Depts d inner join Depts d2 on d.dept_id=d2.DEPT_ID where d.dept_id=depts.dept_id))
		and exists (select 1 from @tCustomer t inner join customer c on t.custno=c.custno where c.custno=woentry.custno)
	
union
--This section gathers the serial number information already moved to FGI
select	dept_qty.WONO,woentry.bldqty,dept_qty.DEPT_ID,depts.DEPT_NAME,cast(dbo.fremoveLeadingZeros(SERIALNO) as varchar(MAx)) as SerialNo,dept_qty.NUMBER,invtser.ACTVKEY,dept_qty.DEPTKEY
		,ISNULL(ACTV_QTY.NUMBERA,0),ISNULL(actv_qty.ACTIV_ID,'')ACTIV_ID,ISNULL(activity.ACTIV_NAME,'') AS ACTIV_NAME

from	dept_Qty
		inner join DEPTS on dept_qty.DEPT_ID = depts.DEPT_ID
		inner join INVTSER on dept_qty.wono = invtser.wono
		left outer join ACTV_QTY on INVTSER.ACTVKEY = ACTV_qTY.ACTVKEY
		left outer join ACTIVITY on actv_qty.ACTIV_ID = activity.ACTIV_ID
		LEFT OUTER JOIN QUOTDPDT ON ACTV_QTY.ACTVKEY = QUOTDPDT.UNIQNBRA
		inner join WOENTRY on DEPT_qty.WONO = woentry.WONO
	
where	invtser.ID_KEY = 'W_KEY'
		and dept_qty.DEPT_ID = 'FGI'
		and dept_qty.WONO = invtser.wono
		and invtser.WONO <> ''
		and dept_qty.WONO = dbo.padl(@lcWoNo,10,'0')
		--and DEPTS.DEPT_ID like case when @lcDeptId ='*' then '%' else @lcDeptId + '%' end	--11/12/15 DRP: replaced with below
		and (@lcDeptId='All' OR exists (select 1 from @Depts d inner join Depts d2 on d.dept_id=d2.DEPT_ID where d.dept_id=depts.dept_id))
		and exists (select 1 from @tCustomer t inner join customer c on t.custno=c.custno where c.custno=woentry.custno)
		 
order by NUMBER
end