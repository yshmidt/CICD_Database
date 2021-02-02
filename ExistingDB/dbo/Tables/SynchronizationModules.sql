CREATE TABLE [dbo].[SynchronizationModules] (
    [SynchronizationsModuleId] INT IDENTITY (1, 1) NOT NULL,
    [SyncItemNumber]           INT NOT NULL,
    [ModuleSyncEnabled]        BIT NOT NULL,
    [LocationId]               INT NOT NULL,
    CONSTRAINT [PK_SynchronizationModules] PRIMARY KEY CLUSTERED ([SynchronizationsModuleId] ASC)
);

