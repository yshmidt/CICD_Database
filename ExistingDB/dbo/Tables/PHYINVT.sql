﻿CREATE TABLE [dbo].[PHYINVT] (
    [UNIQ_KEY]   CHAR (10)       CONSTRAINT [DF__PHYINVT__UNIQ_KE__20238DFD] DEFAULT ('') NOT NULL,
    [UNIQPIHEAD] CHAR (10)       CONSTRAINT [DF__PHYINVT__UNIQPIH__2117B236] DEFAULT ('') NOT NULL,
    [UNIQPHYNO]  CHAR (10)       CONSTRAINT [DF__PHYINVT__UNIQPHY__220BD66F] DEFAULT ('') NOT NULL,
    [TAG_NO]     CHAR (6)        CONSTRAINT [DF__PHYINVT__TAG_NO__22FFFAA8] DEFAULT ('') NOT NULL,
    [W_KEY]      CHAR (10)       CONSTRAINT [DF__PHYINVT__W_KEY__23F41EE1] DEFAULT ('') NOT NULL,
    [LOTCODE]    NVARCHAR (25)   CONSTRAINT [DF__PHYINVT__LOTCODE__24E8431A] DEFAULT ('') NOT NULL,
    [REFERENCE]  CHAR (12)       CONSTRAINT [DF__PHYINVT__REFEREN__25DC6753] DEFAULT ('') NOT NULL,
    [QTY_OH]     NUMERIC (12, 2) CONSTRAINT [DF__PHYINVT__QTY_OH__26D08B8C] DEFAULT ((0)) NOT NULL,
    [SYS_DATE]   SMALLDATETIME   NULL,
    [PHYCOUNT]   NUMERIC (12, 2) CONSTRAINT [DF__PHYINVT__PHYCOUN__27C4AFC5] DEFAULT ((0)) NOT NULL,
    [INIT]       CHAR (8)        CONSTRAINT [DF__PHYINVT__INIT__28B8D3FE] DEFAULT ('') NULL,
    [PHYDATE]    SMALLDATETIME   NULL,
    [INVREASON]  CHAR (20)       CONSTRAINT [DF__PHYINVT__INVREAS__29ACF837] DEFAULT ('') NOT NULL,
    [INVRECNCL]  BIT             CONSTRAINT [DF__PHYINVT__INVRECN__2AA11C70] DEFAULT ((0)) NOT NULL,
    [EXPDATE]    SMALLDATETIME   NULL,
    [PONUM]      CHAR (15)       CONSTRAINT [DF__PHYINVT__PONUM__2B9540A9] DEFAULT ('') NOT NULL,
    [UNIQ_LOT]   CHAR (10)       CONSTRAINT [DF__PHYINVT__UNIQ_LO__2C8964E2] DEFAULT ('') NOT NULL,
    CONSTRAINT [PHYINVT_PK] PRIMARY KEY CLUSTERED ([UNIQPHYNO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [UNIQ_KEY]
    ON [dbo].[PHYINVT]([UNIQ_KEY] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQ_LOT]
    ON [dbo].[PHYINVT]([UNIQ_LOT] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQPIHEAD]
    ON [dbo].[PHYINVT]([UNIQPIHEAD] ASC);


GO
CREATE NONCLUSTERED INDEX [W_KEY]
    ON [dbo].[PHYINVT]([W_KEY] ASC);

