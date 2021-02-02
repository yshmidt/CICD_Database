CREATE TABLE [dbo].[wmTriggerEventSubscriptions] (
    [subscriptionId] UNIQUEIDENTIFIER CONSTRAINT [DF_WMTriggerEventSubscriptions_subscriptionId] DEFAULT (newid()) NOT NULL,
    [userId]         UNIQUEIDENTIFIER NOT NULL,
    [eventId]        UNIQUEIDENTIFIER NOT NULL,
    [toAddress]      VARCHAR (MAX)    CONSTRAINT [DF_WMTriggerEventSubscriptions_toAddress] DEFAULT ('') NOT NULL,
    [messageBody]    VARCHAR (MAX)    CONSTRAINT [DF_WMTriggerEventSubscriptions_messageBody] DEFAULT ('') NOT NULL,
    [messageSubject] VARCHAR (MAX)    CONSTRAINT [DF_WMTriggerEventSubscriptions_messageSubject] DEFAULT ('System Notification') NOT NULL,
    [noticeType]     VARCHAR (MAX)    CONSTRAINT [DF_WMTriggerEventSubscriptions_noticeType] DEFAULT ('') NOT NULL,
    [selectBase]     VARCHAR (MAX)    CONSTRAINT [DF_WMTriggerEventSubscriptions_selectBase] DEFAULT ('') NOT NULL,
    [filterValue]    VARCHAR (MAX)    CONSTRAINT [DF_WMTriggerEventSubscriptions_filterValue] DEFAULT ('') NOT NULL,
    [isActive]       BIT              CONSTRAINT [DF_WMTriggerEventSubscriptions_isActive] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_WMTriggerEventSubscriptions] PRIMARY KEY CLUSTERED ([subscriptionId] ASC)
);

