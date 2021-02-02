﻿CREATE TABLE [dbo].[ROLLUP] (
    [UNIQ_KEY]        CHAR (10)       CONSTRAINT [DF__ROLLUP__UNIQ_KEY__67EA21D2] DEFAULT ('') NOT NULL,
    [UNIQ_ROLL]       CHAR (10)       CONSTRAINT [DF__ROLLUP__UNIQ_ROL__68DE460B] DEFAULT ('') NOT NULL,
    [ROLL_QTY]        NUMERIC (12, 2) CONSTRAINT [DF__ROLLUP__ROLL_QTY__69D26A44] DEFAULT ((0)) NOT NULL,
    [NEWSTDCOST]      NUMERIC (13, 5) CONSTRAINT [DF__ROLLUP__NEWSTDCO__6AC68E7D] DEFAULT ((0)) NOT NULL,
    [USECALC]         BIT             CONSTRAINT [DF__ROLLUP__USECALC__6BBAB2B6] DEFAULT ((0)) NOT NULL,
    [MANUAL]          BIT             CONSTRAINT [DF__ROLLUP__MANUAL__6CAED6EF] DEFAULT ((0)) NOT NULL,
    [DELTA]           NUMERIC (12, 2) CONSTRAINT [DF__ROLLUP__DELTA__6DA2FB28] DEFAULT ((0)) NOT NULL,
    [RUNDATE]         SMALLDATETIME   NULL,
    [PCT]             NUMERIC (3)     CONSTRAINT [DF__ROLLUP__PCT__6E971F61] DEFAULT ((0)) NOT NULL,
    [ROLLTYPE]        CHAR (4)        CONSTRAINT [DF__ROLLUP__ROLLTYPE__6F8B439A] DEFAULT ('') NOT NULL,
    [CALCCOST]        NUMERIC (13, 5) CONSTRAINT [DF__ROLLUP__CALCCOST__707F67D3] DEFAULT ((0)) NOT NULL,
    [MANUALCOST]      NUMERIC (13, 5) CONSTRAINT [DF__ROLLUP__MANUALCO__71738C0C] DEFAULT ((0)) NOT NULL,
    [NEWMATLCST]      NUMERIC (13, 5) CONSTRAINT [DF__ROLLUP__NEWMATLC__7267B045] DEFAULT ((0)) NOT NULL,
    [NEWLABRCST]      NUMERIC (13, 5) CONSTRAINT [DF__ROLLUP__NEWLABRC__735BD47E] DEFAULT ((0)) NOT NULL,
    [NEWOVHDCST]      NUMERIC (13, 5) CONSTRAINT [DF__ROLLUP__NEWOVHDC__744FF8B7] DEFAULT ((0)) NOT NULL,
    [NEWOTHRCST]      NUMERIC (13, 5) CONSTRAINT [DF__ROLLUP__NEWOTHRC__75441CF0] DEFAULT ((0)) NOT NULL,
    [NEWUDCST]        NUMERIC (13, 5) CONSTRAINT [DF__ROLLUP__NEWUDCST__76384129] DEFAULT ((0)) NOT NULL,
    [WIPQTY]          NUMERIC (12, 2) CONSTRAINT [DF__ROLLUP__WIPQTY__772C6562] DEFAULT ((0)) NOT NULL,
    [NAMOUNTDIFF]     NUMERIC (12, 2) CONSTRAINT [DF__ROLLUP__NAMOUNTD__7820899B] DEFAULT ((0)) NOT NULL,
    [NEWSTDCOSTPR]    NUMERIC (13, 5) CONSTRAINT [DF__ROLLUP__NEWSTDCO__31DB5740] DEFAULT ((0)) NOT NULL,
    [DELTAPR]         NUMERIC (12, 2) CONSTRAINT [DF__ROLLUP__DELTAPR__66D92F64] DEFAULT ((0)) NOT NULL,
    [CALCCOSTPR]      NUMERIC (13, 5) CONSTRAINT [DF__ROLLUP__CALCCOST__67CD539D] DEFAULT ((0)) NOT NULL,
    [MANUALCOSTPR]    NUMERIC (13, 5) CONSTRAINT [DF__ROLLUP__MANUALCO__68C177D6] DEFAULT ((0)) NOT NULL,
    [NEWMATLCSTPR]    NUMERIC (13, 5) CONSTRAINT [DF__ROLLUP__NEWMATLC__69B59C0F] DEFAULT ((0)) NOT NULL,
    [NEWLABRCSTPR]    NUMERIC (13, 5) CONSTRAINT [DF__ROLLUP__NEWLABRC__6AA9C048] DEFAULT ((0)) NOT NULL,
    [NEWOVHDCSTPR]    NUMERIC (13, 5) CONSTRAINT [DF__ROLLUP__NEWOVHDC__6B9DE481] DEFAULT ((0)) NOT NULL,
    [NEWOTHRCSTPR]    NUMERIC (13, 5) CONSTRAINT [DF__ROLLUP__NEWOTHRC__6C9208BA] DEFAULT ((0)) NOT NULL,
    [NEWUDCSTPR]      NUMERIC (13, 5) CONSTRAINT [DF__ROLLUP__NEWUDCST__6D862CF3] DEFAULT ((0)) NOT NULL,
    [NAMOUNTDIFFPR]   NUMERIC (12, 2) CONSTRAINT [DF__ROLLUP__NAMOUNTD__6E7A512C] DEFAULT ((0)) NOT NULL,
    [PRFCUSED_UNIQ]   CHAR (10)       CONSTRAINT [DF__ROLLUP__PRFCUSED__772F92BE] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)       CONSTRAINT [DF__ROLLUP__FUNCFCUS__7823B6F7] DEFAULT ('') NOT NULL,
    CONSTRAINT [ROLLUP_PK] PRIMARY KEY CLUSTERED ([UNIQ_ROLL] ASC)
);


GO
CREATE NONCLUSTERED INDEX [UNIQ_KEY]
    ON [dbo].[ROLLUP]([UNIQ_KEY] ASC);

