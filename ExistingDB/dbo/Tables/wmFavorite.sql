CREATE TABLE [dbo].[wmFavorite] (
    [FavoriteId] INT              IDENTITY (1, 1) NOT NULL,
    [fkUserId]   UNIQUEIDENTIFIER NOT NULL,
    [fkModuleId] INT              NOT NULL,
    [ModulePath] NVARCHAR (100)   NOT NULL,
    CONSTRAINT [PK_mnxFavorite] PRIMARY KEY CLUSTERED ([FavoriteId] ASC),
    CONSTRAINT [FK_mnxFavorite_aspnet_Profile] FOREIGN KEY ([fkUserId]) REFERENCES [dbo].[aspnet_Profile] ([UserId]),
    CONSTRAINT [FK_mnxFavorite_MnxModule] FOREIGN KEY ([fkModuleId]) REFERENCES [dbo].[MnxModule] ([ModuleId])
);

