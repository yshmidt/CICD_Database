CREATE TABLE [dbo].[ImportPODetails] (
    [PODetailId]   UNIQUEIDENTIFIER CONSTRAINT [DF__ImportPOD__PODet__54A63BE7] DEFAULT (newsequentialid()) NOT NULL,
    [fkPOImportId] UNIQUEIDENTIFIER NOT NULL,
    [RowId]        UNIQUEIDENTIFIER NOT NULL,
    [fkFieldDefId] UNIQUEIDENTIFIER NOT NULL,
    [UniqLnNo]     VARCHAR (10)     NULL,
    [Original]     NVARCHAR (MAX)   NOT NULL,
    [Adjusted]     NVARCHAR (MAX)   NOT NULL,
    [Status]       VARCHAR (10)     CONSTRAINT [DF__ImportPOD__Statu__559A6020] DEFAULT ('') NOT NULL,
    [Validation]   VARCHAR (10)     CONSTRAINT [DF__ImportPOD__Valid__568E8459] DEFAULT ('') NOT NULL,
    [Message]      NVARCHAR (MAX)   NULL,
    CONSTRAINT [PK__ImportPO__4EB47B3E0BCF6253] PRIMARY KEY CLUSTERED ([PODetailId] ASC),
    CONSTRAINT [FK__ImportPOD__fkFie__5876CCCB] FOREIGN KEY ([fkFieldDefId]) REFERENCES [dbo].[ImportFieldDefinitions] ([FieldDefId]),
    CONSTRAINT [FK__ImportPOD__fkPOI__5782A892] FOREIGN KEY ([fkPOImportId]) REFERENCES [dbo].[ImportPOMain] ([POImportId])
);

