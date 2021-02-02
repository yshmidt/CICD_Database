CREATE TABLE [dbo].[udfPackingList] (
    [udfId]        UNIQUEIDENTIFIER CONSTRAINT [DF_udfPackingList_udfId] DEFAULT (newid()) NOT NULL,
    [fkPACKLISTNO] CHAR (10)        CONSTRAINT [DF_udfPackingList_fkPACKLISTNO] DEFAULT ('') NOT NULL,
    [Weight]       VARCHAR (50)     CONSTRAINT [DF_udfPackingList_Weight] DEFAULT ('') NULL,
    CONSTRAINT [PK_udfPackingList] PRIMARY KEY CLUSTERED ([udfId] ASC)
);

