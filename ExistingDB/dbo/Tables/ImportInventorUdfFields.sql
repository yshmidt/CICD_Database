CREATE TABLE [dbo].[ImportInventorUdfFields] (
    [DetailId]   UNIQUEIDENTIFIER CONSTRAINT [DF__ImportInv__Detai__7F1176FF] DEFAULT (newid()) ROWGUIDCOL NOT NULL,
    [FkImportId] UNIQUEIDENTIFIER NOT NULL,
    [RowId]      UNIQUEIDENTIFIER NOT NULL,
    [FieldName]  NVARCHAR (MAX)   NULL,
    [Original]   NVARCHAR (MAX)   CONSTRAINT [DF__ImportInv__Origi__00F9BF71] DEFAULT ('') NULL,
    [Adjusted]   NVARCHAR (MAX)   CONSTRAINT [DF__ImportInv__Adjus__01EDE3AA] DEFAULT ('') NULL,
    [Status]     VARCHAR (50)     NULL,
    [Message]    NVARCHAR (MAX)   CONSTRAINT [DF__ImportInv__Messa__02E207E3] DEFAULT ('') NOT NULL,
    [Validation] VARCHAR (100)    CONSTRAINT [DF__ImportInv__Valid__03D62C1C] DEFAULT ('') NOT NULL,
    [DataType]   VARCHAR (10)     NULL,
    CONSTRAINT [PK__ImportIn__135C316D6AF61263] PRIMARY KEY CLUSTERED ([DetailId] ASC),
    CONSTRAINT [FK__ImportInv__FkImp__00059B38] FOREIGN KEY ([FkImportId]) REFERENCES [dbo].[ImportInventorUdfHeader] ([ImportId])
);

