-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/10/11
-- Description:	fn_nManex
-- =============================================
CREATE FUNCTION dbo.fn_nManex 
(
	-- Add the parameters for the function here
	 
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @nResult int

	-- Add the T-SQL statements to compute the return value here
	SELECT @nResult = COUNT(*)
	FROM master.dbo.sysprocesses where Program_Name like '%SQLMANEX%'  

	-- Return the result of the function
	RETURN @nResult

END
