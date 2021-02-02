CREATE TABLE [dbo].[priceCustomer] (
    [uniqprcustid]     CHAR (10)        CONSTRAINT [DF__priceCust__uniqp__5B8843A0] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    [custno]           CHAR (10)        CONSTRAINT [DF_priceCustomer_custno] DEFAULT ('') NOT NULL,
    [uniqprhead]       CHAR (10)        NULL,
    [quotenumber]      NVARCHAR (30)    NULL,
    [quoteDate]        SMALLDATETIME    NULL,
    [quoteApprovedID]  UNIQUEIDENTIFIER NULL,
    [quoteApprovedDt]  SMALLDATETIME    NULL,
    [ReadyForApproval] BIT              CONSTRAINT [DF_priceCustomer_ReadyForApproval] DEFAULT ((0)) NOT NULL,
    [AmortAmount]      NUMERIC (14, 5)  CONSTRAINT [DF_priceCustomer_AmortAmount] DEFAULT ((0.00)) NOT NULL,
    [AmortQty]         NUMERIC (9, 2)   CONSTRAINT [DF_priceCustomer_AmortQty] DEFAULT ((0.00)) NOT NULL,
    CONSTRAINT [PK_priceCustomer] PRIMARY KEY CLUSTERED ([uniqprcustid] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_linkpricehead]
    ON [dbo].[priceCustomer]([uniqprhead] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_priceCustomer]
    ON [dbo].[priceCustomer]([custno] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_priceCustDate]
    ON [dbo].[priceCustomer]([quoteApprovedDt] ASC);

