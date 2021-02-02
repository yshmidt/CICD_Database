CREATE TABLE [dbo].[importBOMCheckValueAliases] (
    [systemValue]  VARCHAR (50)     NOT NULL,
    [alias]        VARCHAR (200)    NOT NULL,
    [fkFieldDefId] UNIQUEIDENTIFIER NOT NULL,
    [chkvalueid]   CHAR (10)        CONSTRAINT [DF_importBOMCheckValueAliases_chkvalueid] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    CONSTRAINT [PK_importBOMCheckValueAliases] PRIMARY KEY CLUSTERED ([chkvalueid] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_importBOMCheckValueAliases]
    ON [dbo].[importBOMCheckValueAliases]([alias] ASC, [fkFieldDefId] ASC);

