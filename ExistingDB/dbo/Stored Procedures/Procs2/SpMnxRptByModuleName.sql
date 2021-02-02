-- =============================================
-- Author:Nilesh Sa
-- Create Date: 28/4/2016
-- Description:	Get Report Details Module Wise
-- Example: [SpMnxRptByModuleName] 'Warehouse Management System (WMS)','2EE8060A-56A2-40FC-9F74-4D7567785F9A'
-- Modified By - Vijay G. (03/10/2017) : To get all reports order by on the basis of sequence value.
-- Modified By - Vijay G. (08/16/2017) : To get all reports alpha-numeric order.
-- Modified By - Shripati U. (01/16/2018) : Display the reports on basis of special user (Admin)
--			   - Satyawan H. (12/12/2018) : Display reports on the basis of ModuleId and UserId
-- Modified By - Satyawan H. (12/28/2018) : Add conditions to to show Reports on the basis of super user permission
-- Modified By - Satyawan H. (01/25/2019) : modified inner join to LEFT JOIN 
-- Modified By - Nilesh Sa. (02/13/2019) : modified inner join to LEFT JOIN       
-- Raviraj P 04/19/2019 Change ACCTG to S,G&A       
-- =============================================
-- EXEC [SpMnxRptByModuleName] 'Warehouse Management System (WMS)','49F80792-E15E-4B62-B720-21B360E3108A'

 CREATE PROCEDURE [dbo].[SpMnxRptByModuleName]      
	-- Add The Parameters For The Stored Procedure Here
	@moduleName varchar(100) = '',
	@userId uniqueidentifier
