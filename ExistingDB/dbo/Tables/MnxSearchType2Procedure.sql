CREATE TABLE [dbo].[MnxSearchType2Procedure] (
    [fkProcedureId] INT NOT NULL,
    [fkTypeId]      INT NOT NULL,
    [resultOrder]   INT NOT NULL,
    CONSTRAINT [PK_MnxSearchType2Procedure] PRIMARY KEY CLUSTERED ([fkProcedureId] ASC, [fkTypeId] ASC)
);

