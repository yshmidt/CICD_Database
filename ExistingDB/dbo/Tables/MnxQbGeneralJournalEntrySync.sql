CREATE TABLE [dbo].[MnxQbGeneralJournalEntrySync] (
    [Id]            INT          IDENTITY (1, 1) NOT NULL,
    [SyncTableName] VARCHAR (20) NOT NULL,
    [SyncProcName]  VARCHAR (30) NOT NULL,
    [SyncKeyName]   VARCHAR (20) NOT NULL,
    [CanSync]       BIT          CONSTRAINT [DF_MnxQbGeneralJournalEntrySync_CanSync] DEFAULT ((0)) NOT NULL,
    [ModuleName]    VARCHAR (50) NULL,
    CONSTRAINT [PK_MnxQbGeneralJournalEntrySync] PRIMARY KEY CLUSTERED ([Id] ASC)
);

