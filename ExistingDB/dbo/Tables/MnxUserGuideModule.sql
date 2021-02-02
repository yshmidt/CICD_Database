CREATE TABLE [dbo].[MnxUserGuideModule] (
    [UserGuideModuleId]    INT           IDENTITY (1, 1) NOT NULL,
    [UserGuideModuleName]  VARCHAR (100) NOT NULL,
    [UserGuideModuleRoute] VARCHAR (200) NOT NULL,
    [ModuleCss]            VARCHAR (40)  NULL,
    [RenderNumber]         INT           NULL,
    CONSTRAINT [PK__MnxUserG__38DA9E53C2C3C9E6] PRIMARY KEY CLUSTERED ([UserGuideModuleId] ASC)
);

