CREATE TABLE [dbo].[UdfInvtlot_CAP_SMT] (
    [udfId]       UNIQUEIDENTIFIER CONSTRAINT [DF_UdfInvtlot_CAP_SMT_udfId] DEFAULT (newid()) NOT NULL,
    [fkUNIQ_LOT]  CHAR (10)        CONSTRAINT [DF_UdfInvtlot_CAP_SMT_fkUNIQ_LOT] DEFAULT ('') NOT NULL,
    [String_Test] VARCHAR (400)    CONSTRAINT [DF_UdfInvtlot_CAP_SMT_String_Test] DEFAULT ('') NULL,
    CONSTRAINT [PK_UdfInvtlot_CAP_SMT] PRIMARY KEY CLUSTERED ([udfId] ASC)
);

