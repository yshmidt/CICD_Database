-- =============================================
-- Author:		Vicky Lu
-- Create date: 01/21/2016
-- Description:	Get all the Part number, tooling information for passed in Tooling description, used in Routing
-- 06/13/18 YS structure of tooling is changed will check if we need it
--06/10/19 YS structure is changed had to add tooling. prior to description. Check with Sachin if in use
-- =============================================
CREATE PROCEDURE [dbo].[ToolingWhereUsedView] 
	-- Add the parameters for the stored procedure here
	@ToolDescr char(35)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- 06/13/18 YS structure of tooling is changed will check if we need it
	SELECT Part_no, Revision, Depts.Dept_Name, Tooling.[description], location
	--, Expiredate 
	FROM Inventor, Tooling LEFT OUTER JOIN Depts
	ON Tooling.Dept_id = Depts.Dept_id
	inner join ToolsAndFixtures on tooling.ToolsAndFixtureId=ToolsAndFixtures.ToolsAndFixtureId
	WHERE Tooling.Uniq_key = Inventor.Uniq_key 
	AND ToolsAndFixtures.description = @ToolDescr
	ORDER BY Part_no, Revision

END	