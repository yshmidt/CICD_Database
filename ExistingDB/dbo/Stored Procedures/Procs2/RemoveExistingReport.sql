-- ======================================================================================
-- Date : 08/07/2019
-- BY	: Satyawan H
-- Desc	: Used to delete the existing Manex and User reports from manex if user is manex
-- ======================================================================================
CREATE PROC RemoveExistingReport 
	@rptId Varchar(10)
   ,@isManexRpt Bit
AS 
BEGIN
	SET NOCOUNT ON;
	IF OBJECT_ID('tempdb..#MxRpts') IS NOT NULL DROP TABLE #MxRpts
	IF OBJECT_ID('tempdb..#WmRpts') IS NOT NULL DROP TABLE #WmRpts

	DECLARE @isUserManex Bit
		   ,@paramGroup VARCHAR(50)
		   ,@ReportGrp VARCHAR(50)
		   ,@isDeleteRptGrp Bit
		   ,@isDeleteRptPrm Bit
	
	SELECT @isUserManex = CASE WHEN LIC_NAME = 'ManEx System' THEN 1 ELSE 0 END from MICSSYS 

	IF(@isManexRpt = 1 AND @isUserManex = 1)
	BEGIN
		SELECT @paramGroup=paramGroup, 
			   @ReportGrp=fkrptGroupId FROM MnxReports WHERE rptId=@rptId

		SELECT @isDeleteRptGrp=CASE WHEN count(fkrptGroupId)>1 THEN 0 ELSE 1 END FROM MnxReports 
		WHERE fkrptGroupId <> '' AND fkrptGroupId = @ReportGrp
		GROUP BY fkrptGroupId 

		SELECT @isDeleteRptPrm=CASE WHEN count(paramGroup)>1 THEN 0 ELSE 1 END FROM MnxReports 
		WHERE paramGroup <> '' AND paramGroup = @paramGroup
		GROUP BY paramGroup

		IF(@isDeleteRptPrm=1)
		BEGIN
			SELECT * INTO #MxRpts FROM wmGroupParams WHERE paramGroup = @paramGroup
			DELETE FROM MnxGroupParams WHERE paramGroup = @paramGroup
			DELETE FROM MnxParams WHERE rptParamId IN (SELECT fkParamId FROM #MxRpts WHERE paramGroup = @paramGroup)
		END

		DELETE FROM MnxReports WHERE rptId = @rptId
		
		IF(@isDeleteRptGrp = 1)
		BEGIN
			DELETE FROM MnxGroups where rptGroupId = @ReportGrp
		END
	END	
	ELSE IF(@isManexRpt = 0)
	BEGIN
		SELECT @paramGroup=paramGroup, 
			   @ReportGrp=fkrptGroupId FROM wmReportsCust WHERE rptId=@rptId

		SELECT @isDeleteRptGrp=CASE WHEN count(fkrptGroupId)>1 THEN 0 ELSE 1 END FROM wmReportsCust 
		WHERE fkrptGroupId <> '' AND fkrptGroupId = @ReportGrp
		GROUP BY fkrptGroupId 

		SELECT @isDeleteRptPrm=CASE WHEN count(paramGroup)>1 THEN 0 ELSE 1 END FROM wmReportsCust 
		WHERE paramGroup <> '' AND paramGroup = @paramGroup
		GROUP BY paramGroup

		IF(@isDeleteRptPrm=1)
		BEGIN
			SELECT * INTO #WmRpts FROM wmGroupParams WHERE paramGroup = @paramGroup
			DELETE FROM wmGroupParams WHERE paramGroup = @paramGroup
			DELETE FROM WmParams WHERE rptParamId IN (SELECT fkParamId FROM #WmRpts WHERE paramGroup = @paramGroup)
		END

		DELETE FROM wmReportsCust WHERE rptId = @rptId
		
		IF(@isDeleteRptGrp = 1)
		BEGIN
			DELETE FROM wmGroups where rptGroupId = @ReportGrp
		END
	END
END