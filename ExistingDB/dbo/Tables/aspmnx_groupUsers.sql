CREATE TABLE [dbo].[aspmnx_groupUsers] (
    [groupusersID] UNIQUEIDENTIFIER CONSTRAINT [DF_aspmnx_groupUsers_groupusersID] DEFAULT (newid()) NOT NULL,
    [fkuserid]     UNIQUEIDENTIFIER NOT NULL,
    [fkgroupid]    UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_aspmnx_groupUsers] PRIMARY KEY CLUSTERED ([groupusersID] ASC),
    CONSTRAINT [FK_aspmnx_groupUsers_aspnet_Users] FOREIGN KEY ([fkuserid]) REFERENCES [dbo].[aspnet_Users] ([UserId]) ON DELETE CASCADE,
    CONSTRAINT [FK_groups_groupUsers] FOREIGN KEY ([fkgroupid]) REFERENCES [dbo].[aspmnx_Groups] ([groupId]) ON DELETE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [groupUsersUnique]
    ON [dbo].[aspmnx_groupUsers]([fkgroupid] ASC, [fkuserid] ASC);

