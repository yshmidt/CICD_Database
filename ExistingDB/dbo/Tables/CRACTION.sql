﻿CREATE TABLE [dbo].[CRACTION] (
    [CARNO]       CHAR (10)     CONSTRAINT [DF_CRACTION_CARNO] DEFAULT ('') NOT NULL,
    [CAR_DATE]    SMALLDATETIME NULL,
    [DESCRIPT]    CHAR (35)     CONSTRAINT [DF_CRACTION_DESCRIPT] DEFAULT ('') NOT NULL,
    [ORIGNATR]    CHAR (8)      CONSTRAINT [DF_CRACTION_ORIGNATR] DEFAULT ('') NULL,
    [COMPDATE]    SMALLDATETIME NULL,
    [PROB_TYPE]   CHAR (16)     CONSTRAINT [DF_CRACTION_PROB_TYPE] DEFAULT ('') NOT NULL,
    [CONDITION]   TEXT          CONSTRAINT [DF_CRACTION_CONDITION] DEFAULT ('') NOT NULL,
    [ESTCOMP_DT]  SMALLDATETIME NULL,
    [NEWDUE_DT]   SMALLDATETIME NULL,
    [COR_ACTION]  TEXT          CONSTRAINT [DF_CRACTION_COR_ACTION] DEFAULT ('') NOT NULL,
    [MAJMIN]      CHAR (5)      CONSTRAINT [DF_CRACTION_MAJMIN] DEFAULT ('') NOT NULL,
    [CUSTNO]      CHAR (10)     CONSTRAINT [DF_CRACTION_CUSTNO] DEFAULT ('') NOT NULL,
    [DEPT_ID]     CHAR (4)      CONSTRAINT [DF_CRACTION_DEPT_ID] DEFAULT ('') NOT NULL,
    [ELEM_ID]     CHAR (6)      CONSTRAINT [DF_CRACTION_ELEM_ID] DEFAULT ('') NOT NULL,
    [APP_CAUSE]   TEXT          CONSTRAINT [DF_CRACTION_APP_CAUSE] DEFAULT ('') NOT NULL,
    [ACT_CAUSE]   TEXT          CONSTRAINT [DF_CRACTION_ACT_CAUSE] DEFAULT ('') NOT NULL,
    [CAR_NOTE]    TEXT          CONSTRAINT [DF_CRACTION_CAR_NOTE] DEFAULT ('') NOT NULL,
    [RECDATE]     SMALLDATETIME NULL,
    [RECTIME]     CHAR (8)      CONSTRAINT [DF_CRACTION_RECTIME] DEFAULT ('') NOT NULL,
    [BY]          CHAR (10)     CONSTRAINT [DF_CRACTION_BY] DEFAULT ('') NOT NULL,
    [APPROVE_BY]  CHAR (8)      CONSTRAINT [DF_CRACTION_APPROVE_BY] DEFAULT ('') NOT NULL,
    [APPROVE_DT]  SMALLDATETIME NULL,
    [CAR_PICT]    CHAR (200)    CONSTRAINT [DF_CRACTION_CAR_PICT] DEFAULT ('') NOT NULL,
    [NO_TYPE]     CHAR (15)     CONSTRAINT [DF_CRACTION_NO_TYPE] DEFAULT ('') NOT NULL,
    [NUMBER]      CHAR (10)     CONSTRAINT [DF_CRACTION_NUMBER] DEFAULT ('') NOT NULL,
    [PROBVERFBY]  CHAR (8)      CONSTRAINT [DF_CRACTION_PROBVERFBY] DEFAULT ('') NOT NULL,
    [PROBVERFDT]  SMALLDATETIME NULL,
    [FOLLOWUPBY]  CHAR (8)      CONSTRAINT [DF_CRACTION_FOLLOWUPBY] DEFAULT ('') NOT NULL,
    [FOLLOWUPDT]  SMALLDATETIME NULL,
    [COMPLETEBY]  CHAR (8)      CONSTRAINT [DF_CRACTION_COMPLETEBY] DEFAULT ('') NOT NULL,
    [UNIQUECRNUM] INT           IDENTITY (1, 1) NOT NULL,
    [UniqSupno]   CHAR (10)     NULL,
    CONSTRAINT [CRACTION_PK] PRIMARY KEY CLUSTERED ([UNIQUECRNUM] ASC)
);


GO
CREATE NONCLUSTERED INDEX [CARNO]
    ON [dbo].[CRACTION]([CARNO] ASC);


GO
CREATE NONCLUSTERED INDEX [DEPT_ID]
    ON [dbo].[CRACTION]([DEPT_ID] ASC);
