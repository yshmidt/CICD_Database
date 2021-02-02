---10/25/19 YS modified to use MnxSettingsManagement and WmSettingsManagement
CREATE PROCEDURE [dbo].[GetNextSONumber] 
	@pcNextNumber char(10) OUTPUT
AS	
DECLARE @lExit bit=0 ,  @isWMSetting BIT = 1, @settingId UNIQUEIDENTIFIER	
	WHILE (1=1)
		BEGIN
			BEGIN TRANSACTION
			BEGIN TRY
			   
				SELECT @pcNextNumber= dbo.padl(convert(bigint,ISNULL(w.settingValue,m.settingValue))+1,10,DEFAULT) 
				       ,@isWMSetting = CASE WHEN ISNULL(w.settingValue,'')='' THEN 0 ELSE 1 END,
					    @settingId = m.settingId
				   from MnxSettingsManagement  m LEFT JOIN wmsettingsmanagement w 
				       on w.settingId = m.settingId where m.settingName='LastSONumber'

				IF( @isWMSetting =1)
					   BEGIN
							update w set w.settingValue= @pcNextNumber from wmsettingsmanagement w  join MnxSettingsManagement m 
								  on w.settingId = m.settingId   where m.settingName='LastSONumber'
					   END
				ELSE 
				
				      BEGIN
					         INSERT INTO wmsettingsmanagement values(@settingId,@pcNextNumber)
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
				IF EXISTS(SELECT Sono from Somain WHERE Sono=@pcNextNumber )
					CONTINUE
				ELSE
					BREAK
			END
			ELSE -- IF lExit=0
			BREAK
		END -- WHILE (1=1)
		IF  @lExit=1
		BEGIN
			RAISERROR('Error occurred selecting next Sales Order Number.',11,1)
			set @pcNextNumber=' '
			RETURN -1
		END





/* old code */	
	--DECLARE @lExit bit=0	
	--WHILE (1=1)
	--	BEGIN
	--		BEGIN TRANSACTION
	--		BEGIN TRY
	--			SELECT @pcNextNumber= dbo.PADL(CONVERT(bigint,LastSono)+1,10,DEFAULT) FROM MicsSys
	--			UPDATE Micssys SET LastSono = @pcNextNumber	
	--		END TRY
	--		BEGIN CATCH
	--			set @lExit=1;
	--			IF @@TRANCOUNT>0
	--				ROLLBACK
					
	--		END CATCH
	--		IF @lExit=0
	--		BEGIN
	--			IF @@TRANCOUNT>0
	--			COMMIT
	--			--check if the number already in use
	--			SELECT Sono FROM Somain WHERE Sono=@pcNextNumber
	--			IF @@ROWCOUNT<>0
	--				CONTINUE
	--			ELSE
	--				BREAK
	--		END
	--		ELSE -- IF lExit=0
	--		BREAK
	--	END -- WHILE (1=1)
	--	IF  @lExit=1
	--	BEGIN
	--		RAISERROR('Error occurred selecting next Sales Order number.',11,1)
	--		set @pcNextNumber=' '
	--		RETURN -1
	--	END
	
		
	