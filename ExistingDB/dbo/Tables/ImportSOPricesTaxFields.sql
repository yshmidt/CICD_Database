CREATE TABLE [dbo].[ImportSOPricesTaxFields] (
    [SOPricesTaxId]   UNIQUEIDENTIFIER NOT NULL,
    [FKSODetailRowId] UNIQUEIDENTIFIER NOT NULL,
    [RowId]           UNIQUEIDENTIFIER NOT NULL,
    [FKFieldDefId]    UNIQUEIDENTIFIER NOT NULL,
    [Original]        NVARCHAR (MAX)   NULL,
    [Adjusted]        NVARCHAR (MAX)   NULL,
    [Status]          NVARCHAR (50)    NULL,
    [Message]         NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__ImportSO__6BE2C3E9CCD52BAE] PRIMARY KEY CLUSTERED ([SOPricesTaxId] ASC)
);

