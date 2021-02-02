CREATE TABLE [dbo].[MnxQbSyncModules] (
    [SyncModuleName]      VARCHAR (50) NOT NULL,
    [QbModuleName]        VARCHAR (50) NOT NULL,
    [SyncModuleId]        INT          IDENTITY (1, 1) NOT NULL,
    [SyncModuleTableName] VARCHAR (50) NULL,
    [CanSyncToQb]         BIT          CONSTRAINT [DF_QbSyncModules_CanSyncToQb] DEFAULT ((1)) NOT NULL,
    [CanChangeMappings]   BIT          CONSTRAINT [DF_MnxQbSyncModules_CanChangeMappings] DEFAULT ((1)) NOT NULL,
    [ModuleOrder]         INT          CONSTRAINT [DF_MnxQbSyncModules_Order] DEFAULT ((1)) NULL,
    [ShowMenu]            BIT          CONSTRAINT [DF_MnxQbSyncModules_ShowMenu] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_QbSyncModules_1] PRIMARY KEY CLUSTERED ([SyncModuleId] ASC)
);

