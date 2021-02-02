-- =============================================
-- Author: Shivshankar Patil	
-- Create date: <05/23/19>
-- Description:	Get ISO Stanndard Data
-- =============================================
CREATE PROCEDURE [GetMnxISOProcesses] 

 AS
 BEGIN
      SET NOCOUNT ON;

	   SELECT CAST(child.isoNode AS nvarchar(100)) AS IsoNodes,
			  child.isoNode.GetLevel(),
			  CASE WHEN CAST(child.isoNode.GetAncestor(1) AS nvarchar(100)) <> '/' THEN CAST(child.isoNode.GetAncestor(1) AS nvarchar(100)) ELSE '' END AS ParentId
			 ,child.ReleventLink,child.ProcessName AS Name
	   FROM mnxISOProcesses as parents Inner Join mnxISOProcesses AS child ON child.isoNode.IsDescendantOf(parents.isoNode ) = 1
				   GROUP BY child.isoNode,child.ProcessName,child.ReleventLink
 END