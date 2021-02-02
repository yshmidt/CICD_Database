-- =============================================
-- Author:		David Sharp
-- Create date: 4/27/2012
-- Description:	get import detail row
-- =============================================
CREATE PROCEDURE [dbo].[importBOMRowGet]
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier,@rowId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   
	SELECT i.detailId,i.rowId,i.fkFieldDefId,fd.fieldName,i.uniq_key,i.lock,i.original,i.adjusted,i.[status],i.[validation],i.[message],fd.fieldLength
		FROM importBOMFields i INNER JOIN importBOMFieldDefinitions fd ON i.fkFieldDefId=fd.fieldDefId
		WHERE fkImportId = @importId AND rowId = @rowId
		
	EXEC importBOMAvlRowGet @importId,@rowId
	EXEC importBOMAvlErrorsGet @importId,@rowId
	SELECT * FROM importBOMRefDesg WHERE fkImportId=@importId AND fkRowId = @rowId ORDER BY refOrd
END