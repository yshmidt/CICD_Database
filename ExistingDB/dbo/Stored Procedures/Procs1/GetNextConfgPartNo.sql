-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/12/2016
-- Description:	Get Next Configuration part number
-- =============================================
CREATE PROCEDURE [dbo].[GetNextConfgPartNo] 
	@pcPreFix as Char(22) = ' ', @pcNextNumber char(7) OUTPUT
AS	
	DECLARE @lExit bit=0,@nCount int	
	WHILE (1=1)
		BEGIN
			BEGIN TRANSACTION
			BEGIN TRY
				SELECT @pcNextNumber= dbo.padl(convert(int,LastCfPtNo)+1,7,'0') from MicsSys
				update Micssys set LastCfPtNo=@pcNextNumber	
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
				SET @nCount=0
				SELECT @nCount=COUNT(*) from Inventor 
					WHERE Part_no = dbo.PADR(LTRIM(RTRIM(@pcPrefix))+'-C'+LTRIM(RTRIM(@pcNextNumber)),25,' ')
				IF @nCount<>0
				
					CONTINUE
				ELSE
					BREAK
			END
			ELSE -- IF lExit=0
			BREAK
		END -- WHILE (1=1)
		IF  @lExit=1
		BEGIN
			RAISERROR('Error occurred selecting next Configuration Part Number.',11,1)
			set @pcNextNumber=' '
			RETURN -1
		END
	
		
	

