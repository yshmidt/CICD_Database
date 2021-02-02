-- =============================================
-- Author:		Debbie Peltier
-- Create date: 09/24/2014
-- Description:	Gathers the Bom Information (Where used) originally created to work for the Open Po Detail by Supplier
-- =============================================
create FUNCTION [dbo].[fnUsedOn]
( 
    @lcUniqKey char (10) = ''
) 
RETURNS varchar(max) 
AS 
BEGIN 
    declare	@output varchar(max) 
	select	@output = rtrim(coalesce (@output + char(13)+CHAR(10),'') +'Prod No: ' + rtrim(inventor.Part_no) + ' Rev: '+ RTRIM(inventor.revision) 
				+ ' Bom Item: '+ rtrim(bom_det.item_no) + '  WC: ' + RTRIM(bom_det.DEPT_ID) + ' Bom Qty Per: '+ RTRIM(bom_det.QTY)) 
	from	bom_det	left outer join INVENTOR on bom_Det.BOMPARENT = inventor.UNIQ_KEY
	where	bom_Det.uniq_key  = @lcUniqKey
	
    return @output 
END 