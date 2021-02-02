CREATE TABLE [dbo].[CustomerSupplierLink] (
    [CustSupLinkId] INT       IDENTITY (1, 1) NOT NULL,
    [UniqSupNo]     CHAR (10) NOT NULL,
    [CustNo]        CHAR (10) NOT NULL,
    CONSTRAINT [PK_CustomerSupplierLink] PRIMARY KEY CLUSTERED ([CustSupLinkId] ASC)
);

