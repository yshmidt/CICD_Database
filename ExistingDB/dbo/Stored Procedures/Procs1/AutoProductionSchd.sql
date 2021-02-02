-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 04/05/2016
-- Description:	Auto-schedule Open Orders that were never scheduled
-- =============================================
CREATE PROCEDURE AutoProductionSchd 
	-- Add the parameters for the stored procedure here
	@userId uniqueidentifier = Null
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- select all open orders with balance and no schedule into cursor
	declare @wono char(10) ='',
			@startDate smalldatetime = GETDATE(),
			@endDate smalldatetime = null,
			@lAutoSchd bit = 1,
			@lCalculatePriorityOnly bit = 0

	DECLARE JobsToSchedule CURSOR LOCAL FAST_FORWARD
	FOR
		SELECT Wono,Due_date 
			from woentry where OPENCLOS not IN ('Closed','Cancel') and balance<>0 and not exists 
			(select 1 from PROD_DTS where prod_dts.wono=woentry.wono)  
	
	OPEN JobsToSchedule;
	FETCH NEXT FROM JobsToSchedule INTO @wono,@endDate ;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC [SchPlanningAdjustWOStart] @wono,@startDate,@endDate,@userID,@lAutoSchd,@lCalculatePriorityOnly
	
		FETCH NEXT FROM JobsToSchedule INTO @wono,@endDate ;
	END --WHILE @@FETCH_STATUS = 0
	CLOSE JobsToSchedule;
	DEALLOCATE JobsToSchedule;

	 

END