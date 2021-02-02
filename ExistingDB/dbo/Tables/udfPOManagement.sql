CREATE TABLE [dbo].[udfPOManagement] (
    [udfId]       UNIQUEIDENTIFIER CONSTRAINT [DF_udfPOManagement_udfId] DEFAULT (newid()) NOT NULL,
    [fkPOUNIQUE]  CHAR (10)        CONSTRAINT [DF_udfPOManagement_fkPOUNIQUE] DEFAULT ('') NOT NULL,
    [Test_String] VARCHAR (600)    CONSTRAINT [DF_udfPOManagement_Test_String] DEFAULT ('""') NULL,
    CONSTRAINT [PK_udfPOManagement] PRIMARY KEY CLUSTERED ([udfId] ASC)
);

