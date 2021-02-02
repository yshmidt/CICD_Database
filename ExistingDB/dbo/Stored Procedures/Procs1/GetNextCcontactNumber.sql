
CREATE PROCEDURE [dbo].[GetNextCcontactNumber] 
	@pcNextNumber char(10) OUTPUT
AS	
	DECLARE @lExit bit = 0	
	WHILE (1=1)
		BEGIN
		BEGIN TRY
			BEGIN TRANSACTION
			SELECT @pcNextNumber= dbo.padl(convert(bigint,LastCid)+1,10,DEFAULT) from MicsSys
			update Micssys set LastCid=@pcNextNumber	
		END TRY
		BEGIN CATCH
			ROLLBACK TRAN ;
			SET @lExit=1 ;
			

		END CATCH
		IF @@TRANCOUNT>0
			COMMIT TRANSACTION;
		IF @lExit=1	
			BREAK
		ELSE
		BEGIN  -- else @lExit=1		
			--check if the number already in use
			SELECT Cid from Ccontact WHERE Cid=@pcNextNumber
			IF @@ROWCOUNT<>0
				CONTINUE
			ELSE
				BREAK
		END	-- end @lExit=1		
	END -- WHILE (1=1)
	IF @lExit=1
	BEGIN
		RAISERROR('Error occurred selecting next contact number.',1,1)
		RETURN -1
	END