CREATE TABLE [dbo].[importBOMTempRefs] (
    [refId]    UNIQUEIDENTIFIER CONSTRAINT [DF_importBOMTempRefs_refId] DEFAULT (newid()) NOT NULL,
    [rowId]    UNIQUEIDENTIFIER NULL,
    [importId] UNIQUEIDENTIFIER NOT NULL,
    [refDesg]  VARCHAR (MAX)    CONSTRAINT [DF_importBOMTempRefs_refDesg] DEFAULT ('') NOT NULL,
    [rowNum]   INT              NOT NULL,
    CONSTRAINT [PK_importBOMTempRefs] PRIMARY KEY CLUSTERED ([refId] ASC)
);

