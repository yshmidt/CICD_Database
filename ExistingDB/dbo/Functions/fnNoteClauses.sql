-- =============================================
-- Author:		Debbie Peltier
-- Create date: 03/02/2012
-- Description:	<Gathering multiple NoteClauses onto one line>
-- =============================================
create FUNCTION [dbo].[fnNoteClauses]
( 
    @lcTableUnique char (10)
) 
RETURNS varchar(max) 
AS 
BEGIN 
    declare @output varchar(max) 
    select @output = rtrim(COALESCE(@output + ', ', '') + NOTENAME )
    from NOTEASSIGN 
    inner join NOTESETUP on noteassign.FKNOTEUNIQUE = NOTESETUP.NOTEUNIQUE
    where TABLEUNIQUE = @lcTableUnique 
 
    return @output 
END 
