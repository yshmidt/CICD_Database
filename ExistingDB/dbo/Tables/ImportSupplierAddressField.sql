CREATE TABLE [dbo].[ImportSupplierAddressField] (
    [AddressDetailId] UNIQUEIDENTIFIER NOT NULL,
    [FkImportId]      UNIQUEIDENTIFIER NOT NULL,
    [SupRowId]        UNIQUEIDENTIFIER NOT NULL,
    [RowId]           UNIQUEIDENTIFIER NOT NULL,
    [FKFieldDefId]    UNIQUEIDENTIFIER NOT NULL,
    [Original]        NVARCHAR (MAX)   NULL,
    [Adjusted]        NVARCHAR (MAX)   NULL,
    [Status]          VARCHAR (50)     NULL,
    [Message]         NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__ImportSu__CC2967FD93EA4592] PRIMARY KEY CLUSTERED ([AddressDetailId] ASC)
);

