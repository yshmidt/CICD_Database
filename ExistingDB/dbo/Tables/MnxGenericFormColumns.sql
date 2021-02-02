CREATE TABLE [dbo].[MnxGenericFormColumns] (
    [FieldId]        INT            IDENTITY (1, 1) NOT NULL,
    [fkFormId]       INT            NOT NULL,
    [fkTableId]      INT            NOT NULL,
    [ColumnName]     VARCHAR (50)   NOT NULL,
    [Type]           VARCHAR (50)   NOT NULL,
    [Title]          VARCHAR (50)   NULL,
    [IsRequire]      BIT            NULL,
    [MaxLength]      INT            NULL,
    [CanShow]        BIT            NULL,
    [JsFunctionName] NVARCHAR (200) CONSTRAINT [DF__MnxGeneri__JsFun__7D128946] DEFAULT (N'') NULL,
    CONSTRAINT [PK_GenericFormColumns] PRIMARY KEY CLUSTERED ([FieldId] ASC),
    CONSTRAINT [FK_GenericFormColumns_GenericForm] FOREIGN KEY ([fkFormId]) REFERENCES [dbo].[MnxGenericForm] ([GenericFormId])
);

