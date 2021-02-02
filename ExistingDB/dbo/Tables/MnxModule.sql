CREATE TABLE [dbo].[MnxModule] (
    [ModuleId]        INT             IDENTITY (1, 1) NOT NULL,
    [ModuleName]      NVARCHAR (100)  NULL,
    [ModuleDesc]      NVARCHAR (1000) NULL,
    [Abbreviation]    NVARCHAR (500)  NULL,
    [HaveChild]       BIT             CONSTRAINT [DF__MnxModule__HaveC__4325137C] DEFAULT ((0)) NULL,
    [FileType]        INT             CONSTRAINT [DF__MnxModule__FileT__50D41455] DEFAULT ((0)) NULL,
    [ModuleCss]       VARCHAR (40)    NULL,
    [FilePath]        VARCHAR (150)   NULL,
    [isWorkflow]      BIT             CONSTRAINT [DF__MnxModule__isWor__44F84D55] DEFAULT ((0)) NOT NULL,
    [IsFilingCabinet] BIT             CONSTRAINT [DF__MnxModule__IsFil__101A70C2] DEFAULT ((0)) NOT NULL,
    [IsModuleShow]    BIT             CONSTRAINT [DF__MnxModule__IsMod__576C034B] DEFAULT ((1)) NOT NULL,
    [IsPermission]    BIT             CONSTRAINT [DF__MnxModule__IsPer__383E3C0C] DEFAULT ((1)) NULL,
    [IsShowChild]     BIT             CONSTRAINT [DF__MnxModule__IsSho__47215840] DEFAULT ((0)) NOT NULL,
    [RenderNumber]    INT             NULL,
    CONSTRAINT [PK_MnxModules] PRIMARY KEY CLUSTERED ([ModuleId] ASC)
);


GO
-- =============================================
-- Author:		Shripati U
-- Create date: 05/27/2016
-- Description:	Insert trigger for mnxModule to insert roles into aspnet_roles
-- Shripati U:- Modified the trigger for mnxModule to insert roles into aspnet_roles for the bulk insert.  
-- 11/18/2019 Rajendra k:- Added "Tools" permission Role
-- =============================================
CREATE TRIGGER [dbo].[MnxModule_Insert] ON [dbo].[MnxModule] 
FOR INSERT
AS
        DECLARE @mnxModules TABLE (nRecno INT IDENTITY, ModuleId INT, IsPermission BIT);	
		DECLARE @role TABLE(RoleName VARCHAR(50));
		DECLARE @applicationId UNIQUEIDENTIFIER = (SELECT ApplicationId FROM aspnet_Applications);	

		INSERT INTO @MnxModules(ModuleId,IsPermission) SELECT i.ModuleId,i.IsPermission FROM inserted i WHERE IsPermission = 1;

		IF EXISTS(SELECT 1 FROM @MnxModules)
		BEGIN
		INSERT INTO @role VALUES('Add'),('Delete'),('Edit'),('Price'),('Reports'),('Setup'),('View'),('Tools')-- 11/18/2019 Rajendra k:- Added "Tools" permission Role

		INSERT INTO aspnet_Roles(RoleId
							    ,ApplicationId
								,ModuleId
								,RoleName
								,LoweredRoleName
								,IsSpecial)
						SELECT  NEWID() AS RoleId
								,@applicationId AS ApplicationId
								,moduleid,RoleName
								,LOWER(RoleName) LoweredRoleName
								,0 AS IsSpecial
		                FROM @mnxModules m CROSS JOIN @role r
					    WHERE (m.IsPermission=1) AND ((SELECT COUNT(1) FROM aspnet_Roles WHERE ModuleId=m.ModuleId)=0)
						ORDER BY m.moduleid;
		END	

GO
-- =============================================
-- Author:		Rajendra K 
-- Create date: 11/19/2019
-- Description:	After Delete trigger for the MnxModule table
-- =============================================
create TRIGGER [dbo].[MnxModule_Delete]
    ON [dbo].[MnxModule] 
	AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
	DECLARE @mnxModules TABLE (RowNo INT IDENTITY,ModuleId INT);
	INSERT INTO @MnxModules(ModuleId) SELECT ModuleId FROM Deleted 

		IF EXISTS(SELECT 1 FROM @MnxModules)
		BEGIN
			DELETE FROM aspnet_UsersInRoles 
				   WHERE RoleId IN (SELECT RoleId FROM aspnet_Roles r INNER JOIN @mnxModules m ON r.ModuleId = m.ModuleId)

			DELETE FROM aspmnx_GroupRoles 
				   WHERE fkRoleId IN (SELECT RoleId FROM aspnet_Roles r INNER JOIN @mnxModules m ON r.ModuleId = m.ModuleId)

			DELETE FROM aspnet_Roles WHERE ModuleId IN(SELECT ModuleId FROM @MnxModules)
		END
END
GO
-- =============================================
-- Author:		Rajendra K 
-- Create date: 11/19/2019
-- Description:	After Update trigger for the MnxModule table
-- =============================================
CREATE TRIGGER [dbo].[MnxModule_Update]
    ON [dbo].[MnxModule] 
    AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
	DECLARE @mnxModules TABLE (RowNo INT IDENTITY,ModuleId INT, IsPermission BIT);
	DECLARE @role TABLE(RoleName VARCHAR(50));
	DECLARE @applicationId UNIQUEIDENTIFIER = (SELECT ApplicationId FROM aspnet_Applications);	
	INSERT INTO @MnxModules(ModuleId,IsPermission) SELECT ModuleId,IsPermission FROM Inserted 

	IF EXISTS(SELECT 1 FROM @MnxModules WHERE IsPermission = 0)
	BEGIN
		DELETE FROM aspnet_UsersInRoles 
			   WHERE RoleId IN (SELECT RoleId FROM aspnet_Roles r INNER JOIN @mnxModules m ON r.ModuleId = m.ModuleId AND IsPermission = 0)

		DELETE FROM aspmnx_GroupRoles 
			   WHERE fkRoleId IN (SELECT RoleId FROM aspnet_Roles r INNER JOIN @mnxModules m ON r.ModuleId = m.ModuleId AND IsPermission = 0)

		DELETE FROM aspnet_Roles WHERE ModuleId IN(SELECT ModuleId FROM @MnxModules WHERE IsPermission = 0)
	END

	IF EXISTS(SELECT 1 FROM @MnxModules WHERE IsPermission = 1)
	BEGIN
		INSERT INTO @role VALUES('Add'),('Delete'),('Edit'),('Price'),('Reports'),('Setup'),('View'),('Tools')
		INSERT INTO aspnet_Roles(RoleId
							    ,ApplicationId
								,ModuleId
								,RoleName
								,LoweredRoleName
								,IsSpecial)
						SELECT  NEWID() AS RoleId
								,@applicationId AS ApplicationId
								,moduleid,RoleName
								,LOWER(RoleName) LoweredRoleName
								,0 AS IsSpecial
		                FROM @mnxModules m CROSS JOIN @role r
					    WHERE (m.IsPermission=1) AND ((SELECT COUNT(1) FROM aspnet_Roles WHERE ModuleId=m.ModuleId)=0)
						ORDER BY m.moduleid;
	END
END