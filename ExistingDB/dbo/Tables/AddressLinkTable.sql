CREATE TABLE [dbo].[AddressLinkTable] (
    [LinkAddressId]        INT       IDENTITY (1, 1) NOT NULL,
    [BillRemitAddess]      CHAR (10) NOT NULL,
    [ShipConfirmToAddress] CHAR (10) NOT NULL,
    [IsDefaultAddress]     BIT       CONSTRAINT [D_AddressLinkTable_IsDefaultAddress] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AddressLinkTable] PRIMARY KEY CLUSTERED ([LinkAddressId] ASC)
);

