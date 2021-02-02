CREATE TABLE [dbo].[WmDashboardWidgetSetting] (
    [Id]             INT           IDENTITY (1, 1) NOT NULL,
    [DashboardId]    INT           NOT NULL,
    [WidgetId]       INT           NOT NULL,
    [WidgetAlias]    VARCHAR (10)  NULL,
    [RenderPosition] INT           NOT NULL,
    [ColumnNumber]   INT           NOT NULL,
    [CreatedDate]    DATETIME      NULL,
    [ModifiedDate]   DATETIME      NULL,
    [SearchSettings] VARCHAR (MAX) NULL,
    CONSTRAINT [PK_WmDashboardWidgetSetting] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_WmDashboardWidgetSetting_MnxWidget] FOREIGN KEY ([WidgetId]) REFERENCES [dbo].[MnxWidget] ([Id]),
    CONSTRAINT [FK_WmDashboardWidgetSetting_WmDashboardWidgetSetting] FOREIGN KEY ([DashboardId]) REFERENCES [dbo].[MnxDashboard] ([Id])
);

