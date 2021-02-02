CREATE TABLE [dbo].[UdfInvtlot_AUDIO] (
    [udfId]      UNIQUEIDENTIFIER CONSTRAINT [DF_UdfInvtlot_AUDIO_udfId] DEFAULT (newid()) NOT NULL,
    [fkUNIQ_LOT] CHAR (10)        CONSTRAINT [DF_UdfInvtlot_AUDIO_fkUNIQ_LOT] DEFAULT ('') NOT NULL,
    [Xref]       VARCHAR (30)     CONSTRAINT [DF_UdfInvtlot_AUDIO_Xref] DEFAULT ('') NULL,
    [testlot]    VARCHAR (500)    CONSTRAINT [DF_UdfInvtlot_AUDIO_testlot] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_UdfInvtlot_AUDIO] PRIMARY KEY CLUSTERED ([udfId] ASC)
);

