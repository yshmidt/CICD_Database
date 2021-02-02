CREATE TABLE [dbo].[SynchronizationMasterLog] (
    [SyncRecordId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [LocationId]       INT             NOT NULL,
    [SyncModuleName]   NVARCHAR (150)  NOT NULL,
    [SyncAddDate]      DATETIME        NOT NULL,
    [LogUniqueKey]     VARCHAR (64)    NULL,
    [StatusMessage]    CHAR (150)      NOT NULL,
    [ExceptionMessage] NVARCHAR (1000) CONSTRAINT [DF__Synchroni__Excep__0D682149] DEFAULT (NULL) NULL,
    [OperationName]    CHAR (100)      CONSTRAINT [DF__Synchroni__Opera__0F5069BB] DEFAULT (NULL) NULL,
    [SyncLogFor]       VARCHAR (50)    NULL,
    CONSTRAINT [PK_SynchronizationMaster] PRIMARY KEY CLUSTERED ([SyncRecordId] ASC),
    CONSTRAINT [FK_SynchronizationMaster_SynchronizationMaster] FOREIGN KEY ([SyncRecordId]) REFERENCES [dbo].[SynchronizationMasterLog] ([SyncRecordId])
);

