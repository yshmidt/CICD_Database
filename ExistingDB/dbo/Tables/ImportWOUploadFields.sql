CREATE TABLE [dbo].[ImportWOUploadFields] (
    [DetailId]   UNIQUEIDENTIFIER CONSTRAINT [DF__ImportWOU__Detai__0E88C4B9] DEFAULT (newid()) ROWGUIDCOL NOT NULL,
    [FkImportId] UNIQUEIDENTIFIER NOT NULL,
    [RowId]      UNIQUEIDENTIFIER NOT NULL,
    [FieldName]  NVARCHAR (MAX)   NULL,
    [Original]   NVARCHAR (MAX)   CONSTRAINT [DF__ImportWOU__Origi__10710D2B] DEFAULT ('') NULL,
    [Adjusted]   NVARCHAR (MAX)   CONSTRAINT [DF__ImportWOU__Adjus__11653164] DEFAULT ('') NULL,
    [Status]     VARCHAR (50)     NULL,
    [Message]    NVARCHAR (MAX)   CONSTRAINT [DF__ImportWOU__Messa__1259559D] DEFAULT ('') NOT NULL,
    [Validation] VARCHAR (100)    CONSTRAINT [DF__ImportWOU__Valid__134D79D6] DEFAULT ('') NOT NULL,
    [DataType]   VARCHAR (10)     NULL,
    CONSTRAINT [PK__ImportWO__135C316D9EB10308] PRIMARY KEY CLUSTERED ([DetailId] ASC),
    CONSTRAINT [FK__ImportWOU__FkImp__0F7CE8F2] FOREIGN KEY ([FkImportId]) REFERENCES [dbo].[ImportWOUploadHeader] ([ImportId])
);

