-- =============================================
-- Author:		David Sharp
-- Create date: 5/20/2013
-- Description:	updates the dynamic match records
-- =============================================
CREATE PROCEDURE [dbo].[importBOMDynamicMatchUpdate] 
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier,
	@rowIds varchar(MAX),
	@fieldName varchar(MAX),
	@fieldValue varchar(MAX)	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @updateTable TABLE (rowId uniqueidentifier)
	INSERT INTO @updateTable
	SELECT CAST(id AS uniqueidentifier) FROM dbo.fn_simpleVarcharlistToTable(@rowIds,',')
	DECLARE @fieldDefId varchar(MAX)
	SELECT @fieldDefId=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = @fieldName

	UPDATE importBOMFields
	SET adjusted=@fieldValue
	WHERE fkImportId=@importId 
		AND fkFieldDefId = @fieldDefId
		AND rowId IN (SELECT rowId FROM @updateTable)
		
	EXEC dbo.importBOMVldtnCheckValues @importId
END