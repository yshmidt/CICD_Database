CREATE TABLE [dbo].[CalcQuoteSupplierMapping] (
    [UkMapId]           CHAR (10)      NOT NULL,
    [UniqSupNo]         CHAR (10)      NOT NULL,
    [CalcuQuoteSupName] NVARCHAR (100) NOT NULL,
    [CreatedDate]       DATETIME       CONSTRAINT [DF__CalcQuote__Creat__18322A84] DEFAULT (getdate()) NULL,
    [CreatedBy]         CHAR (50)      NOT NULL,
    CONSTRAINT [PK__CalcQuot__6C7866269B4EE2BE] PRIMARY KEY CLUSTERED ([UkMapId] ASC)
);

