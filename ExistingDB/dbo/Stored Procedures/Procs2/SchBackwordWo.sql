-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/28/2013
-- Description:	Auot schedule work order using work order due date as complete date and find the erliest start date based on the process time
-- =============================================
CREATE PROCEDURE [dbo].[SchBackwordWo] 
	-- Add the parameters for the stored procedure here
	@wono char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @startDate smalldatetime,@endDate smalldatetime,@liDateFirst integer,@SumCurrqty numeric(7),@nJobWcCount int,@wrkDayCount int,
	@calendarEndDate smalldatetime,@calendarStartDate smalldatetime

    -- Insert statements for procedure here
	select @endDate =woentry.DUE_DATE  from WOENTRY where WONO=@wono
	if DATEDIFF(dd,@endDate,GETDATE())>=0
	BEGIN 
		-- end due date is prior to today assign today as start date and call schedule
		set @startDate =GETDATE()
		set @endDate =GETDATE()
		exec [SchPlanningAdjustWOStart] @wono,@startDate,@endDate
	END	--DATEDIFF(dd,@endDate,GETDATE())>=0
	else -- else DATEDIFF(dd,@endDate,GETDATE())>=0
	BEGIN -- else DATEDIFF(dd,@endDate,GETDATE())>=0
		SET @calendarEndDate = DATEADD(dd,8,@endDate)
		SET @calendarStartDate = CASE WHEN DATEADD(dd,-60,@calendarEndDate)>GETDATE() THEN DATEADD(dd,-60,@calendarEndDate) ELSE GETDATE() end
		DECLARE @calendar as dbo.tCalendar
		INSERT INTO @calendar (ddate, WorkingDay,WorkDayCount) SELECT ddate,WorkingDay,WorkDayCount from dbo.fn_GetCalendar(@calendarStartDate,@calendarEndDate) order by ddate
		-- find first and last working date in the calendar
		 SELECT @startDate=MIN(cal.dDate) from @calendar cal where dDate>=@startDate and WorkingDay=1
		 SELECT @endDate=MIN(cend.dDate) from @calendar cend where dDate>=@endDate and WorkingDay=1
		 
		 DECLARE @CurrShopFlView table (dept_name char(25),Dueoutdt smalldatetime, Setuptimem numeric(11,3), Runtimem numeric(11,3),Dept_pri numeric(7,3),Curr_qty numeric(7,0),
			Wono char(10), Dept_id char(4),Xfer_qty numeric (7,0), Number numeric(4),UNIQUEREC char(10) ,
			Capctyneed numeric(12,0),Wo_wc_note text, Deptkey char(10), Serialstrt bit, Wcnote text,Process_time_h numeric(11,3),Wc_Avg_CapacityH numeric(11,3),uniq_key char(10))
		
		INSERT INTO @CurrShopFlView EXEC currshopflview @wono	
		SELECT @SumCurrqty =SUM(Curr_qty) from @CurrShopFlView	
	
	END  -- else DATEDIFF(dd,@endDate,GETDATE())>=0
	
END