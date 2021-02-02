﻿CREATE TABLE [dbo].[QTMAIN] (
    [QUOTEUNIQ]  CHAR (10)      CONSTRAINT [DF__QTMAIN__QUOTEUNI__4322B177] DEFAULT ('') NOT NULL,
    [QUOTENO]    CHAR (10)      CONSTRAINT [DF__QTMAIN__QUOTENO__4416D5B0] DEFAULT ('') NOT NULL,
    [CUSTNO]     CHAR (10)      CONSTRAINT [DF__QTMAIN__CUSTNO__450AF9E9] DEFAULT ('') NOT NULL,
    [CUSTRFQ]    CHAR (10)      CONSTRAINT [DF__QTMAIN__CUSTRFQ__45FF1E22] DEFAULT ('') NOT NULL,
    [DUEDATE]    SMALLDATETIME  NULL,
    [QUOTEDDT]   SMALLDATETIME  NULL,
    [QUOTENOTE]  TEXT           CONSTRAINT [DF__QTMAIN__QUOTENOT__46F3425B] DEFAULT ('') NOT NULL,
    [MATLMARKUP] NUMERIC (6, 2) CONSTRAINT [DF__QTMAIN__MATLMARK__47E76694] DEFAULT ((0)) NOT NULL,
    [SCRPMARKUP] NUMERIC (6, 2) CONSTRAINT [DF__QTMAIN__SCRPMARK__48DB8ACD] DEFAULT ((0)) NOT NULL,
    [TOOLMARKUP] NUMERIC (6, 2) CONSTRAINT [DF__QTMAIN__TOOLMARK__49CFAF06] DEFAULT ((0)) NOT NULL,
    [LABORMRKUP] NUMERIC (6, 2) CONSTRAINT [DF__QTMAIN__LABORMRK__4AC3D33F] DEFAULT ((0)) NOT NULL,
    [MINORDDEF]  BIT            CONSTRAINT [DF__QTMAIN__MINORDDE__4BB7F778] DEFAULT ((0)) NOT NULL,
    [QTFOOTNOTE] TEXT           CONSTRAINT [DF__QTMAIN__QTFOOTNO__4CAC1BB1] DEFAULT ('') NOT NULL,
    [LINKADDR]   CHAR (10)      CONSTRAINT [DF__QTMAIN__LINKADDR__4DA03FEA] DEFAULT ('') NOT NULL,
    [FULLNAME]   CHAR (25)      CONSTRAINT [DF__QTMAIN__FULLNAME__4E946423] DEFAULT ('') NOT NULL,
    [QUOTE_DOC]  CHAR (200)     CONSTRAINT [DF__QTMAIN__QUOTE_DO__4F88885C] DEFAULT ('') NOT NULL,
    [DREFRESHDT] SMALLDATETIME  NULL,
    CONSTRAINT [QTMAIN_PK] PRIMARY KEY CLUSTERED ([QUOTEUNIQ] ASC)
);


GO
CREATE NONCLUSTERED INDEX [CUSTNO]
    ON [dbo].[QTMAIN]([CUSTNO] ASC);


GO
CREATE NONCLUSTERED INDEX [QUOTENO]
    ON [dbo].[QTMAIN]([QUOTENO] ASC);

