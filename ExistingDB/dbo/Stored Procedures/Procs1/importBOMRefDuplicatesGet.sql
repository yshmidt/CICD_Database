-- =============================================
-- Author:		David Sharp
-- Create date: 6/22/2012
-- Description:	gets a table of duplicate ref desg
-- =============================================
CREATE PROCEDURE [dbo].[importBOMRefDuplicatesGet] 
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    --DECLARE @redDesId uniqueidentifier
    --SELECT @redDesId=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='refdesg'
    DECLARE @itemId uniqueidentifier
    SELECT @itemId=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='itemno'
    
    DECLARE @dupRefs TABLE (refdesg varchar(MAX),cnt int)
	INSERT INTO @dupRefs
	SELECT refdesg,COUNT(refdesId)[count]  
		FROM importBOMRefDesg 
		WHERE fkImportId=@importId 
		GROUP BY refdesg 
		HAVING COUNT(refdesId)>1

	SELECT r.refdesId,r.refdesg, i.rowId, i.adjusted itemno
		FROM importBOMRefDesg r INNER JOIN importBOMFields i ON i.rowId=r.fkRowId 
		WHERE r.refdesg IN (SELECT refdesg FROM @dupRefs) AND r.fkImportId=@importId AND i.fkFieldDefId=@itemId
		ORDER BY r.refdesg,i.adjusted

END