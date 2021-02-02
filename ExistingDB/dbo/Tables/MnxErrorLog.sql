CREATE TABLE [dbo].[MnxErrorLog] (
    [errRecordId]  BIGINT           IDENTITY (1, 1) NOT NULL,
    [errorCode]    VARCHAR (MAX)    NOT NULL,
    [errorMessage] VARCHAR (MAX)    NOT NULL,
    [userId]       UNIQUEIDENTIFIER NULL,
    [methodName]   VARCHAR (MAX)    NOT NULL,
    [errorDate]    SMALLDATETIME    CONSTRAINT [DF_MnxErrorLog_errorDate] DEFAULT (getdate()) NOT NULL,
    [note]         VARCHAR (MAX)    NOT NULL,
    CONSTRAINT [PK_MnxErrorLog] PRIMARY KEY CLUSTERED ([errRecordId] ASC)
);

