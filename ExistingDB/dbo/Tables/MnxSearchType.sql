CREATE TABLE [dbo].[MnxSearchType] (
    [sTypeId]            INT          IDENTITY (1, 1) NOT NULL,
    [sTypeResourceId]    VARCHAR (50) NOT NULL,
    [sTypeResourceValue] VARCHAR (50) NOT NULL,
    [fksCategoryId]      INT          NOT NULL,
    [listOrder]          INT          NOT NULL,
    CONSTRAINT [PK_MnxSearchType] PRIMARY KEY CLUSTERED ([sTypeId] ASC),
    CONSTRAINT [FK_MnxSearchType_MnxSearchType] FOREIGN KEY ([sTypeId]) REFERENCES [dbo].[MnxSearchType] ([sTypeId])
);

