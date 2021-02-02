-- =============================================
-- Author: 
-- Create date:
-- Description : Get next DMR number
-- Modified : 05/15/2018 : Satish B : Comment the old database structure code of getting last DMR number and Updating Micssys table and select and update last dme 
--									  number as per the new database structure
--			: 05/24/2018 : Satish B : Check @pcNextNumber in DMrheader table instade of PORECMRB table
-- exec GetNextDMRNo ''
-- 06/26/18 YS removed moduleid from wmSettingsManagement
-- =============================================

CREATE PROCEDURE [dbo].[GetNextDMRNo] 
	@pcNextNumber char(10) OUTPUT
AS	
	DECLARE @lExit bit=0	
	WHILE (1=1)
		BEGIN
			BEGIN TRANSACTION
			BEGIN TRY
				-- 05/15/2018 : Satish B : Comment the old database structure code of getting last DMR number and Updating Micssys table and select and update last dme number as per the new database structure
				SELECT @pcNextNumber = dbo.PADL(CONVERT(bigint,ISNULL(w.settingValue,m.settingValue))+1,10,DEFAULT) FROM MnxSettingsManagement  m 
									   LEFT JOIN wmSettingsManagement w ON  m.settingId = w.settingId WHERE m.settingName='LastDMRNo'

				--SELECT @pcNextNumber= dbo.padl(convert(bigint,LastDMR)+1,10,'0') from MicsSys
				--update Micssys set LastDMR=@pcNextNumber
				IF EXISTS(SELECT w.settingId FROM wmSettingsManagement w INNER JOIN MnxSettingsManagement m ON w.settingId=m.settingId AND m.settingName='LastDMRNo')
				    BEGIN
						UPDATE wmSettingsManagement SET settingValue = @pcNextNumber WHERE settingId IN(SELECT w.settingId FROM wmSettingsManagement w JOIN MnxSettingsManagement m 
							   ON w.settingId=m.settingId AND m.settingName='LastDMRNo')	
					END
				ELSE
				   BEGIN
				   -- 06/26/18 YS removed moduleid from wmSettingsManagement
				      INSERT INTO [dbo].[wmSettingsManagement]
					   ([settingId]
					   ,[settingValue])
					   --,[ModuleId])
					 SELECT SettingId,@pcNextNumber
					 --,moduleId 
					 FROM MnxSettingsManagement WHERE settingName='LastDMRNo'
				   END
			END TRY
			BEGIN CATCH
				set @lExit=1;
				IF @@TRANCOUNT>0
					ROLLBACK
					
			END CATCH
			IF @lExit=0
			BEGIN
				IF @@TRANCOUNT>0
				COMMIT
				--check if the number already in use
				-- 05/24/2018 : Satish B : Check @pcNextNumber in DMrheader table instade of PORECMRB table
				SELECT DMR_no from DMrheader --PORECMRB 
				WHERE DMR_NO=@pcNextNumber
				IF @@ROWCOUNT<>0
					CONTINUE
				ELSE
					BREAK
			END
			ELSE -- IF lExit=0
			BREAK
		END -- WHILE (1=1)
		IF  @lExit=1
		BEGIN
			RAISERROR('Error occurred selecting next DMR number.',1,1)
			set @pcNextNumber=' '
			RETURN -1
		END
	
	
	
	
	