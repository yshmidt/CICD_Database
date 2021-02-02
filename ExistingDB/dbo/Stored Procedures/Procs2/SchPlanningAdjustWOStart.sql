-- =============================================
-- Author:		Yelena
-- Create date: 03/12/2013
-- Description:	Adjust production schedule according to given start/end date
-- 04/02/13 YS more fixes see comments below
-- 07/23/13 YS added new parameter (@lAutoSchd) to indicate that the procedure called from the WO module when a work order was first created.
-- 08/01/13 YS calculate priority only, when shop floor is moving do not re-calculate due-out for each wc
-- added another parameter
-- 08/02/13 YS when @lCalculatePriorityOnly=1 do not change start and complete dates in the prod_dts table
-- 02/10/14 YS @nslack has to be same as @nHrsProcessTime define as (7,3) 
-- 05/28/16 Anuj Added IsNull check for nSlackPriority
--05/30/16 Anuj Changed @nslack numeric(7,3) to @nslack numeric(9,3) as it is causing error numeric to numeric data type casting
--05/30/16 Anuj Changed @nHrsProcessTime numeric(7,3) to @nHrsProcessTime numeric(9,3) as it is causing error numeric to numeric data type casting
--05/30/16 Anuj Changed @nRemainingTime data type to int as it will always be int instead of numeric(7,3)
--10/08/18 Sachin B Changed @nslack numeric(7,3) to @nslack numeric(20,3) while creating the work order if the Due Date is far away from Start Date then the error message gets displayed
--10/08/18 Sachin B Changed @nHrsProcessTime numeric(7,3) to @nHrsProcessTime numeric(20,3) while creating the work order if the Due Date is far away from Start Date then the error message gets displayed
-- =============================================
CREATE PROCEDURE [dbo].[SchPlanningAdjustWOStart] 
	-- Add the parameters for the stored procedure here
	@wono char(10) =' ', 
	@startDate smalldatetime = null,
	@endDate smalldatetime = null,
	@userID uniqueidentifier = null,
	-- 07/23/13 YS added new parameter to indicate that the procedure called from the WO module when a work order was first created.
	@lAutoSchd bit = null,
	@lCalculatePriorityOnly bit = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @liDateFirst int,@SumCurrqty numeric(7),@nJobWcCount int,@wrkDayCount int
    -- Insert statements for procedure here
	SET @liDateFirst = @@DATEFIRST;
	-- set first date of the week to Monday
	SET DATEFIRST 1;
	-- 07/23/13 YS added new parameter to indicate that the procedure called from the WO module when a work order was first created.
	SET @lAutoSchd =ISNULL(@lAutoSchd,0)
	--declare @calendar Table (dDate smalldatetime,WorkingDay bit default 0,WorkDayCount int)
	DECLARE @calendar as dbo.tCalendar
	INSERT INTO @calendar (ddate, WorkingDay,WorkDayCount) SELECT ddate,WorkingDay,WorkDayCount from dbo.fn_GetCalendar(@startDate,@endDate) order by ddate
	-- make sure start and end date are working dates
    SELECT @startDate=MIN(cal.dDate) from @calendar cal where dDate>=@startDate and WorkingDay=1
		 
	SELECT @endDate=MIN(cend.dDate) from @calendar cend where dDate>=@endDate and WorkingDay=1
 -- 08/01/13 YS move this coe right before the re-calculating due out for the wc
 -- will not clear if only priority is calculated
 --   -- first thing to do is re-set shop floor
	--BEGIN TRANSACTION
	--	-- 04/02/13 YS clear due out for all WC
	--	update DEPT_QTY set DEPT_PRI=0.00,
	--					DUEOUTDT = null
	--				 where WONO=@wono
	--COMMIT
	DECLARE @CurrShopFlView table (dept_name char(25),Dueoutdt smalldatetime, Setuptimem numeric(11,3), Runtimem numeric(11,3),Dept_pri numeric(7,3),Curr_qty numeric(7,0),
		Wono char(10), Dept_id char(4),Xfer_qty numeric (7,0), Number numeric(4),UNIQUEREC char(10) ,
		Capctyneed numeric(12,0),Wo_wc_note text, Deptkey char(10), Serialstrt bit, Wcnote text,Process_time_h numeric(11,3),Wc_Avg_CapacityH numeric(11,3),uniq_key char(10))
	
	INSERT INTO @CurrShopFlView EXEC currshopflview @wono		
	SELECT @SumCurrqty =SUM(Curr_qty) from @CurrShopFlView
	
	-- calculate shop capacity
	--select * from ACTCAP 
	--declare @resourcemonth table(cMonth char(10),nMonth int,nSeqNum int)
	--declare @startMonth as int,@nStartMonth numeric(2),@nEndMonth numeric(2)
	--SELECT @startMonth = a.StartMonth  FROM (select Top 1 StartMonth from ACTCAP order by uniq_cap) a
	
	--;WITH monthlist 
	--as (
	--SELECT @startMonth as [nMonth],CAST(1 as int) as nSeqNumber
	--UNION ALL
	--SELECT CASE WHEN [nMonth]+1>12 THEN [nMonth]+1-12 ELSE [nMonth]+1 END,nSeqNumber+1 
	--FROM monthlist		
	--WHERE monthlist.nSeqNumber+1<=12)

	--INSERT INTO @resourcemonth 
	--select DATENAME(MM,dbo.padl(cast(Monthlist.nMonth as CHAR(2)),2,'0')+'/01/'+CAST(DATEPART(yy,getdate()) as CHAR(4))),
	--MonthList.nMonth,MonthList.nSeqNumber
	--from monthlist


 
	--SELECT @nStartMonth=R.nSeqNum FROM @resourcemonth R where DATENAME(mm,@startDate)=R.cMonth
	--SELECT @nEndMonth=R.nSeqNum FROM @resourcemonth R where DATENAME(mm,@EndDate)=R.cMonth

	--DECLARE @cWorkCenterDOWCapacity TABLE (Dept_id char(4),Activ_id char(4),Number numeric(4),nDow Integer,AvgCapacityMin numeric(12,2),StartMonth Numeric(2),
	--	M1_TotWork_min Numeric(12,2),M1_TotWork_hrs Numeric(11,2),
	--	M2_TotWork_min Numeric(12,2),M2_TotWork_hrs Numeric(11,2),
	--	M3_TotWork_min Numeric(12,2),M3_TotWork_hrs Numeric(11,2),
	--	M4_TotWork_min Numeric(12,2),M4_TotWork_hrs Numeric(11,2),
	--	M5_TotWork_min Numeric(12,2),M5_TotWork_hrs Numeric(11,2),
	--	M6_TotWork_min Numeric(12,2),M6_TotWork_hrs Numeric(11,2),
	--	M7_TotWork_min Numeric(12,2),M7_TotWork_hrs Numeric(11,2),
	--	M8_TotWork_min Numeric(12,2),M8_TotWork_hrs Numeric(11,2),
	--	M9_TotWork_min Numeric(12,2),M9_TotWork_hrs Numeric(11,2),
	--	M10_TotWork_min Numeric(12,2),M10_TotWork_hrs Numeric(11,2),
	--	M11_TotWork_min Numeric(12,2),M11_TotWork_hrs Numeric(11,2),
	--	M12_TotWork_min Numeric(12,2),M12_TotWork_hrs Numeric(11,2))

	--declare @strDays TABLE (cDayName char(10),nSeqNum integer)
	--INSERT INTO @strDays (cDayName,nSeqNum) VALUES 
	--		('Monday',1),
	--		('Tuesday',2),
	--		('Wednesday',3),
	--		('Thursday',4),
	--		('Friday',5),
	--		('Saturday',6),
	--		('Sunday',7) 
			

	--;WITH WcCapacity
	--AS(
	--select ActCap.DEPT_ID,ActCap.ACTIV_ID,ActCap.SHIFT_NO ,Depts.Number,
	--	WRKSHIFT.DHR_STRT,WrkShift.DMIN_STRT ,WrkShift.DHR_END,WrkShift.DMIN_END,
	--	WRKSHIFT.Tot_min,WrkShift.Break_min,WrkShift.Lunch_min,
	--	WRKSHIFT.NO_OF_DAYS,WrkShift.DAY_START, 
	--	ActCap.STARTMONTH  ,ActCap.RESMONTH1,
	--	ActCap.RESMONTH2,ActCap.RESMONTH3,ActCap.RESMONTH4,ActCap.RESMONTH5,ActCap.RESMONTH6,
	--	ActCap.RESMONTH7,ActCap.RESMONTH8,ActCap.RESMONTH9,ActCap.RESMONTH10,ActCap.RESMONTH11,ActCap.RESMONTH12 
	--	FROM ActCap INNER JOIN WRKSHIFT ON ActCap.SHIFT_NO =WrkShift.SHIFT_NO 
	--INNER JOIN DEPTS on ActCap.DEPT_ID =Depts.DEPT_ID 
	--),
	--WcCapDays
	--AS(	
	--	SELECT WC.DEPT_ID,WC.ACTIV_ID,WC.SHIFT_NO ,WC.Number,
	--		WC.DHR_STRT,WC.DMIN_STRT ,WC.DHR_END,WC.DMIN_END,
	--		WC.Tot_min,WC.Break_min,Wc.Lunch_min,
	--		WC.NO_OF_DAYS,WC.DAY_START, 
	--		WC.STARTMONTH,WC.RESMONTH1,
	--		WC.RESMONTH2,WC.RESMONTH3,WC.RESMONTH4,WC.RESMONTH5,WC.RESMONTH6,
	--		WC.RESMONTH7,WC.RESMONTH8,WC.RESMONTH9,WC.RESMONTH10,WC.RESMONTH11,WC.RESMONTH12  ,
	--		SD.nSeqNum,CAST(1 as int) as nDayNumber from WcCapacity WC INNER JOIN @strDays SD ON WC.DAY_START=SD.cDayName
	--	UNION ALL
	--		SELECT WCD.DEPT_ID,WCD.ACTIV_ID,WCD.SHIFT_NO ,WCD.Number,
	--		WCD.DHR_STRT,WCD.DMIN_STRT ,WCD.DHR_END,WCD.DMIN_END,
	--		WCD.Tot_min,WCD.Break_min,WcD.Lunch_min,
	--		WCD.NO_OF_DAYS,WCD.DAY_START, 
	--		WCD.STARTMONTH,WCD.RESMONTH1,
	--		WCD.RESMONTH2,WCD.RESMONTH3,WCD.RESMONTH4,WCD.RESMONTH5,WCD.RESMONTH6,
	--		WCD.RESMONTH7,WCD.RESMONTH8,WCD.RESMONTH9,WCD.RESMONTH10,WCD.RESMONTH11,WCD.RESMONTH12  ,
	--		WCD.nSeqNum+1 as nSeqNum,WCD.nDayNumber+1 as nDayNumber 
	--		FROM WcCapDays WCD WHERE WCD.nDayNumber+1<=WCD.NO_OF_DAYS ),
	--SumWcCapDays AS
	--(
	--	SELECT WC.DEPT_ID,WC.ACTIV_ID,WC.SHIFT_NO ,WC.Number,
	--		WC.DHR_STRT,WC.DMIN_STRT ,WC.DHR_END,WC.DMIN_END,
	--		WC.Tot_min,WC.Break_min,Wc.Lunch_min,
	--		WC.NO_OF_DAYS,WC.DAY_START, 
	--		WC.STARTMONTH,
	--		WC.RESMONTH1*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M1_TotWork_min,
	--		WC.RESMONTH2*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M2_TotWork_min,
	--		WC.RESMONTH3*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M3_TotWork_min,
	--		WC.RESMONTH4*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M4_TotWork_min,
	--		WC.RESMONTH5*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M5_TotWork_min,
	--		WC.RESMONTH6*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M6_TotWork_min,
	--		WC.RESMONTH7*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M7_TotWork_min,
	--		WC.RESMONTH8*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M8_TotWork_min,
	--		WC.RESMONTH9*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M9_TotWork_min,
	--		WC.RESMONTH10*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M10_TotWork_min,
	--		WC.RESMONTH11*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M11_TotWork_min,
	--		WC.RESMONTH12*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M12_TotWork_min ,
	--		WC.nSeqNum
	--	from WcCapDays WC 
	--)
	--INSERT @cWorkCenterDOWCapacity 
	--select WCD.DEPT_ID,WCD.ACTIV_ID,WCD.Number,nSeqNum as nDOW,CAST(0.00 as numeric(12,2)) as AvgCapacityMin,
	--	WCD.STARTMONTH, 
	--	SUM(M1_TotWork_min) as M1_totwork_min,
	--	SUM(M1_TotWork_min)/60 as M1_totwork_hrs,    
	--	SUM(M2_TotWork_min) as M2_totwork_min,
	--	SUM(M2_TotWork_min)/60 as M2_totwork_hrs,    
	--	SUM(M3_TotWork_min) as M3_totwork_min,    
	--	SUM(M3_TotWork_min)/60 as M3_totwork_hrs,    
	--	SUM(M4_TotWork_min) as M4_totwork_min,
	--	SUM(M4_TotWork_min)/60 as M4_totwork_hrs,    
	--	SUM(M5_TotWork_min) as M5_totwork_min,    
	--	SUM(M5_TotWork_min)/60 as M5_totwork_hrs,    
	--	SUM(M6_TotWork_min) as M6_totwork_min,
	--	SUM(M6_TotWork_min)/60 as M6_totwork_hrs,    
	--	SUM(M7_TotWork_min) as M7_totwork_min,    
	--	SUM(M7_TotWork_min)/60 as M7_totwork_hrs,    
	--	SUM(M8_TotWork_min) as M8_totwork_min,
	--	SUM(M8_TotWork_min)/60 as M8_totwork_hrs,    
	--	SUM(M9_TotWork_min) as M9_totwork_min,    
	--	SUM(M9_TotWork_min)/60 as M9_totwork_hrs,    
	--	SUM(M10_TotWork_min) as M10_totwork_min,
	--	SUM(M10_TotWork_min)/60 as M10_totwork_hrs,    
	--	SUM(M11_TotWork_min) as M11_totwork_min,
	--	SUM(M11_TotWork_min)/60 as M11_totwork_hrs,    
	--	SUM(M12_TotWork_min) as M12_totwork_min,
	--	SUM(M12_TotWork_min)/60 as M12_totwork_hrs
	--	from SumWcCapDays WCD 
	--GROUP BY WCD.DEPT_ID,WCD.ACTIV_ID,WCD.Number,
	--	WCD.STARTMONTH,nSeqNum
	
	---- trying un-pivot
	---- crate dynamic column names based on start/end date
	--DECLARE @clmnResource varchar(max),@lnCount int,@SQL as nvarchar(max)
	--set @lnCount=@nStartMonth+1 
	--SET @clmnResource='M'+RTRIM(CAST(@nStartMonth as CHAR(2)))+'_TotWork_min'
	--WHILE @lnCount <= @nEndMonth 
	--BEGIN
	--	SET @clmnResource=@clmnResource+',M'+RTRIM(CAST(@lnCount as CHAR(2)))+'_TotWork_min'
	--	SET @lnCount = @lnCount + 1
	--END
	
	--;with unpvtResources
	--AS(
	--select dept_id,Activ_id,Number,nDow,cResource,nResource
	--	FROM
	--	(
	--	SELECT dept_id,Activ_id,Number,nDow,M1_totwork_min,M2_totwork_min,M3_totwork_min,M4_totwork_min,
	--			M5_totwork_min,M6_totwork_min,M7_totwork_min,M8_totwork_min,
	--			M9_totwork_min,M10_totwork_min,M11_totwork_min,M12_totwork_min
	--			FROM @cWorkCenterDOWCapacity
				
	--	) t
	--	UNPIVOT
	--	(nResource
		
	--	FOR cResource IN (M1_totwork_min,M2_totwork_min,M3_totwork_min,M4_totwork_min,
	--			M5_totwork_min,M6_totwork_min,M7_totwork_min,M8_totwork_min,
	--			M9_totwork_min,M10_totwork_min,M11_totwork_min,M12_totwork_min ) )  unpvt
	--	),
	--	-- get number of days for a work center/activity
	--	wcActDays AS
	--	(
	--	select DEPT_id,activ_id,COUNT(*) as nDays  
	--		FROM @cWorkCenterDOWCapacity
	--		GROUP BY dept_id,activ_id
	--	),
	--	AvgResource as
	--	(
	--	SELECT UR.*,wcActDays.nDays,
	--		ROW_NUMBER () OVER(PARTITION BY ur.number,ur.activ_id,nDow ORDER BY cast(substring(cResource,2,CHARINDEX('_',cResource)-2) as int)) as nRec 
	--		from unpvtResources UR INNER JOIN wcActDays on UR.Dept_id=wcActDays.Dept_id and UR.Activ_id=wcActDays.Activ_id ),
	--	--select * from AvgResource	
	--	--select * from unpvtResources
	--	CalcAvg as(	
	--	SELECT A.Dept_id,A.Activ_id,SUM(A.nResource)/((@nEndMonth-@nStartMonth+1)*nDays) as  AvgCapacityMin
	--		FROM AvgResource A where A.nRec BETWEEN @nStartMonth and @nEndMonth
	--		GROUP BY A.Dept_id ,A.Activ_id ,A.nDays   )
	--	UPDATE @cWorkCenterDOWCapacity SET 	AvgCapacityMin=CalcAvg.AvgCapacityMin FROM CalcAvg INNER JOIN @cWorkCenterDOWCapacity W ON CalcAvg.Dept_id =W.Dept_id and CalcAvg.Activ_id =W.Activ_id   
	--	--SELECT * from @cWorkCenterDOWCapacity
	--08/01/13 ys use [spCalculateAvgDailyWcCap] instead of the code above, to be able to re-use the code when needed
		DECLARE @DeptsAvgTime TABLE (Dept_id char(4),Avg_Time_min numeric(11,3))
		INSERT INTO @DeptsAvgTime EXEC spCalculateAvgDailyWcCap @startDate,@endDate
		--INSERT INTO @DeptsAvgTime
		--		SELECT Dept_id,AVG(avgcapacitymin) as Avg_Time_min FROM 
		--			(SELECT DISTINCT Dept_id,Activ_id,avgcapacitymin FROM @cWorkCenterDOWCapacity) A 
		--				GROUP BY A.Dept_id 
		
		
		
		--SELECT * from @DeptsAvgTime		
		-- capactyneed saved in seconds
		--calculate process time based on the processtime (H) * 24/(Avg_Time_min/60)
		-- all calculations so far in the ZWcLoad1 were done in seconds
		-- Capctyneed = Capctyneed * (24*3600)/(Avg_Time_min*60)
		-- prorated process for each WC. E.g. if the process time calculated for a work center based on qty run and setup time is 20 hours
		--   and  average WC day is 17 hours and the process requred 20 hours, we will update process time to be 20*24/17=28.235 h
		-- capctyneed (process time) calculated and saved in seconds, For the hours use Process_time_h in the CurrShopFlView
