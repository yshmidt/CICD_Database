-- =============================================
-- Author:		Debbie Peltier
-- Create date: 08/08/2012
-- Description:	<Gathering Requestor, WO Alloc aor Prj Alloc from PO item schedules for Reference information on the GL Xtabbed Reports>
-- =============================================
create FUNCTION [dbo].[fnGlXtabRef]
( 
    @lcUniqApHead char (10)
) 
RETURNS varchar(max) 
AS 
BEGIN 
    declare	@output varchar(max) 
	select	@output = rtrim(coalesce (@output + ', ','') + RTRIM(poitschd.requesttp)+': '+case when poitschd.requesttp = 'MRO' then rtrim(POITSCHD.REQUESTOR) 
			else RTRIM(poitschd.WOPRJNUMBER)end) 
	from	poitschd 
	where	uniqdetno in (SELECT uniqdetno from  SINVDETL where SINV_UNIQ in (SELECT sinvoice.SINV_UNIQ  from SINVOICE where sinvoice.fk_uniqaphead =@lcUniqApHead))
			and poitschd.REQUESTTP <> 'Invt Recv'
  
    return @output 
END 
