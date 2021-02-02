CREATE TABLE [dbo].[WmFileHistory] (
    [HistoryId]  BIGINT           IDENTITY (1, 1) NOT NULL,
    [FileId]     BIGINT           NOT NULL,
    [UserId]     UNIQUEIDENTIFIER NOT NULL,
    [AccessDate] SMALLDATETIME    NULL,
    [AccessType] VARCHAR (50)     NOT NULL,
    CONSTRAINT [PK_WmFileHistory] PRIMARY KEY CLUSTERED ([HistoryId] ASC),
    CONSTRAINT [FK_WmFileHistory_aspnet_Profile] FOREIGN KEY ([UserId]) REFERENCES [dbo].[aspnet_Profile] ([UserId])
);

