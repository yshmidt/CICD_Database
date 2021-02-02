-- ============================================================================================================
-- Date			: 07/29/2019
-- Author		: Sachin B
-- Description	: Used for get routing import error data for excel
-- 08/01/2019 : Sachin B - Added one more and condition on join  rf.FKImportTemplateId=ri.ImportTemplateId to fixed the issue of Routing: In template there is only one error per routing still the two error is getting displayed per routing
-- GetRoutingImportErrorData '0c6e9390-fee9-4c58-955c-ff69ca6a2935'  
-- ============================================================================================================

CREATE PROC GetRoutingImportErrorData  
	@ImportId UNIQUEIDENTIFIER
AS
BEGIN
	
SET NOCOUNT ON 
 
DECLARE @ModuleId INT,@deptFieldDefid UNIQUEIDENTIFIER,@NumberFieldDefid UNIQUEIDENTIFIER
SELECT @ModuleId = moduleID FROM mnxmodule WHERE ModuleDesc = 'MnxM_RoutingSetup'
SELECT @deptFieldDefid = FieldDefId FROM ImportFieldDefinitions WHERE FieldName = 'dept_id' AND ModuleId =@ModuleId
SELECT @NumberFieldDefid =FieldDefId FROM ImportFieldDefinitions WHERE FieldName = 'Number' AND ModuleId =@ModuleId

;WITH routingError AS(
	SELECT ri.partNo,ri.revision,ri.uniq_Key,ri.templateName,ri.templateType,ri.validationMessage,ri.[Status],
	fieldData.FieldName,fieldData.[Message] AS FieldValidationMessage,fieldData.[Status] As FieldStatus,fieldData.rowid
	FROM importRoutingAssemblyInfo ri
	OUTER APPLY 
	(
		SELECT f.FieldName,rf.[Message],rf.[Status],rf.rowid 
		FROM importRoutingFields rf
		INNER JOIN ImportFieldDefinitions f ON rf.FKFieldDefId =f.FieldDefId
		-- 08/01/2019 : Sachin B - Added one more and condition on join  rf.FKImportTemplateId=ri.ImportTemplateId to fixed the issue of Routing: In template there is only one error per routing still the two error is getting displayed per routing
		WHERE rf.FkImportId = ri.FkImportId AND rf.FKImportTemplateId = ri.ImportTemplateId AND rf.[Status] = 'i05red'  
	) fieldData
	WHERE ri.FkImportId =@ImportId
)

--select * from routingError

,WCName AS(
	SELECT RowId,Adjusted AS Deptid FROM importRoutingFields WHERE
	FkImportId =@ImportId AND FKFieldDefId =@deptFieldDefid
)

,WCNumber AS(
	SELECT RowId,Adjusted AS Number FROM importRoutingFields WHERE
	FkImportId =@ImportId AND FKFieldDefId =@NumberFieldDefid
)

SELECT re.partNo,re.revision,re.uniq_Key,re.templateName,re.templateType,re.validationMessage, re.Status,
ISNULL(wc.Deptid,'') AS Deptid,ISNULL(wcNo.Number,'') AS Number,ISNULL(re.FieldName,'') AS FieldName,ISNULL(re.FieldValidationMessage,'') AS FieldValidationMessage,
ISNULL(FieldStatus,'') AS FieldStatus
FROM routingError re
LEFT JOIN WCName wc ON re.rowid =wc.RowId
LEFT JOIN WCNumber wcNo ON re.rowid =wcNo.RowId
WHERE FieldStatus ='i05red' OR re.Status ='i05red' 
ORDER BY re.partNo,re.revision,re.uniq_Key,wc.Deptid,wcNo.Number,re.rowid

END