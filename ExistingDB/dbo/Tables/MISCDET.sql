﻿CREATE TABLE [dbo].[MISCDET] (
    [MISCKEY]    CHAR (10)       CONSTRAINT [DF__MISCDET__MISCKEY__1B09D325] DEFAULT ('') NOT NULL,
    [AUDITBY]    CHAR (8)        CONSTRAINT [DF__MISCDET__AUDITBY__1BFDF75E] DEFAULT ('') NULL,
    [AUDITDATE]  SMALLDATETIME   NULL,
    [SHORTBAL]   NUMERIC (12, 2) CONSTRAINT [DF__MISCDET__SHORTBA__1CF21B97] DEFAULT ((0)) NOT NULL,
    [SHQUALIFY]  CHAR (3)        CONSTRAINT [DF__MISCDET__SHQUALI__1DE63FD0] DEFAULT ('') NOT NULL,
    [SHORTQTY]   NUMERIC (12, 2) CONSTRAINT [DF__MISCDET__SHORTQT__1EDA6409] DEFAULT ((0)) NOT NULL,
    [SHREASON]   CHAR (15)       CONSTRAINT [DF__MISCDET__SHREASO__1FCE8842] DEFAULT ('') NOT NULL,
    [MISCDETKEY] CHAR (10)       CONSTRAINT [DF__MISCDET__MISCDET__20C2AC7B] DEFAULT ('') NOT NULL,
    CONSTRAINT [MISCDET_PK] PRIMARY KEY CLUSTERED ([MISCDETKEY] ASC)
);


GO
CREATE NONCLUSTERED INDEX [MISCKEY]
    ON [dbo].[MISCDET]([MISCKEY] ASC);


GO
CREATE NONCLUSTERED INDEX [SHQUALIFY]
    ON [dbo].[MISCDET]([SHQUALIFY] ASC);
