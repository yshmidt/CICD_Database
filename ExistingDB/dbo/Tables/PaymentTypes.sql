CREATE TABLE [dbo].[PaymentTypes] (
    [PaymentId]   INT            IDENTITY (1, 1) NOT NULL,
    [PaymentType] NVARCHAR (200) NOT NULL,
    CONSTRAINT [PK_PaymentTypes] PRIMARY KEY CLUSTERED ([PaymentId] ASC)
);

