CREATE TABLE [dbo].[wmUserGridConfig] (
    [userId]     UNIQUEIDENTIFIER NOT NULL,
    [gridId]     VARCHAR (50)     NOT NULL,
    [colModel]   VARCHAR (MAX)    NOT NULL,
    [colNames]   VARCHAR (MAX)    NOT NULL,
    [groupedCol] VARCHAR (MAX)    NULL,
    CONSTRAINT [PK__WMUserG__2F61851B55773733] PRIMARY KEY CLUSTERED ([userId] ASC, [gridId] ASC)
);

