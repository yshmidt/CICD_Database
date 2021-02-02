CREATE TABLE [dbo].[UdfInvtlot_BHB] (
    [udfId]      UNIQUEIDENTIFIER CONSTRAINT [DF_UdfInvtlot_BHB_udfId] DEFAULT (newid()) NOT NULL,
    [fkUNIQ_LOT] CHAR (10)        CONSTRAINT [DF_UdfInvtlot_BHB_fkUNIQ_LOT] DEFAULT ('') NOT NULL,
    [Packaging]  VARCHAR (100)    CONSTRAINT [DF_UdfInvtlot_BHB_Packaging] DEFAULT ('') NULL,
    [Weight]     VARCHAR (100)    CONSTRAINT [DF_UdfInvtlot_BHB_Weight] DEFAULT ('') NULL,
    [Project]    VARCHAR (100)    CONSTRAINT [DF_UdfInvtlot_BHB_Project] DEFAULT ('H12') NULL,
    [Year]       INT              CONSTRAINT [DF_UdfInvtlot_BHB_Year] DEFAULT ('2020') NULL,
    CONSTRAINT [PK_UdfInvtlot_BHB] PRIMARY KEY CLUSTERED ([udfId] ASC)
);

