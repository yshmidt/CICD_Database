CREATE TABLE [dbo].[routingProductSetup] (
    [uniquerout] CHAR (10) CONSTRAINT [DF_routingProductSetup_uniquerout] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    [Uniq_key]   CHAR (10) CONSTRAINT [DF_routingProductSetup_Uniq_key] DEFAULT ('') NOT NULL,
    [isDefault]  BIT       CONSTRAINT [DF_routingProductSetup_isDefault] DEFAULT ((0)) NOT NULL,
    [TemplateID] INT       NOT NULL,
    CONSTRAINT [PK_routingProductSetup] PRIMARY KEY CLUSTERED ([uniquerout] ASC),
    CONSTRAINT [FK_routingProductSetup_TemplateID] FOREIGN KEY ([TemplateID]) REFERENCES [dbo].[RoutingTemplate] ([TemplateID])
);


GO
CREATE NONCLUSTERED INDEX [IX_routingProductSetup_1]
    ON [dbo].[routingProductSetup]([Uniq_key] ASC);

