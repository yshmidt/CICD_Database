CREATE TABLE [dbo].[priceItemCust] (
    [uniqpriceItemCustId] CHAR (10)       CONSTRAINT [DF__priceItem__uniqp__7A0CCAC0] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    [uniqprcustbrkid]     CHAR (10)       CONSTRAINT [DF__priceItem__uniqp__7B00EEF9] DEFAULT ('') NOT NULL,
    [priceitemuk]         CHAR (10)       CONSTRAINT [DF__priceItem__price__7BF51332] DEFAULT ('') NOT NULL,
    [Amount]              NUMERIC (13, 5) CONSTRAINT [DF__priceItem__Amoun__7CE9376B] DEFAULT ((0.00)) NOT NULL,
    [priceitemtype]       NVARCHAR (20)   CONSTRAINT [DF__priceItem__price__7DDD5BA4] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_priceItemCust] PRIMARY KEY CLUSTERED ([uniqpriceItemCustId] ASC)
);

