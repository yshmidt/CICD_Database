CREATE TABLE [dbo].[FCSTDCOSTERHIST] (
    [FCSTDCOSTERHISTUNIQ]         CHAR (10)        CONSTRAINT [DF_Table_1_FUNCERUNIQ] DEFAULT ('') NOT NULL,
    [StdCostERUpdateDate]         SMALLDATETIME    NOT NULL,
    [StdCostExRate]               NUMERIC (13, 5)  NOT NULL,
    [StdCostERChangeUserId]       CHAR (8)         NOT NULL,
    [StdCostERChangeAspnetUserId] UNIQUEIDENTIFIER NULL
);

