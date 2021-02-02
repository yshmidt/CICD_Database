

CREATE PROCEDURE [dbo].[RecordTagAdd] 
	@RecordId uniqueidentifier,
	@RecordTagId uniqueidentifier,
	@CreatedUserID uniqueidentifier,
	@fkAdminTagID varchar(50),
	@RecordType varchar(50)
AS
BEGIN
	INSERT INTO [dbo].[RecordTags]
           (RecordTagId
           ,[fkRecordID]
           ,fkAdminTagID
           ,[fkCreatedUserID]
           ,[CreatedDate]
		   ,RecordType)
     VALUES
           (@RecordTagId
           ,@RecordId
           ,@fkAdminTagID
           ,@CreatedUserID
           ,getdate()
		   ,@RecordType);

END



