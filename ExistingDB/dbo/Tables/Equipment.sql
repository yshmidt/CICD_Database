CREATE TABLE [dbo].[Equipment] (
    [EquipmentId]   CHAR (10) NOT NULL,
    [UNIQ_KEY]      CHAR (10) NOT NULL,
    [DEPT_ID]       CHAR (10) NOT NULL,
    [UNIQNUMBER]    CHAR (10) NOT NULL,
    [WcEquipmentId] INT       NOT NULL,
    [TemplateId]    INT       NULL,
    CONSTRAINT [PK_Equipment] PRIMARY KEY CLUSTERED ([EquipmentId] ASC),
    CONSTRAINT [FK_Equipment_Equipment] FOREIGN KEY ([WcEquipmentId]) REFERENCES [dbo].[WcEquipment] ([WcEquipmentId]),
    CONSTRAINT [FK_Equipment_TemplateId] FOREIGN KEY ([TemplateId]) REFERENCES [dbo].[RoutingTemplate] ([TemplateID])
);

