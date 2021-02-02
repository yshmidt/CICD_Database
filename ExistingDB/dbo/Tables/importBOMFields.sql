CREATE TABLE [dbo].[importBOMFields] (
    [detailId]     UNIQUEIDENTIFIER CONSTRAINT [DF_importBOMFields_detailId] DEFAULT (newsequentialid()) NOT NULL,
    [fkImportId]   UNIQUEIDENTIFIER NOT NULL,
    [rowId]        UNIQUEIDENTIFIER NOT NULL,
    [fkFieldDefId] UNIQUEIDENTIFIER NOT NULL,
    [uniq_key]     VARCHAR (10)     CONSTRAINT [DF_importBOMFields_uniq_key] DEFAULT ('') NOT NULL,
    [lock]         BIT              CONSTRAINT [DF_importBOMFields_lock] DEFAULT ((0)) NOT NULL,
    [original]     NVARCHAR (MAX)   CONSTRAINT [DF_importBOMFields_original] DEFAULT ('') NOT NULL,
    [adjusted]     NVARCHAR (MAX)   CONSTRAINT [DF_importBOMFields_adjusted] DEFAULT ('') NOT NULL,
    [status]       VARCHAR (10)     CONSTRAINT [DF_importBOMFields_status] DEFAULT ('i02fade') NOT NULL,
    [validation]   VARCHAR (10)     CONSTRAINT [DF_importBOMFields_validation] DEFAULT ('00none') NOT NULL,
    [message]      VARCHAR (MAX)    CONSTRAINT [DF_importBOMFields_message] DEFAULT ('') NOT NULL,
    [UseCustPFX]   BIT              CONSTRAINT [DF__importBOM__UseCu__20F0C260] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_importBOMFields] PRIMARY KEY CLUSTERED ([detailId] ASC),
    CONSTRAINT [FK_importBOMFields_importBOMHeader] FOREIGN KEY ([fkImportId]) REFERENCES [dbo].[importBOMHeader] ([importId]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [importid]
    ON [dbo].[importBOMFields]([fkImportId] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [RowField]
    ON [dbo].[importBOMFields]([rowId] ASC, [fkFieldDefId] ASC);


GO
CREATE NONCLUSTERED INDEX [Status]
    ON [dbo].[importBOMFields]([status] ASC);


GO
CREATE NONCLUSTERED INDEX [uniq_key]
    ON [dbo].[importBOMFields]([uniq_key] ASC);

