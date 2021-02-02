﻿CREATE TABLE [dbo].[PRODOPTN] (
    [PDFETRUNIQ] CHAR (10)   CONSTRAINT [DF__PRODOPTN__PDFETR__54B751CD] DEFAULT ('') NOT NULL,
    [UNIQ_KEY]   CHAR (10)   CONSTRAINT [DF__PRODOPTN__UNIQ_K__55AB7606] DEFAULT ('') NOT NULL,
    [PDOPTNUNIQ] CHAR (10)   CONSTRAINT [DF__PRODOPTN__PDOPTN__569F9A3F] DEFAULT ('') NOT NULL,
    [PRODTPUNIQ] CHAR (10)   CONSTRAINT [DF__PRODOPTN__PRODTP__5793BE78] DEFAULT ('') NOT NULL,
    [ISREQUIRED] BIT         CONSTRAINT [DF__PRODOPTN__ISREQU__5887E2B1] DEFAULT ((0)) NOT NULL,
    [QTYPER]     NUMERIC (7) CONSTRAINT [DF__PRODOPTN__QTYPER__597C06EA] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PRODOPTN_PK] PRIMARY KEY CLUSTERED ([PDOPTNUNIQ] ASC)
);
