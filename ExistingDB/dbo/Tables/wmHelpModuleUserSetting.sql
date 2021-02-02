CREATE TABLE [dbo].[wmHelpModuleUserSetting] (
    [ModuleId] INT              NOT NULL,
    [UserId]   UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_wmlUserRootURLSettings] PRIMARY KEY CLUSTERED ([ModuleId] ASC, [UserId] ASC)
);