AS
BEGIN
	-- 	SET NOCOUNT ON Added To Prevent Extra Result Sets From
	-- Interfering With SELECT Statements.
	SET NOCOUNT ON;

	-- Insert Statements For Procedure Here
	/* 
		Check To See If User Is Super User 
		Right Now, Only CompanyAdmin Is Used.
	*/

	/* 
		Shripati U. (01/16/2018) : Display the reports on basis of special user (Admin)
		Added the Admin MOC (ProdAdmin), SCM Admin, CRM Admin     
	*/
	DECLARE @superAccountUser bit =0,@superUser bit =0,@superProdUser bit=0, @superScmUser bit=0, 
			@superCrmUser bit=0,@isAdmin bit=0, @ParentModulePermission bit = 0      
				
	SELECT  @superAccountUser=AcctAdmin,
			@superUser=CompanyAdmin,
			@superScmUser= ScmAdmin, 
			@superCrmUser = CrmAdmin,  
			@superProdUser=ProdAdmin
	FROM aspnet_Profile WHERE aspnet_Profile.UserId = @userId 
			
	--PRINT @superScmUser
	DECLARE @usrTags TABLE (tagId char(10), tagName varchar(50) )
			
	--IF @superUser=1
	--BEGIN
	--    SET @isAdmin = 1
	--	INSERT INTO @usrTags
	--	SELECT sTagId, tagName FROM MnxSystemTags WHERE (compAdmin=1)
	--END
		   
	--   IF @superProdUser=1
	--BEGIN
	--     SET @isAdmin = 1
	--	INSERT INTO @usrTags
	--	SELECT sTagId, tagName FROM MnxSystemTags WHERE (ProdAdmin=1)
	--END
			
	--   IF @superAccountUser=1
	--BEGIN
	--     SET @isAdmin = 1
	--	INSERT INTO @usrTags
	--	SELECT sTagId, tagName FROM MnxSystemTags WHERE (AccountAdmin=1)
	--END
		   
	--   IF @superScmUser=1
	--BEGIN
	--     SET @isAdmin = 1
	--	INSERT INTO @usrTags
	--	SELECT sTagId, tagName FROM MnxSystemTags WHERE (ScmAdmin=1)
	--END
		   
	--   IF @superCrmUser=1
	--BEGIN
	--     SET @isAdmin = 1
	--	INSERT INTO @usrTags
	--	SELECT sTagId, tagName FROM MnxSystemTags WHERE (CrmAdmin=1)
	--END

	--IF @isAdmin=0
	--BEGIN
	--	INSERT INTO @usrTags
	--	SELECT	t.fksTagId, s.tagName
	--		FROM	dbo.aspmnx_RoleSystemTags AS t 
	--					INNER JOIN  dbo.aspmnx_GroupRoles gr ON gr.fkRoleId=t.fkRoleId
	--					INNER JOIN	dbo.aspmnx_groupUsers AS g ON gr.fkGroupId = g.fkgroupid
	--					INNER JOIN dbo.MnxSystemTags s ON s.sTagId=t.fksTagId
	--		WHERE   (g.fkuserid = @userId )
	--END
					
           
	--DECLARE @rptTag TABLE (tags varchar(50))
	--INSERT INTO @rptTag
	--SELECT fksTagId FROM [MnxModuleReports] mr (NOLOCK)
	--Inner join [MnxModule] m on m.ModuleId = mr.ModuleId
	-- WHERE m.ModuleName = @moduleName

	DECLARE @moduleId INT
	SELECT  @moduleId= ModuleId FROM  [MnxModule] 
	WHERE ModuleName = @moduleName
				
	--Satyawan H. (12/28/2018) : Add conditions to to show Reports on the basis of super user permission
	IF(@superAccountUser = 1 OR @superUser = 1 OR @superProdUser = 1 OR @superScmUser = 1 OR @superCrmUser = 1 OR @isAdmin = 1)			
	BEGIN
		SELECT @ParentModulePermission = CASE WHEN	(ModuleName = 'SCM' AND @superScmUser = 1)	   OR 
													-- Raviraj P 04/19/2019 Change ACCTG to S,G&A    
													(ModuleName = 'S,G&A' AND @superAccountUser=1) OR         
													(ModuleName = 'SALES'  AND @superCrmUser = 1 ) OR 
													(ModuleName = 'MES'  AND @superProdUser = 1)   OR (@superUser =1) THEN 1 ELSE 0 END
		FROM MNXMODULE WHERE MODULEID IN (SELECT MMR.PARENTID FROM MNXMODULE MM 
		JOIN MNXMODULERELATIONSHIP MMR ON MMR.CHILDID = MM.MODULEID 
		WHERE MM.MODULEID = @moduleId) 
	END
				
	SELECT distinct rptId,rptGroupTitle,fkrptGroupId,rptTitle,rptTitleLong,rptOrigin,rptType,reportCount,
	quickViewCount,exportCount,sendreportCount,totalUse,Fav,isnull(Z.Fav,cast(0 as bit)) as userFavorite,
	--sequence,
	CASE WHEN isnull(Z.Fav,cast(0 as bit))=1 THEN 'flagOrange' ELSE 'flagGray' END favoriteCSS
	FROM (
			-- Satyawan H. (12/12/2018) : Display reports on the basis of ModuleId and UserId
			SELECT  r.rptId,COALESCE(g.rptGroupTitle,'')rptGroupTitle,r.fkrptGroupId,rptTitle,rptTitleLong,--rt.sequence,st.tagName,
					'm' rptOrigin, CASE WHEN r.filePath IS NULL OR r.filePath =''  THEN 'qv' ELSE 'rpt' END rptType
					,[reportCount],[quickViewCount],[exportCount],[sendreportCount]
					,SUM([reportCount]+[quickViewCount]+[exportCount]+[sendreportCount])totalUse
			FROM MnxReports r 
			INNER JOIN MnxModuleReports rt ON r.rptId=rt.FkReportID  AND FkReportID <> ''
			JOIN aspnet_Roles ar on  rt.ModuleId =  ar.ModuleId 
			LEFT join aspmnx_GroupRoles on  ar.RoleId=  aspmnx_GroupRoles.fkRoleId      
			-- Modified By - Nilesh Sa. (02/13/2019) : modified inner join to LEFT JOIN       
			left join aspmnx_groupUsers on  aspmnx_groupUsers.fkgroupid =  aspmnx_GroupRoles.fkGroupId
			left JOIN aspnet_Profile p ON p.UserId=  aspmnx_groupUsers.fkuserid -- '044F2E4D-AAB4-4D3F-B56F-2C2DDF37F49C'
			-- Modified By - Satyawan H. (01/25/2019) : modified inner join to LEFT JOIN 
			LEFT OUTER JOIN MnxGroups g ON r.fkrptGroupId=g.rptGroupId
			--INNER JOIN MnxSystemTags st ON st.sTagId=rt.fksTagId
			WHERE -- @userId
			--rt.fksTagId IN (SELECT tagId FROM @usrTags WHERE tagId IN (SELECT tags FROM @rptTag))AND
			r.display=1 AND r.custReportReplace = ''and ar.ModuleId =@moduleId 
			AND (-- Satyawan H. (12/28/2018) : Add conditions to to show Reports on the basis of super user permission
			((@ParentModulePermission = 1) AND 1=1 ) OR
			((@ParentModulePermission= 0) AND RoleName = 'Reports' and p.UserId = @userId))
			--and p.UserId = @userId
			GROUP BY r.rptId,rptTitle,rptTitleLong,--rt.sequence,
			--st.tagName
			fkrptGroupId,g.rptGroupTitle,r.filePath,[reportCount],[quickViewCount],[exportCount],[sendreportCount]
		UNION
			-- Satyawan H. (12/12/2018) : Display reports on the basis of ModuleId and UserId
			SELECT  rc.rptId,COALESCE(g.rptGroupTitle,'')rptGroupTitle,rc.fkrptGroupId,rc.rptTitle,rc.rptTitleLong,--rt.sequence,st.tagName,
					'h' rptOrigin, CASE WHEN rc.filePath IS NULL OR rc.filePath =''  THEN 'qv' ELSE 'rpt' END rptType
					,rc.[reportCount],rc.[quickViewCount],rc.[exportCount],rc.[sendreportCount]
					,SUM(rc.[reportCount]+rc.[quickViewCount]+rc.[exportCount]+rc.[sendreportCount])totalUse
					FROM wmReportsCust rc INNER JOIN MnxReports r ON rc.rptId = r.custReportReplace
			INNER JOIN MnxModuleReports rt ON r.rptId=rt.FkReportID  AND FkReportID <> ''
			JOIN aspnet_Roles ar on rt.ModuleId =  ar.ModuleId 
			LEFT join aspmnx_GroupRoles on  ar.RoleId=  aspmnx_GroupRoles.fkRoleId      
			-- Modified By - Nilesh Sa. (02/13/2019) : modified inner join to LEFT JOIN       
			-- INNER JOIN aspnet_Users u ON u.UserId= ''
			LEFT JOIN aspmnx_groupUsers on  aspmnx_groupUsers.fkgroupid =  aspmnx_GroupRoles.fkGroupId
			LEFT JOIN aspnet_Profile p ON p.UserId=  aspmnx_groupUsers.fkuserid 
			--Modified By - Satyawan H. (01/25/2019) : modified inner join to LEFT JOIN 
			LEFT OUTER JOIN MnxGroups g ON r.fkrptGroupId=g.rptGroupId
			--INNER JOIN MnxSystemTags st ON st.sTagId=rt.fksTagId
			WHERE -- @userId
			--rt.fksTagId IN (SELECT tagId FROM @usrTags WHERE tagId IN (SELECT tags FROM @rptTag))AND
			r.display=1 AND r.custReportReplace = ''and ar.ModuleId =@moduleId 
			AND  (-- Satyawan H. (12/28/2018) : Add conditions to to show Reports on the basis of super user permission
			((@ParentModulePermission = 1) AND 1=1) OR
			(( @ParentModulePermission=0) AND RoleName = 'Reports' and p.UserId = @userId))
			--and p.UserId = @userId
			GROUP BY rc.rptId,rc.rptTitle, rc.rptTitleLong,--rt.sequence,
			--st.tagName
			rc.fkrptGroupId,g.rptGroupTitle,rc.filePath,rc.[reportCount],rc.[quickViewCount],rc.[exportCount],rc.[sendreportCount]
		UNION
		-- Satyawan H. (12/12/2018) : Display reports on the basis of ModuleId and UserId
		SELECT  rc.rptId,COALESCE(g.rptGroupTitle,'')rptGroupTitle,rc.fkrptGroupId,rc.rptTitle,rc.rptTitleLong,--rc.sequence,COALESCE(st.tagName,'')tagName, 
				'c' rptOrigin, CASE WHEN rc.filePath IS NULL OR rc.filePath =''  THEN 'qv' ELSE 'rpt' END rptType
				,rc.[reportCount],rc.[quickViewCount],rc.[exportCount],rc.[sendreportCount]
				,SUM(rc.[reportCount]+rc.[quickViewCount]+rc.[exportCount]+rc.[sendreportCount])totalUse
		FROM wmReportsCust rc 
		LEFT OUTER JOIN MnxModuleReports rt ON rc.rptId=rt.FkReportID AND FkReportID <> ''
		join aspnet_Roles ar on  rt.ModuleId =  ar.ModuleId 
		LEFT join aspmnx_GroupRoles on  ar.RoleId=  aspmnx_GroupRoles.fkRoleId      
		-- Modified By - Nilesh Sa. (02/13/2019) : modified inner join to LEFT JOIN       
		-- INNER JOIN aspnet_Users u ON u.UserId= @userId
		left join aspmnx_groupUsers on  aspmnx_groupUsers.fkgroupid =  aspmnx_GroupRoles.fkGroupId
		left JOIN aspnet_Profile p ON p.UserId=  aspmnx_groupUsers.fkuserid 
		-- Modified By - Satyawan H. (01/25/2019) : Modified inner join to LEFT JOIN 
		LEFT OUTER JOIN MnxGroups g ON rc.fkrptGroupId=g.rptGroupId
		--INNER JOIN MnxSystemTags st ON st.sTagId=rt.fksTagId
		WHERE -- @userId
		--rt.fksTagId IN (SELECT tagId FROM @usrTags WHERE tagId IN (SELECT tags FROM @rptTag))AND
		rc.display=1 and ar.ModuleId =@moduleId
		AND  (-- Satyawan H. (12/28/2018) : Add conditions to to show Reports on the basis of super user permission
		((@ParentModulePermission = 1) AND 1=1) OR
		((@ParentModulePermission=0) AND RoleName = 'Reports' and p.UserId = @userId))
		GROUP BY rc.rptId,rptTitle,rptTitleLong,--rt.sequence,
		--st.tagName
		fkrptGroupId,g.rptGroupTitle,rc.filePath,[reportCount],[quickViewCount],[exportCount],[sendreportCount]
	) rs
	OUTER APPLY (SELECT CAST(1 as bit) as Fav from wmReportsUserFavorites where fkUserId = @userId and fkRptId =rs.rptId) as Z  
	ORDER BY rs.rptTitle
END