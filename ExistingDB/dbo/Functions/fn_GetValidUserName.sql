
CREATE FUNCTION [dbo].[fn_GetValidUserName] (@cid char(10))
	RETURNS varchar(50) AS
BEGIN 
DECLARE @username varchar(50);
SELECT  @username=REPLACE(CONCAT(LEFT(FIRSTNAME, 4),LEFT(MIDNAME, 1),LEFT(LASTNAME, 5)),' ','') from CCONTACT WHERE CID=@cid

WHILE (SELECT count(1) from aspnet_Users where UserName=@username)>0
BEGIN
   SET @username=@username+'1';
END
 RETURN @username
END