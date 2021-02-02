CREATE TABLE [dbo].[ImportSupplierFields] (
    [SupDetailId]  UNIQUEIDENTIFIER NOT NULL,
    [FkImportId]   UNIQUEIDENTIFIER NOT NULL,
    [FkFieldDefId] UNIQUEIDENTIFIER NOT NULL,
    [RowId]        UNIQUEIDENTIFIER NOT NULL,
    [Original]     NVARCHAR (MAX)   NULL,
    [Adjusted]     NVARCHAR (MAX)   NULL,
    [Status]       VARCHAR (50)     NULL,
    [Message]      NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__ImportSu__C0D22F94BAD331DF] PRIMARY KEY CLUSTERED ([SupDetailId] ASC)
);

