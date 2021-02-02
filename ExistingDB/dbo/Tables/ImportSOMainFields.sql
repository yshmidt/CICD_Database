CREATE TABLE [dbo].[ImportSOMainFields] (
    [SOFieldId]    UNIQUEIDENTIFIER NOT NULL,
    [FkImportId]   UNIQUEIDENTIFIER NOT NULL,
    [FKFieldDefId] UNIQUEIDENTIFIER NOT NULL,
    [RowId]        UNIQUEIDENTIFIER NOT NULL,
    [Original]     NVARCHAR (MAX)   NULL,
    [Adjusted]     NVARCHAR (MAX)   NULL,
    [Status]       NVARCHAR (50)    NULL,
    [Message]      NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__ImportSO__7E9289B4810AEE45] PRIMARY KEY CLUSTERED ([SOFieldId] ASC)
);

