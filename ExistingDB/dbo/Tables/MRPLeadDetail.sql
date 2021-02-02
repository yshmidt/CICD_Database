CREATE TABLE [dbo].[MRPLeadDetail] (
    [MrpUniqKey] NVARCHAR (10)   NOT NULL,
    [Uniq_Key]   NVARCHAR (10)   NOT NULL,
    [QtyFrom]    NUMERIC (10, 2) NULL,
    [QtyTo]      NUMERIC (10, 2) NULL,
    [KitDays]    NUMERIC (5)     NULL,
    [ProdDays]   NUMERIC (5)     NULL,
    CONSTRAINT [PK_MRPLeadDetail] PRIMARY KEY CLUSTERED ([MrpUniqKey] ASC)
);

