CREATE TABLE [dbo].[WmRelatedArticles] (
    [ArticleId]     INT           IDENTITY (1, 1) NOT NULL,
    [TextToDisplay] VARCHAR (200) NOT NULL,
    [DocBranchId]   BIGINT        NOT NULL,
    CONSTRAINT [PK_WmRelatedArticles] PRIMARY KEY CLUSTERED ([ArticleId] ASC)
);

