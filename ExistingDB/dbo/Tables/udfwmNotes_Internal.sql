CREATE TABLE [dbo].[udfwmNotes_Internal] (
    [udfId]    UNIQUEIDENTIFIER CONSTRAINT [DF_udfwmNotes_Internal_udfId] DEFAULT (newid()) NOT NULL,
    [fkNoteID] UNIQUEIDENTIFIER CONSTRAINT [DF_udfwmNotes_Internal_fkNoteID] DEFAULT ('') NOT NULL,
    [Int]      INT              CONSTRAINT [DF_udfwmNotes_Internal_Int] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_udfwmNotes_Internal] PRIMARY KEY CLUSTERED ([udfId] ASC)
);

