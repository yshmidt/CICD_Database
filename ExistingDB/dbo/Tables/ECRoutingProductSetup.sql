CREATE TABLE [dbo].[ECRoutingProductSetup] (
    [uniquerout]     CHAR (10)    NOT NULL,
    [Uniq_key]       CHAR (10)    CONSTRAINT [DF_ECRoutingProductSetup_Uniq_key] DEFAULT ('') NOT NULL,
    [isDefault]      BIT          CONSTRAINT [DF_ECRoutingProductSetup_isDefault] DEFAULT ((0)) NOT NULL,
    [TemplateID]     INT          NOT NULL,
    [UniqEcNo]       VARCHAR (25) NOT NULL,
    [New_Uniquerout] CHAR (10)    CONSTRAINT [DF_ECRoutingProductSetup_uniquerout] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    CONSTRAINT [PK_EcRoutingProductSetup] PRIMARY KEY CLUSTERED ([New_Uniquerout] ASC),
    CONSTRAINT [FK_ECRoutingProductSetup_TemplateID] FOREIGN KEY ([TemplateID]) REFERENCES [dbo].[RoutingTemplate] ([TemplateID])
);

