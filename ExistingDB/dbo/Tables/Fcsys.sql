CREATE TABLE [dbo].[Fcsys] (
    [FcSysUniq]                   CHAR (10)        CONSTRAINT [DF__Fcsys__FcSysUniq__751ACB15] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    [FCLastUpdate]                SMALLDATETIME    CONSTRAINT [DF__Fcsys__FCLastUpd__760EEF4E] DEFAULT ('') NOT NULL,
    [StdCostExRate]               NUMERIC (13, 5)  CONSTRAINT [DF__Fcsys__StdCostEx__0671D64E] DEFAULT ((0)) NOT NULL,
    [StdCostERChangeDt]           DATETIME         CONSTRAINT [DF__Fcsys__StdCostER__0765FA87] DEFAULT ('') NOT NULL,
    [StdCostERChangeUserId]       CHAR (8)         CONSTRAINT [DF__Fcsys__StdCostER__085A1EC0] DEFAULT ('') NOT NULL,
    [StdCostERChangeAspnetUserId] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK__Fcsys__6C5AA278733282A3] PRIMARY KEY CLUSTERED ([FcSysUniq] ASC)
);

