-- =============================================
-- Author:		David Sharp
-- Create date: 5/15/2013
-- Description:	get settings for provided table
-- 07/22/13 YS per David listType and listValues are not used, replace with sourceLink and paramType to use the same method as with report parameters
-- 11/11/13 DS Added showBoth to allow more control over the results (default is 1 to permit it to function like it did prior to the change)
-- 01/20/15 DS Added code to handle split settings tables (commented out until it is ready)
-- 05/08/17 YS changed settingType for passwords to be 'password' . Camouflage pasword on the screen with '****'
-- =============================================
CREATE PROCEDURE [dbo].[settingsGetValues] 
	-- Add the parameters for the stored procedure here
	@moduleId int,
	@pivotResults bit = 1,
	@showBoth bit = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    IF @pivotResults = 1
    BEGIN
		-- 05/08/17 YS changed settingType for passwords to be 'password' . Camouflage pasword on the screen with '****'
		DECLARE @SQL nvarchar(MAX), @colList varchar(MAX),@colNames varchar(MAX),@isTable bit    
		SET @SQL = 'SELECT @colList = COALESCE(@colList+'','','''')+ ''CAST('' + settingName +'' AS '' + case when settingType=''password'' then ''varchar(max)'' else
		settingType end + '')'' + settingName FROM mnxSettingsManagement WHERE moduleId= ' + CAST(@moduleId AS varchar(MAX)) + ''
		exec sp_executesql @SQL, N'@colList varchar(MAX) out' ,@colList out
		SET @SQL = 'SELECT @colNames = COALESCE(@colNames+'','','''')+settingName FROM mnxSettingsManagement WHERE moduleId= ' + CAST(@moduleId AS varchar(MAX)) + ''
		exec sp_executesql @SQL, N'@colNames varchar(MAX) out' ,@colNames out
		
		--04/08/15 YS time to activate 'TODO:'
		--SET @SQL = 'SELECT ' + @colList + ' FROM(SELECT settingName, settingValue FROM mnxSettingsManagement WHERE moduleId= ' + CAST(@moduleId AS varchar(MAX)) + ')a PIVOT(MAX(settingValue)FOR settingName IN ('+ @colNames +'))AS PT'
		/* TODO: use this once the table is split */
		--SET @SQL = 'SELECT ' + @colList + ' FROM(SELECT s.settingName, COALESCE(w.settingValue,s.settingValue) settingValue FROM mnxsettingsmanagement s INNER JOIN wmsettingsmanagement w ON s.settingid = w.settingid WHERE s.moduleId= ' + CAST(@moduleId AS varchar(MAX)) + ')a PIVOT(MAX(settingValue)FOR settingName IN ('+ @colNames +'))AS PT'	
		--04/08/15 YS use left outer join
		SET @SQL = 'SELECT ' + @colList + ' FROM(SELECT s.settingName, COALESCE(w.settingValue,s.settingValue) settingValue FROM mnxsettingsmanagement s LEFT OUTER JOIN wmsettingsmanagement w ON s.settingid = w.settingid WHERE s.moduleId= ' + CAST(@moduleId AS varchar(MAX)) + ')a PIVOT(MAX(settingValue)FOR settingName IN ('+ @colNames +'))AS PT'	
		
		exec sp_executesql @SQL

		-- 07/22/13 YS per David listType and listValues are not used, replace with sourceLink and paramType to use the same method as with report parameters
		--SELECT settingName,settingValue,settingType,settingDescription,listType,listValues FROM MnxSettingsManagement WHERE moduleId= @moduleId
		--SELECT settingName,settingValue,settingType,settingDescription,sourceLink,paramType FROM MnxSettingsManagement WHERE moduleId= @moduleId
	END
	IF @showBoth = 1
	-- 07/22/13 YS per David listType and listValues are not used, replace with sourceLink and paramType to use the same method as with report parameters
		--SELECT settingName,settingValue,settingType,settingDescription,listType,listValues FROM MnxSettingsManagement WHERE moduleId= @moduleId
		--SELECT settingName,settingValue,settingType,settingDescription,sourceLink,paramType FROM MnxSettingsManagement WHERE moduleId= @moduleId
		/* TODO: use this once the table is split */
		--SELECT s.settingName, COALESCE(w.settingValue,s.settingValue) settingValue, s.settingType, s.settingDescription, s.sourceLink, s.paramType
		--	FROM mnxsettingsmanagement s INNER JOIN wmsettingsmanagement w ON s.settingid = w.settingid
		--	 WHERE moduleId= @moduleId
		--04/08/15 YS use left outer join
		SELECT s.settingName, COALESCE(w.settingValue,s.settingValue) settingValue, s.settingType, s.settingDescription, s.sourceLink, s.paramType
			FROM mnxsettingsmanagement s LEFT OUTER JOIN wmsettingsmanagement w ON s.settingid = w.settingid
			 WHERE s.moduleId= @moduleId
END