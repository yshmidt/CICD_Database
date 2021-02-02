-- =============================================  
-- Author:  <Shrikant B> 
-- Create date: <01/07/2019>  
-- Description: Get Sub module based on parent selected 
-- GetChildModuleList 63  
-- =============================================  
CREATE PROCEDURE [dbo].GetChildModuleList  
  @NodeId INT = ''  
AS  
BEGIN  

SET NOCOUNT ON;  
 ;WITH cte AS 
(
   SELECT * ,1 AS level
   FROM MnxModuleRelationship
   WHERE ChildId = @NodeId 
   UNION ALL
   SELECT mr.RelationshipId, mr.ParentId, mr.ChildId, mr.ModuleOrder, level +1
   FROM MnxModuleRelationship mr
   JOIN cte p ON p.ChildId = mr.ParentId  
) 

SELECT *, level  FROM cte  WHERE ChildId<>@NodeId ORDER BY cte.level, ModuleOrder ; 

END  