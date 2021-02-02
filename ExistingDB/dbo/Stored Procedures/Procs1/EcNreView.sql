CREATE PROC [dbo].[EcNreView] @gUniqEcNo AS char(10) = ' '
AS
--07/17/18 YS tools an fixtures moved from support
SELECT UniqNreno, UniqEcno, Ecnre.ToolsAndFixtureId, Costamt, Chargeamt, Effectivedt, Terminatdt, ToolsAndFixtures.Description,
	Ecnre.Dept_id, ISNULL(Depts.Dept_name, SPACE(25)) AS Dept_name
	FROM ToolsAndFixtures, Ecnre LEFT OUTER JOIN Depts
	ON Ecnre.Dept_id = Depts.Dept_id
	WHERE Ecnre.ToolsAndFixtureId = ToolsAndFixtures.ToolsAndFixtureId
	AND Ecnre.Uniqecno = @gUniqecno




