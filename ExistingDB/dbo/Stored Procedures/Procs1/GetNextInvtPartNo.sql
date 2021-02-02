-- =============================================
-- 04/20/18 Vijay G : Moved the Auto Number No and Last Part No setting value from MICSSYS table to MnxSettingsManagement and wmSettingsManagement table
-- 04/20/18 Vijay G : Update Last auto part number value in to the wmSettingsManagement table
---05/31/18 YS using module name creates an issue. In this case we do not need module id at all because we have the settings name and in my opinion we should not use 
--- the same setting name more than once.
--05/31/18 YS For the users that are using manex for the first time the first value will come from mnxsettings, unless the last value is populated in the application already
-- =============================================
CREATE PROCEDURE [dbo].[GetNextInvtPartNo] 
	@pcNextNumber char(15) OUTPUT
AS	
	
	-- 05/13/13 YS changed the procedure to suppress SQL result printing in the output window every time I check if part number already exists
	DECLARE @lExit bit=0,@nCount int	
	WHILE (1=1)
		BEGIN
			BEGIN TRANSACTION
			BEGIN TRY
			-- 04/20/18 Vijay G : Get the Last auto part number value from wmSettingsManagement table	
			--05/31/18 get the setting id at the same time. 
			declare @settingid uniqueidentifier 
			SELECT @pcNextNumber= dbo.padl(convert(int,RTRIM(isnull(w.settingValue,m.settingValue)))+1,7,'0') ,
					@settingid=m.settingId
					FROM MnxSettingsManagement M left outer join wmSettingsManagement W on m.settingId=w.settingId  
					WHERE settingName ='LastPartNO' 
				---05/31/18 YS using module name creates an issue. In this case we do not need module id at all because we have the settings name and in my opinion we should not use 
--- the same setting name more than once.
					---and moduleId =
			--(SELECT moduleid FROM MnxModule WHERE ModuleName='Part Master with AML Control (PM)'))

				-- 04/20/18 Vijay G : Moved the Auto Number No and Last Part No setting value from MICSSYS table to MnxSettingsManagement and wmSettingsManagement table
				--update Micssys set LastPtNo=@pcNextNumber
				-- 04/20/18 Vijay G : Update Last auto part number value in to the wmSettingsManagement table	
				--- 05/31/18 YS setting id was saved into a variable @settingid
			--	UPDATE wmSettingsManagement SET settingValue=RTRIM(@pcNextNumber) WHERE settingId =(SELECT settingId FROM MnxSettingsManagement WHERE settingName ='LastPartNO' and moduleId =
			--(SELECT moduleid FROM MnxModule WHERE ModuleName='Part Master with AML Control (PM)'))
			UPDATE wmSettingsManagement SET settingValue=RTRIM(@pcNextNumber) WHERE settingId =@settingid

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
				-- 05/13/13 YS
				--SELECT uniq_key from Inventor 
				--	WHERE RIGHT(Part_no,7)=@pcNextNumber
				--IF @@ROWCOUNT<>0
				--05/31/18 YS just check if exists
				--set @nCount=0
				--SELECT @nCount=COUNT(*) from Inventor 
				--	WHERE RIGHT(Part_no,7)=@pcNextNumber
				--IF @nCount<>0
				IF EXISTS (select 1 from inventor where RIGHT(Part_no,7)=@pcNextNumber) 
					CONTINUE
				ELSE
					BREAK
			END
			ELSE -- IF lExit=0
			BREAK
		END -- WHILE (1=1)
		IF  @lExit=1
		BEGIN
			RAISERROR('Error occurred selecting next Inventory Part Number.',11,1)
			set @pcNextNumber=' '
			RETURN -1
		END
		
	

