-------------------------------------------------------------
--- Author : ?
--- Created Date : ?
--- Desc : Create next customer number
--- 4/20/2018 Shripati Update last generated cust no using Mnx setting management table
--------------------------------------
CREATE PROCEDURE [dbo].[GetNextCustomerNumber] 
	@pcNextNumber char(10) OUTPUT
AS	
	
	DECLARE @lExit bit=0	
	WHILE (1=1)
		BEGIN
			BEGIN TRANSACTION
			BEGIN TRY
				--SELECT @pcNextNumber= dbo.padl(convert(bigint,LastCustNo)+1,10,DEFAULT) from MicsSys
				--update Micssys set LastCustNo=@pcNextNumber	
				--- 4/20/2018 Shripati Update last generated cust no using Mnx setting management table
			    DECLARE @updateMnxSettingManagementRecord NVARCHAR;
				SELECT @pcNextNumber= dbo.PADL(CONVERT(bigint,ISNULL(w.settingValue,m.settingValue))+1,10,DEFAULT) ,@updateMnxSettingManagementRecord = w.settingValue 
				FROM MnxSettingsManagement m LEFT JOIN  wmSettingsManagement w 
				ON w.settingId=m.settingId  WHERE m.settingName='LastGeneratedCustomerNumber'

				IF(@updateMnxSettingManagementRecord IS NOT NULL)		
				   BEGIN
						UPDATE wmSettingsManagement SET settingValue = @pcNextNumber 
						WHERE settingId IN(SELECT w.settingId 
						FROM wmSettingsManagement w 
						JOIN MnxSettingsManagement m  ON w.settingId=m.settingId  
						WHERE m.settingName='LastGeneratedCustomerNumber')	
				   END
				ELSE 
				   BEGIN
						UPDATE MnxSettingsManagement SET settingValue = @pcNextNumber WHERE settingName='LastGeneratedCustomerNumber'	
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



