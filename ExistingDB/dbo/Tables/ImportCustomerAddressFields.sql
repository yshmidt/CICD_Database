CREATE TABLE [dbo].[ImportCustomerAddressFields] (
    [AddressDetailId] UNIQUEIDENTIFIER NOT NULL,
    [FkImportId]      UNIQUEIDENTIFIER NOT NULL,
    [CustRowId]       UNIQUEIDENTIFIER NOT NULL,
    [RowId]           UNIQUEIDENTIFIER NOT NULL,
    [FKFieldDefId]    UNIQUEIDENTIFIER NOT NULL,
    [Original]        NVARCHAR (MAX)   NULL,
    [Adjusted]        NVARCHAR (MAX)   NULL,
    [Status]          VARCHAR (50)     NULL,
    [Message]         NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__ImportCu__CC2967FD663073FD] PRIMARY KEY CLUSTERED ([AddressDetailId] ASC)
);

