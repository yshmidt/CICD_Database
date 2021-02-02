﻿CREATE TABLE [dbo].[CNFGPRIC] (
    [UNIQ_KEY]    CHAR (10)       CONSTRAINT [DF__CNFGPRIC__UNIQ_K__2AC04CAA] DEFAULT ('') NOT NULL,
    [QTY_BREAK]   NUMERIC (7)     CONSTRAINT [DF__CNFGPRIC__QTY_BR__2BB470E3] DEFAULT ((0)) NOT NULL,
    [STDPRICE]    NUMERIC (12, 5) CONSTRAINT [DF__CNFGPRIC__STDPRI__2CA8951C] DEFAULT ((0)) NOT NULL,
    [SALEPRICE]   NUMERIC (12, 5) CONSTRAINT [DF__CNFGPRIC__SALEPR__2D9CB955] DEFAULT ((0)) NOT NULL,
    [UNIQ_PRICE]  CHAR (10)       CONSTRAINT [DF__CNFGPRIC__UNIQ_P__2E90DD8E] DEFAULT ('') NOT NULL,
    [STDPRICEFC]  NUMERIC (12, 5) CONSTRAINT [DF__CNFGPRIC__STDPRI__3441F748] DEFAULT ((0)) NOT NULL,
    [SALEPRICEFC] NUMERIC (12, 5) CONSTRAINT [DF__CNFGPRIC__SALEPR__35361B81] DEFAULT ((0)) NOT NULL,
    [FCUSED_UNIQ] CHAR (10)       CONSTRAINT [DF__CNFGPRIC__FCUSED__362A3FBA] DEFAULT ('') NOT NULL,
    CONSTRAINT [CNFGPRIC_PK] PRIMARY KEY CLUSTERED ([UNIQ_PRICE] ASC)
);


GO
CREATE NONCLUSTERED INDEX [UNIQ_KEY]
    ON [dbo].[CNFGPRIC]([UNIQ_KEY] ASC);

