-- =============================================
-- Author:		Vicky Lu
-- Create date: 12/03/2020
-- Description:	Get invoice foot note from wmNotes and wmNoteRelationship, but only get the latest one because didn't re-write to create several records for same note
-- =============================================
CREATE PROCEDURE [dbo].[wmNote4DesktopPLMAIN_INVFNView] 
	-- Add the parameters for the stored procedure here
	@lcRecordId varchar(100) = ' '

AS
BEGIN

	SELECT TOP 1 RecordId, wmNoteRelationship.*
		FROM wmNotes LEFT OUTER JOIN wmNoteRelationship ON wmNotes.NoteID = wmNoteRelationship.FkNoteId
		WHERE wmNotes.RecordType = 'PLMAIN_INVFN'
		AND wmNotes.RecordId = @lcRecordId
		ORDER BY wmNoteRelationship.CreatedDate DESC

END	