CREATE TABLE [dbo].[MnxWFMetaData] (
    [MetaDataId]         CHAR (10)     NOT NULL,
    [MetaDataName]       CHAR (25)     NOT NULL,
    [TableName]          CHAR (50)     NOT NULL,
    [ColumnName]         CHAR (50)     NOT NULL,
    [ModuleId]           INT           NOT NULL,
    [RequestForLabelKey] CHAR (500)    NOT NULL,
    [Source]             VARCHAR (MAX) NULL,
    CONSTRAINT [PK_MnxWFMetaData] PRIMARY KEY CLUSTERED ([MetaDataId] ASC),
    CONSTRAINT [FK_MnxWFMetaData_MnxWFMetaData] FOREIGN KEY ([ModuleId]) REFERENCES [dbo].[MnxModule] ([ModuleId])
);

