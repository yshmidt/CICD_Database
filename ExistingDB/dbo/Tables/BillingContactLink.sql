CREATE TABLE [dbo].[BillingContactLink] (
    [BillingContactLinkId] INT       IDENTITY (1, 1) NOT NULL,
    [BillRemitAddess]      CHAR (10) NOT NULL,
    [CID]                  CHAR (10) NOT NULL,
    [IsDefaultAddress]     BIT       CONSTRAINT [D_BillingContactLink_IsDefaultAddress] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_BillingContactLink] PRIMARY KEY CLUSTERED ([BillingContactLinkId] ASC)
);

