CREATE TABLE [dbo].[MnxSystemTags] (
    [sTagId]       CHAR (10)    NOT NULL,
    [tagName]      VARCHAR (50) CONSTRAINT [DF_MnxSystemTags_tagName] DEFAULT ('') NOT NULL,
    [compAdmin]    BIT          CONSTRAINT [DF_MnxSystemTags_compAdmin] DEFAULT ((1)) NOT NULL,
    [AccountAdmin] BIT          CONSTRAINT [DF_MnxSystemTags_AccountAdmin] DEFAULT ((0)) NOT NULL,
    [ProdAdmin]    BIT          CONSTRAINT [DF_MnxSystemTags_ProdAdmin] DEFAULT ((0)) NOT NULL,
    [ScmAdmin]     BIT          CONSTRAINT [DF_MnxSystemTags_ScmAdmin] DEFAULT ((0)) NOT NULL,
    [CrmAdmin]     BIT          CONSTRAINT [DF_MnxSystemTags_CrmAdmin] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_MnxSystemTags] PRIMARY KEY CLUSTERED ([sTagId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [tagName]
    ON [dbo].[MnxSystemTags]([tagName] ASC);

