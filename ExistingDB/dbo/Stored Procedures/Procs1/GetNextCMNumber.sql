CREATE PROCEDURE [dbo].[GetNextCMNumber] 
	@pcNextNumber char(10) OUTPUT
AS	
	DECLARE @lExit bit=0		
	WHILE (1=1)
		BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			SELECT @pcNextNumber= 'CM' + dbo.PADL(CONVERT(int,right(LastCMno,8))+1,8,DEFAULT) FROM MicsSys
			UPDATE Micssys SET LastCMno = @pcNextNumber				
		END TRY
		BEGIN CATCH
			SET @lExit=1;
			IF @@TRANCOUNT>0
					ROLLBACK
			
		END CATCH	
		IF @lExit=0
		BEGIN
			IF @@TRANCOUNT>0
				COMMIT
			--check if the number already in use
			SELECT CMemoNo FROM CMMain WHERE CMemoNo=@pcNextNumber
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
			RAISERROR('Error occurred selecting next Credit Memo number.',1,1)
			set @pcNextNumber=' '
			RETURN -1
		END