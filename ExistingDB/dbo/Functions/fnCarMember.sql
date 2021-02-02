-- =============================================
-- Author:		Debbie Peltier
-- Create date: 06/05/2017
-- Description:	<Gathering Team Members associated to Corrective Action>
-- Modified:	
-- =============================================
create FUNCTION [dbo].[fnCarMember]
( 
    @lcCarNo char (10)
) 
RETURNS varchar(max) 
AS 
BEGIN 
    declare @output varchar(max) 
    select @output = rtrim(COALESCE(@output + ', ', '') + CRMEMBER )
    from CRACTEAM 
    where tmcarno = @lcCarNo 
    group by CRMEMBER
 
    return @output 
END 
 
