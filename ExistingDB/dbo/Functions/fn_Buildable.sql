-- =============================================
-- Author:		Debbie
-- Create date: 04/20/2012
-- Description:	Function to return the buildable qty for wono (used in the WIP Report for Shopflwo, WO Screens)
-- Reports:		wipdell3.rpt//wipdel_l.rpt//wipdel_w.rpt//wip_l3.rpt//wip_l2.rpt//wip_w2.rpt
-- =============================================

create FUNCTION [dbo].[fn_Buildable]

(
		@lcWono char(10)
) 
returns numeric(10)

as
begin

DECLARE @output char(10)

select @output = MAX(CEILING(shortqty/case when qty>0 then Qty else 1 end))
from KAMAIN
where WONO = @lcWono
group by wono

return isnull(@output,0.00)
end