-- =============================================
-- Author:		
-- Create date: 
-- 03-01-2017 Raviraj P- Change settings from MicsSys table to wmSettingsManagement and MnxSettingsManagement table & made the CAR No as integer
-- 11/22/2017 Raviraj P : Change setting implementation
-- 06/26/18 YS removed moduleid from wmSettingsManagement
-- =============================================
CREATE PROCEDURE [dbo].[GetNextCARNumber] 
		@pcNextNumber INT OUTPUT
AS	
	BEGIN
	DECLARE @lExit BIT=0

	WHILE (1=1)
		BEGIN
			BEGIN TRANSACTION
				BEGIN TRY
				DECLARE @settingId UNIQUEIDENTIFIER
				DECLARE @defaultSettingValue INT
				DECLARE @moduleId INT

				-- 03-01-2017 Raviraj P- Change settings from MicsSys table to wmSettingsManagement and MnxSettingsManagement table & made the CAR No as integer
					SELECT @settingId= m.settingID ,@defaultSettingValue = m.settingValue,@moduleId =m.moduleId FROM MnxSettingsManagement m where m.settingName='LastCarNo'
				
					--UPDATE wmSettingsManagement SET settingValue=@pcNextNumber WHERE settingId =@settingId
					   --UPDATE wmSettingsManagement SET settingValue = @pcNextNumber WHERE settingId IN(SELECT w.settingId FROM wmSettingsManagement w JOIN MnxSettingsManagement m 
			     --      ON w.settingId=m.settingId AND m.settingName='LastCarNo')	
				 -- 11/22/2017 Raviraj P : Change setting implementation
						IF EXISTS (SELECT 1 FROM dbo.wmSettingsManagement WHERE settingId = @settingId)
						BEGIN
						  UPDATE wmSettingsManagement SET settingValue = (settingValue) + 1 WHERE settingId = @settingId
						END
						ELSE
						BEGIN
						-- 06/26/18 YS removed moduleid from wmSettingsManagement
						  INSERT INTO wmSettingsManagement(settingId,settingValue)
						  --,ModuleId)
						  VALUES(@settingId, @defaultSettingValue + 1)
						  --,@moduleId)
						END
					  SELECT  @pcNextNumber = settingValue FROM  wmSettingsManagement  WHERE settingId = @settingId

				END TRY
				BEGIN CATCH
					SET @lExit=1;
					IF @@TRANCOUNT>0
						ROLLBACK
					
				END CATCH
				IF @lExit=0
					BEGIN
						IF @@TRANCOUNT>0
						COMMIT
						--check if the number already in use
						SELECT CarNo FROM wmNotes WHERE CarNo = @pcNextNumber 
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
				RAISERROR('Error occurred selecting next CAR number.',11,1)
				SET @pcNextNumber=0
				RETURN -1
			END
END

