CREATE TABLE [dbo].[WMAisle] (
    [UniqAisle] NVARCHAR (10)   NOT NULL,
    [Name]      VARCHAR (50)    NOT NULL,
    [UniqWH]    NVARCHAR (10)   NOT NULL,
    [Height]    NUMERIC (18, 2) NULL,
    [Width]     NUMERIC (18, 2) NULL,
    [XAxis]     FLOAT (53)      NOT NULL,
    [YAxis]     FLOAT (53)      NOT NULL,
    [Angle]     NUMERIC (18, 2) NULL,
    CONSTRAINT [PK_WMAisle] PRIMARY KEY CLUSTERED ([UniqAisle] ASC)
);

