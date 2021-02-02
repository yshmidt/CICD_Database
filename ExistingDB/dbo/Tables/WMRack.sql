CREATE TABLE [dbo].[WMRack] (
    [UniqRack]  NVARCHAR (10)   NOT NULL,
    [Name]      VARCHAR (50)    NOT NULL,
    [UniqAisle] NVARCHAR (10)   NOT NULL,
    [Height]    NUMERIC (18, 2) NULL,
    [Width]     NUMERIC (18, 2) NULL,
    [XAxis]     FLOAT (53)      NOT NULL,
    [YAxis]     FLOAT (53)      NOT NULL,
    [Angle]     NUMERIC (18, 2) NULL,
    CONSTRAINT [PK_WMRack] PRIMARY KEY CLUSTERED ([UniqRack] ASC),
    CONSTRAINT [fk_uniqAisle] FOREIGN KEY ([UniqAisle]) REFERENCES [dbo].[WMAisle] ([UniqAisle]) ON DELETE CASCADE
);

