﻿CREATE TABLE [dbo].[ACTCOST] (
    [ACTIV_ID]    CHAR (4)       CONSTRAINT [DF__ACTCOST__ACTIV_I__267ABA7A] DEFAULT ('') NOT NULL,
    [ACTCOST_ID]  CHAR (10)      CONSTRAINT [DF__ACTCOST__ACTCOST__276EDEB3] DEFAULT ('') NOT NULL,
    [AMT_HR]      NUMERIC (7, 2) CONSTRAINT [DF__ACTCOST__AMT_HR__286302EC] DEFAULT ((0)) NOT NULL,
    [OVERHEAD]    NUMERIC (5, 1) CONSTRAINT [DF__ACTCOST__OVERHEA__29572725] DEFAULT ((0)) NOT NULL,
    [COST_HR]     NUMERIC (7, 2) CONSTRAINT [DF__ACTCOST__COST_HR__2A4B4B5E] DEFAULT ((0)) NOT NULL,
    [UNIQUERECID] CHAR (10)      CONSTRAINT [DF__ACTCOST__UNIQUER__2B3F6F97] DEFAULT ('') NOT NULL,
    CONSTRAINT [ACTCOST_PK] PRIMARY KEY CLUSTERED ([UNIQUERECID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ACTCOST_ID]
    ON [dbo].[ACTCOST]([ACTCOST_ID] ASC);


GO
CREATE NONCLUSTERED INDEX [ACTCOSTID]
    ON [dbo].[ACTCOST]([ACTIV_ID] ASC, [ACTCOST_ID] ASC);


GO
CREATE NONCLUSTERED INDEX [ACTIV_ID]
    ON [dbo].[ACTCOST]([ACTIV_ID] ASC);
