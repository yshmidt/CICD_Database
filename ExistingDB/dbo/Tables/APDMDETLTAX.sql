﻿CREATE TABLE [dbo].[APDMDETLTAX] (
    [UNIQAPDMDETLTAX] CHAR (10)      CONSTRAINT [DF__APDMDETLT__UNIQA__3283CC08] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    [UNIQDMHEAD]      CHAR (10)      CONSTRAINT [DF__APDMDETLT__UNIQD__3377F041] DEFAULT ('') NOT NULL,
    [UNIQDMDETL]      CHAR (10)      CONSTRAINT [DF__APDMDETLT__UNIQD__346C147A] DEFAULT ('') NOT NULL,
    [TAX_ID]          CHAR (8)       CONSTRAINT [DF__APDMDETLT__TAX_I__356038B3] DEFAULT ('') NOT NULL,
    [TAX_RATE]        NUMERIC (8, 4) CONSTRAINT [DF__APDMDETLT__TAX_R__36545CEC] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK__APDMDETL__5CC128DE46027F2F] PRIMARY KEY CLUSTERED ([UNIQAPDMDETLTAX] ASC)
);
