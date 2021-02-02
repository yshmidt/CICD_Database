CREATE PROC [dbo].[ToolingView] @gUniq_key AS char(10) = ''
--06/13/18 YS probably no one can use it now, will comment the code for now.
AS

SELECT ToolsAndFixtures.Description, Depts.Dept_name, ToolsAndFixtures.location, 
--Tooling.Expiredate, 
Tooling.Toolid, 
		Tooling.Uniq_key, Tooling.Dept_id, Tooling.TOOLID
	FROM Tooling inner join Depts on Tooling.Dept_id = Depts.Dept_id
	inner join ToolsAndFixtures on TOOLING.ToolsAndFixtureId=ToolsAndFixtures.ToolsAndFixtureId
	WHERE Tooling.Uniq_key = @gUniq_key
	ORDER BY Depts.Dept_name