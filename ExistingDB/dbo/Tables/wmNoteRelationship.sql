CREATE TABLE [dbo].[wmNoteRelationship] (
    [NoteRelationshipId]      UNIQUEIDENTIFIER CONSTRAINT [DF_WmNoteRelationShip_NoteRelationshipId] DEFAULT (newid()) NOT NULL,
    [FkNoteId]                UNIQUEIDENTIFIER NOT NULL,
    [CreatedUserId]           UNIQUEIDENTIFIER NOT NULL,
    [Note]                    VARCHAR (MAX)    NOT NULL,
    [CreatedDate]             DATETIME2 (7)    CONSTRAINT [DF_WmNoteRelationShip_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [ImagePath]               VARCHAR (MAX)    NULL,
    [IsWhisper]               BIT              CONSTRAINT [DF_wmNoteRelationship_IsWhisper] DEFAULT ((0)) NOT NULL,
    [ReplyNoteRelationshipId] UNIQUEIDENTIFIER CONSTRAINT [DF_wmNoteRelationship_ReplyNoteRelationshipId] DEFAULT (newsequentialid()) NULL,
    CONSTRAINT [PK_NoteRelationship] PRIMARY KEY CLUSTERED ([NoteRelationshipId] ASC),
    CONSTRAINT [FK_wmNoteRelationship_wmNotes] FOREIGN KEY ([FkNoteId]) REFERENCES [dbo].[wmNotes] ([NoteID])
);

