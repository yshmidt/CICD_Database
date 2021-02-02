CREATE FUNCTION dbo.fn_GetWorkDay (@tdTestDt smalldatetime = NULL,@tcDirection char(1)='-' )
RETURNS date
AS
-- remember that maximum nesting level is 32. But since we are just looking for the next working date, hope that they do not have 30 days in between working days
BEGIN
declare @dDateHold date = @tdTestDt
if (SELECT lProdWorkDay
		FROM CalendarSetup 
		WHERE CalendarSetup.cDayOfWeek=datename(weekday,@tdTestDt))=0 or exists(select HOLIDAYS.iHolidaysUk from HOLIDAYS where CAST(HOLIDAYS.[DATE] as DATE)=@tdTestDt and holidays.date=@tdTestDt) 

BEGIN		
		
		--select @tdTestDt = CASE WHEN @tcDirection='-' THEN fn_GetWorkDay(DATEADD(Day,-1,@tdTestDt)
		--					ELSE fn_GetWorkDay(DATEADD(Day,+1,@tdTestDt) END
		
		SET @dDateHold=CASE WHEN @tcDirection='-' THEN DATEADD(Day,-1,@tdTestDt) ELSE DATEADD(Day,+1,@tdTestDt) END
		EXEC @tdTestDt = dbo.fn_GetWorkDay @dDateHold,@tcDirection
						
END
return @tdTestDt 

END
