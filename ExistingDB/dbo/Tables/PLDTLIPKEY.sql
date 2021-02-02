﻿CREATE TABLE [dbo].[PLDTLIPKEY] (
    [UNIQPLIPKY]     CHAR (10)      CONSTRAINT [DF_PLDTLIPKEY_UNIQPLIPKY] DEFAULT ('') NOT NULL,
    [FK_INV_LINK]    CHAR (10)      CONSTRAINT [DF_PLDTLIPKEY_FK_INV_LINK] DEFAULT ('') NOT NULL,
    [FK_IPKEYUNIQUE] CHAR (10)      CONSTRAINT [DF_PLDTLIPKEY_FK_IPKEYUNIQUE] DEFAULT ('') NULL,
    [NSHPQTY]        NUMERIC (9, 2) CONSTRAINT [DF_PLDTLIPKEY_NSHPQTY] DEFAULT ((0)) NOT NULL
);

