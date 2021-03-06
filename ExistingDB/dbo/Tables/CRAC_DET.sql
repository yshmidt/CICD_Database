﻿CREATE TABLE [dbo].[CRAC_DET] (
    [CARNO]       CHAR (10)     CONSTRAINT [DF__CRAC_DET__CARNO__07420643] DEFAULT ('') NOT NULL,
    [C_ID]        CHAR (8)      CONSTRAINT [DF__CRAC_DET__C_ID__08362A7C] DEFAULT ('') NOT NULL,
    [START_DT]    SMALLDATETIME NULL,
    [ESTCOMP_DT]  SMALLDATETIME NULL,
    [NEWDUE_DT]   SMALLDATETIME NULL,
    [ACOMP_DT]    SMALLDATETIME NULL,
    [PROJ_STAT]   NUMERIC (3)   CONSTRAINT [DF__CRAC_DET__PROJ_S__092A4EB5] DEFAULT ((0)) NOT NULL,
    [LAST_EDIT]   CHAR (3)      CONSTRAINT [DF__CRAC_DET__LAST_E__0A1E72EE] DEFAULT ('') NOT NULL,
    [RECDATE]     SMALLDATETIME NULL,
    [BY]          CHAR (10)     CONSTRAINT [DF__CRAC_DET__BY__0C06BB60] DEFAULT ('') NOT NULL,
    [UNIQUECRDET] CHAR (10)     CONSTRAINT [DF__CRAC_DET__UNIQUE__0CFADF99] DEFAULT ('') NOT NULL,
    CONSTRAINT [CRAC_DET_PK] PRIMARY KEY CLUSTERED ([UNIQUECRDET] ASC)
);


GO
CREATE NONCLUSTERED INDEX [CARID]
    ON [dbo].[CRAC_DET]([CARNO] ASC, [C_ID] ASC);


GO
CREATE NONCLUSTERED INDEX [CARNO]
    ON [dbo].[CRAC_DET]([CARNO] ASC);

