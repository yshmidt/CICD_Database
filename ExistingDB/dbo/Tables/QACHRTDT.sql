﻿CREATE TABLE [dbo].[QACHRTDT] (
    [QACHRTDTUK] CHAR (10)     NOT NULL,
    [dStartDt]   SMALLDATETIME NOT NULL,
    [dEndDt]     SMALLDATETIME NOT NULL,
    [cChartType] CHAR (10)     CONSTRAINT [DF__QACHRTDT__cChart__1E711B0C] DEFAULT ('') NOT NULL
);

