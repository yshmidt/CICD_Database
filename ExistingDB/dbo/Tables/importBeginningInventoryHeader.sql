CREATE TABLE [dbo].[importBeginningInventoryHeader] (
    [qtyImportId]    CHAR (10)        CONSTRAINT [DF_importBeginningInventoryHeader_qtyImportId] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    [importUserId]   UNIQUEIDENTIFIER NULL,
    [importDate]     DATETIME         CONSTRAINT [DF_importBeginningInventoryHeader_importDate] DEFAULT (getdate()) NULL,
    [importComplete] BIT              CONSTRAINT [DF_importBeginningInventoryHeader_importComplete] DEFAULT ((0)) NOT NULL,
    [importtype]     CHAR (1)         CONSTRAINT [DF__importBeg__impor__273D01E5] DEFAULT ('P') NOT NULL,
    CONSTRAINT [PK_importBeginningInventoryHeader] PRIMARY KEY CLUSTERED ([qtyImportId] ASC)
);

