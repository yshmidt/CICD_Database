--Modified Satish B: 02/11/2019 Get LastPONumber from WmsettingManagement instead of MicsSys 
--Modified Satish B: 02/19/2019 Get LastPoNumber from settingValue of MnxSettingsManagement and Replace INNER JOIN with LEFT JOIN
--EXEC [GetNextPONumber] @pcNextNumber=''
CREATE PROCEDURE [dbo].[GetNextPONumber] 
	@pcNextNumber char(15) OUTPUT
AS	
		
	DECLARE @lExit bit=0 ,  @isWMSetting BIT = 1, @settingId UNIQUEIDENTIFIER	
	WHILE (1=1)
		BEGIN
			BEGIN TRANSACTION
			BEGIN TRY
			    --Satish B: 02/11/2019 Get LastPONumber from WmsettingManagement instead of MicsSys 
				--SELECT @pcNextNumber= dbo.padl(convert(bigint,LastPoNo)+1,15,DEFAULT) from MicsSys
				--Satish B: 02/19/2019 Get LastPoNumber from settingValue of MnxSettingsManagement and Replace INNER JOIN with LEFT JOIN
				SELECT @pcNextNumber= dbo.padl(convert(bigint,ISNULL(w.settingValue,m.settingValue))+1,15,DEFAULT) 
				       ,@isWMSetting = CASE WHEN ISNULL(w.settingValue,'')='' THEN 0 ELSE 1 END,
					    @settingId = m.settingId
				   from MnxSettingsManagement  m LEFT JOIN wmsettingsmanagement w 
				       on w.settingId = m.settingId where m.settingName='LastPONumber'

				IF( @isWMSetting =1)
					   BEGIN
							update w set w.settingValue= @pcNextNumber from wmsettingsmanagement w  join MnxSettingsManagement m 
								  on w.settingId = m.settingId   where m.settingName='LastPONumber'
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
				IF EXISTS(SELECT PonUM from Pomain WHERE PoNum=@pcNextNumber OR Ponum='T'+SUBSTRING(@pcNextNumber,2,LEN(@pcNextNumber)))
					CONTINUE
				ELSE
					BREAK
			END
			ELSE -- IF lExit=0
			BREAK
		END -- WHILE (1=1)
		IF  @lExit=1
		BEGIN
			RAISERROR('Error occurred selecting next Purchase Order Number.',11,1)
			set @pcNextNumber=' '
			RETURN -1
		END
	
	
	

