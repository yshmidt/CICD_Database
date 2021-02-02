

CREATE PROCEDURE [dbo].[MnxNoteToRecordGet] (
@RecordId varchar(100),
@RecordType varchar(50),
@NoteId uniqueidentifier
)
AS BEGIN
--10/14/13 YS modifed table name from mnxNoteToRecord to wmNoteToRecord
select * from wmNoteToRecord  
where RecordId = @RecordId AND RecordType = @RecordType and fkNoteId = @NoteId

END
