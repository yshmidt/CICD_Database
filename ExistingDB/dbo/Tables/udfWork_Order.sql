CREATE TABLE [dbo].[udfWork_Order] (
    [udfId]  UNIQUEIDENTIFIER CONSTRAINT [DF_udfWork_Order_udfId] DEFAULT (newid()) NOT NULL,
    [fkWONO] CHAR (10)        CONSTRAINT [DF_udfWork_Order_fkWONO] DEFAULT ('') NOT NULL,
    [SODate] DATE             CONSTRAINT [DF_udfWork_Order_SODate] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_udfWork_Order] PRIMARY KEY CLUSTERED ([udfId] ASC)
);

