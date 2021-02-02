CREATE TABLE [dbo].[ImportPOTax] (
    [POTaxId]        UNIQUEIDENTIFIER CONSTRAINT [DF__ImportPOT__POTax__62F45B3E] DEFAULT (newsequentialid()) NOT NULL,
    [fkPOImportId]   UNIQUEIDENTIFIER NOT NULL,
    [fkRowId]        UNIQUEIDENTIFIER NOT NULL,
    [fkFieldDefId]   UNIQUEIDENTIFIER NOT NULL,
    [TaxRowId]       UNIQUEIDENTIFIER NOT NULL,
    [UniqPoItemsTax] VARCHAR (10)     NULL,
    [Original]       NVARCHAR (MAX)   NOT NULL,
    [Adjusted]       NVARCHAR (MAX)   NOT NULL,
    [Status]         VARCHAR (10)     CONSTRAINT [DF__ImportPOT__Statu__63E87F77] DEFAULT ('') NOT NULL,
    [Validation]     VARCHAR (10)     CONSTRAINT [DF__ImportPOT__Valid__64DCA3B0] DEFAULT ('') NOT NULL,
    [Message]        NVARCHAR (MAX)   CONSTRAINT [DF__ImportPOT__Messa__65D0C7E9] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK__ImportPO__1B7329BB74D44CF4] PRIMARY KEY CLUSTERED ([POTaxId] ASC),
    CONSTRAINT [FK__ImportPOT__fkFie__67B9105B] FOREIGN KEY ([fkFieldDefId]) REFERENCES [dbo].[ImportFieldDefinitions] ([FieldDefId]),
    CONSTRAINT [FK__ImportPOT__fkPOI__66C4EC22] FOREIGN KEY ([fkPOImportId]) REFERENCES [dbo].[ImportPOMain] ([POImportId])
);

