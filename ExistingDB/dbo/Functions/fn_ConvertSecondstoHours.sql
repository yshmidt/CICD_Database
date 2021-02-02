-- =============================================
-- Author:		Vicky Lu	
-- Create date: <04/01/2014>
-- Description:	<Convert seconds to hours>
-- =============================================
CREATE FUNCTION [dbo].[fn_ConvertSecondstoHours]
(
	-- Add the parameters for the function here
	@pnSeconds numeric(11,3) = 0
)
RETURNS varchar(13)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ResultVar varchar(13)
	--declare @pnseconds numeric(11,3)=3972.345
	DECLARE @lnWholeNumberPart bigint = FLOOR(@pnSeconds)
	DECLARE @lnDecimalPart varchar(11) = SUBSTRING(LTRIM(RTRIM(CONVERT(char(11),@pnSeconds))), CHARINDEX('.',LTRIM(RTRIM(CONVERT(char(11),@pnSeconds))))+1,3)
	SELECT @ResultVar = CONVERT(varchar(6), @lnWholeNumberPart/3600)
						+ ':' + RIGHT('0' + CONVERT(varchar(2), (@lnWholeNumberPart % 3600) / 60), 2)
						+ ':' + RIGHT('0' + CONVERT(varchar(2), @lnWholeNumberPart % 60), 2)+'.'+@lnDecimalPart

	-- Return the result of the function
	RETURN ISNULL(@ResultVar,'0:00:00')

END