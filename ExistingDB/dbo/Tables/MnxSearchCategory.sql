CREATE TABLE [dbo].[MnxSearchCategory] (
    [sCategoryId]       INT          IDENTITY (1, 1) NOT NULL,
    [sCatResourceId]    VARCHAR (50) NOT NULL,
    [sCatResourceValue] VARCHAR (50) NOT NULL,
    [listOrder]         INT          NULL,
    [moduleId]          INT          CONSTRAINT [DF_MnxSearchCategory_moduleId] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_MnxSearchGroups] PRIMARY KEY CLUSTERED ([sCategoryId] ASC)
);

