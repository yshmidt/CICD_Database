﻿CREATE TABLE [dbo].[ROLLMAKE] (
    [UNIQ_FIELD] CHAR (10)     CONSTRAINT [DF__ROLLMAKE__UNIQ_F__63256CB5] DEFAULT ('') NOT NULL,
    [RUNDATE]    SMALLDATETIME NULL,
    [MAXLEVEL]   NUMERIC (2)   CONSTRAINT [DF__ROLLMAKE__MAXLEV__641990EE] DEFAULT ((0)) NOT NULL,
    [CURLEVEL]   NUMERIC (2)   CONSTRAINT [DF__ROLLMAKE__CURLEV__650DB527] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [ROLLMAKE_PK] PRIMARY KEY CLUSTERED ([UNIQ_FIELD] ASC)
);

