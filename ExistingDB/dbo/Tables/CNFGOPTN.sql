﻿CREATE TABLE [dbo].[CNFGOPTN] (
    [UNIQ_KEY]    CHAR (10)       CONSTRAINT [DF__CNFGOPTN__UNIQ_K__1E5A75C5] DEFAULT ('') NOT NULL,
    [UNIQ_FETR]   CHAR (10)       CONSTRAINT [DF__CNFGOPTN__UNIQ_F__1F4E99FE] DEFAULT ('') NOT NULL,
    [ISREQUIRED]  BIT             CONSTRAINT [DF__CNFGOPTN__ISREQU__2042BE37] DEFAULT ((0)) NOT NULL,
    [PDOPTNUNIQ]  CHAR (10)       CONSTRAINT [DF__CNFGOPTN__PDOPTN__2136E270] DEFAULT ('') NOT NULL,
    [QTYPER]      NUMERIC (7)     CONSTRAINT [DF__CNFGOPTN__QTYPER__222B06A9] DEFAULT ((0)) NOT NULL,
    [EXTENDQTY]   NUMERIC (7)     CONSTRAINT [DF__CNFGOPTN__EXTEND__231F2AE2] DEFAULT ((0)) NOT NULL,
    [STDPRICE]    NUMERIC (12, 5) CONSTRAINT [DF__CNFGOPTN__STDPRI__24134F1B] DEFAULT ((0)) NOT NULL,
    [SALEPRICE]   NUMERIC (12, 5) CONSTRAINT [DF__CNFGOPTN__SALEPR__25077354] DEFAULT ((0)) NOT NULL,
    [UNIQ_PRICE]  CHAR (10)       CONSTRAINT [DF__CNFGOPTN__UNIQ_P__25FB978D] DEFAULT ('') NOT NULL,
    [UNIQ_OPTN]   CHAR (10)       CONSTRAINT [DF__CNFGOPTN__UNIQ_O__26EFBBC6] DEFAULT ('') NOT NULL,
    [COMPUNQKEY]  CHAR (10)       CONSTRAINT [DF__CNFGOPTN__COMPUN__27E3DFFF] DEFAULT ('') NOT NULL,
    [STDPRICEFC]  NUMERIC (12, 5) CONSTRAINT [DF__CNFGOPTN__STDPRI__3906AC65] DEFAULT ((0)) NOT NULL,
    [SALEPRICEFC] NUMERIC (12, 5) CONSTRAINT [DF__CNFGOPTN__SALEPR__39FAD09E] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [CNFGOPTN_PK] PRIMARY KEY CLUSTERED ([UNIQ_OPTN] ASC)
);


GO
CREATE NONCLUSTERED INDEX [PDOPTNUNIQ]
    ON [dbo].[CNFGOPTN]([PDOPTNUNIQ] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQ_FETR]
    ON [dbo].[CNFGOPTN]([UNIQ_FETR] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQ_KEY]
    ON [dbo].[CNFGOPTN]([UNIQ_KEY] ASC);
