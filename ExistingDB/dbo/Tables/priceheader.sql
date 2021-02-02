CREATE TABLE [dbo].[priceheader] (
    [uniqprhead]   CHAR (10)        CONSTRAINT [DF__pricehead__uniqp__58ABD6F5] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    [uniq_key]     CHAR (10)        CONSTRAINT [DF__pricehead__uniq___599FFB2E] DEFAULT ('') NOT NULL,
    [lastUpdate]   SMALLDATETIME    CONSTRAINT [DF_priceheader_lastUpdate] DEFAULT (getdate()) NULL,
    [lastUpdateBy] UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_priceheader] PRIMARY KEY CLUSTERED ([uniqprhead] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_priceheader_Uniq_key]
    ON [dbo].[priceheader]([uniq_key] ASC);

