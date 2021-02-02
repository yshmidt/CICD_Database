CREATE TABLE [dbo].[importPartClassTypeFields] (
    [DetailId]           UNIQUEIDENTIFIER NOT NULL,
    [FkImportId]         UNIQUEIDENTIFIER NOT NULL,
    [FKImportTemplateId] UNIQUEIDENTIFIER NOT NULL,
    [RowId]              UNIQUEIDENTIFIER NOT NULL,
    [FKFieldDefId]       UNIQUEIDENTIFIER NOT NULL,
    [Original]           NVARCHAR (MAX)   NULL,
    [Adjusted]           NVARCHAR (MAX)   NULL,
    [Status]             NVARCHAR (50)    NULL,
    [Message]            NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__importPa__135C316DD0E14A17] PRIMARY KEY CLUSTERED ([DetailId] ASC)
);

