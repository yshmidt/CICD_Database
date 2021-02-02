
-- Author:Sachin B
-- Create date: 08/19/2019
-- Description:	 Get encrypted data value
-- SELECT [dbo].[fn_GetEncryptedValue] ('http://mx.manex.com/ManexISO/')
-- =============================================  
CREATE FUNCTION [dbo].[fn_GetEncryptedValue]
(
	@Name  VARCHAR(MAX)
)

RETURNS VARBINARY(MAX)
AS
BEGIN
	DECLARE @encrypt VARBINARY(MAX) 
	SET @encrypt = (SELECT CONVERT(VARBINARY(MAX), EncryptByPassPhrase('key', CONVERT(VARCHAR(MAX), @Name, 1))))
	RETURN @encrypt
END
