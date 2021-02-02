
-- =============================================
-- Author:		Debbie
-- Create date: 04/25/2012
-- Description:	This Stored Procedure was created for the Backlog Report by Work Center report
-- Reports:		bklgwc.rpt
-- Modified:	11/02/2012 DRP:  I had to add the @lcDeptId parameter to the stored procedure
-- =============================================

CREATE PROCEDURE [dbo].[rptWcBackLog]

		@lcDeptId as char(4) = '*'

as
begin 
select	due_date,CUSTNAME,woentry.UNIQ_KEY,PART_NO,REVISION,PART_CLASS,PART_TYPE,DEPT_QTY.WONO,dept_qty.DEPT_ID,DEPT_NAME,CURR_QTY,depts.NUMBER,MICSSYS.LIC_NAME
		
from	DEPT_QTY
		inner join WOENTRY on dept_qty.WONO = WOENTRY.WONO
		inner join CUSTOMER on WOENTRY.custno = customer.CUSTNO
		inner join inventor on woentry.UNIQ_KEY = inventor.UNIQ_KEY
		inner join DEPTS on depts.DEPT_ID = dept_qty.DEPT_ID
		cross join MICSSYS

where	

		woentry.OPENCLOS not in ('Closed','Cancel','ARCHIVED')
		and CURR_QTY <> 0.00
		and DEPTS.DEPT_id like case when @lcDeptId ='*' then '%' else @lcDeptId + '%' end

		
Order by depts.NUMBER,DUE_DATE,dept_qty.WONO,PART_NO,revision
end		