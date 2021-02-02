CREATE TABLE [dbo].[WmNotesSetup] (
    [SetupId]  INT              IDENTITY (1, 1) NOT NULL,
    [FkNoteID] UNIQUEIDENTIFIER NOT NULL,
    [UserId]   UNIQUEIDENTIFIER NULL,
    [Priority] INT              NULL,
    [IsHide]   BIT              CONSTRAINT [DF_wmnotesSetup_IsHide] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WmNotesSetup] PRIMARY KEY CLUSTERED ([SetupId] ASC)
);

