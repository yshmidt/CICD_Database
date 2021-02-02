CREATE TABLE [dbo].[udfBOM_Details] (
    [udfId]       UNIQUEIDENTIFIER CONSTRAINT [DF_udfBOM_Details_udfId] DEFAULT (newid()) NOT NULL,
    [fkUNIQBOMNO] CHAR (10)        CONSTRAINT [DF_udfBOM_Details_fkUNIQBOMNO] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_udfBOM_Details] PRIMARY KEY CLUSTERED ([udfId] ASC)
);

