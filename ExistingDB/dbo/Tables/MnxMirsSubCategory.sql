CREATE TABLE [dbo].[MnxMirsSubCategory] (
    [SubCategoryId]   INT            IDENTITY (1, 1) NOT NULL,
    [SubCategoryName] NVARCHAR (150) NOT NULL,
    [CategoryId]      INT            NOT NULL
);

