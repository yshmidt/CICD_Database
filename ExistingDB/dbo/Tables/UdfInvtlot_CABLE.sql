﻿CREATE TABLE [dbo].[UdfInvtlot_CABLE] (
    [udfId]      UNIQUEIDENTIFIER CONSTRAINT [DF_UdfInvtlot_CABLE_udfId] DEFAULT (newid()) NOT NULL,
    [fkUNIQ_LOT] CHAR (10)        CONSTRAINT [DF_UdfInvtlot_CABLE_fkUNIQ_LOT] DEFAULT ('') NOT NULL,
    [VOLTAGE]    VARCHAR (100)    CONSTRAINT [DF_UdfInvtlot_CABLE_VOLTAGE] DEFAULT ('0') NULL,
    CONSTRAINT [PK_UdfInvtlot_CABLE] PRIMARY KEY CLUSTERED ([udfId] ASC)
);

