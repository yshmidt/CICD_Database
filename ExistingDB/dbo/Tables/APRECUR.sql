﻿CREATE TABLE [dbo].[APRECUR] (
    [UNIQRECUR]       CHAR (10)       CONSTRAINT [DF__APRECUR__UNIQREC__6BAEFA67] DEFAULT ('') NOT NULL,
    [UNIQSUPNO]       CHAR (10)       CONSTRAINT [DF__APRECUR__UNIQSUP__6D9742D9] DEFAULT ('') NOT NULL,
    [INVNO]           CHAR (20)       CONSTRAINT [DF__APRECUR__INVNO__6E8B6712] DEFAULT ('') NOT NULL,
    [DUE_DATE]        SMALLDATETIME   NULL,
    [RECR_DATE]       SMALLDATETIME   NULL,
    [PONUM]           CHAR (15)       CONSTRAINT [DF__APRECUR__PONUM__6F7F8B4B] DEFAULT ('') NOT NULL,
    [INVAMOUNT]       NUMERIC (12, 2) CONSTRAINT [DF__APRECUR__INVAMOU__7073AF84] DEFAULT ((0)) NOT NULL,
    [RECR_NOTE]       TEXT            CONSTRAINT [DF__APRECUR__RECR_NO__7167D3BD] DEFAULT ('') NOT NULL,
    [APTYPE]          CHAR (10)       CONSTRAINT [DF__APRECUR__APTYPE__725BF7F6] DEFAULT ('') NOT NULL,
    [DESCRIPT]        CHAR (30)       CONSTRAINT [DF__APRECUR__DESCRIP__73501C2F] DEFAULT ('') NOT NULL,
    [PERIOD]          CHAR (12)       CONSTRAINT [DF__APRECUR__PERIOD__753864A1] DEFAULT ('') NOT NULL,
    [MAXPMTS]         NUMERIC (4)     CONSTRAINT [DF__APRECUR__MAXPMTS__762C88DA] DEFAULT ((0)) NOT NULL,
    [NO_INVCD]        NUMERIC (4)     CONSTRAINT [DF__APRECUR__NO_INVC__7720AD13] DEFAULT ((0)) NOT NULL,
    [TOTAMT_GEN]      NUMERIC (12, 2) CONSTRAINT [DF__APRECUR__TOTAMT___7814D14C] DEFAULT ((0)) NOT NULL,
    [PMTTYPE]         CHAR (5)        CONSTRAINT [DF__APRECUR__PMTTYPE__7908F585] DEFAULT ('') NOT NULL,
    [FIRSTPMT]        SMALLDATETIME   NULL,
    [LASTPMTGEN]      SMALLDATETIME   NULL,
    [SELECTED]        BIT             CONSTRAINT [DF__APRECUR__SELECTE__7AF13DF7] DEFAULT ((0)) NOT NULL,
    [C_LINK]          CHAR (10)       CONSTRAINT [DF__APRECUR__C_LINK__7BE56230] DEFAULT ('') NOT NULL,
    [R_LINK]          CHAR (10)       CONSTRAINT [DF__APRECUR__R_LINK__7CD98669] DEFAULT ('') NOT NULL,
    [TERMS]           CHAR (15)       CONSTRAINT [DF__APRECUR__TERMS__7DCDAAA2] DEFAULT ('') NOT NULL,
    [EDITDATE]        SMALLDATETIME   NULL,
    [INIT]            CHAR (8)        CONSTRAINT [DF__APRECUR__INIT__7EC1CEDB] DEFAULT ('') NOT NULL,
    [REASON]          CHAR (30)       CONSTRAINT [DF__APRECUR__REASON__7FB5F314] DEFAULT ('') NOT NULL,
    [IS_CLOSED]       BIT             CONSTRAINT [DF__APRECUR__IS_CLOS__00AA174D] DEFAULT ((0)) NOT NULL,
    [Pmt2DOM]         NUMERIC (2)     CONSTRAINT [DF_APRECUR_Pmt2DOM] DEFAULT ((0)) NOT NULL,
    [PmtDow]          NUMERIC (1)     CONSTRAINT [DF_APRECUR_PmtDow] DEFAULT ((0)) NOT NULL,
    [INVAMOUNTFC]     NUMERIC (12, 2) CONSTRAINT [DF__APRECUR__INVAMOU__01E094AD] DEFAULT ((0)) NOT NULL,
    [TOTAMT_GENFC]    NUMERIC (12, 2) CONSTRAINT [DF__APRECUR__TOTAMT___02D4B8E6] DEFAULT ((0)) NOT NULL,
    [FCUSED_UNIQ]     CHAR (10)       CONSTRAINT [DF__APRECUR__FCUSED___03C8DD1F] DEFAULT ('') NOT NULL,
    [FCHIST_KEY]      CHAR (10)       CONSTRAINT [DF__APRECUR__FCHIST___04BD0158] DEFAULT ('') NOT NULL,
    [INVAMOUNTPR]     NUMERIC (12, 2) CONSTRAINT [DF__APRECUR__INVAMOU__4A71FAE0] DEFAULT ((0)) NOT NULL,
    [TOTAMT_GENPR]    NUMERIC (12, 2) CONSTRAINT [DF__APRECUR__TOTAMT___4B661F19] DEFAULT ((0)) NOT NULL,
    [PRFCUSED_UNIQ]   CHAR (10)       CONSTRAINT [DF__APRECUR__PRFCUSE__4C5A4352] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)       CONSTRAINT [DF__APRECUR__FUNCFCU__4D4E678B] DEFAULT ('') NOT NULL,
    CONSTRAINT [APRECUR_PK] PRIMARY KEY CLUSTERED ([UNIQRECUR] ASC)
);


GO
CREATE NONCLUSTERED INDEX [INVNO]
    ON [dbo].[APRECUR]([UNIQSUPNO] ASC, [INVNO] ASC);

