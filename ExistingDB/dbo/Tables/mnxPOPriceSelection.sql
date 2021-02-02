CREATE TABLE [dbo].[mnxPOPriceSelection] (
    [poPriceId]      INT            IDENTITY (1, 1) NOT NULL,
    [poPriceName]    NVARCHAR (100) CONSTRAINT [DF_mnxPOPriceSelection_poPriceName] DEFAULT ('') NOT NULL,
    [sequenceNumber] INT            CONSTRAINT [DF_mnxPOPriceSelection_sequenceNumber] DEFAULT ((0)) NOT NULL,
    [Show]           BIT            CONSTRAINT [DF_mnxPOPriceSelection_Show] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_mnxPOPriceSelection] PRIMARY KEY CLUSTERED ([poPriceId] ASC),
    CONSTRAINT [IX_mnxPOPriceName] UNIQUE NONCLUSTERED ([poPriceName] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_mnxPOPriceSeq]
    ON [dbo].[mnxPOPriceSelection]([sequenceNumber] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_mnxPOPriceShow]
    ON [dbo].[mnxPOPriceSelection]([Show] ASC);

