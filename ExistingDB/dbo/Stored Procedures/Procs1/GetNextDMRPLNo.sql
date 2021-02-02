CREATE PROCEDURE [dbo].[GetNextDMRPLNo] 
	@pcNextNumber char(10) OUTPUT
AS	
	
	DECLARE @lExit bit=0	
	WHILE (1=1)
		BEGIN
			BEGIN TRANSACTION
			BEGIN TRY
				SELECT @pcNextNumber= dbo.padl(convert(bigint,LASTDMRPLNO)+1,10,'0') from MicsSys
				update Micssys set LASTDMRPLNO=@pcNextNumber
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
				SELECT DMRPlno from PORECMRB WHERE DMRPLNO=@pcNextNumber
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
			RAISERROR('Error occurred selecting next Debit Memo number.',1,1)
			set @pcNextNumber=' '
			RETURN -1
		END
	
	
