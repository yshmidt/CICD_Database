CREATE TABLE [dbo].[udfPOManagementDtl] (
    [udfId]      UNIQUEIDENTIFIER CONSTRAINT [DF_udfPOManagementDtl_udfId] DEFAULT (newid()) NOT NULL,
    [fkUNIQLNNO] CHAR (10)        CONSTRAINT [DF_udfPOManagementDtl_fkUNIQLNNO] DEFAULT ('') NOT NULL,
    [Package]    VARCHAR (30)     CONSTRAINT [DF_udfPOManagementDtl_Package] DEFAULT ('') NULL,
    CONSTRAINT [PK_udfPOManagementDtl] PRIMARY KEY CLUSTERED ([udfId] ASC)
);

