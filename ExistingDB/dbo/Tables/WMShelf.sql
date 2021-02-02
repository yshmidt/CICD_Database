CREATE TABLE [dbo].[WMShelf] (
    [UniqShelf] NVARCHAR (10) NOT NULL,
    [Name]      VARCHAR (50)  NOT NULL,
    [BinCounts] INT           NOT NULL,
    [UniqRack]  NVARCHAR (10) NOT NULL,
    CONSTRAINT [PK_WMShelf] PRIMARY KEY CLUSTERED ([UniqShelf] ASC),
    CONSTRAINT [fk_wmshelf_uniqRack] FOREIGN KEY ([UniqRack]) REFERENCES [dbo].[WMRack] ([UniqRack]) ON DELETE CASCADE
);

