CREATE TYPE [dbo].[selectToHtmlType] AS TABLE (
    [id] INT           IDENTITY (1, 1) NOT NULL,
    [c1] VARCHAR (MAX) NOT NULL,
    [c2] VARCHAR (MAX) NOT NULL,
    [c3] VARCHAR (MAX) NULL,
    [c4] VARCHAR (MAX) NULL,
    [c5] VARCHAR (MAX) NULL,
    [c6] VARCHAR (MAX) NULL,
    [c7] VARCHAR (MAX) NULL,
    [c8] VARCHAR (MAX) NULL,
    [c9] VARCHAR (MAX) NULL,
    PRIMARY KEY CLUSTERED ([id] ASC));

