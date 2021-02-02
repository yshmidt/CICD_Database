-- =============================================
-- Author: Satish B		
-- Create date: 04/05/2018
-- Description : Get next packing list number (This procedure is created to resolved the problem of performance while generating new packing list number)
-- Modified : 04/30/2018 : Satish B : Added BEGIN TRANSACTION and  BEGIN TRY and BEGIN CATCH block
--			: 04/30/2018 : Satish B : Add BEGIN - END and implement IF - ELSE conditionally
--			: 04/30/2018 : Satish B : Add leadign zeros in new generated packinglist number
--			: 04/30/2018 : Satish B : There is no need to set @intFlag = 1  and continue statement
--			: 04/30/2018 : Satish B : Comment mnxSettingsManagement updation code and Insert value into [wmSettingsManagement] table instead of updating mnxSettingsManagement table
--			: 04/30/2018 : Satish B : Added code for error handling
--			: 05/23/2018 : Satish B : Modify the condition from dbo.PADL (CONVERT(bigint,@pcNextNumber+1),10,0) To dbo.PADL (CONVERT(bigint,@pcNextNumber)+1,10,0)
--			: 06/25/2018 : Satish B : Removed Insertion of ModuleId column into wmSettingsManagement table
-- exec GetNextPackingListNumber
-- =============================================
CREATE PROCEDURE [dbo].[GetNextPackingListNumber] 
AS	
BEGIN	
	DECLARE @pcNextNumber char(10)='' 
	DECLARE @intFlag BIT = 1
	SELECT @pcNextNumber = dbo.PADL(CONVERT(bigint,ISNULL(w.settingValue,m.settingValue))+1,10,DEFAULT) FROM MnxSettingsManagement  m 
									   LEFT JOIN wmSettingsManagement w ON  m.settingId = w.settingId WHERE m.settingName='LASTPSNO'
	 -- 04/30/2018 : Satish B : Added BEGIN TRANSACTION and  BEGIN TRY and BEGIN CATCH block
	BEGIN TRANSACTION  
		BEGIN TRY
			WHILE (@intFlag =1 )
				BEGIN
					 IF NOT EXISTS(SELECT Packlistno FROM Plmain WHERE Packlistno=@pcNextNumber)
					-- 04/30/2018 : Satish B : Add BEGIN - END and implement IF - ELSE conditionally
					  BEGIN
						SET @intFlag = 0
						BREAK
					  END
					ELSE
					  BEGIN
					  -- 04/30/2018 : Satish B : Add leadign zeros in new generated packinglist number
						--SET @pcNextNumber = @pcNextNumber + 1
					  -- 05/23/2018 : Satish B : Modify the condition from dbo.PADL (CONVERT(bigint,@pcNextNumber+1),10,0) To dbo.PADL (CONVERT(bigint,@pcNextNumber)+1,10,0)
						SET @pcNextNumber = dbo.PADL (CONVERT(bigint,@pcNextNumber)+1,10,0)
							 -- 04/30/2018 : Satish B : There is no need to set @intFlag = 1  and continue statement
							--IF @intFlag = 1 
							--CONTINUE;	
					  END
				END	
				-- Insert / Update wmSettingsManagement table
				IF EXISTS(SELECT w.settingId FROM wmSettingsManagement w INNER JOIN MnxSettingsManagement m ON w.settingId=m.settingId AND m.settingName='LASTPSNO')
				    BEGIN
						UPDATE wmSettingsManagement SET settingValue = @pcNextNumber WHERE settingId IN(SELECT w.settingId FROM wmSettingsManagement w JOIN MnxSettingsManagement m 
							   ON w.settingId=m.settingId AND m.settingName='LASTPSNO')	
					END
				ELSE
				   BEGIN
				    -- 04/30/2018 : Satish B : Comment mnxSettingsManagement updation code and Insert value into [wmSettingsManagement] table instaed of updating mnxSettingsManagement table								  
					--UPDATE mnxSettingsManagement SET settingValue = @pcNextNumber WHERE settingName='LASTPSNO'
					  INSERT INTO [dbo].[wmSettingsManagement]
					   ([settingId]
					   ,[settingValue])
					   --06/25/2018 : Satish B : Removed Insertion of ModuleId column into wmSettingsManagement table
					   --,[ModuleId])
					 SELECT SettingId,@pcNextNumber--,moduleId
					 FROM MnxSettingsManagement WHERE settingName='LASTPSNO'
				   END
			COMMIT
		END TRY
		-- 04/30/2018 : Satish B : Added code for error handling
	    BEGIN CATCH				
		  IF @@TRANCOUNT>0
		  ROLLBACK
		  RAISERROR('Error occurred selecting next Packing List Number.',11,1)
		  RETURN -1
	   END CATCH
	   SELECT @pcNextNumber
END













