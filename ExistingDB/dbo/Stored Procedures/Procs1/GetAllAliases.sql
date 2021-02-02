
CREATE  PROCEDURE [dbo].GetAllAliases   
  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  SELECT Alias,partMfg as AliasFor,mfgAliasId as Id from importBOMAVLAliases order by partMfg
   
END
