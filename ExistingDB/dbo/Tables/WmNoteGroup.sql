CREATE TABLE [dbo].[WmNoteGroup] (
    [WmNoteGroupId] UNIQUEIDENTIFIER NOT NULL,
    [GroupName]     VARCHAR (50)     NOT NULL,
    [CreatedBy]     UNIQUEIDENTIFIER NOT NULL,
    [CreatedDate]   SMALLDATETIME    NOT NULL,
    CONSTRAINT [PK_WmNoteGroup] PRIMARY KEY CLUSTERED ([WmNoteGroupId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_WmNoteGroup]
    ON [dbo].[WmNoteGroup]([GroupName] ASC, [CreatedBy] ASC);


GO
CREATE TRIGGER [dbo].[WmNoteGroup_Insert]
   ON  [dbo].[WmNoteGroup]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    BEGIN TRANSACTION
	 
	 INSERT INTO dbo.WmNoteGroupUsers
	         ( WmNoteGroupUsersId ,
	           FkWmNoteGroupId ,
	           UserId
	         )
	 SELECT  NEWID() , -- WmNoteGroupUsersId - uniqueidentifier
	            Inserted.WmNoteGroupId , -- FkWmNoteGroupId - uniqueidentifier
	           Inserted.CreatedBy FROM Inserted  -- UserId - uniqueidentifier
	         
	COMMIT
END