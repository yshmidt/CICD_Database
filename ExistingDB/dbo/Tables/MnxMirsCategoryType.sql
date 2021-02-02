CREATE TABLE [dbo].[MnxMirsCategoryType] (
    [CategoryTypeId] INT           IDENTITY (1, 1) NOT NULL,
    [Name]           CHAR (100)    NOT NULL,
    [DataSource]     VARCHAR (MAX) NOT NULL,
    [FkCategoryId]   INT           NOT NULL,
    CONSTRAINT [PK_MnxMirsCategoryType] PRIMARY KEY CLUSTERED ([CategoryTypeId] ASC),
    CONSTRAINT [FK_MnxMirsCategoryType_MnxMirsCategory] FOREIGN KEY ([FkCategoryId]) REFERENCES [dbo].[MnxMirsCategory] ([CategoryId])
);

