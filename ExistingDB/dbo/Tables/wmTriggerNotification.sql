CREATE TABLE [dbo].[wmTriggerNotification] (
    [messageId]             UNIQUEIDENTIFIER CONSTRAINT [DF_WMTriggerNotification_noticeId] DEFAULT (newsequentialid()) NOT NULL,
    [noticeType]            VARCHAR (50)     CONSTRAINT [DF_WMTriggerNotification_noticeType] DEFAULT ('') NOT NULL,
    [recipientId]           UNIQUEIDENTIFIER NOT NULL,
    [senderId]              UNIQUEIDENTIFIER CONSTRAINT [DF_WMTriggerNotification_senderId] DEFAULT ('00000000-0000-0000-0000-000000000000') NOT NULL,
    [emailId]               UNIQUEIDENTIFIER CONSTRAINT [DF_WMTriggerNotification_emailId] DEFAULT ('00000000-0000-0000-0000-000000000000') NOT NULL,
    [subject]               VARCHAR (200)    CONSTRAINT [DF_WMTriggerNotification_subject] DEFAULT ('') NOT NULL,
    [body]                  VARCHAR (MAX)    CONSTRAINT [DF_WMTriggerNotification_body] DEFAULT ('') NOT NULL,
    [dateAdded]             SMALLDATETIME    NULL,
    [dateRead]              SMALLDATETIME    NULL,
    [dateRemind]            SMALLDATETIME    NULL,
    [triggerId]             UNIQUEIDENTIFIER NOT NULL,
    [dateFirstRead]         SMALLDATETIME    NULL,
    [flagType]              VARCHAR (12)     CONSTRAINT [DF_WMTriggerNotification_flagType] DEFAULT ('flagGray') NOT NULL,
    [notificationValues]    VARCHAR (MAX)    CONSTRAINT [DF_WMTriggerNotification_notificationValues] DEFAULT ('') NOT NULL,
    [isRequestNotification] BIT              CONSTRAINT [DF__wmTrigger__isReq__68968F4D] DEFAULT ((0)) NULL,
    [ModuleId]              INT              CONSTRAINT [DF__wmTrigger__Modul__698AB386] DEFAULT ((0)) NULL,
    [RecordId]              CHAR (100)       NULL,
    [IsCAR]                 BIT              CONSTRAINT [DF__wmTrigger__IsCAR__18EFADE5] DEFAULT ((0)) NULL,
    [ModuleRoute]           VARCHAR (100)    CONSTRAINT [DF__wmTrigger__Modul__3A075444] DEFAULT ('') NULL,
    CONSTRAINT [PK_WMTriggerNotifications] PRIMARY KEY CLUSTERED ([messageId] ASC)
);

