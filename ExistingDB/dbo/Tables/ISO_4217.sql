﻿CREATE TABLE [dbo].[ISO_4217] (
    [FCUSED_UNIQ] CHAR (10)   CONSTRAINT [DF__ISO_4217__FCUSED__502A08DF] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    [Entity]      CHAR (60)   CONSTRAINT [DF__ISO_4217__Entity__511E2D18] DEFAULT ('') NOT NULL,
    [Currency]    CHAR (40)   CONSTRAINT [DF__ISO_4217__Curren__52125151] DEFAULT ('') NOT NULL,
    [Acode]       CHAR (3)    CONSTRAINT [DF__ISO_4217__Acode__5306758A] DEFAULT ('') NOT NULL,
    [Ncode]       CHAR (3)    CONSTRAINT [DF__ISO_4217__Ncode__53FA99C3] DEFAULT ('') NOT NULL,
    [deci]        NUMERIC (1) CONSTRAINT [DF__ISO_4217__deci__54EEBDFC] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK__ISO_4217__F27749580DDFE861] PRIMARY KEY CLUSTERED ([FCUSED_UNIQ] ASC)
);

