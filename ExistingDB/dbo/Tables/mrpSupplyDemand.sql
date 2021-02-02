CREATE TABLE [dbo].[mrpSupplyDemand] (
    [Uniquerec]  CHAR (10)       CONSTRAINT [DF_mrpSupplyDemand_Uniquerec] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    [Ponum]      CHAR (15)       CONSTRAINT [DF_mrpSupplyDemand_Ponum] DEFAULT ('') NOT NULL,
    [uniqlnno]   CHAR (10)       CONSTRAINT [DF_mrpSupplyDemand_uniqlnno] DEFAULT ('') NOT NULL,
    [uniqdetno]  CHAR (10)       CONSTRAINT [DF_mrpSupplyDemand_uniqdetno] DEFAULT ('') NOT NULL,
    [uniq_key]   CHAR (10)       CONSTRAINT [DF_mrpSupplyDemand_uniq_key] DEFAULT ('') NOT NULL,
    [w_key]      CHAR (10)       CONSTRAINT [DF_mrpSupplyDemand_w_key] DEFAULT ('') NOT NULL,
    [sono]       CHAR (10)       CONSTRAINT [DF_mrpSupplyDemand_sono] DEFAULT ('') NOT NULL,
    [uniqueln]   CHAR (10)       CONSTRAINT [DF_mrpSupplyDemand_uniqueln] DEFAULT ('') NOT NULL,
    [wono]       CHAR (10)       CONSTRAINT [DF_mrpSupplyDemand_wono] DEFAULT ('') NOT NULL,
    [reqDate]    DATETIME        NULL,
    [reqQty]     NUMERIC (12, 2) CONSTRAINT [DF_mrpSupplyDemand_reqQty] DEFAULT ((0.00)) NOT NULL,
    [qtyUsed]    NUMERIC (12, 2) CONSTRAINT [DF_mrpSupplyDemand_qtyUsed] DEFAULT ((0.00)) NOT NULL,
    [demandType] NVARCHAR (50)   CONSTRAINT [DF_mrpSupplyDemand_demandType] DEFAULT ('') NOT NULL,
    [supplyType] NVARCHAR (50)   CONSTRAINT [DF_mrpSupplyDemand_supplyType] DEFAULT ('') NOT NULL,
    [Mrp_code]   INT             CONSTRAINT [DF_mrpSupplyDemand_Mrp_code] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_mrpSupplyDemand] PRIMARY KEY CLUSTERED ([Uniquerec] ASC)
);

