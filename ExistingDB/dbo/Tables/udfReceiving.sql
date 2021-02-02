CREATE TABLE [dbo].[udfReceiving] (
    [udfId]           UNIQUEIDENTIFIER CONSTRAINT [DF_udfReceiving_udfId] DEFAULT (newid()) NOT NULL,
    [fkreceiverHdrId] CHAR (10)        CONSTRAINT [DF_udfReceiving_fkreceiverHdrId] DEFAULT ('') NOT NULL,
    [Weight]          VARCHAR (20)     CONSTRAINT [DF_udfReceiving_Weight] DEFAULT ('') NOT NULL,
    [Test]            VARCHAR (34)     CONSTRAINT [DF_udfReceiving_Test] DEFAULT ('') NULL,
    CONSTRAINT [PK_udfReceiving] PRIMARY KEY CLUSTERED ([udfId] ASC)
);

