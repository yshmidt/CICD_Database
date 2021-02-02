
CREATE PROCEDURE [dbo].[GetNextGLTransNumber] 
	-- Add the parameters for the stored procedure here
	-- 05/28/13 YS changed the procedure to suppress SQL result printing in the output window every time we check if trans_no is already in use
	@pcNextNumber int OUTPUT
AS
BEGIN
	-- 05/28/13 YS changed the procedure to suppress SQL result printing in the output window every time we check if trans_no is already in use
	DECLARE @nCount as int
	WHILE (1=1)
		BEGIN
			SELECT @pcNextNumber = GlSys.Last_Trans + 1 from GlSys
			
			BEGIN TRANSACTION
			update GlSys set Last_Trans=@pcNextNumber					
			--check if the number already in use
			COMMIT
			-- 05/28/13 YS changed the procedure to suppress SQL result printing in the output window every time we check if trans_no is already in use
			--SELECT GltransHeader.TRANS_NO from GlTransHeader WHERE Trans_No= @pcNextNumber
			
			SELECT @nCount=COUNT(*) from GlTransHeader WHERE Trans_No= @pcNextNumber
			IF @nCount <>0
				CONTINUE
			ELSE
				BREAK
			
		END
END



