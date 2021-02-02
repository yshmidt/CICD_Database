CREATE TABLE [dbo].[WMBin] (
    [UniqBin]   NVARCHAR (10) NOT NULL,
    [Name]      VARCHAR (50)  NOT NULL,
    [Quantity]  NUMERIC (10)  NULL,
    [UniqShelf] NVARCHAR (10) NOT NULL,
    [IsBinFull] BIT           CONSTRAINT [DF__WMBin__IsBinFull__683767F1] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WMBin] PRIMARY KEY CLUSTERED ([UniqBin] ASC),
    CONSTRAINT [fk_UniqShelf_id] FOREIGN KEY ([UniqShelf]) REFERENCES [dbo].[WMShelf] ([UniqShelf]) ON DELETE CASCADE
);

