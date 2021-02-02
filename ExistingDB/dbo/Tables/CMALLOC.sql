﻿CREATE TABLE [dbo].[CMALLOC] (
    [CMEMONO]    CHAR (10)      CONSTRAINT [DF__CMALLOC__CMEMONO__7B4643B2] DEFAULT ('') NOT NULL,
    [PACKLISTNO] CHAR (10)      CONSTRAINT [DF__CMALLOC__PACKLIS__7C3A67EB] DEFAULT ('') NOT NULL,
    [UNIQUELN]   CHAR (10)      CONSTRAINT [DF__CMALLOC__UNIQUEL__7D2E8C24] DEFAULT ('') NOT NULL,
    [W_KEY]      CHAR (10)      CONSTRAINT [DF__CMALLOC__W_KEY__7E22B05D] DEFAULT ('') NOT NULL,
    [WHNO]       CHAR (3)       CONSTRAINT [DF__CMALLOC__WHNO__7F16D496] DEFAULT ('') NOT NULL,
    [ALLOCQTY]   NUMERIC (9, 2) CONSTRAINT [DF__CMALLOC__ALLOCQT__000AF8CF] DEFAULT ((0)) NOT NULL,
    [UOM]        CHAR (4)       CONSTRAINT [DF__CMALLOC__UOM__00FF1D08] DEFAULT ('') NOT NULL,
    [WH_GL_NBR]  CHAR (13)      CONSTRAINT [DF__CMALLOC__WH_GL_N__01F34141] DEFAULT ('') NOT NULL,
    [UNIQ_ALLOC] CHAR (10)      CONSTRAINT [DF__CMALLOC__UNIQ_AL__02E7657A] DEFAULT ('') NOT NULL,
    [IS_INVT_UP] BIT            CONSTRAINT [DF__CMALLOC__IS_INVT__03DB89B3] DEFAULT ((0)) NOT NULL,
    [cmUnique]   CHAR (10)      CONSTRAINT [DF_CMALLOC_cmUnique] DEFAULT ('') NOT NULL,
    CONSTRAINT [CMALLOC_PK] PRIMARY KEY CLUSTERED ([UNIQ_ALLOC] ASC)
);


GO
CREATE NONCLUSTERED INDEX [CMEMONO]
    ON [dbo].[CMALLOC]([CMEMONO] ASC);


GO
CREATE NONCLUSTERED INDEX [CMUNIQUE]
    ON [dbo].[CMALLOC]([cmUnique] ASC);


GO
CREATE NONCLUSTERED INDEX [PKNOUKLNWK]
    ON [dbo].[CMALLOC]([PACKLISTNO] ASC, [UNIQUELN] ASC, [W_KEY] ASC);

