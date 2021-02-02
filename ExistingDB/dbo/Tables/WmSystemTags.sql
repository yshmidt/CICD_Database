CREATE TABLE [dbo].[WmSystemTags] (
    [sTagId]       CHAR (10)    NOT NULL,
    [tagName]      VARCHAR (50) CONSTRAINT [wmDF_WmSystemTags_tagName] DEFAULT ('') NOT NULL,
    [compAdmin]    BIT          CONSTRAINT [wmDF_WmSystemTags_compAdmin] DEFAULT ((1)) NOT NULL,
    [AccountAdmin] BIT          CONSTRAINT [wmDF_WmSystemTags_AccountAdmin] DEFAULT ((0)) NOT NULL,
    [ProdAdmin]    BIT          CONSTRAINT [wmDF_WmSystemTags_ProdAdmin] DEFAULT ((0)) NOT NULL,
    [ScmAdmin]     BIT          CONSTRAINT [wmDF_WmSystemTags_ScmAdmin] DEFAULT ((0)) NOT NULL,
    [CrmAdmin]     BIT          CONSTRAINT [wmDF_WmSystemTags_CrmAdmin] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WmSystemTags] PRIMARY KEY CLUSTERED ([sTagId] ASC)
);

