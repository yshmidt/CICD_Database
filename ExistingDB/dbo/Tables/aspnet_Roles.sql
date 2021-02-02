CREATE TABLE [dbo].[aspnet_Roles] (
    [ApplicationId]   UNIQUEIDENTIFIER NOT NULL,
    [RoleId]          UNIQUEIDENTIFIER CONSTRAINT [DF__aspnet_Ro__RoleI__1DFC19C0] DEFAULT (newid()) NOT NULL,
    [RoleName]        NVARCHAR (256)   NOT NULL,
    [LoweredRoleName] NVARCHAR (256)   NOT NULL,
    [Description]     NVARCHAR (256)   NULL,
    [ModuleId]        INT              NULL,
    [IsSpecial]       BIT              CONSTRAINT [DF__aspnet_Ro__IsSpe__7A7613BD] DEFAULT ((0)) NULL,
    CONSTRAINT [PK__aspnet_R__8AFACE1B1B1FAD15] PRIMARY KEY NONCLUSTERED ([RoleId] ASC),
    CONSTRAINT [FK__aspnet_Ro__Appli__1D07F587] FOREIGN KEY ([ApplicationId]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
);

