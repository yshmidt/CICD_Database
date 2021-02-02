CREATE TABLE [dbo].[SynchronizationMultiLocationLog] (
    [UniqueKey]             BIGINT        IDENTITY (1, 1) NOT NULL,
    [UniqueNum]             VARCHAR (64)  NOT NULL,
    [SyncModuleName]        NVARCHAR (50) CONSTRAINT [DF_SynchronizationMultiLocationLog_SyncModuleName] DEFAULT ('') NOT NULL,
    [LocationId]            INT           NOT NULL,
    [OperationName]         CHAR (100)    NOT NULL,
    [IsSynchronizationFlag] BIT           CONSTRAINT [DF_SynchronizationMultiLocationLog_IsSynchronizationFlag] DEFAULT ((0)) NOT NULL,
    [IsBomSynchronized]     BIT           CONSTRAINT [DF__Synchroni__IsBom__16FBAD24] DEFAULT ((0)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [DF__Synchroni__IsDel__2594B095] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_SynchronizationMultiLocationLog] PRIMARY KEY CLUSTERED ([UniqueKey] ASC)
);

