CREATE TABLE [dbo].[MnxParamSources] (
    [sourceName] VARCHAR (50)  NOT NULL,
    [sourceType] VARCHAR (MAX) NULL,
    [dataSource] VARCHAR (MAX) NULL,
    [bigData]    BIT           CONSTRAINT [DF_MnxParamSources_bigData] DEFAULT ((0)) NOT NULL,
    [SortBy]     VARCHAR (50)  CONSTRAINT [DF_MnxParamSources_SortBy] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_reportParamSources] PRIMARY KEY CLUSTERED ([sourceName] ASC)
);

