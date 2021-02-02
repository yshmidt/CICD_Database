-- ================================================================================
-- Date   : 01/06/2020
-- Author  : Mahesh B	
-- DESCRIPTION	: This SP Is Used for Get Next SO No
-- [GetNextSONO] OUTPUT
-- ================================================================================
CREATE PROCEDURE [dbo].[GetNextSONO] 
	@pcNextNumber CHAR(10) OUTPUT
AS
		
DECLARE @lExit BIT=0	
WHILE (1=1)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			SELECT @pcNextNumber=(
									SELECT dbo.padl(convert(bigint,ISNULL(wmSet.settingValue, mnxSet.settingValue))+1,10,DEFAULT)AS SONO 
									FROM MnxSettingsManagement mnxSet 
									LEFT JOIN wmSettingsManagement wmSet ON mnxSet.settingId = wmSet.settingId 
									WHERE settingName = 'LastSONumber'
								 )

			DECLARE @LastSONoSettingId Uniqueidentifier =(SELECT settingID FROM MnxSettingsManagement WHERE settingName='LastSONumber')
			IF EXISTS (SELECT 1 FROM wmSettingsManagement WHERE settingId = @LastSONoSettingId )
				BEGIN
					UPDATE wmSettingsManagement  SET settingValue =@pcNextNumber
					WHERE settingId=@LastSONoSettingId
				END 
			ELSE
    			BEGIN
					INSERT INTO wmSettingsManagement (settingId,settingValue)VALUES(@LastSONoSettingId,@pcNextNumber)
				END
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
			print @pcNextNumber
			SELECT SONO from SOMAIN WHERE SONO=@pcNextNumber
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
		RAISERROR('Error occurred selecting next SONO number.',1,1)
		set @pcNextNumber=' '
		RETURN -1
	END