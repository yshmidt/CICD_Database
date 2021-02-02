CREATE TABLE [dbo].[KendoGridFilterData] (
    [ID]              INT              IDENTITY (1, 1) NOT NULL,
    [UserId]          UNIQUEIDENTIFIER NOT NULL,
    [GridId]          NVARCHAR (200)   NOT NULL,
    [FilterString]    NVARCHAR (MAX)   CONSTRAINT [DF__KendoGrid__Filte__76115153] DEFAULT ('') NOT NULL,
    [ShortExpression] NVARCHAR (MAX)   CONSTRAINT [DF__KendoGrid__Short__7705758C] DEFAULT ('') NOT NULL,
    [GridOptions]     NVARCHAR (MAX)   CONSTRAINT [DF__KendoGrid__GridO__77F999C5] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_KendoGridFilterData] PRIMARY KEY CLUSTERED ([ID] ASC)
);

