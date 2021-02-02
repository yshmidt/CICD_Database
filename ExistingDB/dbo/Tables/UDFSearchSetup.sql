CREATE TABLE [dbo].[UDFSearchSetup] (
    [FilterId]      INT              IDENTITY (1, 1) NOT NULL,
    [FilterName]    VARCHAR (100)    NULL,
    [CreatedUserId] UNIQUEIDENTIFIER NULL,
    [CreatedDate]   DATETIME         NULL,
    [SectionName]   VARCHAR (100)    NULL,
    [CapaStatus]    VARCHAR (50)     NULL,
    [CapaCategory]  VARCHAR (50)     NULL,
    [ColumnKey]     VARCHAR (50)     NULL,
    CONSTRAINT [PK_UDFSearchSetup] PRIMARY KEY CLUSTERED ([FilterId] ASC)
);

