﻿CREATE TABLE [dbo].[MRPAVL] (
    [UNIQMRPACT] CHAR (10) CONSTRAINT [DF__MRPAVL__UNIQMRPA__151BEFA5] DEFAULT ('') NOT NULL,
    [UNIQAVL]    CHAR (10) CONSTRAINT [DF__MRPAVL__UNIQAVL__161013DE] DEFAULT ('') NOT NULL,
    [PARTMFGR]   CHAR (8)  CONSTRAINT [DF__MRPAVL__PARTMFGR__17043817] DEFAULT ('') NOT NULL,
    [MFGR_PT_NO] CHAR (30) CONSTRAINT [DF__MRPAVL__MFGR_PT___17F85C50] DEFAULT ('') NOT NULL,
    CONSTRAINT [MRPAVL_PK] PRIMARY KEY CLUSTERED ([UNIQAVL] ASC)
);


GO
CREATE NONCLUSTERED INDEX [UNIQMRPACT]
    ON [dbo].[MRPAVL]([UNIQMRPACT] ASC);

