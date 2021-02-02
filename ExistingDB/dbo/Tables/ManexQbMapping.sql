CREATE TABLE [dbo].[ManexQbMapping] (
    [MappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [MnxId]     VARCHAR (36)  NOT NULL,
    [QbId]      VARCHAR (36)  NOT NULL,
    [TableName] VARCHAR (100) NOT NULL,
    [QbName]    VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_ManexQbMapping] PRIMARY KEY CLUSTERED ([MappingId] ASC)
);

