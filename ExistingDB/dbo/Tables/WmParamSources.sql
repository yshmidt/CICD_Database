CREATE TABLE [dbo].[WmParamSources] (
    [sourceName] VARCHAR (50)  NOT NULL,
    [sourceType] VARCHAR (MAX) NULL,
    [dataSource] VARCHAR (MAX) NULL,
    [bigData]    BIT           CONSTRAINT [wmDF_WmParamSources_bigData] DEFAULT ((0)) NOT NULL,
    [SortBy]     VARCHAR (50)  CONSTRAINT [wmDF_WmParamSources_SortBy] DEFAULT ('') NOT NULL,
    CONSTRAINT [wmPK_reportParamSources] PRIMARY KEY CLUSTERED ([sourceName] ASC)
);

