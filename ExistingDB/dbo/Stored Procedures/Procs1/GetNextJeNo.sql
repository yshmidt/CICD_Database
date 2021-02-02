
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <06/29/11>
-- Description:	<Generate next JE number (used in JE modules)>
-- =============================================
CREATE PROCEDURE [dbo].[GetNextJeNo]
	@pnNextNumber numeric(6,0)=0 OUTPUT
	AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @lExit bit=0	
	WHILE (1=1)
		BEGIN
			BEGIN TRANSACTION
			BEGIN TRY
				SELECT @pnNextNumber=GLSYS.Lastje_no + 1 FROM GlSys
				update GLSYS set LASTJE_NO=@pnNextNumber 
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
				SELECT GlJeHdro.Je_no
					FROM GlJeHdro
				WHERE Je_no=@pnNextNumber 
				UNION 
				SELECT GlJeHdr.Je_no
					FROM GlJeHdr
				WHERE Je_no=@pnNextNumber
				
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
			RAISERROR('Error occurred selecting next Journal Entry number.',11,1)
			set @pnNextNumber=0
			RETURN -1
		END
	
	
	
	
	
END -- procedure 