CREATE TABLE [dbo].[UDFListValues] (
    [FK_FieldListID] UNIQUEIDENTIFIER NOT NULL,
    [UniqueListID]   INT              IDENTITY (1, 1) NOT NULL,
    [ListItemValue]  NVARCHAR (MAX)   CONSTRAINT [DF_UDFListValues_ListItem] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_UDFListValues] PRIMARY KEY CLUSTERED ([UniqueListID] ASC)
);

