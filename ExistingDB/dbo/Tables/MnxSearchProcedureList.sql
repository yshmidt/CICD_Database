CREATE TABLE [dbo].[MnxSearchProcedureList] (
    [procedureId]     INT          IDENTITY (1, 1) NOT NULL,
    [storedProcedure] VARCHAR (50) CONSTRAINT [DF_MnxSearchProcedureList_storedProcedure] DEFAULT ('') NOT NULL,
    [searchOrder]     INT          CONSTRAINT [DF_MnxSearchProcedureList_searchOrder] DEFAULT ((0)) NOT NULL,
    [isActive]        BIT          CONSTRAINT [DF_MnxSearchProcedureList_isActive] DEFAULT ((1)) NULL,
    CONSTRAINT [PK_MnxSearchProcedureList] PRIMARY KEY CLUSTERED ([procedureId] ASC)
);

