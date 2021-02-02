
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/29/12
-- Description:	This SP will collect all assigned notes to a specific table and specific key to display
-- (NoteAssignedDisplay )
-- =============================================
CREATE PROCEDURE [dbo].NoteAssignedDisplay 
	-- Add the parameters for the stored procedure here
	@lcTableName char(15) = null, 
	@lcTableunique char(15) = null
AS
SELECT Noteassign.tablename,
		Noteassign.tableunique, NoteSetup.NOTENAME,NOTESETUP.NOTETEXT, Noteassign.assignunique,NOTEASSIGN.cAssignId , Noteassign.fknoteunique
		FROM noteassign INNER JOIN NOTESETUP on NOTEASSIGN.FKNOTEUNIQUE =NOTESetup.NOTEUNIQUE 
		WHERE  Noteassign.tablename = @lcTableName
		AND  Noteassign.tableunique = @lcTableunique
