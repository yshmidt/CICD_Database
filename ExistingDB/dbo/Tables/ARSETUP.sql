﻿CREATE TABLE [dbo].[ARSETUP] (
    [DIVNO]         CHAR (2)    CONSTRAINT [DF__ARSETUP__DIVNO__60083D91] DEFAULT ('') NOT NULL,
    [AR_GL_NO]      CHAR (13)   CONSTRAINT [DF__ARSETUP__AR_GL_N__60FC61CA] DEFAULT ('') NOT NULL,
    [DEP_GL_NO]     CHAR (13)   CONSTRAINT [DF__ARSETUP__DEP_GL___61F08603] DEFAULT ('') NOT NULL,
    [DEP_IMPRES]    BIT         CONSTRAINT [DF__ARSETUP__DEP_IMP__62E4AA3C] DEFAULT ((0)) NOT NULL,
    [DISC_GL_NO]    CHAR (13)   CONSTRAINT [DF__ARSETUP__DISC_GL__63D8CE75] DEFAULT ('') NOT NULL,
    [PC_GL_NO]      CHAR (13)   CONSTRAINT [DF__ARSETUP__PC_GL_N__64CCF2AE] DEFAULT ('') NOT NULL,
    [OC_GL_NO]      CHAR (13)   CONSTRAINT [DF__ARSETUP__OC_GL_N__65C116E7] DEFAULT ('') NOT NULL,
    [OT_GL_NO]      CHAR (13)   CONSTRAINT [DF__ARSETUP__OT_GL_N__66B53B20] DEFAULT ('') NOT NULL,
    [FRT_GL_NO]     CHAR (13)   CONSTRAINT [DF__ARSETUP__FRT_GL___67A95F59] DEFAULT ('') NOT NULL,
    [FC_GL_NO]      CHAR (13)   CONSTRAINT [DF__ARSETUP__FC_GL_N__689D8392] DEFAULT ('') NOT NULL,
    [CUDEPGL_NO]    CHAR (13)   CONSTRAINT [DF__ARSETUP__CUDEPGL__6991A7CB] DEFAULT ('') NOT NULL,
    [ST_GL_NO]      CHAR (13)   CONSTRAINT [DF__ARSETUP__ST_GL_N__6A85CC04] DEFAULT ('') NOT NULL,
    [AL_GL_NO]      CHAR (13)   CONSTRAINT [DF__ARSETUP__AL_GL_N__6B79F03D] DEFAULT ('') NOT NULL,
    [BD_GL_NO]      CHAR (13)   CONSTRAINT [DF__ARSETUP__BD_GL_N__6C6E1476] DEFAULT ('') NOT NULL,
    [RET_GL_NO]     CHAR (13)   CONSTRAINT [DF__ARSETUP__RET_GL___6D6238AF] DEFAULT ('') NOT NULL,
    [AVG_DAYS]      NUMERIC (4) CONSTRAINT [DF__ARSETUP__AVG_DAY__6F4A8121] DEFAULT ((0)) NOT NULL,
    [HIGH_DAYS]     NUMERIC (4) CONSTRAINT [DF__ARSETUP__HIGH_DA__703EA55A] DEFAULT ((0)) NOT NULL,
    [ENFORCRLIM]    BIT         CONSTRAINT [DF__ARSETUP__ENFORCR__7132C993] DEFAULT ((0)) NOT NULL,
    [FORCETDATE]    BIT         CONSTRAINT [DF__ARSETUP__FORCETD__7226EDCC] DEFAULT ((0)) NOT NULL,
    [UNIQARSET]     CHAR (10)   CONSTRAINT [DF__ARSETUP__UNIQARS__731B1205] DEFAULT ('') NOT NULL,
    [UNIQSEG1]      CHAR (10)   CONSTRAINT [DF__ARSETUP__UNIQSEG__740F363E] DEFAULT ('') NOT NULL,
    [UNIQSEG2]      CHAR (10)   CONSTRAINT [DF__ARSETUP__UNIQSEG__75035A77] DEFAULT ('') NOT NULL,
    [UNIQSEG3]      CHAR (10)   CONSTRAINT [DF__ARSETUP__UNIQSEG__75F77EB0] DEFAULT ('') NOT NULL,
    [CEV_GL_NO]     CHAR (13)   CONSTRAINT [DF__ARSETUP__CEV_GL___2FB180FE] DEFAULT ('') NOT NULL,
    [CTVFUNC_GL_NO] CHAR (13)   CONSTRAINT [DF__ARSETUP__CTVFUNC__4BA6163B] DEFAULT ('') NOT NULL,
    [CTVPR_GL_NO]   CHAR (13)   CONSTRAINT [DF__ARSETUP__CTVPR_G__4C9A3A74] DEFAULT ('') NOT NULL,
    CONSTRAINT [ARSETUP_PK] PRIMARY KEY CLUSTERED ([UNIQARSET] ASC)
);
