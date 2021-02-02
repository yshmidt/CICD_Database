CREATE TABLE [dbo].[WmWidgetRelationship] (
    [Id]               INT           IDENTITY (1, 1) NOT NULL,
    [DashboardId]      INT           NOT NULL,
    [WidgetId]         INT           NOT NULL,
    [ParentWidgetId]   INT           NOT NULL,
    [AvailableColumns] VARCHAR (MAX) NULL,
    [DisplayedColumns] VARCHAR (MAX) NULL,
    [SourceType]       BIT           CONSTRAINT [DF_WmWidgetRelationship_SourceType] DEFAULT ((0)) NOT NULL,
    [DataSource]       VARCHAR (100) NULL,
    [WidgetAlias]      VARCHAR (10)  NULL,
    CONSTRAINT [PK_WmWidgetRelationship] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_WmWidgetRelationship_MnxDashboard] FOREIGN KEY ([DashboardId]) REFERENCES [dbo].[MnxDashboard] ([Id]),
    CONSTRAINT [FK_WmWidgetRelationship_MnxWidget] FOREIGN KEY ([ParentWidgetId]) REFERENCES [dbo].[MnxWidget] ([Id]),
    CONSTRAINT [FK_WmWidgetRelationship_MnxWidget1] FOREIGN KEY ([WidgetId]) REFERENCES [dbo].[MnxWidget] ([Id])
);

