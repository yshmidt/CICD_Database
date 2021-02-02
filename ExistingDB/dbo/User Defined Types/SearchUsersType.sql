CREATE TYPE [dbo].[SearchUsersType] AS TABLE (
    [searchProc] VARCHAR (MAX)  NOT NULL,
    [id]         VARCHAR (50)   NOT NULL,
    [group]      NVARCHAR (255) NOT NULL,
    [table]      NVARCHAR (255) NOT NULL,
    [link]       VARCHAR (255)  NOT NULL,
    [fullName]   NVARCHAR (255) NOT NULL,
    [phone_f]    NVARCHAR (255) NULL,
    [INIT_f]     NVARCHAR (255) NULL,
    [WC_a]       NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([id] ASC));

