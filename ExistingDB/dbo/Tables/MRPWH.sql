﻿CREATE TABLE [dbo].[MRPWH] (
    [UNIQ_KEY]   CHAR (10)       CONSTRAINT [DF__MRPWH__UNIQ_KEY__2F9ADBB7] DEFAULT ('') NOT NULL,
    [PARTMFGR]   CHAR (8)        CONSTRAINT [DF__MRPWH__PARTMFGR__308EFFF0] DEFAULT ('') NOT NULL,
    [MFGR_PT_NO] CHAR (30)       CONSTRAINT [DF__MRPWH__MFGR_PT_N__31832429] DEFAULT ('') NOT NULL,
    [QTY_OH]     NUMERIC (12, 2) CONSTRAINT [DF__MRPWH__QTY_OH__32774862] DEFAULT ((0)) NOT NULL,
    [NETABLE]    BIT             CONSTRAINT [DF__MRPWH__NETABLE__336B6C9B] DEFAULT ((0)) NOT NULL,
    [LOCATION]   NVARCHAR (200)  CONSTRAINT [DF__MRPWH__LOCATION__3553B50D] DEFAULT ('') NOT NULL,
    [W_KEY]      CHAR (10)       CONSTRAINT [DF__MRPWH__W_KEY__3647D946] DEFAULT ('') NOT NULL,
    [RESERVED]   NUMERIC (12, 2) CONSTRAINT [DF__MRPWH__RESERVED__373BFD7F] DEFAULT ((0)) NOT NULL,
    [ORDERPREF]  NUMERIC (2)     CONSTRAINT [DF__MRPWH__ORDERPREF__383021B8] DEFAULT ((0)) NOT NULL,
    [UNIQMFGRHD] CHAR (10)       CONSTRAINT [DF__MRPWH__UNIQMFGRH__392445F1] DEFAULT ('') NOT NULL,
    [Uniqwh]     CHAR (10)       CONSTRAINT [DF__MRPWH__WHNO__345F90D4] DEFAULT ('') NOT NULL,
    CONSTRAINT [MRPWH_PK] PRIMARY KEY CLUSTERED ([W_KEY] ASC)
);


GO
CREATE NONCLUSTERED INDEX [UNIQ_KEY]
    ON [dbo].[MRPWH]([UNIQ_KEY] ASC);


GO
CREATE NONCLUSTERED INDEX [UniqMfgrhd]
    ON [dbo].[MRPWH]([UNIQMFGRHD] ASC);


GO
CREATE NONCLUSTERED INDEX [WHNO]
    ON [dbo].[MRPWH]([Uniqwh] ASC);
