CREATE TABLE [dbo].[InventorLotChangeLog] (
    [uniq_key]      CHAR (10)        CONSTRAINT [DF_InventorLotChangeLog_uniq_key] DEFAULT ('') NOT NULL,
    [oldLotdetail]  BIT              CONSTRAINT [DF_InventorLotChangeLog_oldLotdetail] DEFAULT ((0)) NOT NULL,
    [newLotDetail]  BIT              CONSTRAINT [DF_InventorLotChangeLog_newLotDetail] DEFAULT ((0)) NOT NULL,
    [userid]        UNIQUEIDENTIFIER NULL,
    [changeDate]    DATETIME         CONSTRAINT [DF_InventorLotChangeLog_changeDate] DEFAULT (getdate()) NULL,
    [lotChageLogId] CHAR (10)        CONSTRAINT [DF_InventorLotChangeLog_lotChageLogId] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    CONSTRAINT [PK_InventorLotChangeLog] PRIMARY KEY CLUSTERED ([lotChageLogId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_InventorLotChangeLog]
    ON [dbo].[InventorLotChangeLog]([uniq_key] ASC);

