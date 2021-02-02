CREATE TYPE [dbo].[tWmNotes] AS TABLE (
    [NoteID]          UNIQUEIDENTIFIER NOT NULL,
    [Description]     VARCHAR (MAX)    NOT NULL,
    [fkCreatedUserID] UNIQUEIDENTIFIER NOT NULL,
    [ReminderDate]    SMALLDATETIME    NULL,
    [RecordId]        VARCHAR (100)    NULL,
    [RecordType]      VARCHAR (100)    NULL,
    [NoteCategory]    INT              NULL,
    [ImagePath]       VARCHAR (MAX)    NULL,
    [OldNoteID]       UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([NoteID] ASC));

