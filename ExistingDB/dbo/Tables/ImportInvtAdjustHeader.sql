CREATE TABLE [dbo].[ImportInvtAdjustHeader] (
    [ImportId]     UNIQUEIDENTIFIER NOT NULL,
    [FileName]     NVARCHAR (100)   NOT NULL,
    [Status]       NVARCHAR (50)    NOT NULL,
    [ImportDate]   DATETIME         NULL,
    [ImportBy]     UNIQUEIDENTIFIER NULL,
    [CompleteDate] DATETIME         CONSTRAINT [DF__ImportInv__Compl__06488473] DEFAULT (NULL) NULL,
    [CompletedBy]  UNIQUEIDENTIFIER CONSTRAINT [DF__ImportInv__Compl__073CA8AC] DEFAULT (NULL) NULL,
    CONSTRAINT [PK__ImportIn__869767EA3BEA6486] PRIMARY KEY CLUSTERED ([ImportId] ASC)
);

