-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 01/13/2011
-- Description:	<Remove leading zeros from a string (like serial number>
-- =============================================
CREATE FUNCTION [dbo].[fRemoveLeadingZeros]
(
	-- Add the parameters for the function here
	@lcstring varchar(50)
)
RETURNS varchar(50)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ResultVar varchar(50)=''
	/*example "000000000Ad4585m032483", first replace all "0" with a space we will have "         Ad4585m 32483". 
	Then trim leading spaces we will have "Ad4585m 32483", after that replace left over spaces with "0"
	"Ad4585m032483" */
	-- Add the T-SQL statements to compute the return value here
	--SELECT @ResultVar=REPLACE(LTRIM(REPLACE(@lcstring,'0',' ')),' ','0')
	-- 01/14/13 YS use patindex('%[^0]%,@lcstring - to find first none zero
	-- this way if the string had a space like '000000000Ad4585m 032483' the result will be 'Ad4585m 032483'
	-- SELECT @ResultVar=REPLACE(LTRIM(REPLACE(@lcstring,'0',' ')),' ','0') will retunr 'Ad4585m0032483'
	SELECT @ResultVar=substring(@lcstring,patindex('%[^0]%',@lcstring), 50)
	-- Return the result of the function
	RETURN @ResultVar

END


