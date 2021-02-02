CREATE PROCEDURE [dbo].[GetNextPOReceiverNo] 
	@pcNextNumber char(10) OUTPUT
AS	
	
	DECLARE @lExit bit=0	
	WHILE (1=1)
		BEGIN
			BEGIN TRANSACTION
			BEGIN TRY
				SELECT @pcNextNumber= dbo.padl(convert(bigint,LastRecvr)+1,10,'0') from MicsSys
				update Micssys set LastRecvr=@pcNextNumber
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
				SELECT Receiverno from PoDock WHERE ReceiverNo=@pcNextNumber
				IF @@ROWCOUNT<>0
					CONTINUE
				
				ELSE -- IF @@ROWCOUNT<>0 in PODOC
				BEGIN
					--check for the receiver number in the porecdtl table
					SELECT Receiverno FROM PoRecDtl WHERE ReceiverNo = @pcNextNumber
					IF @@ROWCOUNT<>0
						CONTINUE
					ELSE
						BREAK
				END -- -- IF @@ROWCOUNT<>0 in PODOC
			END
			ELSE -- IF lExit=0
			BREAK
		END -- WHILE (1=1)
		IF  @lExit=1
		BEGIN
			RAISERROR('Error occurred selecting next Purchase Receiver Number.',11,1)
			set @pcNextNumber=' '
			RETURN -1
		END	
	