CREATE TABLE [dbo].[UdfInvtlot_RES_SMT] (
    [udfId]      UNIQUEIDENTIFIER CONSTRAINT [DF_UdfInvtlot_RES_SMT_udfId] DEFAULT (newid()) NOT NULL,
    [fkUNIQ_LOT] CHAR (10)        CONSTRAINT [DF_UdfInvtlot_RES_SMT_fkUNIQ_LOT] DEFAULT ('') NOT NULL,
    [testlot]    VARCHAR (500)    CONSTRAINT [DF_UdfInvtlot_RES_SMT_testlot] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_UdfInvtlot_RES_SMT] PRIMARY KEY CLUSTERED ([udfId] ASC)
);

