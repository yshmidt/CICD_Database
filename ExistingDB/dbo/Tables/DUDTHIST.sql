﻿CREATE TABLE [dbo].[DUDTHIST] (
    [UNIQDUHIST] CHAR (10)      CONSTRAINT [DF__DUDTHIST__UNIQDU__0E7913B7] DEFAULT ('') NOT NULL,
    [UNIQHISTNO] CHAR (10)      CONSTRAINT [DF__DUDTHIST__UNIQHI__0F6D37F0] DEFAULT ('') NOT NULL,
    [SONO]       CHAR (10)      CONSTRAINT [DF__DUDTHIST__SONO__10615C29] DEFAULT ('') NOT NULL,
    [DUE_DTS]    SMALLDATETIME  NULL,
    [SHIP_DTS]   SMALLDATETIME  NULL,
    [COMMIT_DTS] SMALLDATETIME  NULL,
    [QTY]        NUMERIC (9, 2) CONSTRAINT [DF__DUDTHIST__QTY__11558062] DEFAULT ((0)) NOT NULL,
    [ACT_SHP_QT] NUMERIC (9, 2) CONSTRAINT [DF__DUDTHIST__ACT_SH__1249A49B] DEFAULT ((0)) NOT NULL,
    [UNIQUELN]   CHAR (10)      CONSTRAINT [DF__DUDTHIST__UNIQUE__133DC8D4] DEFAULT ('') NOT NULL,
    [DUEDT_UNIQ] CHAR (10)      CONSTRAINT [DF__DUDTHIST__DUEDT___1431ED0D] DEFAULT ('') NOT NULL,
    CONSTRAINT [DUDTHIST_PK] PRIMARY KEY CLUSTERED ([UNIQDUHIST] ASC)
);


GO
CREATE NONCLUSTERED INDEX [UNIQHISTNO]
    ON [dbo].[DUDTHIST]([UNIQHISTNO] ASC);

