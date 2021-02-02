﻿CREATE TABLE [dbo].[PKINPGST] (
    [PKPRINT_BY]   NUMERIC (1) CONSTRAINT [DF__PKINPGST__PKPRIN__67AA2AB0] DEFAULT ((0)) NOT NULL,
    [INPRINT_BY]   NUMERIC (1) CONSTRAINT [DF__PKINPGST__INPRIN__689E4EE9] DEFAULT ((0)) NOT NULL,
    [PKPRINTNO]    NUMERIC (2) CONSTRAINT [DF__PKINPGST__PKPRIN__69927322] DEFAULT ((0)) NOT NULL,
    [INVPRINTNO]   NUMERIC (2) CONSTRAINT [DF__PKINPGST__INVPRI__6A86975B] DEFAULT ((0)) NOT NULL,
    [PKSHOWZERO]   BIT         CONSTRAINT [DF__PKINPGST__PKSHOW__6B7ABB94] DEFAULT ((0)) NOT NULL,
    [INSHOWZERO]   BIT         CONSTRAINT [DF__PKINPGST__INSHOW__6C6EDFCD] DEFAULT ((0)) NOT NULL,
    [CALOPENORD]   BIT         CONSTRAINT [DF__PKINPGST__CALOPE__6D630406] DEFAULT ((0)) NOT NULL,
    [PK_CUSTPN]    BIT         CONSTRAINT [DF__PKINPGST__PK_CUS__6E57283F] DEFAULT ((0)) NOT NULL,
    [INV_CUSTPN]   BIT         CONSTRAINT [DF__PKINPGST__INV_CU__6F4B4C78] DEFAULT ((0)) NOT NULL,
    [PKPRINTBC]    BIT         CONSTRAINT [DF__PKINPGST__PKPRIN__703F70B1] DEFAULT ((0)) NOT NULL,
    [PKINPGSTUK]   CHAR (10)   CONSTRAINT [DF__PKINPGST__PKINPG__713394EA] DEFAULT ('') NOT NULL,
    [INVSHOWSN]    BIT         CONSTRAINT [DF__PKINPGST__INVSHO__22B6AD3C] DEFAULT ((0)) NOT NULL,
    [INVSHOWBKORD] BIT         CONSTRAINT [DF__PKINPGST__INVSHO__23AAD175] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PKINPGST_PK] PRIMARY KEY CLUSTERED ([PKINPGSTUK] ASC)
);

