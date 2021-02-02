CREATE PROCEDURE [dbo].[wmHelpModuleUserSettingGet]
(
 @ModuleId varchar(100),
 @UserId uniqueidentifier
)
AS
BEGIN
If NOT EXISTS (SELECT 1 FROM wmHelpModuleUserSetting WHERE ModuleID =@ModuleId AND UserId = @UserId)
BEGIN
	SELECT *
	FROM   [dbo].[MnxHelpModule]
	WHERE  ModuleId  = @ModuleId And ShowOnStartUp=0
	
END
Else
BEGIN
	SELECT [ModuleId]
		  ,[UserId]
	FROM   [dbo].[wmHelpModuleUserSetting]
	WHERE  ModuleId  = @ModuleId AND  UserId = @UserId 
END

END
