﻿CREATE TABLE [dbo].[PLFREIGHTTAX] (
    [UNIQPLFREIGHTTAX] CHAR (10)      CONSTRAINT [DF__PLFREIGHT__UNIQP__6B5C56B1] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    [PACKLISTNO]       CHAR (10)      CONSTRAINT [DF__PLFREIGHT__PACKL__6C507AEA] DEFAULT ('') NOT NULL,
    [TAX_ID]           CHAR (8)       CONSTRAINT [DF__PLFREIGHT__TAX_I__6D449F23] DEFAULT ('') NOT NULL,
    [TAX_RATE]         NUMERIC (8, 4) CONSTRAINT [DF__PLFREIGHT__TAX_R__6E38C35C] DEFAULT ((0)) NOT NULL,
    [PTPROD]           BIT            CONSTRAINT [DF__PLFREIGHT__PTPRO__6F2CE795] DEFAULT ((0)) NOT NULL,
    [PTFRT]            BIT            CONSTRAINT [DF__PLFREIGHT__PTFRT__70210BCE] DEFAULT ((0)) NOT NULL,
    [STPROD]           BIT            CONSTRAINT [DF__PLFREIGHT__STPRO__71153007] DEFAULT ((0)) NOT NULL,
    [STFRT]            BIT            CONSTRAINT [DF__PLFREIGHT__STFRT__72095440] DEFAULT ((0)) NOT NULL,
    [STTX]             BIT            CONSTRAINT [DF__PLFREIGHTT__STTX__72FD7879] DEFAULT ((0)) NOT NULL,
    [TAXTYPE]          CHAR (1)       CONSTRAINT [DF__PLFREIGHT__TAXTY__75D9E524] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK__PLFREIGH__A5EA3567899B1C21] PRIMARY KEY CLUSTERED ([UNIQPLFREIGHTTAX] ASC)
);

