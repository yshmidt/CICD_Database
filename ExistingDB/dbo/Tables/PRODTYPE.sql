﻿CREATE TABLE [dbo].[PRODTYPE] (
    [PRODTPUNIQ]  CHAR (10) CONSTRAINT [DF__PRODTYPE__PRODTP__5C587395] DEFAULT ('') NOT NULL,
    [PART_CLASS]  CHAR (8)  CONSTRAINT [DF__PRODTYPE__PART_C__5D4C97CE] DEFAULT ('') NOT NULL,
    [PART_TYPE]   CHAR (8)  CONSTRAINT [DF__PRODTYPE__PART_T__5E40BC07] DEFAULT ('') NOT NULL,
    [DESCRIPT]    CHAR (45) CONSTRAINT [DF__PRODTYPE__DESCRI__5F34E040] DEFAULT ('') NOT NULL,
    [ROUTUNQKEY]  CHAR (10) CONSTRAINT [DF__PRODTYPE__ROUTUN__60290479] DEFAULT ('') NOT NULL,
    [CUSTNO]      CHAR (10) CONSTRAINT [DF__PRODTYPE__CUSTNO__611D28B2] DEFAULT ('') NOT NULL,
    [taxable]     BIT       CONSTRAINT [DF__PRODTYPE__taxabl__1F46DA62] DEFAULT ((0)) NOT NULL,
    [fcused_uniq] CHAR (10) CONSTRAINT [DF__PRODTYPE__fcused__203AFE9B] DEFAULT ('') NOT NULL,
    CONSTRAINT [PRODTYPE_PK] PRIMARY KEY CLUSTERED ([PRODTPUNIQ] ASC)
);

