CREATE TABLE [dbo].[CalcuQuoteUser] (
    [CalcuQuoteId] INT            IDENTITY (1, 1) NOT NULL,
    [ClientId]     NVARCHAR (250) NOT NULL,
    [ClientSecret] NVARCHAR (250) NOT NULL,
    [CreatedDate]  DATETIME       CONSTRAINT [DF__CalcuQuot__Creat__11852CF5] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK__CalcuQuo__65B0EC0B064E01EB] PRIMARY KEY CLUSTERED ([CalcuQuoteId] ASC)
);

