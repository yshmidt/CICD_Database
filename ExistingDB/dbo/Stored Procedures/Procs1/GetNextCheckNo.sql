-- =============================================
-- Author:		<Yelena>
-- Create date: <???>
-- Description:	Get next Check number
-- Modified: 
-- 04/22/16	VL	The "LastCkNo" might be updated by wire or other type number, the number might look like this:"WIR0000001", so will check if first letter is not number will just pick right 7 character to get next number
-- =============================================
CREATE PROCEDURE [dbo].[GetNextCheckNo] 
	@pcBk_Uniq as Char(10) = ' ',@lUpdateNextNum as bit=1, @pcNextNumber char(15) OUTPUT
	-- @pcBk_Uniq link to the specific bank record
	-- @lUpdateNextNum - 1- to save next number into the Banks record, 0- to just get the next number and return
	-- @pcNextNumber - return next number
AS	
		
	DECLARE @lFirstLoop Bit=1, @lExit Bit=0
	
	WHILE (1=1)
		BEGIN
			BEGIN TRY
			IF (@lFirstLoop=1 OR @lUpdateNextNum=1)
				-- 04/22/16 VL changed to cover other type check number
				--SELECT @pcNextNumber= dbo.padl(convert(bigint,LastCkNo)+1,10,'0') from Banks Where Bk_Uniq = @pcBk_Uniq
				SELECT @pcNextNumber = CASE WHEN (ISNUMERIC(SUBSTRING(Lastckno, 1, 1)) = 1 OR SUBSTRING(lastckno, 1, 1) = '') 
					THEN dbo.padl(convert(bigint,LastCkNo)+1,10,'0')
					ELSE ISNULL(dbo.padl(convert(bigint,RIGHT(lastckno,7))+1,7,'0'),'0000001') END from Banks Where Bk_Uniq = @pcBk_Uniq

			ELSE -- (@lFirstLoop=1 OR @lUpdateNextNum=1)
				SELECT @pcNextNumber= dbo.padl(convert(bigint,@pcNextNumber)+1,10,'0') 
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
					update Banks set LastCkNo=@pcNextNumber	where BK_UNIQ = @pcBk_Uniq	
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
				SELECT Apchk_Uniq from ApChkMst
					WHERE CheckNo=@pcNextNumber and Bk_Uniq = @pcBk_Uniq
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
			RETURN -1
		END