CREATE TABLE [dbo].[ImportAddressContactLink] (
    [AddressContactLinkDetId] UNIQUEIDENTIFIER NOT NULL,
    [FkImportId]              UNIQUEIDENTIFIER NULL,
    [CustRowId]               UNIQUEIDENTIFIER NULL,
    [AddressRowId]            UNIQUEIDENTIFIER NULL,
    [RecordType]              VARCHAR (4)      NULL,
    [ContactRowId]            UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK__ImportAd__CB59B983364B759A] PRIMARY KEY CLUSTERED ([AddressContactLinkDetId] ASC)
);

