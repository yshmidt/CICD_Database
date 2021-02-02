CREATE TABLE [dbo].[ManexItemAccountMapping] (
    [ItemAccountMappingId] INT            IDENTITY (1, 1) NOT NULL,
    [Item]                 NVARCHAR (MAX) NULL,
    [CogsAccount]          NVARCHAR (MAX) NULL,
    [AssetAccount]         NVARCHAR (MAX) NULL,
    [IncomeAccount]        NVARCHAR (MAX) NULL,
    [SaleTypeId]           CHAR (10)      NULL,
    [WareHouseName]        CHAR (10)      NULL,
    [LastUpdateDate]       SMALLDATETIME  NULL,
    CONSTRAINT [PK_ManexItemAccountMapping] PRIMARY KEY CLUSTERED ([ItemAccountMappingId] ASC)
);

