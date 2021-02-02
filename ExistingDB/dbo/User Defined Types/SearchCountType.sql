CREATE TYPE [dbo].[SearchCountType] AS TABLE (
    [searchProc] VARCHAR (255)  NULL,
    [group]      NVARCHAR (255) NOT NULL,
    [table]      NVARCHAR (255) NOT NULL,
    [link]       VARCHAR (255)  NOT NULL);

