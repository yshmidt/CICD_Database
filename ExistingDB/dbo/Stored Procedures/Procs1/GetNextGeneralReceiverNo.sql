---------------------------------------------------------------
--- Author : Shivshankar Patil
--- Date : 1/14/2017
--- Desc : Generate next general receiver number
--- [dbo].[GetNextGeneralReceiverNo] '0000000000'
--- Nilesh Sa 3/15/2018 Modified with left join
--- Nilesh Sa 04/30/2018 Modified with Check for add new wmSettingsManagement record
--- Nilesh Sa 06/11/2018 Modified with Remove the ModuleId column
--- Rajendra B 07/16/2018 : Code commented(inspectionSource='g') to avoid duplicate receiver no generation 
--- Rajendra K 07/16/2018 : Commented condition inspectionSource='g'
--- Rajendra K 07/16/2018 : Changed datatype of param '@defaultSettingValue' from int to bigint
---------------------------------------------------------------
CREATE PROCEDURE [dbo].[GetNextGeneralReceiverNo] 
	@pcNextNumber char(10) OUTPUT
AS	
	DECLARE @lExit bit=0	
	WHILE (1=1)
		BEGIN
			BEGIN TRANSACTION
			BEGIN TRY
				
				DECLARE @updateWmSettingManagementRecord NVARCHAR,@settingId UNIQUEIDENTIFIER,@defaultSettingValue BIGINT,@moduleId INT; --Rajendra K 07/16/2018 : Changed datatype of param '@defaultSettingValue' from int to bigint

				SELECT @settingId= m.settingID ,@defaultSettingValue = m.settingValue,@moduleId =m.moduleId,
				@pcNextNumber= dbo.PADL(CONVERT(bigint,ISNULL(w.settingValue,m.settingValue)) + 1,10,DEFAULT) ,@updateWmSettingManagementRecord = w.settingValue 
				FROM MnxSettingsManagement m 
			    LEFT JOIN wmSettingsManagement w ON w.settingId=m.settingId  --- Nilesh Sa 3/15/2018 Modified with left join
				WHERE m.settingName='LastGeneralReceiverNumber'  

				IF(@updateWmSettingManagementRecord IS NOT NULL)		
				   BEGIN
						UPDATE wmSettingsManagement SET settingValue = @pcNextNumber WHERE settingId IN (SELECT w.settingId FROM wmSettingsManagement w JOIN MnxSettingsManagement m 
							   ON w.settingId=m.settingId  WHERE m.settingName='LastGeneralReceiverNumber')								
				   END
				ELSE 
				   BEGIN
				       --- Nilesh Sa 04/30/2018 Modified with Check for add new wmSettingsManagement record
					   --- Nilesh Sa 06/11/2018 Modified with Remove the ModuleId column
						INSERT INTO wmSettingsManagement(settingId,settingValue)
						VALUES(@settingId, @defaultSettingValue + 1)
				   END
			END TRY
			BEGIN CATCH
				SET @lExit=1;
				IF @@TRANCOUNT>0
					ROLLBACK
			END CATCH

			IF @lExit=0
				BEGIN
					IF @@TRANCOUNT > 0
					COMMIT
					--check if the number already in use
					SELECT receiverno FROM Receiverheader WHERE ISNUMERIC(receiverno) = 1 AND  receiverno = @pcNextNumber --and inspectionSource='g'
					-- Rajendra K 07/16/2018 : Commented condition inspectionSource='g'
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
			RAISERROR('Error occurred selecting next General Receiver Number.',11,1)
			set @pcNextNumber=' '
			RETURN -1
		END	
	