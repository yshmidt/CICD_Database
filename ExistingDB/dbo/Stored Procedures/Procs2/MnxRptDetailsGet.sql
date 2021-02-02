 -- =======================================================================================================================================          
 -- Author:  David Sharp          
 -- Create date: 11/12/2012          
 -- Description: Get the details and params for the selected report      
 -- Modified: 08/08/13 YS changed to be able to use dynamic value for the default        
 -- 08/10/13 DS modified the report details call to include all columns    
 -- 08/13/13 DS Added Target Param Influencers    
 -- 08/14/13 DS Added parentParam to connect cascaded parameters    
 -- 08/28/13 MItesh Added finalParam for label report grid load.  
 -- 11/11/13 DS Added group summary info
 -- 03/03/14 DS separated MnxParams
 -- 03/19/14 DS Added fieldWidth option
 -- 04/16/14 DS Added report tag info for admins and rowLink and rowLinkId
 -- 04/23/14 DS Added handling for customer report params
 -- 08/08/14 YS Added bigData column to mnxParamSources table
 -- 10/06/14 DS Added quickviewTitleTemplate
 -- 12/04/15 YS added new table for users assign different tags than mnxReportTags (wmReportTags)
 -- 01/04/2019 SatyawanH  : Added "isBigDataRpt" column in of mnxreports table And set default 0 value for "wmReportsCust" 
 --							this is used for pagination of report.
 -- 01/06/2019 SatyawanH  : Added UNION to WmGroupParams, wmReportParamTargets 
 -- 01/06/2019 SatyawanH : Added Join on MnxParamSources with WmParamSources
 -- 01/16/2019 SatyawanH : selected sourceType, bigData, and dataSource on wmparamsources
 -- 01/08/2020 SatyawanH : Pass report type as 'M' for manex and 'C' for Custom report
 -- 01/08/2020 SatyawanH : Pass report custom report filepath saved from setting for .MRT files
 -- 02/20/2020 Rajendra K : Changed the length of @pGroup from 10 to 50
 -- 07/20/2020 Satyawan H: Added new "RptEmailBodySetting" column in selection of mnxReports table
 -- EXEC MnxRptDetailsGet 'SBZDZS4G6K','49F80792-E15E-4B62-B720-21B360E3108A',@ExecuteDefaultVal =0 
 -- EXEC MnxRptDetailsGet @pGroup='PO', @userId='49F80792-E15E-4B62-B720-21B360E3108A',@ExecuteDefaultVal =0 
 -- =======================================================================================================================================          
 
CREATE PROCEDURE [dbo].[MnxRptDetailsGet] 
	@rptId varchar(10)='',    
	@userId uniqueidentifier,
	@ExecuteDefaultVal bit = 1,         
  @pGroup char(50) =''--char(10) ='' -- 02/20/2020 Rajendra K : Changed the length of @pGroup from 10 to 50  
