
CREATE PROCEDURE [dbo].[GetNextTempPoNumber] 
	-- Add the parameters for the stored procedure here
	@pcNextNumber char(15) OUTPUT
AS
BEGIN
	
	DECLARE @nLastTempNo int
 	DECLARE @lExit bit=0	
	WHILE (1=1)
		BEGIN
			BEGIN TRANSACTION
			BEGIN TRY
				SELECT @nLastTempNo = LasttempNo+1 from PoDeflts
				update PoDeflts set LasttempNo=@nLastTempNo	
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
				-- 11/15/12 Change temp number to have leading 0s that way all POs numbers have leading 0 and it makes it consistent to search for a PO 
				--SELECT @pcNextNumber = dbo.padr('TEMP'+CONVERT(char,@nLastTempNo),15,' ')
				SELECT @pcNextNumber = 'T'+dbo.padl('TEMP'+CONVERT(char,@nLastTempNo),14,'0')
				SELECT PonUM from Pomain WHERE PoNum= @pcNextNumber
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
			RAISERROR('Error occurred selecting next Temporaray Purchase Order number.',11,1)
			set @pcNextNumber=' '
			RETURN -1
		END
 	
 	
 	
 	
 	END

