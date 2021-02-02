﻿CREATE TABLE [dbo].[CurrTrfr] (
    [TRFRKEY]         CHAR (10)       CONSTRAINT [DF__CurrTrfr__TRFRKE__79A05467] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    [JEOHKEY]         CHAR (10)       CONSTRAINT [DF__CurrTrfr__JEOHKE__7A9478A0] DEFAULT ('') NOT NULL,
    [JEODKEY]         CHAR (10)       CONSTRAINT [DF__CurrTrfr__JEODKE__7B889CD9] DEFAULT ('') NOT NULL,
    [JE_NO]           NUMERIC (6)     CONSTRAINT [DF__CurrTrfr__JE_NO__7C7CC112] DEFAULT ((0)) NOT NULL,
    [CT_NO]           NUMERIC (6)     CONSTRAINT [DF__CurrTrfr__CT_NO__7D70E54B] DEFAULT ((0)) NOT NULL,
    [BK_UNIQ]         CHAR (10)       CONSTRAINT [DF__CurrTrfr__BK_UNI__7E650984] DEFAULT ('') NOT NULL,
    [TRANSDATE]       SMALLDATETIME   NULL,
    [REF_NO]          CHAR (10)       CONSTRAINT [DF__CurrTrfr__REF_NO__7F592DBD] DEFAULT ('') NOT NULL,
    [DEBIT]           NUMERIC (14, 2) CONSTRAINT [DF__CurrTrfr__DEBIT__004D51F6] DEFAULT ((0)) NOT NULL,
    [CREDIT]          NUMERIC (14, 2) CONSTRAINT [DF__CurrTrfr__CREDIT__0141762F] DEFAULT ((0)) NOT NULL,
    [DEBITFC]         NUMERIC (14, 2) CONSTRAINT [DF__CurrTrfr__DEBITF__02359A68] DEFAULT ((0)) NOT NULL,
    [CREDITFC]        NUMERIC (14, 2) CONSTRAINT [DF__CurrTrfr__CREDIT__0329BEA1] DEFAULT ((0)) NOT NULL,
    [ORIG_BK_BAL]     NUMERIC (13, 2) CONSTRAINT [DF__CurrTrfr__ORIG_B__041DE2DA] DEFAULT ((0)) NOT NULL,
    [ORIG_BK_BALFC]   NUMERIC (13, 2) CONSTRAINT [DF__CurrTrfr__ORIG_B__05120713] DEFAULT ((0)) NOT NULL,
    [FINAL_BK_BAL]    NUMERIC (13, 2) CONSTRAINT [DF__CurrTrfr__FINAL___06062B4C] DEFAULT ((0)) NOT NULL,
    [FINAL_BK_BALFC]  NUMERIC (13, 2) CONSTRAINT [DF__CurrTrfr__FINAL___06FA4F85] DEFAULT ((0)) NOT NULL,
    [GL_NBR]          CHAR (13)       CONSTRAINT [DF__CurrTrfr__GL_NBR__07EE73BE] DEFAULT ('') NOT NULL,
    [CHKMANUAL]       BIT             NULL,
    [NOTES]           CHAR (250)      CONSTRAINT [DF__CurrTrfr__NOTES__08E297F7] DEFAULT ('') NOT NULL,
    [SUNDRY]          CHAR (15)       CONSTRAINT [DF__CurrTrfr__SUNDRY__09D6BC30] DEFAULT ('') NOT NULL,
    [TAX_ID]          CHAR (8)        CONSTRAINT [DF__CurrTrfr__TAX_ID__0ACAE069] DEFAULT ('') NOT NULL,
    [TAX_RATE]        NUMERIC (8, 4)  CONSTRAINT [DF__CurrTrfr__TAX_RA__0BBF04A2] DEFAULT ((0)) NOT NULL,
    [FCHIST_KEY]      CHAR (10)       CONSTRAINT [DF__CurrTrfr__FCHIST__0CB328DB] DEFAULT ('') NOT NULL,
    [FCUSED_UNIQ]     CHAR (10)       CONSTRAINT [DF__CurrTrfr__FCUSED__0DA74D14] DEFAULT ('') NOT NULL,
    [DEBITPR]         NUMERIC (14, 2) CONSTRAINT [DF__CurrTrfr__DEBITP__08F93D3E] DEFAULT ((0)) NOT NULL,
    [CREDITPR]        NUMERIC (14, 2) CONSTRAINT [DF__CurrTrfr__CREDIT__09ED6177] DEFAULT ((0)) NOT NULL,
    [ORIG_BK_BALPR]   NUMERIC (13, 2) CONSTRAINT [DF__CurrTrfr__ORIG_B__0AE185B0] DEFAULT ((0)) NOT NULL,
    [FINAL_BK_BALPR]  NUMERIC (13, 2) CONSTRAINT [DF__CurrTrfr__FINAL___0BD5A9E9] DEFAULT ((0)) NOT NULL,
    [PRFCUSED_UNIQ]   CHAR (10)       CONSTRAINT [DF__CurrTrfr__PRFCUS__0CC9CE22] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)       CONSTRAINT [DF__CurrTrfr__FUNCFC__0DBDF25B] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK__CurrTrfr__28EB21521A4803EB] PRIMARY KEY CLUSTERED ([TRFRKEY] ASC)
);
