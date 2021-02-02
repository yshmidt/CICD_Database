CREATE TABLE [dbo].[ImportSupplierContactField] (
    [ContactDetailId] UNIQUEIDENTIFIER NOT NULL,
    [FkImportId]      UNIQUEIDENTIFIER NOT NULL,
    [SupRowId]        UNIQUEIDENTIFIER NOT NULL,
    [RowId]           UNIQUEIDENTIFIER NOT NULL,
    [FKFieldDefId]    UNIQUEIDENTIFIER NOT NULL,
    [Original]        NVARCHAR (MAX)   NULL,
    [Adjusted]        NVARCHAR (MAX)   NULL,
    [Status]          VARCHAR (50)     NULL,
    [Message]         NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__ImportSu__6F780E009E3BDE5C] PRIMARY KEY CLUSTERED ([ContactDetailId] ASC)
);

