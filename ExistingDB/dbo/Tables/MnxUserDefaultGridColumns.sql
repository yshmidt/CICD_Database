CREATE TABLE [dbo].[MnxUserDefaultGridColumns] (
    [id]        INT           IDENTITY (1, 1) NOT NULL,
    [gridId]    VARCHAR (50)  NULL,
    [fixedCols] VARCHAR (MAX) NULL,
    [hideCols]  VARCHAR (MAX) NULL,
    [sortby]    VARCHAR (50)  NULL,
    CONSTRAINT [PK_userDefaultGridColumns] PRIMARY KEY CLUSTERED ([id] ASC)
);

