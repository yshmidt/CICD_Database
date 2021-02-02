
-- 09/06/12 VL changed to SET @dDateHold by @tcDirection is '-' or '+', now, the @tnDays is for move forward or backword how many days
-- and @tcDirection is to indicate move forward or backword.  the @tnDays is always positive

CREATE FUNCTION [dbo].[fn_GetWorkDayWithOffset] (@tdTestDt smalldatetime=null, @tnDays int=0,@tcDirection char(1)='-')
RETURNS date
AS
BEGIN
DECLARE @lnCount int=0, @dDateHold date = @tdTestDt

WHILE @lnCount<=ABS(@tnDays)
BEGIN
	
	SELECT @tdTestDt = dbo.fn_GetWorkDay(@dDateHold,@tcDirection) ,@lnCount=@lnCount+1
	--SET @dDateHold=CASE WHEN @tnDays<0 THEN DATEADD(Day,-1,@tdTestDt) ELSE DATEADD(Day,+1,@tdTestDt) END
	SET @dDateHold=CASE WHEN @tcDirection = '-' THEN DATEADD(Day,-1,@tdTestDt) ELSE DATEADD(Day,+1,@tdTestDt) END

END
RETURN @tdTestDt
END
