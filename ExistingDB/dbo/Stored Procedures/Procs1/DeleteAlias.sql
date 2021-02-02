
CREATE PROCEDURE [dbo].DeleteAlias   
  @alias NVARCHAR(MAX)=''
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  DELETE FROM importBOMAVLAliases where alias=@alias
   
END

