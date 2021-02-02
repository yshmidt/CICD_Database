---------------------------------------------------------------
--- Author : Shivshankar Patil
--- Date : 04/30/2018
--- Desc : Generate next PO receiver number
--- Modification
    -- 07/16/2018 Nitesh B : Code commented(inspectionSource='g') to avoid duplicate receiver no generation
	-- 10/12/2018 Rajendra K : Replaced  'LastPORecNumber' BY 'LastGeneralReceiverNumber'
---------------------------------------------------------------
CREATE PROCEDURE [dbo].[GetNextPORecNo] 
	@nextRecNumber char(10) OUTPUT
AS	
	DECLARE @lExit bit=0	
	WHILE (1=1)
		BEGIN
			BEGIN TRANSACTION
			BEGIN TRY
				
				DECLARE @updateWmSettingManagementRecord NVARCHAR,@settingId UNIQUEIDENTIFIER,@defaultSettingValue INT,@moduleId INT;

				SELECT @settingId= m.settingID ,@defaultSettingValue = m.settingValue,@moduleId =m.moduleId,
				@nextRecNumber= dbo.PADL(CONVERT(bigint,ISNULL(w.settingValue,m.settingValue)) + 1,10,DEFAULT) ,@updateWmSettingManagementRecord = w.settingValue 
				FROM MnxSettingsManagement m 
			    LEFT JOIN wmSettingsManagement w ON w.settingId=m.settingId  --- Nilesh Sa 3/15/2018 Modified with left join
				WHERE m.settingName='LastGeneralReceiverNumber' 	-- 10/12/2018 Rajendra K : Replaced  'LastPORecNumber' BY 'LastGeneralReceiverNumber'

				IF(@updateWmSettingManagementRecord IS NOT NULL)		
				   BEGIN
						UPDATE wmSettingsManagement SET settingValue = @nextRecNumber WHERE settingId IN (SELECT w.settingId FROM wmSettingsManagement w JOIN MnxSettingsManagement m 
							   ON w.settingId=m.settingId  WHERE m.settingName='LastGeneralReceiverNumber')	 	-- 10/12/2018 Rajendra K : Replaced  'LastPORecNumber' BY 'LastGeneralReceiverNumber'
				   END
				ELSE 
				   BEGIN
				       --- Nilesh Sa 04/30/2018 Modified with Check for add new wmSettingsManagement record
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
					SELECT receiverno FROM Receiverheader WHERE receiverno=@nextRecNumber 
					 --and inspectionSource='g' -- 07/16/2018 Nitesh B : Code commented to avoid duplicate receiver no generation 
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
			set @nextRecNumber=' '
			RETURN -1
		END