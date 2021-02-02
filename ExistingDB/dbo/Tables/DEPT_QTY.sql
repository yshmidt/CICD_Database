﻿CREATE TABLE [dbo].[DEPT_QTY] (
    [DEPT_ID]    CHAR (4)       CONSTRAINT [DF__DEPT_QTY__DEPT_I__5DD5DC5C] DEFAULT ('') NOT NULL,
    [WONO]       CHAR (10)      CONSTRAINT [DF__DEPT_QTY__WONO__5ECA0095] DEFAULT ('') NOT NULL,
    [CURR_QTY]   NUMERIC (7)    CONSTRAINT [DF__DEPT_QTY__CURR_Q__5FBE24CE] DEFAULT ((0)) NOT NULL,
    [XFER_QTY]   NUMERIC (7)    CONSTRAINT [DF__DEPT_QTY__XFER_Q__60B24907] DEFAULT ((0)) NOT NULL,
    [XFER_MIN]   NUMERIC (6)    CONSTRAINT [DF__DEPT_QTY__XFER_M__61A66D40] DEFAULT ((0)) NOT NULL,
    [XFER_SETUP] NUMERIC (6)    CONSTRAINT [DF__DEPT_QTY__XFER_S__629A9179] DEFAULT ((0)) NOT NULL,
    [NUMBER]     NUMERIC (4)    CONSTRAINT [DF__DEPT_QTY__NUMBER__638EB5B2] DEFAULT ((0)) NOT NULL,
    [CAPCTYNEED] NUMERIC (12)   CONSTRAINT [DF__DEPT_QTY__CAPCTY__6482D9EB] DEFAULT ((0)) NOT NULL,
    [SCHED_STAT] VARCHAR (20)   CONSTRAINT [DF__DEPT_QTY__SCHED___6576FE24] DEFAULT ('') NOT NULL,
    [DUEOUTDT]   SMALLDATETIME  NULL,
    [DEPT_PRI]   NUMERIC (7, 3) CONSTRAINT [DF__DEPT_QTY__DEPT_P__666B225D] DEFAULT ((0)) NOT NULL,
    [DEPTKEY]    CHAR (10)      CONSTRAINT [DF__DEPT_QTY__DEPTKE__675F4696] DEFAULT ('') NOT NULL,
    [WO_WC_NOTE] TEXT           CONSTRAINT [DF__DEPT_QTY__WO_WC___68536ACF] DEFAULT ('') NOT NULL,
    [SERIALSTRT] BIT            CONSTRAINT [DF__DEPT_QTY__SERIAL__69478F08] DEFAULT ((0)) NOT NULL,
    [UNIQUEREC]  CHAR (10)      CONSTRAINT [DF__DEPT_QTY__UNIQUE__6B2FD77A] DEFAULT ('') NOT NULL,
    [operator]   NVARCHAR (50)  CONSTRAINT [DF_DEPT_QTY_operator] DEFAULT ('') NOT NULL,
    [equipment]  NVARCHAR (50)  CONSTRAINT [DF_DEPT_QTY_equipment] DEFAULT ('') NOT NULL,
    [IsOptional] BIT            CONSTRAINT [DEPT_QTY_IsOptional] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [DEPT_QTY_PK] PRIMARY KEY CLUSTERED ([UNIQUEREC] ASC)
);


GO
CREATE NONCLUSTERED INDEX [DEPT_ID]
    ON [dbo].[DEPT_QTY]([DEPT_ID] ASC);


GO
CREATE NONCLUSTERED INDEX [DEPTDUEOUT]
    ON [dbo].[DEPT_QTY]([DEPT_ID] ASC, [DUEOUTDT] ASC);


GO
CREATE NONCLUSTERED INDEX [DEPTKEY]
    ON [dbo].[DEPT_QTY]([DEPTKEY] ASC);


GO
CREATE NONCLUSTERED INDEX [DUEOUTDT]
    ON [dbo].[DEPT_QTY]([DUEOUTDT] ASC);


GO
CREATE NONCLUSTERED INDEX [NUMBER]
    ON [dbo].[DEPT_QTY]([NUMBER] ASC);


GO
CREATE NONCLUSTERED INDEX [WONO]
    ON [dbo].[DEPT_QTY]([WONO] ASC);


GO
CREATE NONCLUSTERED INDEX [WONODEPT]
    ON [dbo].[DEPT_QTY]([WONO] ASC, [DEPT_ID] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [WONOKEY]
    ON [dbo].[DEPT_QTY]([WONO] ASC, [DEPTKEY] ASC);


GO
CREATE NONCLUSTERED INDEX [WOUNIQNUMB]
    ON [dbo].[DEPT_QTY]([WONO] ASC, [NUMBER] ASC);

