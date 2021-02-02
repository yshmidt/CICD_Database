CREATE TABLE [dbo].[WmNoteUser] (
    [WmNoteUserId] UNIQUEIDENTIFIER NOT NULL,
    [GroupId]      UNIQUEIDENTIFIER NULL,
    [UserId]       UNIQUEIDENTIFIER NULL,
    [NoteId]       UNIQUEIDENTIFIER NOT NULL,
    [IsGroup]      BIT              NOT NULL,
    CONSTRAINT [PK_WmNoteUser] PRIMARY KEY CLUSTERED ([WmNoteUserId] ASC),
    CONSTRAINT [FK_WmNoteUser_wmNotes] FOREIGN KEY ([NoteId]) REFERENCES [dbo].[wmNotes] ([NoteID]) ON DELETE CASCADE ON UPDATE CASCADE
);

