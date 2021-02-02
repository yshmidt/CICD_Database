-- =============================================  
-- Author:  <Shrikant B> 
-- Create date: <01/07/2019>  
-- Description: Get module list based on child selected 
-- GetParentModuleList 1151 
-- =============================================  
CREATE PROCEDURE [dbo].GetParentModuleList  
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
   JOIN cte p ON mr.ChildId =  p.ParentId
) 
SELECT *, level  FROM cte; 
END  