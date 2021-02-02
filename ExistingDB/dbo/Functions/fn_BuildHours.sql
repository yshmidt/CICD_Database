-- =============================================
-- Author:		<Debbie>
-- Create date: <04/25/2012>
-- Description:	<Teturn the hours for building wono>
-- Reports:		<wipdell3.rpt//wipdel_l.rpt//wipdel_w.rpt//wip_l3.rpt//wip_l2.rpt//wip_w2.rpt>
-- Modified:	02/16/17 DRP:  found that <<numeric (7,5)>> was causing numeric overflow issues on some of our users datasets, changed to <<numeric (11,5)>>
-- =============================================
CREATE FUNCTION [dbo].[fn_BuildHours] 
(	
	-- Add the parameters for the function here
	@lcUniqKey as char (10) = ''

)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
--select	cast(SUM(runtimesec)/3600 as numeric (7,5)) as RunTime, cast (SUM(setupSec)/3600 as numeric (7,5)) as SetupTime	--02/16/17 DRP:  replaced with below
select	cast(SUM(runtimesec)/3600 as numeric (11,5)) as RunTime, cast (SUM(setupSec)/3600 as numeric (11,5)) as SetupTime
from	QUOTDEPT
where	quotdept.UNIQ_KEY = @lcUniqkey

	
)