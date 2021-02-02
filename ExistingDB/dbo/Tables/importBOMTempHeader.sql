CREATE TABLE [dbo].[importBOMTempHeader] (
    [importId] UNIQUEIDENTIFIER NOT NULL,
    [custno]   VARCHAR (MAX)    CONSTRAINT [DF_importBOMTempHeader_custno] DEFAULT ('') NOT NULL,
    [assynum]  VARCHAR (MAX)    CONSTRAINT [DF_importBOMTempHeader_assynum] DEFAULT ('') NOT NULL,
    [assyrev]  VARCHAR (MAX)    CONSTRAINT [DF_importBOMTempHeader_assyrev] DEFAULT ('') NOT NULL,
    [assydesc] VARCHAR (MAX)    CONSTRAINT [DF_importBOMTempHeader_assydesc] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_importBOMTempHeader] PRIMARY KEY CLUSTERED ([importId] ASC)
);

