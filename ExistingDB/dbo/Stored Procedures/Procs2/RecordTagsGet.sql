
CREATE PROCEDURE [dbo].[RecordTagsGet] 
(
@recordId uniqueidentifier
)
AS
BEGIN

SELECT [RecordTags].[RecordTagID] 
      ,[RecordTags].[fkAdminTagID]
      ,[MnxAdminTags].[Description]
      ,[RecordTags].[fkCreatedUserID]
      ,[RecordTags].[CreatedDate]
      ,[RecordTags].fkAdminTagID
      ,[RecordTags].RecordType
 FROM [dbo].[RecordTags]
 inner join wmNotes n on n.NoteId = [RecordTags].fkRecordId
 inner join MnxAdminTags on [RecordTags].fkAdminTagID = MnxAdminTags.AdminTagID
 where fkRecordID=convert(nvarchar(256), @recordId)
 ORDER by [CreatedDate] DESC

END