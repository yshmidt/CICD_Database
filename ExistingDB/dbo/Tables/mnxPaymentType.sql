CREATE TABLE [dbo].[mnxPaymentType] (
    [PaymentType]    VARCHAR (50) CONSTRAINT [DF_mnxPaymentType_PaymentType] DEFAULT ('') NOT NULL,
    [PaymentTypeKey] INT          IDENTITY (1, 1) NOT NULL
);

