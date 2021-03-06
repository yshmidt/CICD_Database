﻿CREATE TABLE [dbo].[APCHKDET] (
    [APCKD_UNIQ]      CHAR (10)       CONSTRAINT [DF__APCHKDET__APCKD___2B0A656D] DEFAULT ('') NOT NULL,
    [APCHK_UNIQ]      CHAR (10)       CONSTRAINT [DF__APCHKDET__APCHK___2BFE89A6] DEFAULT ('') NOT NULL,
    [CHECKNO]         CHAR (10)       CONSTRAINT [DF__APCHKDET__CHECKN__2DE6D218] DEFAULT ('') NOT NULL,
    [PONUM]           CHAR (15)       CONSTRAINT [DF__APCHKDET__PONUM__2EDAF651] DEFAULT ('') NOT NULL,
    [APRPAY]          NUMERIC (12, 2) CONSTRAINT [DF__APCHKDET__APRPAY__2FCF1A8A] DEFAULT ((0)) NOT NULL,
    [DISC_TKN]        NUMERIC (12, 2) CONSTRAINT [DF__APCHKDET__DISC_T__30C33EC3] DEFAULT ((0)) NOT NULL,
    [SUPID]           CHAR (10)       CONSTRAINT [DF__APCHKDET__SUPID__32AB8735] DEFAULT ('') NOT NULL,
    [INVNO]           CHAR (20)       CONSTRAINT [DF__APCHKDET__INVNO__339FAB6E] DEFAULT ('') NOT NULL,
    [INVDATE]         SMALLDATETIME   NULL,
    [INVAMOUNT]       NUMERIC (12, 2) CONSTRAINT [DF__APCHKDET__INVAMO__3493CFA7] DEFAULT ((0)) NOT NULL,
    [DUE_DATE]        SMALLDATETIME   NULL,
    [ITEM_DESC]       CHAR (25)       CONSTRAINT [DF__APCHKDET__ITEM_D__3587F3E0] DEFAULT ('') NOT NULL,
    [GL_NBR]          CHAR (13)       CONSTRAINT [DF__APCHKDET__GL_NBR__367C1819] DEFAULT ('') NOT NULL,
    [TRANS_NO]        NUMERIC (10)    CONSTRAINT [DF__APCHKDET__TRANS___37703C52] DEFAULT ((0)) NOT NULL,
    [UNIQAPHEAD]      CHAR (10)       CONSTRAINT [DF__APCHKDET__UNIQAP__3864608B] DEFAULT ('') NOT NULL,
    [ITEM_NO]         NUMERIC (3)     CONSTRAINT [DF__APCHKDET__ITEM_N__395884C4] DEFAULT ((0)) NOT NULL,
    [ITEMNOTE]        TEXT            CONSTRAINT [DF__APCHKDET__ITEMNO__3B40CD36] DEFAULT ('') NOT NULL,
    [BALANCE]         NUMERIC (12, 2) CONSTRAINT [DF__APCHKDET__BALANC__3C34F16F] DEFAULT ((0)) NOT NULL,
    [APRPAYFC]        NUMERIC (12, 2) CONSTRAINT [DF__APCHKDET__APRPAY__53E4BFD3] DEFAULT ((0)) NOT NULL,
    [DISC_TKNFC]      NUMERIC (12, 2) CONSTRAINT [DF__APCHKDET__DISC_T__54D8E40C] DEFAULT ((0)) NOT NULL,
    [INVAMOUNTFC]     NUMERIC (12, 2) CONSTRAINT [DF__APCHKDET__INVAMO__55CD0845] DEFAULT ((0)) NOT NULL,
    [BALANCEFC]       NUMERIC (12, 2) CONSTRAINT [DF__APCHKDET__BALANC__56C12C7E] DEFAULT ((0)) NOT NULL,
    [ORIG_FCHIST_KEY] CHAR (10)       CONSTRAINT [DF__APCHKDET__ORIG_F__29B97BDD] DEFAULT ('') NOT NULL,
    [APRPAYPR]        NUMERIC (12, 2) CONSTRAINT [DF__APCHKDET__APRPAY__1D6A4A3F] DEFAULT ((0)) NOT NULL,
    [DISC_TKNPR]      NUMERIC (12, 2) CONSTRAINT [DF__APCHKDET__DISC_T__1E5E6E78] DEFAULT ((0)) NOT NULL,
    [INVAMOUNTPR]     NUMERIC (12, 2) CONSTRAINT [DF__APCHKDET__INVAMO__1F5292B1] DEFAULT ((0)) NOT NULL,
    [BALANCEPR]       NUMERIC (12, 2) CONSTRAINT [DF__APCHKDET__BALANC__2046B6EA] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [APCHKDET_PK] PRIMARY KEY CLUSTERED ([APCKD_UNIQ] ASC)
);


GO
CREATE NONCLUSTERED INDEX [APCHK_UNIQ]
    ON [dbo].[APCHKDET]([APCHK_UNIQ] ASC);


GO
CREATE NONCLUSTERED INDEX [APCHK_UNIQ_INCLUDE]
    ON [dbo].[APCHKDET]([APCHK_UNIQ] ASC)
    INCLUDE([APRPAY], [DISC_TKN], [GL_NBR]);


GO
CREATE NONCLUSTERED INDEX [CHECKINV]
    ON [dbo].[APCHKDET]([CHECKNO] ASC, [SUPID] ASC, [INVNO] ASC, [DUE_DATE] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQAPHEAD]
    ON [dbo].[APCHKDET]([UNIQAPHEAD] ASC);

