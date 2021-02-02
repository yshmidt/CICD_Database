
-- =============================================
-- Author:		Shripati U
-- Create date: 05/27/2016
-- Description:	Get module parent list by ChildId
-- =============================================
CREATE FUNCTION [dbo].[GetModuleByChildId](
	-- Add the parameters for the stored procedure here
	@childId as Int,
	@parentId as Int)
  RETURNS NVARCHAR(MAX)
AS
begin
declare @return nvarchar(MAX);
declare @modules TABLE(ModuleName VARCHAR(MAX));
 WITH items AS (      
    SELECT relationship.ParentId ,relationship.ChildId  ,module.ModuleName, module.FileType 
    FROM MnxModuleRelationship relationship join MnxModule module on module.ModuleId = relationship.ParentId    
    WHERE  ChildId = @childId AND ParentId=@parentId
    UNION ALL    
    SELECT i.ParentId,i.ChildId  ,module.ModuleName, module.FileType
    FROM MnxModuleRelationship i    join MnxModule module on module.ModuleId = i.ParentId  
    INNER JOIN items itms ON itms.ParentId = i.ChildId 
)      
INSERT INTO @modules SELECT ModuleName FROM items ORDER BY ParentId
SELECT DISTINCT @return= STUFF((SELECT '> ', b.ModuleName as [text()]
         FROM @modules b
           FOR XML PATH ('')), 1, 5, '')


		   RETURN @return
END



