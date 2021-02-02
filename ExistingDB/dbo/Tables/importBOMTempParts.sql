CREATE TABLE [dbo].[importBOMTempParts] (
    [rowId]        UNIQUEIDENTIFIER CONSTRAINT [DF_importBOMTemp_tempId] DEFAULT (newsequentialid()) NOT NULL,
    [importId]     UNIQUEIDENTIFIER NOT NULL,
    [itemno]       VARCHAR (MAX)    CONSTRAINT [DF_importBOMTemp_itemno] DEFAULT ('') NOT NULL,
    [used]         VARCHAR (MAX)    CONSTRAINT [DF_importBOMTemp_used] DEFAULT ('') NOT NULL,
    [partSource]   VARCHAR (MAX)    CONSTRAINT [DF_importBOMTemp_partSource] DEFAULT ('') NOT NULL,
    [qty]          VARCHAR (MAX)    CONSTRAINT [DF_importBOMTemp_qty] DEFAULT ('') NOT NULL,
    [custPartNo]   VARCHAR (MAX)    CONSTRAINT [DF_importBOMTemp_custPartNo] DEFAULT ('') NOT NULL,
    [crev]         VARCHAR (MAX)    CONSTRAINT [DF_importBOMTemp_crev] DEFAULT ('') NOT NULL,
    [descript]     VARCHAR (MAX)    CONSTRAINT [DF_importBOMTemp_descript] DEFAULT ('') NOT NULL,
    [u_of_m]       VARCHAR (MAX)    CONSTRAINT [DF_importBOMTemp_u_of_m] DEFAULT ('') NOT NULL,
    [partClass]    VARCHAR (MAX)    CONSTRAINT [DF_importBOMTemp_partClass] DEFAULT ('') NOT NULL,
    [partType]     VARCHAR (MAX)    CONSTRAINT [DF_importBOMTemp_partType] DEFAULT ('') NOT NULL,
    [warehouse]    VARCHAR (MAX)    CONSTRAINT [DF_importBOMTemp_warehouse] DEFAULT ('') NOT NULL,
    [partNo]       VARCHAR (MAX)    CONSTRAINT [DF_importBOMTemp_partNo] DEFAULT ('') NOT NULL,
    [rev]          VARCHAR (MAX)    CONSTRAINT [DF_importBOMTemp_rev] DEFAULT ('') NOT NULL,
    [workCenter]   VARCHAR (MAX)    CONSTRAINT [DF_importBOMTemp_workCenter] DEFAULT ('') NOT NULL,
    [standardCost] VARCHAR (MAX)    CONSTRAINT [DF_importBOMTemp_standardCost] DEFAULT ('') NOT NULL,
    [bomNote]      VARCHAR (MAX)    CONSTRAINT [DF_importBOMTemp_bomNote] DEFAULT ('') NOT NULL,
    [invNote]      VARCHAR (MAX)    CONSTRAINT [DF_importBOMTemp_invNote] DEFAULT ('') NOT NULL,
    [rowNum]       INT              NOT NULL,
    CONSTRAINT [PK_importBOMTemp] PRIMARY KEY CLUSTERED ([rowId] ASC)
);

