CREATE TABLE [dbo].[transferInternalInventory2Consign] (
    [uniq_key]   CHAR (10)       CONSTRAINT [DF_transferInternalInventory2Consign_uniq_key] DEFAULT ('') NOT NULL,
    [part_no]    CHAR (25)       CONSTRAINT [DF_transferInternalInventory2Consign_part_no] DEFAULT ('') NOT NULL,
    [revision]   CHAR (8)        CONSTRAINT [DF_transferInternalInventory2Consign_revision] DEFAULT ('') NOT NULL,
    [part_sourc] CHAR (10)       CONSTRAINT [DF_transferInternalInventory2Consign_part_sourc] DEFAULT ('') NOT NULL,
    [warehouse]  CHAR (10)       CONSTRAINT [DF_transferInternalInventory2Consign_warehouse] DEFAULT ('') NOT NULL,
    [w_key]      CHAR (10)       CONSTRAINT [DF_transferInternalInventory2Consign_w_key] DEFAULT ('') NOT NULL,
    [location]   CHAR (17)       CONSTRAINT [DF_transferInternalInventory2Consign_location] DEFAULT ('') NOT NULL,
    [qty_oh]     NUMERIC (12, 2) CONSTRAINT [DF_transferInternalInventory2Consign_qty_oh] DEFAULT ((0.0)) NOT NULL,
    [reserved]   NUMERIC (12, 2) CONSTRAINT [DF_transferInternalInventory2Consign_reserved] DEFAULT ((0.00)) NOT NULL,
    [partmfgr]   CHAR (8)        CONSTRAINT [DF_transferInternalInventory2Consign_partmfgr] DEFAULT ('') NOT NULL,
    [mfgr_pt_no] CHAR (30)       CONSTRAINT [DF_transferInternalInventory2Consign_mfgr_pt_no] DEFAULT ('') NOT NULL,
    [custname]   CHAR (35)       CONSTRAINT [DF_transferInternalInventory2Consign_custname] DEFAULT ('') NOT NULL,
    [custpartno] CHAR (25)       CONSTRAINT [DF_transferInternalInventory2Consign_custpartno] DEFAULT ('') NOT NULL,
    [custrev]    CHAR (8)        CONSTRAINT [DF_transferInternalInventory2Consign_custrev] DEFAULT ('') NOT NULL,
    [uniquerec]  CHAR (10)       CONSTRAINT [DF_transferInternalInventory2Consign_uniquerec] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL
);

