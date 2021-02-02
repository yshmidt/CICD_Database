CREATE TABLE [dbo].[fileManagerAccessLog] (
    [fileAccessId] UNIQUEIDENTIFIER CONSTRAINT [DF_fileManagerAccessLog_fileAccessId] DEFAULT (newsequentialid()) NOT NULL,
    [fileId]       UNIQUEIDENTIFIER NOT NULL,
    [userId]       UNIQUEIDENTIFIER NOT NULL,
    [accessDate]   SMALLDATETIME    NOT NULL,
    [userIP]       VARCHAR (20)     CONSTRAINT [DF_fileManagerAccessLog_userIP] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_fileManagerAccessLog] PRIMARY KEY CLUSTERED ([fileAccessId] ASC)
);

