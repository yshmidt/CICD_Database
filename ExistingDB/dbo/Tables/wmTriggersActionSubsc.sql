CREATE TABLE [dbo].[wmTriggersActionSubsc] (
    [fkActTriggerId]   UNIQUEIDENTIFIER NOT NULL,
    [fkUserId]         UNIQUEIDENTIFIER NOT NULL,
    [recordLink]       VARCHAR (50)     CONSTRAINT [DF_MnxTriggersActionSubsc_recordLink] DEFAULT ('') NOT NULL,
    [linkType]         VARCHAR (50)     CONSTRAINT [DF_MnxTriggersActionSubsc_linkType] DEFAULT ('') NOT NULL,
    [notificationType] VARCHAR (20)     CONSTRAINT [DF_wmTriggersActionSubsc_notificationType] DEFAULT ('N') NOT NULL,
    [SubscrId]         INT              IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_wmTriggersActionSubsc] PRIMARY KEY CLUSTERED ([SubscrId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_wmTriggersActionSubsc]
    ON [dbo].[wmTriggersActionSubsc]([fkActTriggerId] ASC, [fkUserId] ASC, [recordLink] ASC, [linkType] ASC);

