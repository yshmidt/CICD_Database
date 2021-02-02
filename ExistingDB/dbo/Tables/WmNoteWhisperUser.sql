CREATE TABLE [dbo].[WmNoteWhisperUser] (
    [WmNoteWhisperUserId]  UNIQUEIDENTIFIER NOT NULL,
    [FkNoteRelationshipId] UNIQUEIDENTIFIER NULL,
    [UserId]               UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_WmNoteWhisperUser] PRIMARY KEY CLUSTERED ([WmNoteWhisperUserId] ASC),
    CONSTRAINT [FK_WmNoteWhisperUser_wmNoteRelationship] FOREIGN KEY ([FkNoteRelationshipId]) REFERENCES [dbo].[wmNoteRelationship] ([NoteRelationshipId]) ON DELETE CASCADE ON UPDATE CASCADE
);

