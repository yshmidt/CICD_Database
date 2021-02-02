CREATE TABLE [dbo].[MnxGenericFormTables] (
    [FormTableId]        INT          IDENTITY (1, 1) NOT NULL,
    [fkGenericFormId]    INT          NOT NULL,
    [TableName]          VARCHAR (50) NOT NULL,
    [TableUniqueCol]     VARCHAR (50) NULL,
    [TableUniqueColType] VARCHAR (50) NULL,
    CONSTRAINT [PK_mnxGenericFormTables] PRIMARY KEY CLUSTERED ([FormTableId] ASC),
    CONSTRAINT [FK_GenericFormTables_GenericForm] FOREIGN KEY ([fkGenericFormId]) REFERENCES [dbo].[MnxGenericForm] ([GenericFormId])
);

