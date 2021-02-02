-- =============================================
-- Author:		Debbie Peltier
-- Create date: 02/21/2012
-- Description:	<Gathering Sales Reps per Sales Order>
-- Modified:	11/02/2012 DRP:  The Invoice was repeating the Sales Rep for as many times as it was associated to line items on the order.  
--								 Added the group by CID to the function below.
-- =============================================
CREATE FUNCTION [dbo].[fnSoRep]
( 
    @lcSono char (10)
) 
RETURNS varchar(max) 
AS 
BEGIN 
    declare @output varchar(max) 
    select @output = rtrim(COALESCE(@output + ', ', '') + cid )
    from SOPRSREP 
    where sono = @lcSono 
    group by CID
 
    return @output 
END 

