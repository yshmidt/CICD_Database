CREATE TABLE [dbo].[ImportPoNum] (
    [ID]         INT         IDENTITY (1, 1) NOT NULL,
    [EmptyValue] VARCHAR (2) NULL,
    [PONUM]      AS          ('T-'+right(CONVERT([varchar](15),[ID],(0)),(15))),
    CONSTRAINT [PK__ImportPo__3214EC27A3D73855] PRIMARY KEY CLUSTERED ([ID] ASC)
);

