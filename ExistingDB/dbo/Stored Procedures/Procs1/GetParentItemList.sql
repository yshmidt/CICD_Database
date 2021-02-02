-- =============================================  
-- Author:  Sachin B  
-- Create date: 01/02/2019   
-- Description: This SP is used for get Child all Parent List
-- GetParentItemList 112  
-- =============================================  
CREATE PROCEDURE [dbo].[GetParentItemList]  
@childId int 

AS  
SET NOCOUNT ON;  

BEGIN  

	;WITH name_tree AS 
	(
	   SELECT ChildId, parentid,m.IsPermission
	   FROM MnxModuleRelationship c
	   INNER JOIN MnxModule m ON c.ChildId =m.ModuleId
	   WHERE ChildId = @childId -- this is the starting point you want in your recursion
	  UNION ALL
	   SELECT C.ChildId, C.parentid,m.IsPermission
	   FROM MnxModuleRelationship c
	   INNER JOIN MnxModule m ON c.ChildId =m.ModuleId
	   INNER JOIN name_tree p ON C.ChildId = P.parentid  -- this is the recursion

		AND C.ChildId<>C.parentid 
	) 
	-- Here you can insert directly to a temp table without CREATE TABLE synthax
	SELECT ChildId AS 'ModuleId',ParentId,IsPermission
	INTO #TEMP
	FROM name_tree
	OPTION (MAXRECURSION 0)

	SELECT * FROM #TEMP

END 