AS          
BEGIN          
	-- SET NOCOUNT ON added to prevent extra result sets from          
	-- interfering with SELECT statements.          
	SET NOCOUNT ON;          
	DECLARE @RptBy char(1)
		   ,@custRptPath VARCHAR(MAX) =''

	select @custRptPath = IIF(w.settingId IS NOT NULL,w.settingValue,m.settingValue) 
	FROM MnxSettingsManagement m
	LEFT JOIN wmSettingsManagement w ON w.settingId = m.settingId 
	WHERE settingName = 'DefaultReportPath'

	IF EXISTS(SELECT 1 From MnxReports where rptId = @rptId) SET @RptBy = 'M'
	ELSE IF EXISTS(SELECT 1 From wmReportsCust where rptId = @rptId) SET @RptBy = 'C'
	
	-- Insert statements for procedure here          
	-- DECLARE @pGroup varchar(15)          
	SELECT @pGroup=paramGroup 
	FROM
	(
		SELECT paramGroup FROM MnxReports WHERE rptId=@rptId  
		UNION
		SELECT paramGroup FROM wmReportsCust WHERE rptId=@rptId
	)r      
                
	--DECLARE @roles varchar(MAX)          
  
	-- 12/04/15 YS added new table for users assign different tags than mnxReportTags (wmReportTags)    
	--SELECT @roles=COALESCE(@roles+',','')+r.LoweredRoleName FROM MnxReportTags rt           
	-- INNER JOIN MnxSystemTags st ON st.sTagId=rt.fksTagId          
	-- INNER JOIN aspmnx_RoleSystemTags rst ON  rst.fksTagId=st.sTagId          
	-- INNER JOIN aspnet_Roles r ON r.roleId=rst.fkRoleId          
	--WHERE rt.rptId=@rptId          
	--ORDER BY r.RoleName    
   
	--    SELECT @roles=COALESCE(@roles+',','')+r.LoweredRoleName FROM 
	--  (SELECT FKStAGiD from MnxReportTags where rptid =@rptid
	--   UNION 
	--SELECT FKStAGiD from wmReportTags where rptid =@rptid) rt
	--   INNER JOIN MnxSystemTags st ON st.sTagId=rt.fksTagId          
	--   INNER JOIN aspmnx_RoleSystemTags rst ON  rst.fksTagId=st.sTagId          
	--   INNER JOIN aspnet_Roles r ON r.roleId=rst.fkRoleId          
	--  ORDER BY r.RoleName       
             
	/* 12/29/2012 DS Added colNames, colModel, and groupedCol from user config */          
	/* 12/31/2012 DS Added handling for Custom Reports */          
	DECLARE @colNames varchar(MAX),@colModel varchar(MAX), @groupedCol varchar(MAX)          
	SELECT @colNames=colNames,@colModel=colModel,@groupedCol=groupedCol FROM wmUserGridConfig 
	WHERE gridId =@rptId AND userId =@userId          
                
	 -- 01/08/2020 SatyawanH : Pass report type as 'M' for manex and 'C' for Custom report
	SELECT r.*,isnull(Z.Fav,cast(0 AS bit)) AS userFavorite     
	FROM 
	(    
		SELECT rptId,fkrptGroupId,rptTitle,rptTitleLong,rptDescription,[sequence],label,filePath,display,
			   dataSource,reportType,paramGroup,CASE WHEN @groupedCol<>'' THEN @groupedCol ELSE groupedCol END groupedCol, --@roles AS roleNames,
			   @colNames AS colNames,@colModel AS colModel,showGroupSummary,showSummaryOnHide,maxSqlTimeout,
			   -- 07/20/2020 Satyawan H: Added new "RptEmailBodySetting" column in selection of mnxReports table
			   rowLink,rowLinkId,quickviewTitleTemplate,isBigDataRpt,'M' rptOrigin,RptEmailBodySetting
		FROM MnxReports    
		WHERE rptId=@rptId AND custReportReplace = ''          

		UNION          
		SELECT @rptId,fkrptGroupId,rptTitle,rptTitleLong,rptDescription,[sequence],label,CONCAT(@custRptPath,filePath) filePath,display,
			   dataSource,reportType,paramGroup,CASE WHEN @groupedCol<>'' THEN @groupedCol ELSE groupedCol END groupedCol,--@roles AS roleNames,
			   @colNames AS colNames,@colModel AS colModel,showGroupSummary,showSummaryOnHide,maxSqlTimeout,
			   rowLink,rowLinkId,quickviewTitleTemplate,0,'C',''
		FROM wmReportsCust           
		WHERE rptId IN (SELECT custReportReplace FROM MnxReports WHERE rptId=@rptId)          

		UNION           
		SELECT rptId,fkrptGroupId,rptTitle,rptTitleLong,rptDescription,[sequence],label,CONCAT(@custRptPath,filePath) filePath,display,
			   dataSource,reportType,paramGroup,CASE WHEN @groupedCol<>'' THEN @groupedCol ELSE groupedCol END groupedCol,--@roles AS roleNames,
			   @colNames AS colNames,@colModel AS colModel,showGroupSummary,showSummaryOnHide,maxSqlTimeout,
			   rowLink,rowLinkId,quickviewTitleTemplate,0,'C',''
		FROM wmReportsCust WHERE rptId= @rptId 
	) r    
	OUTER APPLY (
		SELECT CAST(1 AS BIT) AS Fav FROM wmReportsUserFavorites 
		WHERE fkUserId = @userId and fkRptId =r.rptId
	) AS Z           
             
	--08/08/13 YS attempt to create dynamic default value for now I could not find any better way then cursor    
	-- create table variable and populate with records for the given @pGroup    
	-- 08/10/13 DS Added isFixed and changed columnCount to columnNum    
	-- 08/14/13 DS parentParam added    
	-- 8/28/2013 Mitesh Added finalParam   
	DECLARE @Rpt TABLE (rptparamid uniqueidentifier,paramgroup varchar(15),localizationKey varchar(50), paramname varchar(50),paramtype varchar(50),
						columnNum int, selectParam char(1),hideFirst bit,onchange varchar(max),addressSp varchar(max),[sequence] int,sourceLink varchar(100),
						defaultValue varchar(100),defaultValueSql bit,isFixed bit,cascadeId uniqueidentifier,parentParam varchar(50),finalParam bit,
						fieldWidth varchar(50),RptType varchar(5))   
   
	IF(@RptBy='M')
	BEGIN
		INSERT INTO @Rpt    
		SELECT p.rptparamid,paramgroup,p.localizationKey,p.paramname,p.paramType,columnNum,    
			   selectParam,hideFirst,onchange,addressSp,[sequence], p.sourceLink,    
			   defaultValue,defaultValueSql,isFixed,cascadeId,parentParam,finalParam,fieldWidth,1
		FROM MnxGroupParams g 
		INNER JOIN MnxParams p ON g.fkParamId = p.rptParamId 
		WHERE paramGroup=@pGroup    
	END
	ELSE IF (@RptBy='C')  
	BEGIN
		INSERT INTO @Rpt    
		SELECT p.rptparamid,paramgroup,p.localizationKey,p.paramname,p.paramType,columnNum,    
			   selectParam,hideFirst,onchange,addressSp,[sequence], p.sourceLink,defaultValue,
			   defaultValueSql,isFixed,cascadeId,parentParam,finalParam,p.fieldWidth,0
		FROM WmGroupParams g 
		INNER JOIN WmParams p ON g.fkParamId = p.rptParamId 
		WHERE paramGroup=@pGroup 
	END  
	ELSE
	BEGIN 
		INSERT INTO @Rpt    
		select p.rptparamid,paramgroup,p.localizationKey,p.paramname,p.paramType,columnNum,    
			   selectParam,hideFirst,onchange,addressSp,[sequence], p.sourceLink,defaultValue,
			   defaultValueSql,isFixed,cascadeId,parentParam,finalParam,p.fieldWidth,0
		FROM WmGroupParams g 
		INNER JOIN WmParams p ON g.fkParamId = p.rptParamId 
		WHERE paramGroup=@pGroup 
	
		UNION

		SELECT p.rptparamid,paramgroup,p.localizationKey,p.paramname,p.paramType,columnNum, 
			   selectParam,hideFirst,onchange,addressSp,[sequence], p.sourceLink,defaultValue,
			   defaultValueSql,isFixed,cascadeId,parentParam,finalParam,fieldWidth,1
		FROM MnxGroupParams g 
		INNER JOIN MnxParams p ON g.fkParamId = p.rptParamId 
		WHERE paramGroup=@pGroup 
	END

	IF(@ExecuteDefaultVal = 1)
	BEGIN
		DECLARE @rptparamid uniqueidentifier,@defaultValue nvarchar(max)    
		DECLARE @retvalue table (retValue varchar(max))    
		
		DECLARE C1 CURSOR LOCAL FAST_FORWARD FOR    
			SELECT rptparamid,defaultValue from @Rpt     
			-- 08/09/13 YS added flag if the default value is a sql statement    
			WHERE defaultValue<>'' and defaultValueSql=1    
		
			OPEN c1    
				FETCH NEXT FROM c1 INTO @rptparamid,@defaultValue    
				WHILE @@fetch_status <> -1    
				BEGIN    
					INSERT INTO @retvalue EXEC sp_executesql @defaultValue    

					UPDATE @Rpt 
						SET defaultValue=retValue FROM @retvalue 
					WHERE rptparamid = @rptparamid    
			
					-- clear ret value     
					DELETE FROM @retvalue     
					FETCH NEXT FROM c1 INTO @rptparamid,@defaultValue    
				END    
			CLOSE c1    
		DEALLOCATE c1    
	END
	   
	-- 08/08/13 YS now use updated @Rpt for the end result     
	-- 08/10/13 DS changed to rp.* to include all columns 
	--08/08/14 YS added bigData Column to mnxParamSOurces table   
  
	IF(@RptBy='M')
	BEGIN
		SELECT rp.*, ps.sourceType,ps.dataSource,ps.bigData FROM @Rpt rp 
			LEFT OUTER JOIN MnxParamSources ps ON rp.sourceLink=ps.sourceName    
		--LEFT OUTER JOIN WmParamSources wps ON rp.sourceLink= wps.sourceName          
		WHERE rp.paramGroup=@pGroup          
		ORDER BY rp.sequence     

		-- 08/13/13 DS Added MnxReportParamTarget data    
		SELECT * FROM MnxReportParamTargets WHERE rptParamId IN (SELECT rptParamId FROM @Rpt)    
	END
	ELSE IF(@RptBy='C')
	BEGIN
		-- 01/16/2019 SatyawanH : selected sourceType, bigData, and dataSource on wmparamsources
		SELECT rp.*, wps.sourceType,wps.dataSource,wps.bigData FROM @Rpt rp 
			--LEFT OUTER JOIN MnxParamSources ps ON rp.sourceLink=ps.sourceName    
			LEFT OUTER JOIN WmParamSources wps ON rp.sourceLink= wps.sourceName          
		WHERE rp.paramGroup=@pGroup          
		ORDER BY rp.sequence     

		-- 01/06/2019 SatyawanH: Added UNION to WmGroupParams, wmReportParamTargets 
		SELECT * FROM wmReportParamTargets 
		WHERE rptParamId IN (SELECT rptParamId FROM @Rpt)    
	END
	ELSE
	BEGIN
		-- EXEC MnxRptDetailsGet @pGroup='PO', @userId='49F80792-E15E-4B62-B720-21B360E3108A',@ExecuteDefaultVal =1 
		--select * from @Rpt  
		SELECT rp.*, ps.sourceType,ps.dataSource,ps.bigData FROM @Rpt rp 
			LEFT OUTER JOIN MnxParamSources ps ON rp.sourceLink=ps.sourceName   
		WHERE rp.paramGroup = @pGroup   
		UNION
		SELECT rp.*, wps.sourceType,wps.dataSource,wps.bigData FROM @Rpt rp 
			JOIN WmParamSources wps ON rp.sourceLink= wps.sourceName              
		WHERE rp.paramGroup = @pGroup          
		ORDER BY rp.sequence    
		
		SELECT * FROM wmReportParamTargets WHERE rptParamId IN (SELECT rptParamId FROM @Rpt)    
		UNION
		-- 08/13/13 DS Added MnxReportParamTarget data    
		SELECT * FROM MnxReportParamTargets WHERE rptParamId IN (SELECT rptParamId FROM @Rpt)  
	END

	-- 08/13/13 DS Added MnxReportParamTarget data    
	-- SELECT * FROM MnxReportParamTargets WHERE rptParamId IN (SELECT rptParamId FROM @Rpt)    
	--UNION -- 01/06/2019 SatyawanH: Added UNION to WmGroupParams, wmReportParamTargets 
	-- SELECT * FROM wmReportParamTargets WHERE rptParamId IN (SELECT rptParamId FROM @Rpt)    

	-- --SELECT * FROM MnxReportParamTargets     
	-- -- WHERE rptParamId IN (SELECT rptParamId FROM @Rpt)    

	--04/16/14 DS Added report management details
	--12/04/15 YS do not know where this result is used, but changed it to add wmReportTags table
	SELECT st.tagName,COALESCE(r.selected,0) selected
	FROM 
	--MnxReportTags rt 
	(
		SELECT FKStAGiD,rptId from MnxReportTags 
		UNION 
		SELECT FKStAGiD,rptId from wmReportTags 
	) rt
	INNER JOIN MnxSystemTags st ON rt.fksTagId=st.sTagId
	LEFT OUTER JOIN (SELECT rptId, cast(1 AS bit) selected FROM MnxReports WHERE rptId=@rptId) r ON r.rptId=rt.rptId
	GROUP BY st.tagName,r.selected
	ORDER BY selected DESC,tagName
END 