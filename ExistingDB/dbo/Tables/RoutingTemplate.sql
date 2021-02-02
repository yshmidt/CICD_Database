CREATE TABLE [dbo].[RoutingTemplate] (
    [TemplateID]   INT              IDENTITY (1, 1) NOT NULL,
    [TemplateName] NVARCHAR (100)   NOT NULL,
    [TemplateType] NVARCHAR (100)   NOT NULL,
    [UserID]       UNIQUEIDENTIFIER NOT NULL,
    [UpdateDate]   DATETIME         NOT NULL,
    [IsDefault]    BIT              NOT NULL,
    CONSTRAINT [PK_RoutingTemplate] PRIMARY KEY CLUSTERED ([TemplateID] ASC)
);

