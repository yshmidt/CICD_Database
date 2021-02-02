CREATE TABLE [dbo].[importRoutingFields] (
    [DetailId]           UNIQUEIDENTIFIER NOT NULL,
    [FkImportId]         UNIQUEIDENTIFIER NOT NULL,
    [FKImportTemplateId] UNIQUEIDENTIFIER NOT NULL,
    [RowId]              UNIQUEIDENTIFIER NOT NULL,
    [Original]           NVARCHAR (MAX)   NULL,
    [Adjusted]           NVARCHAR (MAX)   NULL,
    [Status]             NVARCHAR (50)    NULL,
    [Message]            NVARCHAR (MAX)   NOT NULL,
    [FKFieldDefId]       UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK__importRo__135C316DAAC9CFA4] PRIMARY KEY CLUSTERED ([DetailId] ASC)
);

