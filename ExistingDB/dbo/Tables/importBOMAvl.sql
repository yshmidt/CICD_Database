CREATE TABLE [dbo].[importBOMAvl] (
    [avlId]        UNIQUEIDENTIFIER CONSTRAINT [DF_importBOMAvl_avlId] DEFAULT (newsequentialid()) NOT NULL,
    [fkImportId]   UNIQUEIDENTIFIER NOT NULL,
    [fkRowId]      UNIQUEIDENTIFIER NOT NULL,
    [fkFieldDefId] UNIQUEIDENTIFIER NOT NULL,
    [avlRowId]     UNIQUEIDENTIFIER NOT NULL,
    [uniqmfgrhd]   VARCHAR (10)     CONSTRAINT [DF_importBOMAvl_uniqmfgrhd] DEFAULT ('') NOT NULL,
    [original]     VARCHAR (MAX)    CONSTRAINT [DF_importBOMAvl_original] DEFAULT ('') NOT NULL,
    [adjusted]     VARCHAR (MAX)    CONSTRAINT [DF_importBOMAvl_adjusted] DEFAULT ('') NOT NULL,
    [bom]          BIT              CONSTRAINT [DF_importBOMAvl_bom] DEFAULT ((0)) NOT NULL,
    [load]         BIT              NULL,
    [status]       VARCHAR (10)     CONSTRAINT [DF_importBOMAvl_status] DEFAULT ('i02fade') NOT NULL,
    [validation]   VARCHAR (10)     CONSTRAINT [DF_importBOMAvl_validation] DEFAULT ('00none') NOT NULL,
    [message]      VARCHAR (MAX)    CONSTRAINT [DF_importBOMAvl_message] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_importBOMAvl] PRIMARY KEY CLUSTERED ([avlId] ASC),
    CONSTRAINT [FK_importBOMAvl_importBOMFieldDefinitions] FOREIGN KEY ([fkFieldDefId]) REFERENCES [dbo].[importBOMFieldDefinitions] ([fieldDefId]),
    CONSTRAINT [FK_importBOMAvl_importBOMHeader] FOREIGN KEY ([fkImportId]) REFERENCES [dbo].[importBOMHeader] ([importId]) ON DELETE CASCADE
);

