-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/12/2013
-- Description:	create calendar between start and end date
----02/10/14 YS added OPTION (MAXRECURSION 0) to avoid "The maximum recursion 100 has been exhausted before statement completion."
-- =============================================
CREATE FUNCTION [dbo].[fn_GetCalendar]
(	
	-- Add the parameters for the function here
	@startDate smalldatetime, 
	@endDate smalldatetime
)
RETURNS 
@calendar TABLE  (dDate smalldatetime,WorkingDay bit default 0,WorkDayCount int)

AS
BEGIN
	-- Fill the table variable with the rows for your result set
	;with Calendar
	as
	( 		 
    Select @startDate As [dDate]
		Union All
    Select DateAdd(d,1,[dDate])
    From Calendar  
    Where [dDate] < DATEADD(dd,-1,DATEADD(MM,DATEDIFF(mm,0,@endDate)+2,0)) 
    )
    -- populate calendar with working date flag
    --02/10/14 YS added OPTION (MAXRECURSION 0) to avoid "The maximum recursion 100 has been exhausted before statement completion."

    INSERT INTO @calendar (dDate ,WorkingDay )
		Select [dDate],
		CASE WHEN S.lProdWorkDay=0 OR NOT Holidays.HOLIDAY IS NULL THEN 0 ELSE 1 END as  WorkingDay
		From Calendar C INNER JOIN CalendarSetup S ON S.cDayOfWeek =DATENAME(dw,c.dDate) 
		left outer join HOLIDAYS on C.dDate=Holidays.DATE  OPTION (MAXRECURSION 0)

    -- now populate working date sequencce
	;with sequnece
	as (select dDate,ROW_NUMBER() over (order by dDate) as WorkDayCount from @calendar where WorkingDay =1)
	update @calendar set WorkDayCount =isnull(S.WorkDayCount,0) FROM @calendar c1 LEFT OUTER JOIN sequnece S on c1.dDate = s.dDate
	 
	--select * from @calendar
	RETURN 
END
