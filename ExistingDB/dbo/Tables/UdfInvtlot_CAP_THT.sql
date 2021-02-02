﻿CREATE TABLE [dbo].[UdfInvtlot_CAP_THT] (
    [udfId]      UNIQUEIDENTIFIER CONSTRAINT [DF_UdfInvtlot_CAP_THT_udfId] DEFAULT (newid()) NOT NULL,
    [fkUNIQ_LOT] CHAR (10)        CONSTRAINT [DF_UdfInvtlot_CAP_THT_fkUNIQ_LOT] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_UdfInvtlot_CAP_THT] PRIMARY KEY CLUSTERED ([udfId] ASC)
);

