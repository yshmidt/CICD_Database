-- =============================================    
-- Author:  Sachin B    
-- Create date: 11/23/2018    
-- Description: This function is Used for Get Assembly Linked templates   
-- [GetAssemblyLinkedTemplates] '_1LR0NALBN'      
-- =============================================    
CREATE PROCEDURE [dbo].[GetAssemblyLinkedTemplates]    
    
@lcUniqkey char(10) ='',
@userId UNIQUEIDENTIFIER  
  
AS    
BEGIN    
    
SET NOCOUNT ON;    
    
 SELECT TemplateName Value ,UniqueRout [Key] FROM RoutingTemplate rt  
 INNER JOIN routingProductSetup rps ON rt.TemplateID =rps.TemplateID  
 WHERE rps.Uniq_key =@lcUniqkey AND rt.TemplateType ='Regular'   
 ORDER BY rps.isDefault DESC  
       
END 