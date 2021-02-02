
CREATE PROCEDURE [dbo].UpdateAlias   
  @alias NVARCHAR(MAX),
  @aliasFor NVARCHAR(8),
  @id int
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 SET NOCOUNT ON;  
  Update  importBOMAVLAliases set alias=@alias where partMfg=@aliasFor and mfgAliasId=@id
END