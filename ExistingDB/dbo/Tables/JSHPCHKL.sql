﻿CREATE TABLE [dbo].[JSHPCHKL] (
    [WONO]       CHAR (10)     CONSTRAINT [DF__JSHPCHKL__WONO__08611305] DEFAULT ('') NOT NULL,
    [DEPT_ACTIV] CHAR (4)      CONSTRAINT [DF__JSHPCHKL__DEPT_A__0955373E] DEFAULT ('') NOT NULL,
    [NUMBER]     NUMERIC (4)   CONSTRAINT [DF__JSHPCHKL__NUMBER__0A495B77] DEFAULT ((0)) NOT NULL,
    [CHKLST_TIT] CHAR (100)    CONSTRAINT [DF__JSHPCHKL__CHKLST__0B3D7FB0] DEFAULT ('') NOT NULL,
    [CHKLSTINIT] CHAR (8)      CONSTRAINT [DF__JSHPCHKL__CHKLST__0C31A3E9] DEFAULT ('') NULL,
    [CHKLSTDT]   SMALLDATETIME NULL,
    [CHKLSTTM]   CHAR (8)      CONSTRAINT [DF__JSHPCHKL__CHKLST__0D25C822] DEFAULT ('') NOT NULL,
    [DEPTKEY]    CHAR (10)     CONSTRAINT [DF__JSHPCHKL__DEPTKE__0E19EC5B] DEFAULT ('') NOT NULL,
    [CHKLSTFLAG] BIT           CONSTRAINT [DF__JSHPCHKL__CHKLST__0F0E1094] DEFAULT ((0)) NOT NULL,
    [UNIQNBRA]   CHAR (10)     CONSTRAINT [DF__JSHPCHKL__UNIQNB__100234CD] DEFAULT ('') NOT NULL,
    [JSHPCHKUK]  CHAR (10)     CONSTRAINT [DF__JSHPCHKL__JSHPCH__10F65906] DEFAULT ('') NOT NULL,
    CONSTRAINT [JSHPCHKL_PK] PRIMARY KEY CLUSTERED ([JSHPCHKUK] ASC)
);


GO
CREATE NONCLUSTERED INDEX [WONO]
    ON [dbo].[JSHPCHKL]([WONO] ASC);


GO
CREATE NONCLUSTERED INDEX [WOUNCHECK]
    ON [dbo].[JSHPCHKL]([WONO] ASC, [DEPTKEY] ASC, [UNIQNBRA] ASC);


GO
CREATE NONCLUSTERED INDEX [WOUNIQNUMB]
    ON [dbo].[JSHPCHKL]([WONO] ASC, [DEPTKEY] ASC, [UNIQNBRA] ASC);

