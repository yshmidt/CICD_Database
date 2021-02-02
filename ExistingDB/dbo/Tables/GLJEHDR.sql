﻿CREATE TABLE [dbo].[GLJEHDR] (
    [UNIQJEHEAD]      CHAR (10)        CONSTRAINT [DF__GLJEHDR__UNIQJEH__267098D9] DEFAULT ('') NOT NULL,
    [JE_NO]           NUMERIC (6)      CONSTRAINT [DF__GLJEHDR__JE_NO__2764BD12] DEFAULT ((0)) NOT NULL,
    [TRANSDATE]       SMALLDATETIME    NULL,
    [POSTEDDT]        SMALLDATETIME    NULL,
    [SAVEINIT]        CHAR (8)         CONSTRAINT [DF__GLJEHDR__SAVEINI__2858E14B] DEFAULT ('') NULL,
    [APP_DT]          SMALLDATETIME    NULL,
    [REASON]          VARCHAR (MAX)    CONSTRAINT [DF__GLJEHDR__REASON__294D0584] DEFAULT ('') NOT NULL,
    [STATUS]          CHAR (12)        CONSTRAINT [DF__GLJEHDR__STATUS__2A4129BD] DEFAULT ('') NOT NULL,
    [JETYPE]          CHAR (10)        CONSTRAINT [DF__GLJEHDR__JETYPE__2B354DF6] DEFAULT ('') NOT NULL,
    [PERIOD]          NUMERIC (2)      CONSTRAINT [DF__GLJEHDR__PERIOD__2C29722F] DEFAULT ((0)) NOT NULL,
    [FY]              CHAR (4)         CONSTRAINT [DF__GLJEHDR__FY__2D1D9668] DEFAULT ('') NOT NULL,
    [POSTED]          BIT              CONSTRAINT [DF__GLJEHDR__POSTED__2E11BAA1] DEFAULT ((0)) NOT NULL,
    [REVERSED]        BIT              CONSTRAINT [DF__GLJEHDR__REVERSE__2F05DEDA] DEFAULT ((0)) NOT NULL,
    [REVERSE]         BIT              CONSTRAINT [DF__GLJEHDR__REVERSE__2FFA0313] DEFAULT ((0)) NOT NULL,
    [REVPERIOD]       NUMERIC (2)      CONSTRAINT [DF__GLJEHDR__REVPERI__30EE274C] DEFAULT ((0)) NOT NULL,
    [REV_FY]          CHAR (4)         CONSTRAINT [DF__GLJEHDR__REV_FY__31E24B85] DEFAULT ('') NOT NULL,
    [TRANS_NO]        NUMERIC (10)     CONSTRAINT [DF__GLJEHDR__TRANS_N__32D66FBE] DEFAULT ((0)) NOT NULL,
    [SAVEDATE]        SMALLDATETIME    CONSTRAINT [DF_GLJEHDR_SAVEDATE] DEFAULT (getdate()) NULL,
    [APP_INIT]        CHAR (8)         CONSTRAINT [DF__GLJEHDR__APP_INI__33CA93F7] DEFAULT ('') NULL,
    [FCUSED_UNIQ]     CHAR (10)        CONSTRAINT [DF__GLJEHDR__FCUSED___64A53781] DEFAULT ('') NOT NULL,
    [ADJUSTENTRY]     BIT              CONSTRAINT [DF__GLJEHDR__ADJUSTE__50BE3A65] DEFAULT ((0)) NOT NULL,
    [PRFCUSED_UNIQ]   CHAR (10)        CONSTRAINT [DF__GLJEHDR__PRFCUSE__0D33E276] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)        CONSTRAINT [DF__GLJEHDR__FUNCFCU__0E2806AF] DEFAULT ('') NOT NULL,
    [FCHIST_KEY]      CHAR (10)        CONSTRAINT [DF__GLJEHDR__FCHIST___277DC45E] DEFAULT ('') NOT NULL,
    [ENTERCURRBY]     CHAR (1)         CONSTRAINT [DF__GLJEHDR__ENTERCU__506ACB58] DEFAULT ('B') NOT NULL,
    [SaveUserId]      UNIQUEIDENTIFIER NULL,
    CONSTRAINT [GLJEHDR_PK] PRIMARY KEY CLUSTERED ([UNIQJEHEAD] ASC)
);


GO
CREATE NONCLUSTERED INDEX [JE_NO]
    ON [dbo].[GLJEHDR]([JE_NO] ASC);


GO
CREATE NONCLUSTERED INDEX [postdt]
    ON [dbo].[GLJEHDR]([POSTEDDT] ASC);


GO
CREATE NONCLUSTERED INDEX [posted]
    ON [dbo].[GLJEHDR]([POSTED] ASC);
