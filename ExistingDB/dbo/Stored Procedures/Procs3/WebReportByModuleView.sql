-- @lcModule is from Items.ScreenName for module to retrieve web report names for this module
CREATE PROC [dbo].[WebReportByModuleView] @lcModule  AS char(8) = ' '
AS
BEGIN

DECLARE @lcTag varchar(50)=''

SELECT * 
	FROM MnxReports 
	WHERE rptId IN (
		SELECT rptId 
			FROM MnxReportTags
			WHERE fksTagId IN (
				SELECT sTagId 
					FROM MnxSystemTags 
					WHERE sTagId IN 
						(SELECT fksTagId 
							FROM aspmnx_RoleSystemTags
							WHERE fkRoleId IN 
								(SELECT RoleId 
									FROM aspnet_Roles
									WHERE RoleName = LTRIM(RTRIM(@lcModule))+'_Reports')))
							)
	AND display = 1
	ORDER BY Sequence
END