CREATE TABLE [dbo].[MnxGenericFormDataSource] (
    [DataSourceId]   INT           IDENTITY (1, 1) NOT NULL,
    [fkFormColumnId] INT           NOT NULL,
    [DataSourceName] VARCHAR (MAX) NOT NULL,
    CONSTRAINT [PK_GenericFormDataSource_1] PRIMARY KEY CLUSTERED ([DataSourceId] ASC),
    CONSTRAINT [FK_GenericFormDataSource_GenericFormColumns] FOREIGN KEY ([fkFormColumnId]) REFERENCES [dbo].[MnxGenericFormColumns] ([FieldId])
);

