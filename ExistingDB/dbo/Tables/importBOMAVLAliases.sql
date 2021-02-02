CREATE TABLE [dbo].[importBOMAVLAliases] (
    [partMfg]    VARCHAR (8)  NOT NULL,
    [alias]      VARCHAR (50) NOT NULL,
    [mfgAliasId] INT          IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_importBOMAVLAliases_1] PRIMARY KEY CLUSTERED ([mfgAliasId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_importBOMAVLAliases]
    ON [dbo].[importBOMAVLAliases]([partMfg] ASC, [alias] ASC);

