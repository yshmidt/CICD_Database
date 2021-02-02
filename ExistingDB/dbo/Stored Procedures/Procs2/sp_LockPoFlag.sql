CREATE PROCEDURE [dbo].[sp_LockPoFlag] @cSaveInfo char(8)='', @Return bit = 0 OUTPUT
AS
BEGIN

DECLARE @lIs_Lock bit

SELECT @lIs_Lock = lInSave 
	FROM PODEFLTS 

BEGIN
IF @lIs_Lock = 1
	BEGIN	
	
	-- Is locked already, return 0
	SET @Return = 0;
	
	END
ELSE
	BEGIN
	
	-- Not lock yet, can place lock and return 1
	UPDATE PODEFLTS 
		SET lInSave = 1,
			LINSAVEINFO =@cSaveInfo ,
			lInSaveDt  = GETDATE()
			
	SET @Return = 1;
	
	END
END

-- Return the result of the function
SELECT @Return

END
