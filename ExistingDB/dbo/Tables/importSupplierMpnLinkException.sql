CREATE TABLE [dbo].[importSupplierMpnLinkException] (
    [importid]     UNIQUEIDENTIFIER NOT NULL,
    [rowId]        UNIQUEIDENTIFIER NOT NULL,
    [Partmfgr]     VARCHAR (MAX)    CONSTRAINT [DF_importSupplierMpnLinkException_Partmfgr] DEFAULT ('') NOT NULL,
    [Mfgr_pt_no]   VARCHAR (MAX)    CONSTRAINT [DF_importSupplierMpnLinkException_Mfgr_pt_no] DEFAULT ('') NOT NULL,
    [SupName]      VARCHAR (MAX)    CONSTRAINT [DF_importSupplierMpnLinkException_SupName] DEFAULT ('') NOT NULL,
    [SUPLPARTNO]   VARCHAR (MAX)    CONSTRAINT [DF_importSupplierMpnLinkException_SUPLPARTNO] DEFAULT ('') NOT NULL,
    [importDate]   SMALLDATETIME    CONSTRAINT [DF__importSup__impor__4047DB7A] DEFAULT (getdate()) NULL,
    [exceptionMsg] VARCHAR (90)     CONSTRAINT [DF_importSupplierMpnLinkException_exceptionMsg] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_importSupplierMpnLinkException] PRIMARY KEY CLUSTERED ([importid] ASC, [rowId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_exceptionDate]
    ON [dbo].[importSupplierMpnLinkException]([importDate] ASC);

