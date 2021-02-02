-- ================================================================================
-- AUTHOR		: Satyawan H.
-- DATE			: 07/25/2019
-- DESCRIPTION	: Gets import fields which has error
-- ================================================================================

CREATE PROC GetWOUploadImportErrors
	@ImportId UNIQUEIDENTIFIER,
	@RowId UNIQUEIDENTIFIER = null
AS
BEGIN
	SET NOCOUNT ON  
	SELECT Distinct WONO.WONO,UNIQ_KEY.UNIQ_KEY,PART_NO.PART_NO,REVISION.REVISION,Adjusted, FieldName,[Message] FROM ImportWOUploadFields f
		JOIN ImportWOUploadHeader h ON h.ImportId = f.FkImportId
		OUTER APPLY (
			select Top 1 Adjusted As WONO  FROM ImportWOUploadFields 
			Where RowId = f.RowId AND FieldName = 'WONO'
		) WONO
		OUTER APPLY (
			select Top 1 Adjusted As UNIQ_KEY  FROM ImportWOUploadFields 
			Where RowId = f.RowId AND FieldName = 'UNIQ_KEY'
		) UNIQ_KEY
		OUTER APPLY (
			select Top 1 Adjusted As PART_NO  FROM ImportWOUploadFields 
			Where RowId = f.RowId AND FieldName = 'PART_NO'
		) PART_NO
		OUTER APPLY (
			select Top 1 Adjusted As REVISION  FROM ImportWOUploadFields 
			Where RowId = f.RowId AND FieldName = 'REVISION'
		) REVISION
		WHERE Message <> ''
	AND FkImportId = @ImportId
	ORDER BY WONO.WONO,PART_NO.PART_NO,REVISION.REVISION
END