-- Author:Sachin B
-- Create date: 08/19/2019
-- Description:	 Get decrypted Value
-- SELECT [dbo].[fn_GetDecryptedValue] ('0x020000003E2FC5AF35A0CEFFA832389B205E894705C1DF3EAC7F82935D4EAEA951C23AFD30DC4607C0F406C2B1F2B655F69408D8A506A23383A7511E4474A132434D95D7')
-- =============================================  
CREATE FUNCTION [dbo].[fn_GetDecryptedValue]
(
  @Name  VARCHAR(MAX) 
)
RETURNS VARCHAR(MAX)  

AS
BEGIN
	DECLARE @Decrypt VARCHAR(MAX) 
	SET @Decrypt =  (SELECT  DecryptByPassPhrase('key',CONVERT(VARBINARY(MAX), @Name, 1))AS Decrypt) 
    RETURN  @Decrypt
END