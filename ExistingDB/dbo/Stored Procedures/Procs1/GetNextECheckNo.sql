-- =============================================
-- Author:		<Vicky Lu>
-- Create date: <07/20/2015>
-- Description:	Get next eCheck number
-- Modified: 
-- 01/04/16	VL	Added ISNULL() to @pcNextNumber2 to avoid null value if apsetupp or mnxsettingmanagement has no this record
-- 07/05/16 VL	Changed to check eTransactionSetting from wmSettingsManagement first then mnxSettingsManagement
-- 06/30/17 VL  Added @CheckNo as 3rd parameter, if this value is not empty, then will just take @CheckNo+1 as @pcNextNumber to return, also update setup table.  
--				Paramit want to see wire transfer number in check prit form, need to increase number properly if user changes the checkno on screen
-- =============================================
CREATE PROCEDURE [dbo].[GetNextECheckNo] 
	@pcBk_Uniq as Char(10) = ' ',@lUpdateNextNum as bit=1, @PaymentType varchar(50), @CheckNo varchar(10), @pcNextNumber varchar(10) OUTPUT
	-- @pcBk_Uniq link to the specific bank record
	-- @lUpdateNextNum - 1- to save next number into the Banks record, 0- to just get the next number and return
	-- @pcNextNumber - return next number
AS	
		
	DECLARE @lFirstLoop Bit=1, @lExit Bit=0, @eTransactionSetting varchar(15), @pcNextNumber2 varchar(10), @ApChk_Uniq char(10)
	-- 07/20/15 VL added @eTransactionSetting
	-- 07/05/16 VL found that we need to check wmSettingsManagement too, only check MnxSettingManagement when no wmSettingManagement
	--SELECT @eTransactionSetting = settingValue FROM MnxSettingsManagement WHERE moduleId = 70 and settingname = 'eTransactionSetting'
	SELECT @eTransactionSetting = ISNULL(wm.settingValue,mnx.settingValue)
		FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm 
		ON mnx.settingId = wm.settingId 
		WHERE mnx.settingName='eTransactionSetting'
	
	WHILE (1=1)
		BEGIN
			BEGIN TRY
			IF (@lFirstLoop=1 OR @lUpdateNextNum=1)
				BEGIN
				-- 06/30/17 VL added IF @CheckNo <> 0 to update directly from @CheckNo
				IF @CheckNo <> ''
					BEGIN
						SELECT @pcNextNumber2= ISNULL(dbo.padl(convert(bigint,RIGHT(@CheckNo,7))+1,7,'0'),'0000001')
						SELECT @CheckNo = @pcNextNumber2
					END
				ELSE
					BEGIN
					IF @eTransactionSetting = 'Each Bank'
						SELECT @pcNextNumber2= ISNULL(dbo.padl(convert(bigint,RIGHT(eReferencenumber,7))+1,7,'0'),'0000001') from Banks Where Bk_Uniq = @pcBk_Uniq
					ELSE
						-- 'System'
						SELECT @pcNextNumber2= ISNULL(dbo.padl(convert(bigint,RIGHT(WireTrfrno,7))+1,7,'0'),'0000001') from Apsetup
					END
				END
			ELSE -- (@lFirstLoop=1 OR @lUpdateNextNum=1)
				SELECT @pcNextNumber2= ISNULL(dbo.padl(convert(bigint,RIGHT(@pcNextNumber2,7))+1,7,'0'),'0000001')
			END TRY
			BEGIN CATCH
				SET @lExit=1 ;
				
			
			END CATCH
			IF @lExit=1
			BEGIN	
				BREAK
				
			END
			ELSE  -- IF @lExit=1
			BEGIN	
				if (@lUpdateNextNum=1) 
				begin
					BEGIN TRANSACTION
					BEGIN TRY
						BEGIN
						IF @eTransactionSetting = 'Each Bank'
							UPDATE Banks set eReferenceNumber = LEFT(UPPER(@PaymentType),3)+@pcNextNumber2 where BK_UNIQ = @pcBk_Uniq	
						ELSE
							UPDATE Apsetup SET WireTrFrNo = LEFT(UPPER(@PaymentType),3)+@pcNextNumber2
						END
						SET @pcNextNumber = LEFT(UPPER(@PaymentType),3)+@pcNextNumber2
					END TRY
					BEGIN CATCH
						SET @lExit=1 ;
						ROLLBACK
					END CATCH		
				end
			END	-- IF @lExit=1
			IF @@TRANCOUNT>0
				COMMIT TRAN
			IF @lExit=0	
			BEGIN
				--check if the number already in use
				SELECT @ApChk_Uniq = Apchk_Uniq 
					FROM ApChkMst
					WHERE CheckNo=LEFT(UPPER(@PaymentType),3)+RIGHT(@pcNextNumber2,7) and Bk_Uniq = @pcBk_Uniq
				IF @@ROWCOUNT<>0
					-- create next num
					BEGIN		
					SET @lFirstLoop=0
					CONTINUE
					END		
				ELSE
					BREAK
			END --@@lExit=0
			BREAK
					
		END -- WHILE (1=1)
		IF @lExit=1
		BEGIN
			RAISERROR('Error occurred selecting next contact number.',1,1)
			SET @pcNextNumber = ''
			RETURN -1
		END