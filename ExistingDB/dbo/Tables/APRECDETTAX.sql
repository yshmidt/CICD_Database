﻿CREATE TABLE [dbo].[APRECDETTAX] (
    [UNIQAPRECDETTAX] CHAR (10)      CONSTRAINT [DF__APRECDETT__UNIQA__0981B675] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    [UNIQRECUR]       CHAR (10)      CONSTRAINT [DF__APRECDETT__UNIQR__0A75DAAE] DEFAULT ('') NOT NULL,
    [UNIQDETREC]      CHAR (10)      CONSTRAINT [DF__APRECDETT__UNIQD__0B69FEE7] DEFAULT ('') NOT NULL,
    [TAX_ID]          CHAR (8)       CONSTRAINT [DF__APRECDETT__TAX_I__0C5E2320] DEFAULT ('') NOT NULL,
    [TAX_RATE]        NUMERIC (8, 4) CONSTRAINT [DF__APRECDETT__TAX_R__0D524759] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK__APRECDET__01CA46C52CEB9333] PRIMARY KEY CLUSTERED ([UNIQAPRECDETTAX] ASC)
);

