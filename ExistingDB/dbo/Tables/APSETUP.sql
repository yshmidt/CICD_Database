﻿CREATE TABLE [dbo].[APSETUP] (
    [UNIQAPSET]     CHAR (10)    CONSTRAINT [DF__APSETUP__UNIQAPS__047AA831] DEFAULT ('') NOT NULL,
    [UNIQSEG1]      CHAR (10)    CONSTRAINT [DF__APSETUP__UNIQSEG__056ECC6A] DEFAULT ('') NOT NULL,
    [UNIQSEG2]      CHAR (10)    CONSTRAINT [DF__APSETUP__UNIQSEG__0662F0A3] DEFAULT ('') NOT NULL,
    [UNIQSEG3]      CHAR (10)    CONSTRAINT [DF__APSETUP__UNIQSEG__075714DC] DEFAULT ('') NOT NULL,
    [APLINK]        CHAR (10)    CONSTRAINT [DF__APSETUP__APLINK__084B3915] DEFAULT ('') NOT NULL,
    [CKLINK]        CHAR (10)    CONSTRAINT [DF__APSETUP__CKLINK__093F5D4E] DEFAULT ('') NOT NULL,
    [CK_IMPRES]     BIT          CONSTRAINT [DF__APSETUP__CK_IMPR__0A338187] DEFAULT ((0)) NOT NULL,
    [DISCLINK]      CHAR (10)    CONSTRAINT [DF__APSETUP__DISCLIN__0B27A5C0] DEFAULT ('') NOT NULL,
    [RECLINK]       CHAR (10)    CONSTRAINT [DF__APSETUP__RECLINK__0C1BC9F9] DEFAULT ('') NOT NULL,
    [VDISCLINK]     CHAR (10)    CONSTRAINT [DF__APSETUP__VDISCLI__0D0FEE32] DEFAULT ('') NOT NULL,
    [PULINK]        CHAR (10)    CONSTRAINT [DF__APSETUP__PULINK__0E04126B] DEFAULT ('') NOT NULL,
    [STAXLINK]      CHAR (10)    CONSTRAINT [DF__APSETUP__STAXLIN__0EF836A4] DEFAULT ('') NOT NULL,
    [RETLINK]       CHAR (10)    CONSTRAINT [DF__APSETUP__RETLINK__10E07F16] DEFAULT ('') NOT NULL,
    [VATPAYLINK]    CHAR (10)    CONSTRAINT [DF__APSETUP__VATPAYL__11D4A34F] DEFAULT ('') NOT NULL,
    [VATREFLINK]    CHAR (10)    CONSTRAINT [DF__APSETUP__VATREFL__12C8C788] DEFAULT ('') NOT NULL,
    [DIVNO]         CHAR (2)     CONSTRAINT [DF__APSETUP__DIVNO__13BCEBC1] DEFAULT ('') NOT NULL,
    [AP_GL_NO]      CHAR (13)    CONSTRAINT [DF__APSETUP__AP_GL_N__14B10FFA] DEFAULT ('') NOT NULL,
    [CK_GL_NO]      CHAR (13)    CONSTRAINT [DF__APSETUP__CK_GL_N__15A53433] DEFAULT ('') NOT NULL,
    [DISC_GL_NO]    CHAR (13)    CONSTRAINT [DF__APSETUP__DISC_GL__1699586C] DEFAULT ('') NOT NULL,
    [PO_REC_HOLD]   CHAR (13)    CONSTRAINT [DF__APSETUP__PO_REC___178D7CA5] DEFAULT ('') NOT NULL,
    [VDISC_GL_NO]   CHAR (13)    CONSTRAINT [DF__APSETUP__VDISC_G__1881A0DE] DEFAULT ('') NOT NULL,
    [FRT_GL_NO]     CHAR (13)    CONSTRAINT [DF__APSETUP__FRT_GL___1975C517] DEFAULT ('') NOT NULL,
    [PU_GL_NO]      CHAR (13)    CONSTRAINT [DF__APSETUP__PU_GL_N__1A69E950] DEFAULT ('') NOT NULL,
    [RET_GL_NO]     CHAR (13)    CONSTRAINT [DF__APSETUP__RET_GL___1B5E0D89] DEFAULT ('') NOT NULL,
    [STAX_GL_NO]    CHAR (13)    CONSTRAINT [DF__APSETUP__STAX_GL__1C5231C2] DEFAULT ('') NOT NULL,
    [APITEMNO]      NUMERIC (10) CONSTRAINT [DF__APSETUP__APITEMN__1D4655FB] DEFAULT ((0)) NOT NULL,
    [FRTLINK]       CHAR (10)    CONSTRAINT [DF__APSETUP__FRTLINK__1E3A7A34] DEFAULT ('') NOT NULL,
    [CHECKADVANCE]  BIT          CONSTRAINT [DF__APSETUP__CHECKAD__1F2E9E6D] DEFAULT ((0)) NOT NULL,
    [PREPAYGLNO]    CHAR (13)    CONSTRAINT [DF__APSETUP__PREPAYG__2022C2A6] DEFAULT ('') NOT NULL,
    [CEV_GL_NO]     CHAR (13)    CONSTRAINT [DF__APSETUP__CEV_GL___30A5A537] DEFAULT ('') NOT NULL,
    [WIRETRFRNO]    VARCHAR (50) NULL,
    [CTVFUNC_GL_NO] CHAR (13)    CONSTRAINT [DF__APSETUP__CTVFUNC__4D8E5EAD] DEFAULT ('') NOT NULL,
    [CTVPR_GL_NO]   CHAR (13)    CONSTRAINT [DF__APSETUP__CTVPR_G__4E8282E6] DEFAULT ('') NOT NULL,
    CONSTRAINT [APSETUP_PK] PRIMARY KEY CLUSTERED ([UNIQAPSET] ASC)
);

