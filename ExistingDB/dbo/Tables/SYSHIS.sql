﻿CREATE TABLE [dbo].[SYSHIS] (
    [CONAME]    CHAR (20)     CONSTRAINT [DF__SYSHIS__CONAME__141DA9CB] DEFAULT ('') NOT NULL,
    [DATE]      SMALLDATETIME NULL,
    [PATCH]     VARCHAR (200) CONSTRAINT [DF__SYSHIS__PATCH__1511CE04] DEFAULT ('') NOT NULL,
    [SR]        CHAR (10)     CONSTRAINT [DF__SYSHIS__SR__1605F23D] DEFAULT ('') NOT NULL,
    [VER]       VARCHAR (50)  CONSTRAINT [DF__SYSHIS__VER__16FA1676] DEFAULT ('') NOT NULL,
    [UNIQUEREC] CHAR (10)     CONSTRAINT [DF__SYSHIS__UNIQUERE__17EE3AAF] DEFAULT ('') NOT NULL,
    CONSTRAINT [SYSHIS_PK] PRIMARY KEY CLUSTERED ([UNIQUEREC] ASC)
);

