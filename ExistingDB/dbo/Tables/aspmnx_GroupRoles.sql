CREATE TABLE [dbo].[aspmnx_GroupRoles] (
    [GroupRoleID] UNIQUEIDENTIFIER CONSTRAINT [DF_aspmnx_GroupRoles_GroupRoleID] DEFAULT (newid()) NOT NULL,
    [fkRoleId]    UNIQUEIDENTIFIER NOT NULL,
    [fkGroupId]   UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_aspmnx_GroupRoles] PRIMARY KEY CLUSTERED ([GroupRoleID] ASC),
    CONSTRAINT [FK_Groups_GroupRoles] FOREIGN KEY ([fkGroupId]) REFERENCES [dbo].[aspmnx_Groups] ([groupId]) ON DELETE CASCADE,
    CONSTRAINT [FK_Roles_GroupRoles] FOREIGN KEY ([fkRoleId]) REFERENCES [dbo].[aspnet_Roles] ([RoleId]) ON DELETE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [GroupRolesUnique]
    ON [dbo].[aspmnx_GroupRoles]([fkGroupId] ASC, [fkRoleId] ASC);

