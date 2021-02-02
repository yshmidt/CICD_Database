		-- =============================================
		-- Author:		David Sharp
		-- Create date: 11/12/2012
		-- Description:	get report details for the grid
		-- 06/16/14 DS added usage statistics
		-- 06/01/15 DS Added visibility of custom reports without a tag
		--- 12/04/15 YS added wmReportTags table, for user to assign a different tag to a report
		--- 07/10/18 Shivshankar P : When additional role having with superadmin
		-- =============================================
		CREATE PROCEDURE [dbo].[MnxRptGridItemsGet] --'','feae44ee-9a88-4ef0-9fd2-eb57d89af9b0'
			-- Add the parameters for the stored procedure here
			@tagIds varchar(MAX) = '', 
			@userId uniqueidentifier
		AS
		BEGIN
			-- SET NOCOUNT ON added to prevent extra result sets from
			-- interfering with SELECT statements.
			SET NOCOUNT ON;

			-- Insert statements for procedure here
			/* 
				Check to see if user is Super User 
				Right now, only CompanyAdmin is used.
				TODO: Once users are able to define their own tags and specify
			*/
			DECLARE @SuperAccountUser bit =0,@SuperUser bit =0,@SuperProdUser bit=0	
			SELECT @SuperAccountUser=AcctAdmin,@SuperUser=CompanyAdmin,@SuperProdUser=ProdAdmin FROM aspnet_Profile where aspnet_Profile.UserId = @UserId 
			
			DECLARE @usrTags TABLE (tagId char(10), tagName varchar(50) )
			
			IF @SuperUser=1
			BEGIN
				INSERT INTO @usrTags
				SELECT sTagId, tagName FROM MnxSystemTags WHERE (compAdmin=1)
			END
			ELSE IF @SuperProdUser=1
			BEGIN
				INSERT INTO @usrTags
				SELECT sTagId, tagName FROM MnxSystemTags WHERE (ProdAdmin=1)
			END
			ELSE IF @SuperAccountUser=1
			BEGIN
				INSERT INTO @usrTags
				SELECT sTagId, tagName FROM MnxSystemTags WHERE (AccountAdmin=1)
			END 
		    IF EXISTS (SELECT	1 FROM	dbo.aspmnx_RoleSystemTags AS t INNER JOIN  dbo.aspmnx_GroupRoles gr ON gr.fkRoleId=t.fkRoleId
								INNER JOIN	dbo.aspmnx_groupUsers AS g ON gr.fkGroupId = g.fkgroupid INNER JOIN dbo.MnxSystemTags s ON s.sTagId=t.fksTagId	
					WHERE   (g.fkuserid = @userId))  --- 07/10/18 Shivshankar P : When additional role having with superadmin
			  BEGIN
				INSERT INTO @usrTags
				SELECT	t.fksTagId, s.tagName
					FROM	dbo.aspmnx_RoleSystemTags AS t 
								INNER JOIN  dbo.aspmnx_GroupRoles gr ON gr.fkRoleId=t.fkRoleId
								INNER JOIN	dbo.aspmnx_groupUsers AS g ON gr.fkGroupId = g.fkgroupid
								INNER JOIN dbo.MnxSystemTags s ON s.sTagId=t.fksTagId	
					WHERE   (g.fkuserid = @userId)
			   END
					
			IF @tagIds=''
			BEGIN
				SELECT rs.*,isnull(Z.Fav,cast(0 as bit)) as userFavorite, CASE WHEN isnull(Z.Fav,cast(0 as bit))=1 THEN 'flagOrange' ELSE 'flagGray' END favoriteCSS	
				FROM (
				
					SELECT r.rptId,COALESCE(g.rptGroupTitle,'')rptGroupTitle,rptTitle,rptTitleLong,rt.sequence,st.tagName, 
							'm' rptOrigin, CASE WHEN r.filePath IS NULL OR r.filePath =''  THEN 'qv' ELSE 'rpt' END rptType
							,[reportCount],[quickViewCount],[exportCount],[sendreportCount]
							,SUM([reportCount]+[quickViewCount]+[exportCount]+[sendreportCount])totalUse
						FROM MnxReports r LEFT OUTER JOIN 
						--- 12/04/15 YS added wmReportTags table, for user to assign a different tag to a report
						(SELECT FKStAGiD,rptId,sequence from MnxReportTags 
							UNION 
						SELECT FKStAGiD,rptId,sequence from wmReportTags ) rt ON r.rptId=rt.rptId
						--MnxReportTags rt ON r.rptId=rt.rptId
								LEFT OUTER JOIN MnxGroups g ON r.fkrptGroupId=g.rptGroupId
								INNER JOIN MnxSystemTags st ON st.sTagId=rt.fksTagId
						WHERE rt.fksTagId IN (SELECT tagId FROM @usrTags)AND r.display=1 AND r.custReportReplace = ''
						GROUP BY r.rptId,rptTitle,rptTitleLong,rt.sequence,st.tagName,g.rptGroupTitle,r.filePath,[reportCount],[quickViewCount],[exportCount],[sendreportCount]
					UNION
					SELECT r.rptId,COALESCE(g.rptGroupTitle,'')rptGroupTitle,rc.rptTitle,rc.rptTitleLong,rt.sequence,st.tagName, 
							'h' rptOrigin, CASE WHEN r.filePath IS NULL OR r.filePath =''  THEN 'qv' ELSE 'rpt' END rptType
							,rc.[reportCount],rc.[quickViewCount],rc.[exportCount],rc.[sendreportCount]
							,SUM(rc.[reportCount]+rc.[quickViewCount]+rc.[exportCount]+rc.[sendreportCount])totalUse
						FROM wmReportsCust rc INNER JOIN MnxReports r ON rc.rptId = r.custReportReplace
					--- 12/04/15 YS added wmReportTags table, for user to assign a different tag to a report
							--INNER JOIN MnxReportTags rt ON r.rptId=rt.rptId
							LEFT OUTER JOIN (SELECT FKStAGiD,rptId,sequence from MnxReportTags 
							UNION 
							SELECT FKStAGiD,rptId,sequence from wmReportTags ) rt ON r.rptId=rt.rptId
								LEFT OUTER JOIN MnxGroups g ON r.fkrptGroupId=g.rptGroupId
								INNER JOIN MnxSystemTags st ON st.sTagId=rt.fksTagId
						WHERE rt.fksTagId IN (SELECT tagId FROM @usrTags)AND rc.display=1
						GROUP BY r.rptId,rc.rptTitle,rc.rptTitleLong,rt.sequence,st.tagName,g.rptGroupTitle,r.filePath,rc.[reportCount],rc.[quickViewCount],rc.[exportCount],rc.[sendreportCount]
					UNION
					SELECT rc.rptId,COALESCE(g.rptGroupTitle,'')rptGroupTitle,rc.rptTitle,rc.rptTitleLong,rc.sequence,COALESCE(st.tagName,'CUSTOM')tagName,
							'c' rptOrigin, CASE WHEN r.filePath IS NULL OR r.filePath =''  THEN 'qv' ELSE 'rpt' END rptType
							,rc.[reportCount],rc.[quickViewCount],rc.[exportCount],rc.[sendreportCount]
							,SUM(rc.[reportCount]+rc.[quickViewCount]+rc.[exportCount]+rc.[sendreportCount])totalUse
						FROM wmReportsCust rc 
						LEFT OUTER JOIN 
						--- 12/04/15 YS added wmReportTags table, for user to assign a different tag to a report
						---MnxReportTags rt ON rc.rptId=rt.rptId
						(SELECT FKStAGiD,rptId,sequence from MnxReportTags 
							UNION 
						SELECT FKStAGiD,rptId,sequence from wmReportTags ) rt ON rc.rptId=rt.rptId
							LEFT OUTER JOIN MnxGroups g ON rc.fkrptGroupId=g.rptGroupId
								LEFT OUTER JOIN MnxSystemTags st ON st.sTagId=rt.fksTagId
								LEFT OUTER JOIN MnxReports r ON rc.rptId = r.custReportReplace
						WHERE (rt.fksTagId IN (SELECT tagId FROM @usrTags) OR rt.fksTagId IS NULL) AND rc.display=1 AND r.custReportReplace is null
						GROUP BY rc.rptId,rc.rptTitle,rc.rptTitleLong,rc.sequence,st.tagName,g.rptGroupTitle,r.filePath,rc.[reportCount],rc.[quickViewCount],rc.[exportCount],rc.[sendreportCount]
					) rs
					OUTER APPLY (SELECT CAST(1 as bit) as Fav from wmReportsUserFavorites where fkUserId = @userId and fkRptId =rs.rptId) as Z  
					ORDER BY rs.rptTitle
			END
			ELSE
			BEGIN
				DECLARE @rptTag TABLE (tags varchar(50))
				INSERT INTO @rptTag
				SELECT CAST(id as varchar(50)) FROM fn_simpleVarcharlistToTable(@tagIds,',')   
				SELECT * ,isnull(Z.Fav,cast(0 as bit)) as userFavorite, CASE WHEN isnull(Z.Fav,cast(0 as bit))=1 THEN 'flagOrange' ELSE 'flagGray' END favoriteCSS	
				FROM (
					SELECT r.rptId,COALESCE(g.rptGroupTitle,'')rptGroupTitle,r.fkrptGroupId,rptTitle,rptTitleLong,rt.sequence,st.tagName,
							'm' rptOrigin, CASE WHEN r.filePath IS NULL OR r.filePath =''  THEN 'qv' ELSE 'rpt' END rptType
							,[reportCount],[quickViewCount],[exportCount],[sendreportCount]
							,SUM([reportCount]+[quickViewCount]+[exportCount]+[sendreportCount])totalUse
						FROM MnxReports r INNER JOIN 
						--- 12/04/15 YS added wmReportTags table, for user to assign a different tag to a report
						--	MnxReportTags rt ON r.rptId=rt.rptId
						(SELECT FKStAGiD,rptId,sequence from MnxReportTags 
							UNION 
						SELECT FKStAGiD,rptId,sequence from wmReportTags ) rt ON r.rptId=rt.rptId
								LEFT OUTER JOIN MnxGroups g ON r.fkrptGroupId=g.rptGroupId
								INNER JOIN MnxSystemTags st ON st.sTagId=rt.fksTagId
						WHERE rt.fksTagId IN (SELECT tagId FROM @usrTags WHERE tagId IN (SELECT tags FROM @rptTag))AND r.display=1 AND r.custReportReplace = ''
						GROUP BY r.rptId,rptTitle,rptTitleLong,rt.sequence,st.tagName,r.fkrptGroupId,g.rptGroupTitle,r.filePath,[reportCount],[quickViewCount],[exportCount],[sendreportCount]
					UNION
					SELECT r.rptId,COALESCE(g.rptGroupTitle,'')rptGroupTitle,r.fkrptGroupId,rc.rptTitle,rc.rptTitleLong,rt.sequence,st.tagName,
							'h' rptOrigin, CASE WHEN r.filePath IS NULL OR r.filePath =''  THEN 'qv' ELSE 'rpt' END rptType
							,rc.[reportCount],rc.[quickViewCount],rc.[exportCount],rc.[sendreportCount]
							,SUM(rc.[reportCount]+rc.[quickViewCount]+rc.[exportCount]+rc.[sendreportCount])totalUse
						FROM wmReportsCust rc INNER JOIN MnxReports r ON rc.rptId = r.custReportReplace
								INNER JOIN 
								--- 12/04/15 YS added wmReportTags table, for user to assign a different tag to a report
								--MnxReportTags rt ON r.rptId=rt.rptId
								(SELECT FKStAGiD,rptId,sequence from MnxReportTags 
									UNION 
								SELECT FKStAGiD,rptId,sequence from wmReportTags ) rt ON r.rptId=rt.rptId
								LEFT OUTER JOIN MnxGroups g ON r.fkrptGroupId=g.rptGroupId
								INNER JOIN MnxSystemTags st ON st.sTagId=rt.fksTagId
						WHERE rt.fksTagId IN (SELECT tagId FROM @usrTags WHERE tagId IN (SELECT tags FROM @rptTag))AND rc.display=1
						GROUP BY r.rptId,rc.rptTitle,rc.rptTitleLong,rt.sequence,st.tagName,r.fkrptGroupId,g.rptGroupTitle,r.filePath,rc.[reportCount],rc.[quickViewCount],rc.[exportCount],rc.[sendreportCount]
					UNION
					SELECT rc.rptId,COALESCE(g.rptGroupTitle,'')rptGroupTitle,rc.fkrptGroupId,rc.rptTitle,rc.rptTitleLong,rc.sequence,COALESCE(st.tagName,'CUSTOM')tagName, 
							'c' rptOrigin, CASE WHEN r.filePath IS NULL OR r.filePath =''  THEN 'qv' ELSE 'rpt' END rptType
							,rc.[reportCount],rc.[quickViewCount],rc.[exportCount],rc.[sendreportCount]
							,SUM(rc.[reportCount]+rc.[quickViewCount]+rc.[exportCount]+rc.[sendreportCount])totalUse
						FROM wmReportsCust rc LEFT OUTER JOIN 
							--- 12/04/15 YS added wmReportTags table, for user to assign a different tag to a report
								--MnxReportTags rt ON rc.rptId=rt.rptId
								(SELECT FKStAGiD,rptId,sequence from MnxReportTags 
									UNION 
								SELECT FKStAGiD,rptId,sequence from wmReportTags ) rt ON rc.rptId=rt.rptId
								LEFT OUTER JOIN MnxGroups g ON rc.fkrptGroupId=g.rptGroupId
								LEFT OUTER JOIN MnxSystemTags st ON st.sTagId=rt.fksTagId
								LEFT OUTER JOIN MnxReports r ON rc.rptId = r.custReportReplace
						WHERE rt.fksTagId IN (SELECT tagId FROM @usrTags WHERE tagId IN (SELECT tags FROM @rptTag)) AND rc.display=1 AND r.custReportReplace is null
						GROUP BY rc.rptId,rc.rptTitle,rc.rptTitleLong,rc.sequence,st.tagName,rc.fkrptGroupId,g.rptGroupTitle,r.filePath,rc.[reportCount],rc.[quickViewCount],rc.[exportCount],rc.[sendreportCount]
				) rs
				OUTER APPLY (SELECT CAST(1 as bit) as Fav from wmReportsUserFavorites where fkUserId = @userId and fkRptId =rs.rptId) as Z  
				ORDER BY rs.sequence
			END
		END