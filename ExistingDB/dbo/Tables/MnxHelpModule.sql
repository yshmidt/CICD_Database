CREATE TABLE [dbo].[MnxHelpModule] (
    [ModuleId]      INT           NOT NULL,
    [Description]   VARCHAR (100) NOT NULL,
    [LoadAllSteps]  BIT           CONSTRAINT [DF_MnxHelpModule_LoadAllSteps] DEFAULT ((0)) NOT NULL,
    [ShowOnStartUp] BIT           CONSTRAINT [DF_MnxHelpModule_ShowOnStartUp] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_MnxHelpModule] PRIMARY KEY CLUSTERED ([ModuleId] ASC)
);

