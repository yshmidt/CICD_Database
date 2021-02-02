CREATE TABLE [dbo].[SynchronizationConnections] (
    [LocationId]      INT            IDENTITY (1, 1) NOT NULL,
    [LocationName]    NVARCHAR (25)  NOT NULL,
    [RootUrl]         NVARCHAR (100) NOT NULL,
    [ApiKey]          NVARCHAR (10)  NOT NULL,
    [HomeCurrency]    NVARCHAR (50)  NOT NULL,
    [DivisionNumber]  VARCHAR (2)    NULL,
    [LocalSyncEnbled] BIT            CONSTRAINT [DF_SynchronizationConnections_LocalSyncEnbled] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_SynchronizationConnections] PRIMARY KEY CLUSTERED ([LocationId] ASC)
);

