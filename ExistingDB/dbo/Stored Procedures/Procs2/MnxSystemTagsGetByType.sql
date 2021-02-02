-- =============================================
-- Author:		David Sharp
-- Create date: 11/9/2012
-- Description:	get tags by type
--- 12/04/15 YS added wmReportTags table, for user to assign a different tag to a report
-- =============================================
CREATE PROCEDURE [dbo].[MnxSystemTagsGetByType] 
	-- Add the parameters for the stored procedure here
	@tagType varchar(20) = 'All' ,
	@userId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
    /* Determine if the user is an Admin */
    DECLARE @coAdmin bit,@actAdmin bit,@prodAdmin bit
    SELECT @coAdmin=CompanyAdmin,@actAdmin=AcctAdmin,@prodAdmin=ProdAdmin FROM aspnet_Profile WHERE UserId=@userId
    
    /* Get a list of Tags the user has permission to access */
    DECLARE @RoleTags TABLE (sTagId char(10),tagName varchar(100))
    INSERT INTO @RoleTags(sTagId,tagName)
    /* Get a list of Tags assigned to the user by Group */
    SELECT st.fksTagId,t.tagName FROM aspmnx_roleSystemTags st INNER JOIN MnxSystemTags t ON t.sTagId=st.fksTagId
		WHERE fkRoleId IN(SELECT r.RoleId FROM aspnet_Roles r INNER JOIN aspmnx_GroupRoles g ON r.RoleId=g.fkRoleId INNER JOIN aspmnx_groupUsers u ON g.fkGroupId=u.fkgroupid WHERE u.fkuserid=@userId)
    /* Get a list of Tags assigned to the user by CompAdmin */
    UNION
    SELECT sTagId,tagName FROM MnxSystemTags WHERE  compAdmin=case when @coAdmin=1 THEN 1 ELSE 2 END
    UNION
    SELECT sTagId,tagName FROM MnxSystemTags WHERE AccountAdmin=case when @actAdmin=1 THEN 1 ELSE 2 END
    UNION
    SELECT sTagId,tagName FROM MnxSystemTags WHERE ProdAdmin=case when @prodAdmin=1 THEN 1 ELSE 2 END
    
    
	IF @tagType = 'All'
	BEGIN
		SELECT sTagId,tagName FROM @RoleTags
	END
	ELSE IF @tagType='Reports'
	BEGIN
		SELECT DISTINCT rt.fksTagId,t.tagName 
			FROM 
			--- 12/04/15 YS added wmReportTags table, for user to assign a different tag to a report
			--MnxReportTags rt 
			(SELECT FKStAGiD,rptId from MnxReportTags 
			 UNION 
			SELECT FKStAGiD,rptid from wmReportTags ) rt
			INNER JOIN @RoleTags t ON rt.fksTagId=t.sTagId INNER JOIN MnxReports r ON rt.rptId=r.rptId WHERE display=1 
		UNION
		SELECT DISTINCT rt.fksTagId,t.tagName 
			FROM 
			--- 12/04/15 YS added wmReportTags table, for user to assign a different tag to a report
			--MnxReportTags rt 
			(SELECT FKStAGiD,rptid from MnxReportTags 
			 UNION 
			SELECT FKStAGiD,rptid from wmReportTags ) rt 
			INNER JOIN @RoleTags t ON rt.fksTagId=t.sTagId INNER JOIN wmReportsCust r ON rt.rptId=r.rptId WHERE display=1-- ORDER BY t.tagName
		ORDER BY t.tagName
	END
	-- 10/04/13 DS Removed since we consolidated quickviews and reports.
	--ELSE IF @tagType='QuickView'
	--BEGIN
	--	SELECT qt.fksTagId,t.tagName FROM quickViewTags qt INNER JOIN @RoleTags t ON qt.fksTagId=t.sTagId
	--END
END
--SELECT * from MnxSystemTags
--SELECT DISTINCT SUBSTRING(RoleName,0,COALESCE(CHARINDEX('_',RoleName,0),LEN(RoleName))) FROM aspnet_Roles WHERE CHARINDEX('_',RoleName,0)<>0