CREATE TABLE [dbo].[MnxTriggerEvents] (
    [eventId]           UNIQUEIDENTIFIER CONSTRAINT [DF_MnxTriggerEvents_eventId] DEFAULT (newsequentialid()) NOT NULL,
    [eventName]         VARCHAR (100)    CONSTRAINT [DF_MnxTriggerEvents_eventName] DEFAULT ('') NOT NULL,
    [eventSection]      VARCHAR (100)    CONSTRAINT [DF_MnxTriggerEvents_eventSection] DEFAULT ('System') NOT NULL,
    [eventSelectBase]   VARCHAR (MAX)    CONSTRAINT [DF_MnxTriggerEvents_eventSelectBase] DEFAULT ('') NOT NULL,
    [bodyTemplate]      VARCHAR (MAX)    CONSTRAINT [DF_MnxTriggerEvents_bodyTemplate] DEFAULT ('') NOT NULL,
    [subjectTemplate]   VARCHAR (MAX)    CONSTRAINT [DF_MnxTriggerEvents_subjectTemplate] DEFAULT ('') NOT NULL,
    [noticeTypeDefault] VARCHAR (MAX)    CONSTRAINT [DF_MnxTriggerEvents_noticeTypeDefault] DEFAULT ('Notification') NOT NULL,
    CONSTRAINT [PK_MnxTriggerEvents] PRIMARY KEY CLUSTERED ([eventId] ASC)
);

