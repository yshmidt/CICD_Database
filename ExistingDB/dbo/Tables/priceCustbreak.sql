CREATE TABLE [dbo].[priceCustbreak] (
    [uniqprcustbrkid] CHAR (10)       CONSTRAINT [DF__priceCust__uniqp__6F8F3C4D] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    [uniqprhead]      CHAR (10)       CONSTRAINT [DF__priceCust__uniqp__70836086] DEFAULT ('') NOT NULL,
    [uniqprcustid]    CHAR (10)       CONSTRAINT [DF__priceCust__uniqp__717784BF] DEFAULT ('') NOT NULL,
    [FromQty]         NUMERIC (9, 2)  CONSTRAINT [DF__priceCust__FromQ__726BA8F8] DEFAULT ((0.00)) NOT NULL,
    [ToQty]           NUMERIC (9, 2)  CONSTRAINT [DF__priceCust__ToQty__735FCD31] DEFAULT ((0.00)) NOT NULL,
    [Amount]          NUMERIC (14, 5) CONSTRAINT [DF__priceCust__Amoun__7453F16A] DEFAULT ((0.00)) NOT NULL,
    CONSTRAINT [PK_priceCustbreak] PRIMARY KEY CLUSTERED ([uniqprcustbrkid] ASC)
);

