CREATE TABLE [dbo].[SynchronizationDeletedRecords] (
    [TableName]        VARCHAR (50)  CONSTRAINT [DF_DeletedRecordsLog_TableName] DEFAULT ('') NOT NULL,
    [TableKey]         VARCHAR (20)  CONSTRAINT [DF_DeletedRecordsLog_TableKey] DEFAULT ('') NOT NULL,
    [TableKeyValue]    VARCHAR (36)  CONSTRAINT [DF_DeletedRecordsLog_TableKeyValue] DEFAULT ('') NOT NULL,
    [LogDate]          SMALLDATETIME CONSTRAINT [DF_DeletedRecordsLog_LogDate] DEFAULT (getdate()) NULL,
    [DeletedRecordLog] BIGINT        IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_DeletedRecordsLog] PRIMARY KEY CLUSTERED ([DeletedRecordLog] ASC)
);


GO
CREATE NONCLUSTERED INDEX [LogDate]
    ON [dbo].[SynchronizationDeletedRecords]([LogDate] ASC);


GO
CREATE NONCLUSTERED INDEX [TableName]
    ON [dbo].[SynchronizationDeletedRecords]([TableName] ASC);

