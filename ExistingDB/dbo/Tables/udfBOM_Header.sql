CREATE TABLE [dbo].[udfBOM_Header] (
    [udfId]      UNIQUEIDENTIFIER CONSTRAINT [DF_udfBOM_Header_udfId] DEFAULT (newid()) NOT NULL,
    [fkUNIQ_KEY] CHAR (10)        CONSTRAINT [DF_udfBOM_Header_fkUNIQ_KEY] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_udfBOM_Header] PRIMARY KEY CLUSTERED ([udfId] ASC)
);

