CREATE TABLE [dbo].[aspmnx_RoleSystemTags] (
    [fkRoleId] UNIQUEIDENTIFIER NOT NULL,
    [fksTagId] CHAR (10)        NOT NULL,
    CONSTRAINT [PK_aspmnx_RoleSystemTags] PRIMARY KEY CLUSTERED ([fkRoleId] ASC, [fksTagId] ASC)
);

