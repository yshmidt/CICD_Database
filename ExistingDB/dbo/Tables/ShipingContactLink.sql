CREATE TABLE [dbo].[ShipingContactLink] (
    [ShipingContactLinkId] INT       IDENTITY (1, 1) NOT NULL,
    [ShipConfirmAddess]    CHAR (10) NOT NULL,
    [CID]                  CHAR (10) NOT NULL,
    [IsDefaultAddress]     BIT       CONSTRAINT [D_ShipingContactLink_IsDefaultAddress] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ShipingContactLink] PRIMARY KEY CLUSTERED ([ShipingContactLinkId] ASC)
);

