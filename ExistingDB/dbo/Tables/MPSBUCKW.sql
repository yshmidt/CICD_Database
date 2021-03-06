﻿CREATE TABLE [dbo].[MPSBUCKW] (
    [UNIQ_KEY] CHAR (10)    CONSTRAINT [DF__MPSBUCKW__UNIQ_K__5071BF9D] DEFAULT ('') NOT NULL,
    [GLDIVNO]  CHAR (2)     CONSTRAINT [DF__MPSBUCKW__GLDIVN__5165E3D6] DEFAULT ('') NOT NULL,
    [TOTALQTY] NUMERIC (11) CONSTRAINT [DF__MPSBUCKW__TOTALQ__525A080F] DEFAULT ((0)) NOT NULL,
    [PASTDUE]  NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__PASTDU__534E2C48] DEFAULT ((0)) NOT NULL,
    [OUT]      NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__OUT__54425081] DEFAULT ((0)) NOT NULL,
    [WK1]      NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK1__553674BA] DEFAULT ((0)) NOT NULL,
    [WK2]      NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK2__562A98F3] DEFAULT ((0)) NOT NULL,
    [WK3]      NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK3__571EBD2C] DEFAULT ((0)) NOT NULL,
    [WK4]      NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK4__5812E165] DEFAULT ((0)) NOT NULL,
    [WK5]      NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK5__5907059E] DEFAULT ((0)) NOT NULL,
    [WK6]      NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK6__59FB29D7] DEFAULT ((0)) NOT NULL,
    [WK7]      NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK7__5AEF4E10] DEFAULT ((0)) NOT NULL,
    [WK8]      NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK8__5BE37249] DEFAULT ((0)) NOT NULL,
    [WK9]      NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK9__5CD79682] DEFAULT ((0)) NOT NULL,
    [WK10]     NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK10__5DCBBABB] DEFAULT ((0)) NOT NULL,
    [WK11]     NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK11__5EBFDEF4] DEFAULT ((0)) NOT NULL,
    [WK12]     NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK12__5FB4032D] DEFAULT ((0)) NOT NULL,
    [WK13]     NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK13__60A82766] DEFAULT ((0)) NOT NULL,
    [WK14]     NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK14__619C4B9F] DEFAULT ((0)) NOT NULL,
    [WK15]     NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK15__62906FD8] DEFAULT ((0)) NOT NULL,
    [WK16]     NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK16__63849411] DEFAULT ((0)) NOT NULL,
    [WK17]     NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK17__6478B84A] DEFAULT ((0)) NOT NULL,
    [WK18]     NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK18__656CDC83] DEFAULT ((0)) NOT NULL,
    [WK19]     NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK19__666100BC] DEFAULT ((0)) NOT NULL,
    [WK20]     NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK20__675524F5] DEFAULT ((0)) NOT NULL,
    [WK21]     NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK21__6849492E] DEFAULT ((0)) NOT NULL,
    [WK22]     NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK22__693D6D67] DEFAULT ((0)) NOT NULL,
    [WK23]     NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK23__6A3191A0] DEFAULT ((0)) NOT NULL,
    [WK24]     NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK24__6B25B5D9] DEFAULT ((0)) NOT NULL,
    [WK25]     NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK25__6C19DA12] DEFAULT ((0)) NOT NULL,
    [WK26]     NUMERIC (9)  CONSTRAINT [DF__MPSBUCKW__WK26__6D0DFE4B] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [MPSBUCKW_PK] PRIMARY KEY CLUSTERED ([UNIQ_KEY] ASC)
);

