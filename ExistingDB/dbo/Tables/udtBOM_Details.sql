CREATE TABLE [dbo].[udtBOM_Details] (
    [udfId]       UNIQUEIDENTIFIER CONSTRAINT [DF_udtBOM_Details_udfId] DEFAULT (newid()) NOT NULL,
    [fkUNIQBOMNO] CHAR (10)        CONSTRAINT [DF_udtBOM_Details_fkUNIQBOMNO] DEFAULT ('') NOT NULL,
    [Length]      DECIMAL (15, 5)  CONSTRAINT [DF_udtBOM_Details_Length] DEFAULT ('0') NULL,
    [Ref_Desg]    VARCHAR (100)    CONSTRAINT [DF_udtBOM_Details_Ref_Desg] DEFAULT ('') NULL,
    CONSTRAINT [PK_udtBOM_Details] PRIMARY KEY CLUSTERED ([udfId] ASC)
);

