-- ================================================================================
-- Date   : 
-- Author  : 
-- DESCRIPTION	: This SP Is Used for Get Next Supplier No
-- Modification:
-- 06/24/20 VL changed to use wmSettingsManagement table to get next supplier number
-- ================================================================================
CREATE PROCEDURE [dbo].[GetNextSupplierNumber] 
	@pcNextNumber char(10) OUTPUT
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
									WHERE settingName = 'LastSupplierNumber'
								 )

			DECLARE @LastSupplierNoSettingId Uniqueidentifier =(SELECT settingID FROM MnxSettingsManagement WHERE settingName='LastSupplierNumber')
			IF EXISTS (SELECT 1 FROM wmSettingsManagement WHERE settingId = @LastSupplierNoSettingId )
				BEGIN
					UPDATE wmSettingsManagement  SET settingValue =@pcNextNumber
					WHERE settingId=@LastSupplierNoSettingId
				END 
			ELSE
    			BEGIN
					INSERT INTO wmSettingsManagement (settingId,settingValue)VALUES(@LastSupplierNoSettingId,@pcNextNumber)
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
			SELECT Supid from Supinfo WHERE SUPID=@pcNextNumber
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
		RAISERROR('Error occurred selecting next supplier number.',1,1)
		set @pcNextNumber=' '
		RETURN -1
	END