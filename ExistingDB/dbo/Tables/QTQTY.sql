﻿CREATE TABLE [dbo].[QTQTY] (
    [UNIQQTYNO]  CHAR (10)       CONSTRAINT [DF__QTQTY__UNIQQTYNO__1EB046D7] DEFAULT ('') NOT NULL,
    [UNIQLINENO] CHAR (10)       CONSTRAINT [DF__QTQTY__UNIQLINEN__1FA46B10] DEFAULT ('') NOT NULL,
    [QTY]        NUMERIC (7)     CONSTRAINT [DF__QTQTY__QTY__20988F49] DEFAULT ((0)) NOT NULL,
    [COSTEACH]   NUMERIC (13, 5) CONSTRAINT [DF__QTQTY__COSTEACH__218CB382] DEFAULT ((0)) NOT NULL,
    [MARKUP]     NUMERIC (13, 5) CONSTRAINT [DF__QTQTY__MARKUP__2280D7BB] DEFAULT ((0)) NOT NULL,
    [CHARGEEACH] NUMERIC (13, 5) CONSTRAINT [DF__QTQTY__CHARGEEAC__2374FBF4] DEFAULT ((0)) NOT NULL,
    [ORDERAMT]   NUMERIC (11, 2) CONSTRAINT [DF__QTQTY__ORDERAMT__2469202D] DEFAULT ((0)) NOT NULL,
    [COSTEALAB]  NUMERIC (13, 5) CONSTRAINT [DF__QTQTY__COSTEALAB__255D4466] DEFAULT ((0)) NOT NULL,
    [LABORMUAMT] NUMERIC (13, 5) CONSTRAINT [DF__QTQTY__LABORMUAM__2651689F] DEFAULT ((0)) NOT NULL,
    [LABORCHGEA] NUMERIC (13, 5) CONSTRAINT [DF__QTQTY__LABORCHGE__27458CD8] DEFAULT ((0)) NOT NULL,
    [MATL1COST]  NUMERIC (15, 5) CONSTRAINT [DF__QTQTY__MATL1COST__2839B111] DEFAULT ((0)) NOT NULL,
    [MATL1MU]    NUMERIC (13, 5) CONSTRAINT [DF__QTQTY__MATL1MU__292DD54A] DEFAULT ((0)) NOT NULL,
    [MATL1CHG]   NUMERIC (13, 5) CONSTRAINT [DF__QTQTY__MATL1CHG__2A21F983] DEFAULT ((0)) NOT NULL,
    [MATL2COST]  NUMERIC (13, 5) CONSTRAINT [DF__QTQTY__MATL2COST__2B161DBC] DEFAULT ((0)) NOT NULL,
    [MATL2MU]    NUMERIC (13, 5) CONSTRAINT [DF__QTQTY__MATL2MU__2C0A41F5] DEFAULT ((0)) NOT NULL,
    [MATL2CHG]   NUMERIC (13, 5) CONSTRAINT [DF__QTQTY__MATL2CHG__2CFE662E] DEFAULT ((0)) NOT NULL,
    [USE_PCT]    BIT             CONSTRAINT [DF__QTQTY__USE_PCT__2DF28A67] DEFAULT ((0)) NOT NULL,
    [LTIMEASSY]  NUMERIC (3)     CONSTRAINT [DF__QTQTY__LTIMEASSY__2EE6AEA0] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [QTQTY_PK] PRIMARY KEY CLUSTERED ([UNIQQTYNO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [UNIQLINENO]
    ON [dbo].[QTQTY]([UNIQLINENO] ASC);

