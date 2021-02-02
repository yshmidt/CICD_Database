CREATE TABLE [dbo].[wmReportsUserFavorites] (
    [fkRptId]  CHAR (10)        NOT NULL,
    [fkUserId] UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_wmReportsUserFavorites] PRIMARY KEY CLUSTERED ([fkRptId] ASC, [fkUserId] ASC)
);

