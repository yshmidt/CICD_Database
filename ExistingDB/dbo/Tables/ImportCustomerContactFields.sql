CREATE TABLE [dbo].[ImportCustomerContactFields] (
    [ContactDetailId] UNIQUEIDENTIFIER NOT NULL,
    [FkImportId]      UNIQUEIDENTIFIER NOT NULL,
    [CustRowId]       UNIQUEIDENTIFIER NOT NULL,
    [RowId]           UNIQUEIDENTIFIER NOT NULL,
    [FKFieldDefId]    UNIQUEIDENTIFIER NOT NULL,
    [Original]        NVARCHAR (MAX)   NULL,
    [Adjusted]        NVARCHAR (MAX)   NULL,
    [Status]          VARCHAR (50)     NULL,
    [Message]         NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__ImportCu__6F780E00788CE864] PRIMARY KEY CLUSTERED ([ContactDetailId] ASC)
);

