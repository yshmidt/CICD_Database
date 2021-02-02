-- ============================================================================================================
-- Date			: 08/03/2019
-- Author		: Mahesh B
-- Description	: Used for get routing import error data for excel
-- GetPartClassTypeImportErrorData '6e982f44-d1f6-48c9-ae82-cda0f1d14d08'  
-- ============================================================================================================

CREATE PROC GetPartClassTypeImportErrorData  
	@ImportId UNIQUEIDENTIFIER
AS
BEGIN
	
SET NOCOUNT ON 
 
DECLARE @ModuleId INT,@partClassFieldDefid UNIQUEIDENTIFIER,@partTypeFieldDefid UNIQUEIDENTIFIER
SELECT @ModuleId = moduleID FROM mnxmodule WHERE ModuleDesc = 'MnxM_PartMasterAMLControl'
SELECT @partClassFieldDefid = FieldDefId FROM ImportFieldDefinitions WHERE FieldName = 'PART_CLASS' AND ModuleId =@ModuleId
SELECT @partTypeFieldDefid =FieldDefId FROM ImportFieldDefinitions WHERE FieldName = 'PART_TYPE' AND ModuleId =@ModuleId

;WITH partClassTypeError AS(
	SELECT ri.part_class,ri.classDescription,ri.useIpkey,ri.uniqwh,ri.aspnetBuyer,ri.AllowAutokit,ri.Message,ri.[Status],
	fieldData.FieldName,fieldData.[Message] AS FieldValidationMessage,fieldData.[Status] As FieldStatus,fieldData.rowid
	FROM importPartClassTypeInfo ri
	OUTER APPLY 
	(
		SELECT f.FieldName,rf.[Message],rf.[Status],rf.rowid 
		FROM importPartClassTypeFields rf
		INNER JOIN ImportFieldDefinitions f ON rf.FKFieldDefId =f.FieldDefId
		WHERE rf.FkImportId = ri.FkImportId AND rf.FKImportTemplateId = ri.ImportTemplateId AND rf.[Status] = 'i05red'  
	) fieldData
	WHERE ri.FkImportId =@ImportId
)

,PartClass AS(
	SELECT RowId,Adjusted AS PartClass FROM importPartClassTypeFields WHERE
	FkImportId =@ImportId AND FKFieldDefId =@partClassFieldDefid
)

,PartType AS(
	SELECT RowId,Adjusted AS PartType FROM importPartClassTypeFields WHERE
	FkImportId =@ImportId AND FKFieldDefId = @partTypeFieldDefid
)

SELECT  re.part_class AS 'Part Class',pt.PartType AS 'Part Type'
		,ISNULL(re.FieldName,'') AS FieldName,ISNULL(re.FieldValidationMessage,'') AS FieldValidationMessage,
		ISNULL(FieldStatus,'') AS FieldStatus
		FROM partClassTypeError  re
		LEFT JOIN PartClass pc ON re.rowid =pc.RowId
		LEFT JOIN PartType  pt ON re.rowid =pt.RowId
WHERE FieldStatus ='i05red' OR re.Status ='i05red' 
ORDER BY re.part_class asc --,pt.PartType
--ORDER BY   
-- CASE WHEN re.part_class LIKE '[A-Z]%' THEN LEFT(re.part_class,PATINDEX('%[0-9]%',re.part_class)-1) ELSE NULL END,
--    CAST(CASE WHEN re.part_class LIKE '%[0-9]%'
--                THEN REPLACE(SUBSTRING(re.part_class,PATINDEX('%[0-9]%',re.part_class),CHARINDEX(' ;',re.part_class+' ;')-1),' ;','')
--                ELSE re.part_class END as int)
END