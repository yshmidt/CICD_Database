CREATE TABLE [dbo].[importBeginningInventorySerial] (
    [qtyImportDetailId] CHAR (10) CONSTRAINT [DF_importBeginningInventorySerial_qtyImportDetailId] DEFAULT ('') NOT NULL,
    [SerialInvtId]      CHAR (10) CONSTRAINT [DF_importBeginningInventorySerial_SerialInvtId] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    [w_key]             CHAR (10) CONSTRAINT [DF_importBeginningInventorySerial_w_key] DEFAULT ('') NOT NULL,
    [serialno]          CHAR (30) CONSTRAINT [DF_importBeginningInventorySerial_serialno] DEFAULT ('') NOT NULL,
    [Woreserved]        CHAR (1)  CONSTRAINT [DF__importBeg__Wores__2831261E] DEFAULT ('') NOT NULL,
    [Projreserved]      CHAR (1)  CONSTRAINT [DF__importBeg__Projr__29254A57] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_importBeginningInventorySerial] PRIMARY KEY CLUSTERED ([SerialInvtId] ASC)
);

