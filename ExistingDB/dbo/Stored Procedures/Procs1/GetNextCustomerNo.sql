-- ================================================================================
-- AUTHOR		: Sachin B.
-- DATE			: 12/31/2019
-- DESCRIPTION	: This SP Is Used for Get Next Cust No
-- ================================================================================
CREATE PROCEDURE [dbo].[GetNextCustomerNo] 
	@pcNextNumber char(10) OUTPUT
AS
		
DECLARE @lExit BIT=0	
WHILE (1=1)
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			SELECT @pcNextNumber=(
									SELECT dbo.padl(convert(bigint,ISNULL(wmSet.settingValue, mnxSet.settingValue))+1,10,DEFAULT)AS Custno 
									FROM MnxSettingsManagement mnxSet 
									LEFT JOIN wmSettingsManagement wmSet ON mnxSet.settingId = wmSet.settingId 
									WHERE settingName = 'LastGeneratedCustomerNumber'
								 )

			DECLARE @LastCustNoSettingId Uniqueidentifier =(SELECT settingID FROM MnxSettingsManagement WHERE settingName='LastGeneratedCustomerNumber')
			IF EXISTS (SELECT 1 FROM wmSettingsManagement WHERE settingId = @LastCustNoSettingId )
				BEGIN
					UPDATE wmSettingsManagement  SET settingValue =@pcNextNumber
					WHERE settingId=@LastCustNoSettingId
				END 
			ELSE
    			BEGIN
					INSERT INTO wmSettingsManagement (settingId,settingValue)VALUES(@LastCustNoSettingId,@pcNextNumber)
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
			SELECT CustNo from Customer WHERE CustNo=@pcNextNumber
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
		RAISERROR('Error occurred selecting next Customer number.',1,1)
		set @pcNextNumber=' '
		RETURN -1
	END