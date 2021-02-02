CREATE TYPE [dbo].[SearchGroupType] AS TABLE (
    [searchProc] VARCHAR (MAX)  NOT NULL,
    [id]         VARCHAR (50)   NOT NULL,
    [group]      NVARCHAR (255) NOT NULL,
    [table]      NVARCHAR (255) NOT NULL,
    [link]       VARCHAR (255)  NOT NULL,
    [groupName]  NVARCHAR (255) NOT NULL,
    [groupDescr] NVARCHAR (255) NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC));

