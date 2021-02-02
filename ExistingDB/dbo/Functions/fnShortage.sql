-- =============================================
-- Author:		Debbie Peltier
-- Create date: 09/24/2014
-- Description:	Gathers the Kit Shortage information originally created to work for the Open Po Detail by Supplier
-- =============================================
create FUNCTION [dbo].[fnShortage]
( 
    @lcUniqKey char (10) = ''
) 
RETURNS varchar(max) 
AS 
BEGIN 
    declare	@output varchar(max) 
	select	@output = rtrim(coalesce (@output + char(13)+CHAR(10),'') +'Prod No: ' + rtrim(inventor.Part_no) + ' Rev: '+ RTRIM(inventor.revision) 
				+ ' WO: '+ rtrim(kamain.WONO) + '  WC: ' + RTRIM(KAMAIN.DEPT_ID) + ' Qty Shrt: '+ RTRIM(kamain.SHORTQTY)) 
	from	kamain left outer join INVENTOR on kamain.bomparent = inventor.UNIQ_KEY
	where	kamain.UNIQ_KEY = @lcUniqKey	
    return @output 
END 