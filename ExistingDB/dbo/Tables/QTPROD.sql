﻿CREATE TABLE [dbo].[QTPROD] (
    [QUOTEUNIQ]     CHAR (10)    CONSTRAINT [DF__QTPROD__QUOTEUNI__6C24C70A] DEFAULT ('') NOT NULL,
    [QUOTENO]       CHAR (10)    CONSTRAINT [DF__QTPROD__QUOTENO__6D18EB43] DEFAULT ('') NOT NULL,
    [UNIQLINENO]    CHAR (10)    CONSTRAINT [DF__QTPROD__UNIQLINE__6E0D0F7C] DEFAULT ('') NOT NULL,
    [UNIQ_KEY]      CHAR (10)    CONSTRAINT [DF__QTPROD__UNIQ_KEY__6F0133B5] DEFAULT ('') NOT NULL,
    [SALETYPEID]    CHAR (10)    CONSTRAINT [DF__QTPROD__SALETYPE__6FF557EE] DEFAULT ('') NOT NULL,
    [STATUS]        CHAR (10)    CONSTRAINT [DF__QTPROD__STATUS__70E97C27] DEFAULT ('') NOT NULL,
    [ITEM]          NUMERIC (3)  CONSTRAINT [DF__QTPROD__ITEM__71DDA060] DEFAULT ((0)) NOT NULL,
    [PART_SOURC]    CHAR (10)    CONSTRAINT [DF__QTPROD__PART_SOU__72D1C499] DEFAULT ('') NOT NULL,
    [PART_NO]       CHAR (25)    CONSTRAINT [DF__QTPROD__PART_NO__73C5E8D2] DEFAULT ('') NOT NULL,
    [REVISION]      CHAR (4)     CONSTRAINT [DF__QTPROD__REVISION__74BA0D0B] DEFAULT ('') NOT NULL,
    [PART_CLASS]    CHAR (8)     CONSTRAINT [DF__QTPROD__PART_CLA__75AE3144] DEFAULT ('') NOT NULL,
    [PART_TYPE]     CHAR (8)     CONSTRAINT [DF__QTPROD__PART_TYP__76A2557D] DEFAULT ('') NOT NULL,
    [DESCRIPT]      CHAR (30)    CONSTRAINT [DF__QTPROD__DESCRIPT__779679B6] DEFAULT ('') NOT NULL,
    [PRODNOTE]      TEXT         CONSTRAINT [DF__QTPROD__PRODNOTE__788A9DEF] DEFAULT ('') NOT NULL,
    [PTLISTNOTE]    TEXT         CONSTRAINT [DF__QTPROD__PTLISTNO__797EC228] DEFAULT ('') NOT NULL,
    [MATL_DONE]     BIT          CONSTRAINT [DF__QTPROD__MATL_DON__7A72E661] DEFAULT ((0)) NOT NULL,
    [LABOR_DONE]    BIT          CONSTRAINT [DF__QTPROD__LABOR_DO__7B670A9A] DEFAULT ((0)) NOT NULL,
    [OTHER_DONE]    BIT          CONSTRAINT [DF__QTPROD__OTHER_DO__7C5B2ED3] DEFAULT ((0)) NOT NULL,
    [NRE_DONE]      BIT          CONSTRAINT [DF__QTPROD__NRE_DONE__7D4F530C] DEFAULT ((0)) NOT NULL,
    [BREAK_ITEM]    CHAR (20)    CONSTRAINT [DF__QTPROD__BREAK_IT__7E437745] DEFAULT ('') NOT NULL,
    [BREAK_NO]      CHAR (3)     CONSTRAINT [DF__QTPROD__BREAK_NO__7F379B7E] DEFAULT ('') NOT NULL,
    [LBREAKITEM]    CHAR (20)    CONSTRAINT [DF__QTPROD__LBREAKIT__002BBFB7] DEFAULT ('') NOT NULL,
    [LBREAK_NO]     CHAR (3)     CONSTRAINT [DF__QTPROD__LBREAK_N__011FE3F0] DEFAULT ('') NOT NULL,
    [MBREAKITEM]    CHAR (20)    CONSTRAINT [DF__QTPROD__MBREAKIT__02140829] DEFAULT ('') NOT NULL,
    [MBREAK_NO]     CHAR (3)     CONSTRAINT [DF__QTPROD__MBREAK_N__03082C62] DEFAULT ('') NOT NULL,
    [CALCDT]        CHAR (20)    CONSTRAINT [DF__QTPROD__CALCDT__03FC509B] DEFAULT ('') NOT NULL,
    [RECALC]        BIT          CONSTRAINT [DF__QTPROD__RECALC__04F074D4] DEFAULT ((0)) NOT NULL,
    [PRODFOOTNT]    TEXT         CONSTRAINT [DF__QTPROD__PRODFOOT__05E4990D] DEFAULT ('') NOT NULL,
    [APPROVED]      BIT          CONSTRAINT [DF__QTPROD__APPROVED__06D8BD46] DEFAULT ((0)) NOT NULL,
    [CALCSTD]       BIT          CONSTRAINT [DF__QTPROD__CALCSTD__07CCE17F] DEFAULT ((0)) NOT NULL,
    [STDQTY]        NUMERIC (7)  CONSTRAINT [DF__QTPROD__STDQTY__08C105B8] DEFAULT ((0)) NOT NULL,
    [CALCLABOR]     BIT          CONSTRAINT [DF__QTPROD__CALCLABO__09B529F1] DEFAULT ((0)) NOT NULL,
    [LABORQTY]      NUMERIC (7)  CONSTRAINT [DF__QTPROD__LABORQTY__0AA94E2A] DEFAULT ((0)) NOT NULL,
    [REQUIRE_SN]    BIT          CONSTRAINT [DF__QTPROD__REQUIRE___0B9D7263] DEFAULT ((0)) NOT NULL,
    [GLDIVNO]       CHAR (2)     CONSTRAINT [DF__QTPROD__GLDIVNO__0C91969C] DEFAULT ('') NOT NULL,
    [UNIQQTYNO]     CHAR (10)    CONSTRAINT [DF__QTPROD__UNIQQTYN__0D85BAD5] DEFAULT ('') NOT NULL,
    [PRICECRITERIA] CHAR (30)    CONSTRAINT [DF__QTPROD__PRICECRI__0E79DF0E] DEFAULT ('') NOT NULL,
    [PRICELTFACTOR] NUMERIC (3)  CONSTRAINT [DF__QTPROD__PRICELTF__0F6E0347] DEFAULT ((0)) NOT NULL,
    [TRANSALLAVL]   NUMERIC (10) CONSTRAINT [DF__QTPROD__TRANSALL__10622780] DEFAULT ((0)) NOT NULL,
    [MATLTYPE]      CHAR (10)    CONSTRAINT [DF__QTPROD__MATLTYPE__11564BB9] DEFAULT ('') NOT NULL,
    CONSTRAINT [QTPROD_PK] PRIMARY KEY CLUSTERED ([UNIQLINENO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [QUOTENO]
    ON [dbo].[QTPROD]([QUOTENO] ASC);


GO
CREATE NONCLUSTERED INDEX [QUOTEUNIQ]
    ON [dbo].[QTPROD]([QUOTEUNIQ] ASC);

