CREATE PROCEDURE [dbo].[wmHelpModuleUserSettingAdd]
(  
  @ModuleId int,
  @UserId uniqueidentifier ,
  @ShowOnStartup bit
)  
AS  
BEGIN
If @ShowOnStartup = 1
BEGIN
	Delete from wmHelpModuleUserSetting WHERE ModuleID =@ModuleId AND UserId = @UserId
 END

 Else
 BEGIN
	if NOT EXISTS (SELECT 1 FROM wmHelpModuleUserSetting WHERE ModuleID =@ModuleId AND UserId = @UserId)
	BEGIN
		Insert Into wmHelpModuleUserSetting
		Values(@ModuleId,@UserId)
	END
 END
 
END
