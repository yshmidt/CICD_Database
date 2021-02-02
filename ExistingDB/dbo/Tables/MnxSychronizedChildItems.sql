CREATE TABLE [dbo].[MnxSychronizedChildItems] (
    [UniqueNumber]   INT       IDENTITY (1000, 1) NOT NULL,
    [SubModuleName]  CHAR (20) NOT NULL,
    [SyncItemNumber] INT       NOT NULL,
    CONSTRAINT [PK_MnxSychronizedChildItems] PRIMARY KEY CLUSTERED ([UniqueNumber] ASC),
    CONSTRAINT [FK_MnxSychronizedChildItems_MnxSynchronizedItems] FOREIGN KEY ([SyncItemNumber]) REFERENCES [dbo].[MnxSynchronizedItems] ([SyncItemNumber])
);

