CREATE TABLE [dbo].[UserActivityLog] (
    [sessionId]       VARCHAR (50)     NOT NULL,
    [fkuserId]        UNIQUEIDENTIFIER NOT NULL,
    [moduleid]        VARCHAR (50)     NULL,
    [ipAddress]       VARCHAR (50)     NULL,
    [workStationId]   VARCHAR (MAX)    NULL,
    [pkActivityLog]   UNIQUEIDENTIFIER CONSTRAINT [DF_UserActivityLog_pkActivityLog] DEFAULT (newsequentialid()) NOT NULL,
    [startActivityDt] DATETIME         NULL,
    [endActivityDt]   DATETIME         NULL,
    CONSTRAINT [PK_UserActivityLog] PRIMARY KEY CLUSTERED ([pkActivityLog] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_UserActivityLog]
    ON [dbo].[UserActivityLog]([sessionId] ASC, [fkuserId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_UserActivityLog_1]
    ON [dbo].[UserActivityLog]([moduleid] ASC);

