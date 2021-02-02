CREATE TABLE [dbo].[WmNoteGroupUsers] (
    [WmNoteGroupUsersId] UNIQUEIDENTIFIER NOT NULL,
    [FkWmNoteGroupId]    UNIQUEIDENTIFIER NULL,
    [UserId]             UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_WmNoteGroupUsers] PRIMARY KEY CLUSTERED ([WmNoteGroupUsersId] ASC),
    CONSTRAINT [FK_WmNoteGroupUsers_WmNoteGroup] FOREIGN KEY ([FkWmNoteGroupId]) REFERENCES [dbo].[WmNoteGroup] ([WmNoteGroupId])
);

