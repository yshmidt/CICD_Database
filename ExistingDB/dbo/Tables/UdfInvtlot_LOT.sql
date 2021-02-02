CREATE TABLE [dbo].[UdfInvtlot_LOT] (
    [udfId]      UNIQUEIDENTIFIER CONSTRAINT [DF_UdfInvtlot_LOT_udfId] DEFAULT (newid()) NOT NULL,
    [fkUNIQ_LOT] CHAR (10)        CONSTRAINT [DF_UdfInvtlot_LOT_fkUNIQ_LOT] DEFAULT ('') NOT NULL,
    [Value]      VARCHAR (2000)   CONSTRAINT [DF_UdfInvtlot_LOT_Value] DEFAULT ('1000ohm') NULL,
    [Voltage]    VARCHAR (3000)   CONSTRAINT [DF_UdfInvtlot_LOT_Voltage] DEFAULT ('10V') NULL,
    CONSTRAINT [PK_UdfInvtlot_LOT] PRIMARY KEY CLUSTERED ([udfId] ASC)
);

