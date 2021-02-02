
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/06/08
-- Description:	Equivalent to the parameterized view in VFP 
-- (NoteAssign2TableView )
-- =============================================
CREATE PROCEDURE [dbo].[NoteAssign2TableView] 
	-- Add the parameters for the stored procedure here
	@lcTableName char(15) = null, 
	@lcTableunique char(15) = null
AS
SELECT Noteassign.fknoteunique, Noteassign.tablename,
		Noteassign.tableunique, Noteassign.assignunique,NOTEASSIGN.cAssignId 
		FROM noteassign
		WHERE  Noteassign.tablename = @lcTableName
		AND  Noteassign.tableunique = @lcTableunique
