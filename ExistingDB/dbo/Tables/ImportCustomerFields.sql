CREATE TABLE [dbo].[ImportCustomerFields] (
    [CustDetailId] UNIQUEIDENTIFIER NOT NULL,
    [FkImportId]   UNIQUEIDENTIFIER NOT NULL,
    [FkFieldDefId] UNIQUEIDENTIFIER NOT NULL,
    [RowId]        UNIQUEIDENTIFIER NOT NULL,
    [Original]     NVARCHAR (MAX)   NULL,
    [Adjusted]     NVARCHAR (MAX)   NULL,
    [Status]       VARCHAR (50)     NULL,
    [Message]      NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__ImportCu__F3EDFFB9DCC68AB8] PRIMARY KEY CLUSTERED ([CustDetailId] ASC)
);

