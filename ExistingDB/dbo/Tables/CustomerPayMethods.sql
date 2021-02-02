CREATE TABLE [dbo].[CustomerPayMethods] (
    [CustPaymentLinkId] INT           IDENTITY (1, 1) NOT NULL,
    [CustNo]            CHAR (10)     NOT NULL,
    [IsDefault]         BIT           NOT NULL,
    [PaymentType]       VARCHAR (200) DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_CustomerPayMethods] PRIMARY KEY CLUSTERED ([CustPaymentLinkId] ASC)
);

