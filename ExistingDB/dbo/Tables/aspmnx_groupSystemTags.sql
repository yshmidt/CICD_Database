CREATE TABLE [dbo].[aspmnx_groupSystemTags] (
    [fkgroupId] UNIQUEIDENTIFIER NOT NULL,
    [fksTagId]  CHAR (10)        NOT NULL,
    CONSTRAINT [PK_aspmnx_groupSystemTags] PRIMARY KEY CLUSTERED ([fkgroupId] ASC, [fksTagId] ASC)
);

