CREATE TABLE [dbo].[MnxSynchronizedItems] (
    [SyncItemNumber]     INT        IDENTITY (1, 1) NOT NULL,
    [SynModuleName]      CHAR (20)  NOT NULL,
    [IsSynchronizedItem] BIT        CONSTRAINT [DF_SynchronizedItem_IsSynchronized] DEFAULT ((1)) NOT NULL,
    [SyncModuleDesc]     CHAR (100) NOT NULL,
    [UniqueNum]          INT        NOT NULL,
    CONSTRAINT [PK_MnxSynchronizedItems] PRIMARY KEY CLUSTERED ([SyncItemNumber] ASC)
);

