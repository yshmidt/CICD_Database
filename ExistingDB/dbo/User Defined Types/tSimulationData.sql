CREATE TYPE [dbo].[tSimulationData] AS TABLE (
    [Id]      INT              NULL,
    [RowUID]  UNIQUEIDENTIFIER NULL,
    [WONO]    CHAR (10)        NULL,
    [UniqKey] CHAR (10)        DEFAULT ('') NOT NULL,
    [QTY]     NUMERIC (12, 2)  NULL);

