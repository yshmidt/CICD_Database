CREATE TABLE [dbo].[MyTable] (
    [nID]            INT           IDENTITY (1, 1) NOT NULL,
    [cName]          VARCHAR (100) NULL,
    [RecVer]         ROWVERSION    NOT NULL,
    [nDescRowNumber] INT           CONSTRAINT [DF_MyTable_nDescRowNumber] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [MyTable_PK] PRIMARY KEY CLUSTERED ([nID] ASC)
);

