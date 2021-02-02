CREATE TABLE [dbo].[importBOMTempAvl] (
    [avlId]    UNIQUEIDENTIFIER CONSTRAINT [DF_importBOMTempAvl_avlId] DEFAULT (newid()) NOT NULL,
    [rowId]    UNIQUEIDENTIFIER NULL,
    [importId] UNIQUEIDENTIFIER NOT NULL,
    [partMfg]  VARCHAR (MAX)    CONSTRAINT [DF_importBOMTempAvl_partMfg] DEFAULT ('') NOT NULL,
    [mpn]      VARCHAR (MAX)    CONSTRAINT [DF_importBOMTempAvl_mpn] DEFAULT ('') NOT NULL,
    [matlType] VARCHAR (MAX)    CONSTRAINT [DF_importBOMTempAvl_matlType] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_importBOMTempAvl] PRIMARY KEY CLUSTERED ([avlId] ASC)
);

