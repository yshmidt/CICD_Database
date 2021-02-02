CREATE TABLE [dbo].[udfWOTransfer] (
    [udfId]       UNIQUEIDENTIFIER CONSTRAINT [DF_udfWOTransfer_udfId] DEFAULT (newid()) NOT NULL,
    [fkUNIQUEREC] CHAR (10)        CONSTRAINT [DF_udfWOTransfer_fkUNIQUEREC] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_udfWOTransfer] PRIMARY KEY CLUSTERED ([udfId] ASC)
);

