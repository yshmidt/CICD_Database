CREATE TABLE [dbo].[PriceItemizationSetup] (
    [PriceItemUK]          CHAR (10)     CONSTRAINT [DF_PriceItemizationSetup_PriceItemUK] DEFAULT ('dbo.dn_generateuniquenumber()') NOT NULL,
    [PriceItemDescription] NVARCHAR (30) CONSTRAINT [DF_Table_1_Description] DEFAULT ('') NOT NULL,
    [PriceItemType]        NVARCHAR (20) CONSTRAINT [DF_PriceItemizationSetup_PriceItemType] DEFAULT (N'Amount') NOT NULL,
    [DisplaySeq]           INT           CONSTRAINT [DF_PriceItemizationSetup_DisplaySeq] DEFAULT ((0)) NOT NULL,
    [is_Deleted]           BIT           CONSTRAINT [DF_PriceItemizationSetup_Deleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_PriceItemizationSetup] PRIMARY KEY CLUSTERED ([PriceItemUK] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_PriceItemizationSetup_Desc]
    ON [dbo].[PriceItemizationSetup]([PriceItemDescription] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PriceItemizationSetup_Seq]
    ON [dbo].[PriceItemizationSetup]([DisplaySeq] ASC);

