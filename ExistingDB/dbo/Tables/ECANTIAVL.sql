﻿CREATE TABLE [dbo].[ECANTIAVL] (
    [UNIQECANTI] CHAR (10) CONSTRAINT [DF__ECANTIAVL__UNIQE__255C790F] DEFAULT ('') NOT NULL,
    [UNIQECNO]   CHAR (10) CONSTRAINT [DF__ECANTIAVL__UNIQE__26509D48] DEFAULT ('') NOT NULL,
    [UNIQECDET]  CHAR (10) CONSTRAINT [DF__ECANTIAVL__UNIQE__2744C181] DEFAULT ('') NOT NULL,
    [UNIQBOMNO]  CHAR (10) CONSTRAINT [DF__ECANTIAVL__UNIQB__2838E5BA] DEFAULT ('') NOT NULL,
    [UNIQ_KEY]   CHAR (10) CONSTRAINT [DF__ECANTIAVL__UNIQ___292D09F3] DEFAULT ('') NOT NULL,
    [PARTMFGR]   CHAR (8)  CONSTRAINT [DF__ECANTIAVL__PARTM__2A212E2C] DEFAULT ('') NOT NULL,
    [MFGR_PT_NO] CHAR (30) CONSTRAINT [DF__ECANTIAVL__MFGR___2B155265] DEFAULT ('') NOT NULL,
    CONSTRAINT [ECANTIAVL_PK] PRIMARY KEY CLUSTERED ([UNIQECANTI] ASC)
);


GO
CREATE NONCLUSTERED INDEX [UNIQ_KEY]
    ON [dbo].[ECANTIAVL]([UNIQ_KEY] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQECDET]
    ON [dbo].[ECANTIAVL]([UNIQECDET] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQECNO]
    ON [dbo].[ECANTIAVL]([UNIQECNO] ASC);

