CREATE TABLE [dbo].[RecordTags] (
    [RecordTagID]     UNIQUEIDENTIFIER CONSTRAINT [DF_RecordTags_NoteTagID] DEFAULT (newsequentialid()) NOT NULL,
    [fkRecordID]      VARCHAR (36)     NOT NULL,
    [fkAdminTagID]    UNIQUEIDENTIFIER NOT NULL,
    [fkCreatedUserID] UNIQUEIDENTIFIER NOT NULL,
    [CreatedDate]     DATETIME         CONSTRAINT [DF_RecordTags_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [RecordType]      VARCHAR (50)     NOT NULL,
    [TaggedUserId]    UNIQUEIDENTIFIER NULL,
    [SystemTagId]     CHAR (10)        NULL,
    CONSTRAINT [PK_RecordTags] PRIMARY KEY CLUSTERED ([RecordTagID] ASC),
    CONSTRAINT [FK_RecordTags_aspnet_Users_Created] FOREIGN KEY ([fkCreatedUserID]) REFERENCES [dbo].[aspnet_Users] ([UserId])
);

