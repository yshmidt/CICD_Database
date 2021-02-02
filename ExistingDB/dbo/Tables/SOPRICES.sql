﻿CREATE TABLE [dbo].[SOPRICES] (
    [SONO]          CHAR (10)       CONSTRAINT [DF__SOPRICES__SONO__3E48EDC1] DEFAULT ('') NOT NULL,
    [DESCRIPTIO]    CHAR (45)       CONSTRAINT [DF__SOPRICES__DESCRI__3F3D11FA] DEFAULT ('') NOT NULL,
    [QUANTITY]      NUMERIC (10, 2) CONSTRAINT [DF__SOPRICES__QUANTI__40313633] DEFAULT ((0)) NOT NULL,
    [PRICE]         NUMERIC (14, 5) CONSTRAINT [DF__SOPRICES__PRICE__41255A6C] DEFAULT ((0)) NOT NULL,
    [EXTENDED]      NUMERIC (20, 2) CONSTRAINT [DF__SOPRICES__EXTEND__42197EA5] DEFAULT ((0)) NOT NULL,
    [TAXABLE]       BIT             CONSTRAINT [DF__SOPRICES__TAXABL__430DA2DE] DEFAULT ((0)) NOT NULL,
    [FLAT]          BIT             CONSTRAINT [DF__SOPRICES__FLAT__4401C717] DEFAULT ((0)) NOT NULL,
    [RECORDTYPE]    CHAR (1)        CONSTRAINT [DF__SOPRICES__RECORD__44F5EB50] DEFAULT ('') NOT NULL,
    [SALETYPEID]    CHAR (10)       CONSTRAINT [DF__SOPRICES__SALETY__45EA0F89] DEFAULT ('') NOT NULL,
    [PLPRICELNK]    CHAR (10)       CONSTRAINT [DF__SOPRICES__PLPRIC__46DE33C2] DEFAULT ('') NOT NULL,
    [UNIQUELN]      CHAR (10)       CONSTRAINT [DF__SOPRICES__UNIQUE__47D257FB] DEFAULT ('') NOT NULL,
    [PL_GL_NBR]     CHAR (13)       CONSTRAINT [DF__SOPRICES__PL_GL___48C67C34] DEFAULT ('') NOT NULL,
    [COG_GL_NBR]    CHAR (13)       CONSTRAINT [DF__SOPRICES__COG_GL__49BAA06D] DEFAULT ('') NOT NULL,
    [OrigPluniqLnk] CHAR (10)       CONSTRAINT [DF__SOPRICES__OrigPl__25731E56] DEFAULT ('') NOT NULL,
    [PRICEFC]       NUMERIC (14, 5) CONSTRAINT [DF__SOPRICES__PRICEF__3AEE2980] DEFAULT ((0)) NOT NULL,
    [EXTENDEDFC]    NUMERIC (20, 2) CONSTRAINT [DF__SOPRICES__EXTEND__3BE24DB9] DEFAULT ((0)) NOT NULL,
    [PRICEPR]       NUMERIC (14, 5) CONSTRAINT [DF__SOPRICES__PRICEP__6C720D29] DEFAULT ((0)) NOT NULL,
    [EXTENDEDPR]    NUMERIC (20, 2) CONSTRAINT [DF__SOPRICES__EXTEND__6D663162] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [SOPRICES_PK] PRIMARY KEY CLUSTERED ([PLPRICELNK] ASC)
);


GO
CREATE NONCLUSTERED INDEX [SONO]
    ON [dbo].[SOPRICES]([SONO] ASC, [UNIQUELN] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQUELN]
    ON [dbo].[SOPRICES]([UNIQUELN] ASC);

