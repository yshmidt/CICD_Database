﻿CREATE TABLE [dbo].[TMLOGST] (
    [OVERTIMEHR] NUMERIC (5, 1) CONSTRAINT [DF__TMLOGST__OVERTIM__385B0A41] DEFAULT ((0)) NOT NULL,
    [PERIOD]     CHAR (10)      CONSTRAINT [DF__TMLOGST__PERIOD__394F2E7A] DEFAULT ('') NOT NULL,
    [MAXHRINSYS] NUMERIC (5, 1) CONSTRAINT [DF__TMLOGST__MAXHRIN__3A4352B3] DEFAULT ((0)) NOT NULL,
    [TOLERANCE]  NUMERIC (3)    CONSTRAINT [DF__TMLOGST__TOLERAN__3B3776EC] DEFAULT ((0)) NOT NULL,
    [OTCALC]     CHAR (1)       CONSTRAINT [DF__TMLOGST__OTCALC__3C2B9B25] DEFAULT ('') NOT NULL,
    [DAY_START]  CHAR (10)      CONSTRAINT [DF__TMLOGST__DAY_STA__3D1FBF5E] DEFAULT ('') NOT NULL,
    [ENFORCEBRK] BIT            CONSTRAINT [DF__TMLOGST__ENFORCE__3E13E397] DEFAULT ((0)) NOT NULL,
    [TMPLOGSTUK] CHAR (10)      CONSTRAINT [DF__TMLOGST__TMPLOGS__3F0807D0] DEFAULT ('') NOT NULL,
    CONSTRAINT [TMLOGST_PK] PRIMARY KEY CLUSTERED ([TMPLOGSTUK] ASC)
);
