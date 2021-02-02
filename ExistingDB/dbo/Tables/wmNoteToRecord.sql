CREATE TABLE [dbo].[wmNoteToRecord] (
    [NoteRecordID]    UNIQUEIDENTIFIER CONSTRAINT [DF_wmNoteToRecord_NoteRecordID] DEFAULT (newsequentialid()) NOT NULL,
    [fkNoteID]        UNIQUEIDENTIFIER NOT NULL,
    [RecordID]        VARCHAR (100)    CONSTRAINT [DF_WMNoteToRecord_RecordID] DEFAULT ('') NOT NULL,
    [RecordType]      VARCHAR (50)     CONSTRAINT [DF_WMNoteToRecord_RecordType] DEFAULT ('') NOT NULL,
    [DeletedDate]     DATETIME         NULL,
    [fkDeletedUserID] UNIQUEIDENTIFIER NULL,
    [IsDeleted]       BIT              CONSTRAINT [DF_wmNoteToRecord_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_wmNoteToRecord] PRIMARY KEY CLUSTERED ([NoteRecordID] ASC),
    CONSTRAINT [FK_NoteToRecord_aspnet_Users] FOREIGN KEY ([fkDeletedUserID]) REFERENCES [dbo].[aspnet_Users] ([UserId]),
    CONSTRAINT [FK_NoteToRecord_Notes] FOREIGN KEY ([fkNoteID]) REFERENCES [dbo].[wmNotes] ([NoteID]) ON DELETE CASCADE
);

