CREATE TABLE [dbo].[MnxMirsCategory] (
    [CategoryId]     INT           IDENTITY (1, 1) NOT NULL,
    [CategoryName]   VARCHAR (100) NOT NULL,
    [IsCapaCategory] BIT           CONSTRAINT [DF_wmNotes_IsCapaCategory] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_MnxMirsCategory] PRIMARY KEY CLUSTERED ([CategoryId] ASC),
    CONSTRAINT [FK_MnxMirsCategory_MnxMirsCategory] FOREIGN KEY ([CategoryId]) REFERENCES [dbo].[MnxMirsCategory] ([CategoryId])
);

