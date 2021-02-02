CREATE TABLE [dbo].[SynchronizationsEnabledApis] (
    [SynchronizationId] INT              IDENTITY (1, 1) NOT NULL,
    [UserId]            UNIQUEIDENTIFIER NOT NULL,
    [APIKey]            NVARCHAR (10)    NOT NULL,
    [IsEnabled]         BIT              NOT NULL,
    [RefreshLogSeconds] INT              CONSTRAINT [DF__Synchroni__Refre__0C73FD10] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_SynchronizationsEnabledApis] PRIMARY KEY CLUSTERED ([SynchronizationId] ASC),
    CONSTRAINT [FK_SynchronizationsEnabledApis_aspnet_Users] FOREIGN KEY ([UserId]) REFERENCES [dbo].[aspnet_Users] ([UserId])
);

