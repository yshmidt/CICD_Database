CREATE TABLE [dbo].[MnxTriggersAction] (
    [actTriggerId]      UNIQUEIDENTIFIER CONSTRAINT [DF_MnxTriggersAction_actTriggerId] DEFAULT (newid()) NOT NULL,
    [triggerName]       VARCHAR (50)     CONSTRAINT [DF_MnxTriggersAction_triggerName] DEFAULT ('') NOT NULL,
    [relatedTable]      VARCHAR (100)    CONSTRAINT [DF_MnxTriggersAction_relatedTable] DEFAULT ('') NOT NULL,
    [actionDescription] VARCHAR (100)    CONSTRAINT [DF_MnxTriggersAction_actionDescription] DEFAULT ('') NOT NULL,
    [bodyTemplate]      VARCHAR (MAX)    CONSTRAINT [DF_MnxTriggersAction_bodyTemplate] DEFAULT ('') NOT NULL,
    [subjectTemplate]   VARCHAR (MAX)    CONSTRAINT [DF_MnxTriggersAction_subjectTemplate] DEFAULT ('') NOT NULL,
    [summaryTemplate]   VARCHAR (MAX)    CONSTRAINT [DF_MnxTriggersAction_summaryTemplate] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_MnxTriggersAction] PRIMARY KEY CLUSTERED ([actTriggerId] ASC)
);

