﻿CREATE TABLE [dbo].[ACTCSTST] (
    [ACTCOST_NM] CHAR (25)   CONSTRAINT [DF__ACTCSTST__ACTCOS__2F10007B] DEFAULT ('') NOT NULL,
    [NUMBER]     NUMERIC (3) CONSTRAINT [DF__ACTCSTST__NUMBER__300424B4] DEFAULT ((0)) NOT NULL,
    [ACTCOST_ID] CHAR (10)   CONSTRAINT [DF__ACTCSTST__ACTCOS__2E1BDC42] DEFAULT ('') NOT NULL,
    CONSTRAINT [ACTCSTST_PK] PRIMARY KEY CLUSTERED ([ACTCOST_ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ACTCOST_NM]
    ON [dbo].[ACTCSTST]([ACTCOST_NM] ASC);


GO
CREATE NONCLUSTERED INDEX [NUMBER]
    ON [dbo].[ACTCSTST]([NUMBER] ASC);

