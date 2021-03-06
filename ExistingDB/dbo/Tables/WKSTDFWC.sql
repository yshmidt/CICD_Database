﻿CREATE TABLE [dbo].[WKSTDFWC] (
    [UNIQ_WSWC] CHAR (10) CONSTRAINT [DF__WKSTDFWC__UNIQ_W__40863BEE] DEFAULT ('') NOT NULL,
    [DEPT_ID]   CHAR (4)  CONSTRAINT [DF__WKSTDFWC__DEPT_I__417A6027] DEFAULT ('') NOT NULL,
    [WKST_NAME] CHAR (20) CONSTRAINT [DF__WKSTDFWC__WKST_N__426E8460] DEFAULT ('') NOT NULL,
    [WKST_DESC] CHAR (30) CONSTRAINT [DF__WKSTDFWC__WKST_D__4362A899] DEFAULT ('') NOT NULL,
    CONSTRAINT [WKSTDFWC_PK] PRIMARY KEY CLUSTERED ([UNIQ_WSWC] ASC)
);


GO
CREATE NONCLUSTERED INDEX [DEPTWSNAME]
    ON [dbo].[WKSTDFWC]([DEPT_ID] ASC, [WKST_NAME] ASC);


GO
CREATE NONCLUSTERED INDEX [WKST_NAME]
    ON [dbo].[WKSTDFWC]([WKST_NAME] ASC);

