-- =============================================
-- Author:Satish B
-- Create date: 10/05/2018
-- Description : Update WmNotes table for record id
-- exec UpdeteNotesRecord 'T00000000001869','000000000001869'
-- =============================================
CREATE PROCEDURE UpdeteNotesRecord
	  @oldRecordId char(15) = ''
	 ,@newRecordId char(15) = ''
 AS
 BEGIN
	SET NOCOUNT ON
	UPDATE wmNotes 
		SET RecordId=@newRecordId 
	WHERE RecordId=@oldRecordId 
		AND RecordType='WFNote'
 END