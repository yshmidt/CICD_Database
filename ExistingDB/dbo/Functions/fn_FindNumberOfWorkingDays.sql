-- =============================================
-- Author:		Vicky Lu
-- Create date: 02/02/2012
-- Description:	Function to return find the number of woring day between two dates
-- =============================================
CREATE FUNCTION [dbo].[fn_FindNumberOfWorkingDays] 
(
	-- Add the parameters for the function here
	@ldStartDt smalldatetime, @ldEndDt smalldatetime
)

RETURNS numeric(5,0)
AS
BEGIN

IF (@ldStartDt > @ldEndDt)
	RETURN 0
ELSE

	-- Declare the return variable here
	DECLARE @lnReturnDay numeric(5,0), @ldDate smalldatetime, @llProdWorkDay bit, @llIsHoliday bit
	SET @ldDate = @ldStartDt + 1
	SET @lnReturnDay = 0
	
	WHILE @ldDate >= @ldStartDt AND @ldDate <= @ldEndDt
	BEGIN
		SELECT @llProdWorkDay = lprodworkDay from calendarsetup where cDayofWeek = (select DATENAME(WEEKDAY, @ldDate))
		IF @llProdWorkDay = 1	-- a working day
			BEGIN
			SELECT @llIsHoliday = CASE WHEN CAST(@ldDate AS DATE) IN (SELECT CAST(DATE AS DATE) from HOLIDAYS) THEN 1 ELSE 0 END
				IF @llIsHoliday = 0
					BEGIN
						SET @lnReturnDay = @lnReturnDay + 1
				END
		END
		SET @ldDate = @ldDate + 1
	END
	

-- Return the result of the function
RETURN @lnReturnDay

END





