
-- =============================================
-- Author:		Debbie
-- Create date: 04/25/2012
-- Description:	This Stored Procedure was created for the Work Order Summary reports
-- Reports Using Stored Procedure:  wobydudt.rpt//wobyso.rpt//wobycu.rpt
-- =============================================

create PROCEDURE [dbo].[rptWipSummary]

		
		
as
begin

select	woentry.WONO,due_date,Woentry.OPENCLOS,CUSTNAME,woentry.UNIQ_KEY,PART_NO,REVISION,inventor.PROD_ID,PART_CLASS,PART_TYPE,kit,sono,bldqty, BLDQTY-COMPLETE as BalQty
		,case when(BLDQTY-COMPLETE)-(dbo.fn_buildable(WOENTRY.wono))< 0.00 then 0.00 else(BLDQTY-COMPLETE)-(dbo.fn_buildable(WOENTRY.wono))end  as Buildable
from	WOENTRY
		inner join customer on woentry.CUSTNO = customer.CUSTNO
		inner join INVENTOR on woentry.UNIQ_KEY = inventor.UNIQ_KEY


where	woentry.OPENCLOS not in ('Closed','Cancel','ARCHIVED')
		
end