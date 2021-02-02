CREATE TYPE [dbo].[SearchBoMType] AS TABLE (
    [searchProc]    VARCHAR (255)  NULL,
    [id]            VARCHAR (50)   NOT NULL,
    [group]         NVARCHAR (255) NOT NULL,
    [table]         NVARCHAR (255) NOT NULL,
    [link]          VARCHAR (255)  NOT NULL,
    [partNumber_f]  VARCHAR (255)  NOT NULL,
    [revision_f]    VARCHAR (255)  NOT NULL,
    [description_f] NVARCHAR (255) NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC));

