CREATE TYPE [dbo].[tmnxNote] AS TABLE (
    [NoteRecordID]    UNIQUEIDENTIFIER DEFAULT (newsequentialid()) NOT NULL,
    [fkNoteID]        UNIQUEIDENTIFIER NOT NULL,
    [RecordID]        VARCHAR (100)    DEFAULT ('') NOT NULL,
    [RecordType]      VARCHAR (50)     DEFAULT ('') NOT NULL,
    [DeletedDate]     DATETIME         NULL,
    [fkDeletedUserID] UNIQUEIDENTIFIER NULL,
    [IsDeleted]       BIT              DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([NoteRecordID] ASC));

