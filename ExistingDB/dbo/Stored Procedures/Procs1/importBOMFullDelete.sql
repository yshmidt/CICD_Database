-- =============================================
-- Author:		David Sharp
-- Create date: 5/2/2012
-- Description:	Delete all records for an import
-- 07/02/13 YS added Fk to all sub tables related to ImportBomHeader
-- did not set relation to importBomTemp... tables. Not sure if we need to
-- Enforce the delete cascade
-- 07/03/13 DS Added validation to ensure the user has permission to delete
-- 10/14/13 YS modified name of the table 
-- 03/07/2018: Vijay G: Delete notes related to the bom assembly and component from wmNotes and wmNoteRelationship table
-- 24/12/2018: Vijay G: Check permission from js and controller file no need to check here
-- =============================================
CREATE PROCEDURE [dbo].[importBOMFullDelete] 
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier,
	@userId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- 24/12/2018: Vijay G: Check permission from js and controller file no need to check here
  -- Insert statements for procedure here
  --07/02/13 YS added Fk to all sub tables related to ImportBomHeader
	--DELETE FROM importBOMAvl WHERE fkimportId = @importId
	--DELETE FROM importBOMRefDesg WHERE fkImportId = @importId
	--DELETE FROM importBOMFields WHERE fkImportId = @importId
	--DECLARE @hasPermission bit 
	--EXEC	@hasPermission = [dbo].[aspmnxIsUserInRole]
	--		@UserId = @userId,
	--		@RoleId = '12EE58C1-6530-4C9B-B23A-48CF7F13B26B',--RoleId for IBOM_Delete
	--		@SuperUserCode = 1
	--IF @hasPermission=1
	--BEGIN
		/*First delete note*/
		/*03/07/2018: Vijay G: To delete notes related to the bom assembly from wmNoteRelationship table*/
		DELETE FROM wmNoteRelationship WHERE FkNoteId in(
		SELECT NoteID FROM wmNotes WHERE RecordId IN(SELECT DISTINCT CAST(rowId AS VARCHAR(100))  FROM importBOMFields 
			WHERE fkImportId=@importId and fkFieldDefId 
			IN (SELECT fieldDefId FROM importBOMFieldDefinitions WHERE fieldName in('invNote','bomNote'))))

		/*03/07/2018: Vijay G: To delete notes related to the bom assembly component from wmNotes table*/
		DELETE FROM wmNotes WHERE RecordId IN(SELECT DISTINCT CAST(rowId AS VARCHAR(100))  FROM importBOMFields 
			WHERE fkImportId=@importId and fkFieldDefId 
			IN (SELECT fieldDefId FROM importBOMFieldDefinitions WHERE fieldName in('invNote','bomNote')))

		-- 10/14/13 YS change MnxNoteToRecord to WmNoteToRecord
		/*03/07/2018: Vijay G: To delete notes related to the bom assembly header from wmNoteRelationship table*/
		DELETE FROM wmNoteRelationship WHERE FkNoteId IN(SELECT NoteID FROM wmNotes WHERE RecordType='importBOMHeader' AND RecordID=CAST(@importId AS VARCHAR(100)))

		/*03/07/2018: Vijay G: To delete notes related to the bom assembly and component  from wmNotes table*/
		DELETE FROM wmNotes WHERE RecordType='importBOMHeader' AND RecordID=CAST(@importId AS VARCHAR(100))

		/*03/07/2018: Vijay G: Delete imported bom records*/
		DELETE FROM importBOMHeader WHERE importId = @importId		
	--END	
END