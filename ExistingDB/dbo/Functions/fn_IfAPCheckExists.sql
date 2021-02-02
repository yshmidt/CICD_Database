-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/14/2012
-- Description:	finction will check and if check number for the given bank is already in use will return 1 otherwise 0
-- =============================================
CREATE FUNCTION dbo.fn_IfAPCheckExists
(
	-- Add the parameters for the function here
	@lcBk_Uniq char(10) =' ',@lcCheckNo char(10)=' '
)
RETURNS bit
AS
BEGIN
	-- Declare the return variable here
	DECLARE @lChkExists bit=0

	-- Add the T-SQL statements to compute the return value here
	IF EXISTS(SELECT  1 
		FROM APCHKMST 
		WHERE (apchkmst.CHECKNO =@lcCheckNo or apchkmst.CHECKNO=dbo.PADL(@lcCheckNo,10,'0')) and apchkmst.BK_UNIQ=@lcBk_Uniq )
		SET  @lChkExists=1
	ELSE
		SET @lChkExists=0	
		
	
	-- Return the result of the function
	RETURN @lChkExists

END