--03/25/13 YS mistake in calculation of Process_time_h need 24/(Avg_Time_min/60) (was Avg_Time_min/60/24)
		UPDATE @CurrShopFlView SET Capctyneed =(60.00*(CASE WHEN C.Dept_id IN ('FGI','SCRP') THEN 0.00 
													ELSE R.RunningTotal*C.Runtimem+CASE WHEN R.RunningTotal<>0.00 THEN C.Setuptimem ELSE 0.00 END 
													END))*
				(1440.0/CASE WHEN NOT Avg_Time_min IS NULL AND Avg_Time_min<>0.00 THEN Avg_Time_min ELSE 1440 END),
				Wc_Avg_CapacityH = ISNULL(Avg_Time_min/60.00,0.00),
				Process_time_h = ((CASE WHEN C.Dept_id IN ('FGI','SCRP') THEN 0.00 
													ELSE R.RunningTotal*C.Runtimem+CASE WHEN R.RunningTotal<>0.00 THEN C.Setuptimem ELSE 0.00 END 
													END)/60.00)*
									((CASE WHEN NOT Avg_Time_min IS NULL AND Avg_Time_min<>0.00 THEN 24/(Avg_Time_min/60.00) ELSE 1.00 END))
				
		FROM
		(SELECT SF1.Dept_id,Sf1.Curr_qty,Sf1.Number, 
			Sf1.curr_qty+  COALESCE((SELECT SUM(Sf2.curr_qty) as RunningQty
                      FROM @CurrShopFlView SF2 
                      WHERE Sf2.Number < Sf1.Number),0)
                       AS RunningTotal
			FROM @CurrShopFlView SF1 
		GROUP BY SF1.Dept_id ,SF1.Curr_qty,SF1.Number ) R INNER JOIN @CurrShopFlView C ON R.Number =C.Number
		LEFT OUTER JOIN @DeptsAvgTime D ON C.Dept_id =D.Dept_id
		
		
		-- now we calculate priority
		--02/10/14 YS @nslack has to be same as @nHrsProcessTime define as (7,3) 
		--05/30/16 Anuj Changed @nslack numeric(7,3) to @nslack numeric(9,3) as it is causing error numeric to numeric data type casting
		--05/30/16 Anuj Changed @nHrsProcessTime numeric(7,3) to @nHrsProcessTime numeric(9,3) as it is causing error numeric to numeric data type casting
		--05/30/16 Anuj Changed @nRemainingTime data type to int as it will always be int instead of numeric(7,3)
		--10/08/18 Sachin B Changed @nslack numeric(7,3) to @nslack numeric(20,3) while creating the work order if the Due Date is far away from Start Date then the error message gets displayed
		--10/08/18 Sachin B Changed @nHrsProcessTime numeric(7,3) to @nHrsProcessTime numeric(20,3) while creating the work order if the Due Date is far away from Start Date then the error message gets displayed

		declare @nHrsProcessTime numeric(20,3),@nNotWorking int,@nRemainingTime int,@nslack numeric(20,3),@modifypri int=1,@nslackpri int
		SELECT @nHrsProcessTime=SUM(Capctyneed/3600.00) FROM @CurrShopFlView
		Select @nHrsProcessTime 
		SELECT @nNotWorking=COUNT(*) FROM @calendar C WHERE c.dDate BETWEEN @startDate and @endDate AND c.WorkingDay=0 
		Select @nNotWorking 
		SET @nRemainingTime=DATEDIFF(HH,@startDate,@endDate)-(24*@nNotWorking) 
		Select @nRemainingTime 
		SET @nslack =@nRemainingTime-@nHrsProcessTime
		--SET @nSlackPri=CASE WHEN @nHrsProcessTime=0.00 THEN @nSlack*@modifypri*100 ELSE ((@nSlack/@nHrsProcessTime)*@modifypri)*100 END
		SET @nSlackPri=CASE WHEN @nHrsProcessTime=0.00 THEN @nSlack*@modifypri*100 ELSE ((@nSlack/@nHrsProcessTime)*@modifypri)*100 END 
		-- 05/28/16 Anuj Added IsNull check for nSlackPriority
		SET @nSlackPri=CASE WHEN COALESCE(NULLIF(@nSlackPri,0), 0)<1 THEN 1 
						WHEN @nSlackPri>900 THEN 900 ELSE @nSlackPri END
						
		--SELECT 		@nHrsProcessTime [process time hours]	,@nNotWorking*24 [not working hours],DATEDIFF(HH,@startDate,@endDate) [date between start and end],
		--	@nRemainingTime [time remaining],@nslack slack,@nslackpri slackpri
		
		BEGIN TRANSACTION
		--	update prodsch table
		--07/23/13 YS added new parameter to indicate if auto schedule
		-- also when first time scheduled will need to insert the record
			IF EXISTS(SELECT 1 FROM PROD_DTS where WONO=@wono) 
				--08/02/13 YS update dates only if re-schedule or schedule for the first time,
				-- if called from shop floor just change the priority
				update PROD_DTS SET 
					COMPL_DTS = CASE WHEN @lCalculatePriorityOnly = 0 THEN @endDate ELSE COMPL_DTS END,
					START_DTS =CASE WHEN @lCalculatePriorityOnly = 0 THEN @startDate ELSE START_DTS END  ,
					SLACKPRI = @nSlackPri,
					Processtm = @nHrsProcessTime,
					QTY= @SumCurrqty,
					AutoScheduled = @lAutoSchd,
					fk_aspnetUsers = @userID  
				WHERE WONO=@wono
			ELSE -- EXISTS(SELECT 1 FROM PROD_DTS where WONO=@wono) 
				INSERT INTO [PROD_DTS]
						([WONO]
						,[COMPL_DTS]
						,[QTY]
						,[START_DTS]
						,[SLACKPRI]
						,[PROCESSTM]
						,[PRODSCHUNQ]
						,[AutoScheduled]
						,[fk_aspnetUsers])
				VALUES
					(@WONO
					,@endDate
					,@SumCurrqty
           			,@startDate
					,@nSlackPri
					,@nHrsProcessTime
					,dbo.fn_GenerateUniqueNumber()
					,@lAutoSchd
					,@userID )
		COMMIT
		--08/01/13 YS if calculate priority only exit here
		if (@lCalculatePriorityOnly =1)
		RETURN
		--- if not continue with calculating due out 
		
		BEGIN TRANSACTION
		-- 04/02/13 YS clear due out for all WC
		update DEPT_QTY set DEPT_PRI=0.00,
			DUEOUTDT = null
			where WONO=@wono
		COMMIT
		-- update due out time for each WC		
		SELECT @nJobWcCount =COUNT(*) from @CurrShopFlView where Capctyneed <>0.00
		--select @nJobWcCount
		---- create LOG table
		-- 03/26/13 YS mistake in calculating slck time for a WC. Need to claculate total sum, not running sum
		--DECLARE @log TABLE (nSeq int,nLog numeric(9,7),nrunningSum numeric(9,7),wcSlack numeric(13,7))
		DECLARE @log TABLE (nSeq int,nLog numeric(9,7),wcSlack numeric(13,7))
		--;WITH aLog
		--as
		--(
		--SELECT 1 as nSeq,LOG(2) as nLog,LOG(2) as nrunningSum,cast(@nslack as numeric(13,7)) as wcSlack
		--UNION ALL
		--SELECT a.nSeq+1,LOG(a.nSeq+2),a.nrunningSum+LOG(a.nSeq+2) ,CAST((LOG(a.nSeq+2)/a.nrunningSum+LOG(a.nSeq+2))*@nslack as numeric(13,7))
		--FROM aLOg a
		--WHERE a.nSeq<=@nJobWcCount-1)
		
		;WITH aLog
		as
		(
		SELECT 1 as nSeq,LOG(2) as nLog,cast(0.00 as numeric(13,7)) as wcSlack
		UNION ALL
		SELECT a.nSeq+1,LOG(a.nSeq+2),CAST(0.00 as numeric(13,7))
		FROM aLOg a
		WHERE a.nSeq<=@nJobWcCount-1)
		--select * from aLog 
		-- calculate slack for each WC as (nLog/SUm all nLogs)*@nslack (slack for the job)
		INSERT INTO @Log SELECT nSeq,nLog,(nLog/SUM(nLog) OVER())*@nslack from aLog 
		
		--SELECT 2,LOG(3),LOG(2)+LOG(3) ,cast((LOG(3)/LOG(2)+LOG(3))*@nslack as numeric(13,7))
		
		--INSERT INTO @Log SELECT * from aLog 
		--SELECT * from @log
		
		
		-- now calculate due out
		BEGIN TRANSACTION
		;WITH SFProcess
		as
		(
		select O.*,ISNULL(I.nProcess,0) as nProcess 
			from @CurrShopFlView O LEFT OUTER JOIN
			(SELECT Dept_id,Number,ROW_NUMBER() OVER(ORDER BY Number) as nProcess from @CurrShopFlView  where Capctyneed <>0.00 ) I
		ON O.Number=I.Number),
		SFProcessWithSlack
		as(
		-- 03/26/13 YS when calculating Ostatok check CAST(CASE WHEN Process_time_h +ISNULL(l.wcSlack,0) >0.00 not >24. Otherwsie if less than 24 hours missing time
		-- 04/02/13 YS needed ()/24 otherwise the number of days (DatePlus) was calculated bigger than it should be  
		SELECT SF.*,Process_time_h +ISNULL(l.wcSlack,0) as NewProcessHrs,  
			CASE WHEN Process_time_h +ISNULL(l.wcSlack,0) >24 THEN
				CEILING((Process_time_h +ISNULL(l.wcSlack,0))/24) ELSE 0 END as DatePlus,
				CAST(CASE WHEN Process_time_h +ISNULL(l.wcSlack,0) >0.00 THEN
				(Process_time_h +ISNULL(l.wcSlack,0))%24 ELSE 0.00 END as numeric(6,2)) as OstatokHrs
			from SFProcess SF LEFT OUTER JOIN @log L ON SF.nProcess = l.nSeq)
			--SELECT * from SFProcessWithSlack
			-- 03/26/13 YS change calculation of the due out. Make sure that none working day is selected event when process time for a work center require advance by hours only (not days).
			-- some times the calculation can extend to the next day and the day has to be picked from the working day pool 
			,
			SFDueOut
			as
			(
			SELECT cout.WorkDayCount,
				CASE WHEN CAST(DATEADD(MINUTE,sf.OstatokHrs*60+DATEPART(HOUR,@startDate)*60 +DATEPART(MINUTE,@startDate),cOut.dDate) AS Date)  =cOut.dDate THEN
				DATEADD(MINUTE,sf.OstatokHrs*60+DATEPART(HOUR,@startDate)*60 +DATEPART(MINUTE,@startDate),cOut.dDate) 
				ELSE
					(SELECT DATEADD(MINUTE,
					DATEPART(HOUR ,DATEADD(MINUTE,sf.OstatokHrs*60+DATEPART(HOUR,@startDate)*60 +DATEPART(MINUTE,@startDate),cOut.dDate))*60+
					DATEPART(MINUTE ,DATEADD(MINUTE,sf.OstatokHrs*60+DATEPART(HOUR,@startDate)*60 +DATEPART(MINUTE,@startDate),cOut.dDate)),dDate)
							FROM @calendar where WorkDayCount =cout.WorkDayCount+1)   
					 
				END
				as DueOutDt ,
				process_time_h,wc_avg_capacityH, sf.DatePlus,sf.NewProcessHrs,sf.OstatokHrs,sf.nProcess, 
				SF.dept_name,Setuptimem,Runtimem ,Dept_pri,Curr_qty,Wono,Dept_id,Number,sf.Capctyneed
				FROM SFProcessWithSlack SF INNER JOIN @calendar C1 on CAST(c1.dDate as DATE) =cast(@startDate as DATE)
					CROSS APPLY (SELECT dDate,WorkDayCount  from @calendar c2 where c2.WorkDayCount =c1.WorkDayCount +sf.DatePlus -CASE WHEN sf.DatePlus>0 then 1 else 0 end ) cOut
				WHERE SF.Number=1
				
				--select * from SFDueOut 
				
				UNION ALL
				SELECT 	cout.WorkDayCount,	
					CASE WHEN CAST(DATEADD(MINUTE,sf2.OstatokHrs*60+DATEPART(HOUR,SFDueOut.DueOutDt)*60 +DATEPART(MINUTE,SFDueOut.DueoutDt),cOut.dDate) as Date) = cOut.dDate THEN
							DATEADD(MINUTE,sf2.OstatokHrs*60+DATEPART(HOUR,SFDueOut.DueOutDt)*60 +DATEPART(MINUTE,SFDueOut.DueoutDt),cOut.dDate) 
							ELSE
							(SELECT DATEADD(MINUTE,
							DATEPART(HOUR ,DATEADD(MINUTE,sf2.OstatokHrs*60+DATEPART(HOUR,SFDueOut.DueOutDt)*60 +DATEPART(MINUTE,SFDueOut.DueoutDt),cOut.dDate))*60+
							DATEPART(MINUTE,DATEADD(MINUTE,sf2.OstatokHrs*60+DATEPART(HOUR,SFDueOut.DueOutDt)*60 +DATEPART(MINUTE,SFDueOut.DueoutDt),cOut.dDate)),dDate)
							--sf2.OstatokHrs*60+DATEPART(HOUR,SFDueOut.DueOutDt)*60 +DATEPART(MINUTE,SFDueOut.DueoutDt),dDate) 
							FROM @calendar where WorkDayCount =cout.WorkDayCount+1)   
							END
							as DueOut ,
				SF2.process_time_h,SF2.wc_avg_capacityH, SF2.DatePlus,SF2.NewProcessHrs,
				SF2.OstatokHrs,Sf2.nProcess, Sf2.dept_name,SF2.Setuptimem,Sf2.Runtimem ,
				Sf2.Dept_pri,sf2.Curr_qty,sf2.Wono,sf2.Dept_id,sf2.Number,sf2.Capctyneed
			FROM SFDueOut INNER JOIN SFProcessWithSlack SF2 on SFDueOut.Number+1=SF2.Number	
			INNER JOIN @calendar C1 on CAST(c1.dDate as DATE) =cast(SFDueOut.DueOutDt as date) 
			CROSS APPLY (SELECT dDate,WorkDayCount  from @calendar c2 where c2.WorkDayCount =c1.WorkDayCount +sf2.DatePlus -CASE WHEN sf2.DatePlus>0 then 1 else 0 end ) cOut
			)
			update DEPT_QTY SET DUEOUTDT =SFDueOut.DueOutDt,
						CAPCTYNEED = SFDueOut.Capctyneed FROM SFDueOut WHERE SFDueOut.Wono=DEPT_QTY.WONO and SFDueOut.Number=Dept_qty.NUMBER  
			--select * from SfDueout order by number
			
			COMMIT			
			--select * from SFDueOut order by number
			-- re-set to default
			SET @liDateFirst = @liDateFirst 
		
END