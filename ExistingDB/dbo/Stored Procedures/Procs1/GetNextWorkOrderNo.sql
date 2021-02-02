-- ================================================================================
-- AUTHOR		: Rajendra K.
-- DATE			: 04/23/2020
-- DESCRIPTION	: This SP Is Used for Get Next Work Order No
-- ================================================================================
CREATE PROCEDURE [dbo].[GetNextWorkOrderNo] 
	@woNextNumber char(10) OUTPUT
AS
		
DECLARE @lExit BIT=0	
WHILE (1=1)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			SELECT @woNextNumber=(
									SELECT dbo.padl(convert(bigint,ISNULL(wmSet.settingValue, mnxSet.settingValue))+1,10,DEFAULT)AS WoNo 
									FROM MnxSettingsManagement mnxSet 
									LEFT JOIN wmSettingsManagement wmSet ON mnxSet.settingId = wmSet.settingId 
									WHERE settingName = 'LastWONO'
								 )

			DECLARE @LastWoNoSettingId Uniqueidentifier =(SELECT settingID FROM MnxSettingsManagement WHERE 
			settingName='LastWONO')
			IF EXISTS (SELECT 1 FROM wmSettingsManagement WHERE settingId = @LastWoNoSettingId )
				BEGIN
					UPDATE wmSettingsManagement  SET settingValue =@woNextNumber
					WHERE settingId=@LastWoNoSettingId
				END 
			ELSE
    			BEGIN
					INSERT INTO wmSettingsManagement (settingId,settingValue)VALUES(@LastWoNoSettingId,@woNextNumber)
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
			IF EXISTS(SELECT WONO from WOENTRY WHERE WONO=@woNextNumber)
				CONTINUE
			ELSE
			SELECT @woNextNumber
				BREAK
		END
		ELSE -- IF lExit=0
		BREAK
	END -- WHILE (1=1)
	IF  @lExit=1
	BEGIN
		RAISERROR('Error occurred selecting next Work Order number.',1,1)
		set @woNextNumber=' '
		RETURN -1
	END