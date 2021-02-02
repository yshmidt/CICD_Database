
-- =============================================
-- Author:		Debbie
-- Create date: 05/11/2012
-- Description:	Created for Tranfer History Reprt for Selected Work Centers
-- Reports Using Stored Procedure:  trhistrp.rpt
-- Modified:  12/11/2014 DRP:  made needed changes so this procedur will work on the Web.
--			  12/16/2014 DRP:  needed to add the Customer List section below. 
--			  01/06/2015 DRP:  Added @customerStatus Filter
--			  01/18/2017 Sachin B:  Remove the Serial No column because transfer table now does not contain Serial No Column
-- =============================================

CREATE PROCEDURE [dbo].[rptSftTransHistoryWM]
--declare
		 @lcDateStart as smalldatetime= null
		,@lcDateEnd as smalldatetime = null
		,@lcDeptiD as VARchar(max) = 'All'		--12/11/2014 DRP:  changed this from varchar(4) to varchar(max)
		,@lcCustNo as varchar(max) = 'All'		--12/16/2014 DRP:  added for the Customer List 
		,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
		,@userId uniqueidentifier= null	--12/11/2014 DRP:  added the userId
		
as
begin

--12/11/2014 DRP:  added the Department List in order to work with the user Id and the parameters on the web. 
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

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,@customerStatus ;
		--SELECT * FROM @tCustomer	
		
		IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)
		ELSE

		IF  @lcCustNo='All'	
		BEGIN
			INSERT INTO @Customer SELECT CustNo FROM @tCustomer
		END


/*RECORD SELECTION SECTION*/	
	
--This section will gather the from information 
select	XFER_UNIQ,transfer.WONO,woentry.UNIQ_KEY,PART_NO,REVISION,PROD_ID,transfer.DATE,transfer.QTY,FR_DEPT_ID
		,case when FR_ACTVKEY = '' and TO_ACTVKEY = '' then frDept.DEPT_NAME 
			else case when fr_actvkey = '' and to_actvkey <> '' then frDept.dept_name 
				else case when fr_actvkey <> '' and to_Actvkey <> '' then FrActv.ACTIV_NAME 
					else case when FR_ACTVKEY <> '' and TO_ACTVKEY = '' then FrActv.ACTIV_NAME end end end end as FrName
		,case when FR_ACTVKEY = '' and TO_ACTVKEY = '' then CAST('' as CHAR(1))
			else case when fr_actvkey = '' and to_actvkey <> '' then CAST('' as CHAR(1))
				else case when fr_actvkey <> '' and to_Actvkey <> '' then CAST('A' as CHAR(1))
					else case when FR_ACTVKEY <> '' and TO_ACTVKEY = '' then CAST('A' as CHAR(1)) end end end end as FrActvInd
		,TO_DEPT_ID
		,case when FR_ACTVKEY = '' and TO_ACTVKEY = '' then todept.DEPT_NAME
			else case when FR_ACTVKEY = '' and TO_ACTVKEY <> '' then toActv.ACTIV_NAME
				else case when FR_ACTVKEY <> '' and TO_ACTVKEY = '' then todept.dept_name
					else case when FR_ACTVKEY <> '' and TO_ACTVKEY <> '' then ToActv.ACTIV_NAME 	end end end end as ToName
		,case when FR_ACTVKEY = '' and TO_ACTVKEY = '' then CAST('' as CHAR(1))
			else case when FR_ACTVKEY = '' and TO_ACTVKEY <> '' then CAST('A' as CHAR(1))
				else case when FR_ACTVKEY <> '' and TO_ACTVKEY = '' then CAST('' as CHAR(1))
					else case when FR_ACTVKEY <> '' and TO_ACTVKEY <> '' then CAST('A' as CHAR(1)) 	end end end end as ToActvInd
		,[By] AS XferBy
		-- 01/18/2017 Sachin B:  Remove the Serial No column because transfer table now does not contain Serial No Column
		--,cast(dbo.fremoveLeadingZeros(SERIALNO) as varchar(MAx)) as SerialNo

