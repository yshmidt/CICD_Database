CREATE TABLE [dbo].[ContactAddressLink] (
    [UniqContactAdd]   CHAR (10) CONSTRAINT [DF_ContactAddressLink_UniqContactAdd] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    [LinkAdd]          CHAR (10) CONSTRAINT [DF_ContactAddressLink_LinkAdd] DEFAULT ('') NOT NULL,
    [CID]              CHAR (10) CONSTRAINT [DF_ContactAddressLink_CID] DEFAULT ('') NOT NULL,
    [IsDefaultContact] BIT       CONSTRAINT [DF_ContactAddressLink_IsDefault] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ContactAddressLink] PRIMARY KEY CLUSTERED ([UniqContactAdd] ASC)
);

