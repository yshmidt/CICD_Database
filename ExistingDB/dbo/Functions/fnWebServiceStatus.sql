-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 07/30/2013
-- Description:	Check if the web service is running based on the LastWebServiceCheckIn date
-- service is running every 30 sec will compare generalsetup LastWebServiceCheckIn field and current time and if more than 40 sec will return
--- 0 if less than 40 sec will return 1
-- =============================================
CREATE FUNCTION fnWebServiceStatus 
(
	-- Add the parameters for the function here
	 
)
RETURNS bit
AS
BEGIN
	-- Declare the return variable here
	DECLARE @WebStatus bit
	Declare @nWaitSeconds int = 40
	-- Add the T-SQL statements to compute the return value here
	SELECT @WebStatus = CASE WHEN LastWebServiceCheckIn is not null and DATEDIFF(ss,LastWebServiceCheckIn,GETDATE())<=40 THEN 1 ELSE 0 END FROM GENERALSETUP  

	-- Return the result of the function
	RETURN @WebStatus

END