from		TRANSFER 
			left outer join DEPTS as FrDept on transfer.FR_DEPT_ID = FrDept.DEPT_ID
			left outer join DEPTS as ToDept on transfer.TO_DEPT_ID = ToDept.DEPT_ID
			left outer join QUOTDPDT as frQ  on transfer.FR_ACTVKEY = frQ.UNIQNBRA
			left outer join ACTIVITY as FrActv on FrActv.ACTIV_ID = frQ.ACTIV_ID
			LEFT OUTER JOIN QUOTDPDT AS ToQ on transfer.TO_ACTVKEY = ToQ.UNIQNBRA
			left outer join ACTIVITY as ToActv on ToActv.ACTIV_ID = Toq.ACTIV_ID
			inner join woentry on transfer.wono = woentry.wono
			inner join INVENTOR on woentry.UNIQ_KEY = inventor.UNIQ_KEY
			
where		TRANSFER.DATE>=@lcDateStart AND transfer.DATE<@lcDateEnd+1
			AND FR_DEPT_ID IN (SELECT Dept_id FROM @Depts) 
			and 1 = case when woentry.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end	--12/16/2014 DRP:  added




--this section will gather the to information
union
select	XFER_UNIQ,transfer.WONO,woentry.UNIQ_KEY,PART_NO,REVISION,PROD_ID,transfer.DATE,transfer.QTY,FR_DEPT_ID
		,case when FR_ACTVKEY = '' and TO_ACTVKEY = '' then frDept.DEPT_NAME 
			else case when fr_actvkey = '' and to_actvkey <> '' then frDept.dept_name 
				else case when fr_actvkey <> '' and to_Actvkey <> '' then FrActv.ACTIV_NAME 
					else case when FR_ACTVKEY <> '' and TO_ACTVKEY = '' then FrActv.ACTIV_NAME end end end end as FrName
		,case when FR_ACTVKEY = '' and TO_ACTVKEY = '' then CAST('' as CHAR(1))
			else case when fr_actvkey = '' and to_actvkey <> '' then CAST('' as CHAR(1))
				else case when fr_actvkey <> '' and to_Actvkey <> '' then CAST('A' as CHAR(1))
					else case when FR_ACTVKEY <> '' and TO_ACTVKEY = '' then CAST('A' as CHAR(1)) end end end end as FrActvInd
		,TO_DEPT_ID
		,case when FR_ACTVKEY = '' and TO_ACTVKEY = '' then todept.DEPT_NAME
			else case when FR_ACTVKEY = '' and TO_ACTVKEY <> '' then toActv.ACTIV_NAME
				else case when FR_ACTVKEY <> '' and TO_ACTVKEY = '' then todept.dept_name
					else case when FR_ACTVKEY <> '' and TO_ACTVKEY <> '' then ToActv.ACTIV_NAME 	end end end end as ToName
		,case when FR_ACTVKEY = '' and TO_ACTVKEY = '' then CAST('' as CHAR(1))
			else case when FR_ACTVKEY = '' and TO_ACTVKEY <> '' then CAST('A' as CHAR(1))
				else case when FR_ACTVKEY <> '' and TO_ACTVKEY = '' then CAST('' as CHAR(1))
					else case when FR_ACTVKEY <> '' and TO_ACTVKEY <> '' then CAST('A' as CHAR(1)) 	end end end end as ToActvInd
		,[By] AS XferBy
		-- 01/18/2017 Sachin B:  Remove the Serial No column because transfer table now does not contain Serial No Column
		--,cast(dbo.fremoveLeadingZeros(SERIALNO) as varchar(MAx)) as SerialNo

from		TRANSFER 
			left outer join DEPTS as FrDept on transfer.FR_DEPT_ID = FrDept.DEPT_ID
			left outer join DEPTS as ToDept on transfer.TO_DEPT_ID = ToDept.DEPT_ID
			left outer join QUOTDPDT as frQ  on transfer.FR_ACTVKEY = frQ.UNIQNBRA
			left outer join ACTIVITY as FrActv on FrActv.ACTIV_ID = frQ.ACTIV_ID
			LEFT OUTER JOIN QUOTDPDT AS ToQ on transfer.TO_ACTVKEY = ToQ.UNIQNBRA
			left outer join ACTIVITY as ToActv on ToActv.ACTIV_ID = Toq.ACTIV_ID
			inner join woentry on transfer.wono = woentry.wono
			inner join INVENTOR on woentry.UNIQ_KEY = inventor.UNIQ_KEY
where		TRANSFER.DATE>=@lcDateStart AND transfer.DATE<@lcDateEnd+1
			AND TO_DEPT_ID IN (SELECT Dept_id FROM @Depts)	
			and 1 = case when woentry.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end	--12/16/2014 DRP:  Added


order by date

end
		 

		