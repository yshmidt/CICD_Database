CREATE TYPE [dbo].[tSimulationPartData] AS TABLE (
    [Id]      INT              NULL,
    [RowUID]  UNIQUEIDENTIFIER NULL,
    [UniqKey] CHAR (10)        DEFAULT ('') NOT NULL);

