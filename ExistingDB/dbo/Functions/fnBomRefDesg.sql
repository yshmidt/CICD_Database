-- =============================================
-- Author:		Debbie Peltier
-- Create date: 08/08/2012
-- Description:	<Gathering Reference Designators for the Bill of Material Reports>
-- 03/11/14 YS order by NBR
-- =============================================
CREATE FUNCTION [dbo].[fnBomRefDesg]
( 
    @lcUniqBomNo char (10)
) 
RETURNS varchar(max) 
AS 
BEGIN 
    declare	@output varchar(max) 
	select	@output = rtrim(coalesce (@output + ', ','') + RTRIM(bom_ref.REF_DES)) 
	from	BOM_REF 
	where	uniqbomno = @lcUniqBomNo 
	order by BOM_REF.NBR  
    return @output 
END 

