-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 04/10/13
-- Description:	calculate avg work center capacity between start and end date
-- 07/30/13 YS change the output for this procedure to return result
-- =============================================
CREATE PROCEDURE [dbo].[spCalculateAvgDailyWcCap] 
	-- Add the parameters for the stored procedure here
	@startDate smalldatetime = 0, 
	@endDate smalldatetime = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @resourcemonth table(cMonth char(10),nMonth int,nSeqNum int)
	declare @startMonth as int,@nStartMonth numeric(2),@nEndMonth numeric(2)
	SELECT @startMonth = a.StartMonth  FROM (select Top 1 StartMonth from ACTCAP order by uniq_cap) a
	
	;WITH monthlist 
	as (
	SELECT @startMonth as [nMonth],CAST(1 as int) as nSeqNumber
	UNION ALL
	SELECT CASE WHEN [nMonth]+1>12 THEN [nMonth]+1-12 ELSE [nMonth]+1 END,nSeqNumber+1 
	FROM monthlist		
	WHERE monthlist.nSeqNumber+1<=12)

	INSERT INTO @resourcemonth 
	select DATENAME(MM,dbo.padl(cast(Monthlist.nMonth as CHAR(2)),2,'0')+'/01/'+CAST(DATEPART(yy,getdate()) as CHAR(4))),
	MonthList.nMonth,MonthList.nSeqNumber
	from monthlist


 
	SELECT @nStartMonth=R.nSeqNum FROM @resourcemonth R where DATENAME(mm,@startDate)=R.cMonth
	SELECT @nEndMonth=R.nSeqNum FROM @resourcemonth R where DATENAME(mm,@EndDate)=R.cMonth

	DECLARE @cWorkCenterDOWCapacity TABLE (Dept_id char(4),Activ_id char(4),Number numeric(4),nDow Integer,AvgCapacityMin numeric(12,2),StartMonth Numeric(2),
		M1_TotWork_min Numeric(12,2),M1_TotWork_hrs Numeric(11,2),
		M2_TotWork_min Numeric(12,2),M2_TotWork_hrs Numeric(11,2),
		M3_TotWork_min Numeric(12,2),M3_TotWork_hrs Numeric(11,2),
		M4_TotWork_min Numeric(12,2),M4_TotWork_hrs Numeric(11,2),
		M5_TotWork_min Numeric(12,2),M5_TotWork_hrs Numeric(11,2),
		M6_TotWork_min Numeric(12,2),M6_TotWork_hrs Numeric(11,2),
		M7_TotWork_min Numeric(12,2),M7_TotWork_hrs Numeric(11,2),
		M8_TotWork_min Numeric(12,2),M8_TotWork_hrs Numeric(11,2),
		M9_TotWork_min Numeric(12,2),M9_TotWork_hrs Numeric(11,2),
		M10_TotWork_min Numeric(12,2),M10_TotWork_hrs Numeric(11,2),
		M11_TotWork_min Numeric(12,2),M11_TotWork_hrs Numeric(11,2),
		M12_TotWork_min Numeric(12,2),M12_TotWork_hrs Numeric(11,2))

	declare @strDays TABLE (cDayName char(10),nSeqNum integer)
	INSERT INTO @strDays (cDayName,nSeqNum) VALUES 
			('Monday',1),
			('Tuesday',2),
			('Wednesday',3),
			('Thursday',4),
			('Friday',5),
			('Saturday',6),
			('Sunday',7) 
			

	;WITH WcCapacity
	AS(
	select ActCap.DEPT_ID,ActCap.ACTIV_ID,ActCap.SHIFT_NO ,Depts.Number,
		WRKSHIFT.DHR_STRT,WrkShift.DMIN_STRT ,WrkShift.DHR_END,WrkShift.DMIN_END,
		WRKSHIFT.Tot_min,WrkShift.Break_min,WrkShift.Lunch_min,
		WRKSHIFT.NO_OF_DAYS,WrkShift.DAY_START, 
		ActCap.STARTMONTH  ,ActCap.RESMONTH1,
		ActCap.RESMONTH2,ActCap.RESMONTH3,ActCap.RESMONTH4,ActCap.RESMONTH5,ActCap.RESMONTH6,
		ActCap.RESMONTH7,ActCap.RESMONTH8,ActCap.RESMONTH9,ActCap.RESMONTH10,ActCap.RESMONTH11,ActCap.RESMONTH12 
		FROM ActCap INNER JOIN WRKSHIFT ON ActCap.SHIFT_NO =WrkShift.SHIFT_NO 
	INNER JOIN DEPTS on ActCap.DEPT_ID =Depts.DEPT_ID 
	),
	WcCapDays
	AS(	
		SELECT WC.DEPT_ID,WC.ACTIV_ID,WC.SHIFT_NO ,WC.Number,
			WC.DHR_STRT,WC.DMIN_STRT ,WC.DHR_END,WC.DMIN_END,
			WC.Tot_min,WC.Break_min,Wc.Lunch_min,
			WC.NO_OF_DAYS,WC.DAY_START, 
			WC.STARTMONTH,WC.RESMONTH1,
			WC.RESMONTH2,WC.RESMONTH3,WC.RESMONTH4,WC.RESMONTH5,WC.RESMONTH6,
			WC.RESMONTH7,WC.RESMONTH8,WC.RESMONTH9,WC.RESMONTH10,WC.RESMONTH11,WC.RESMONTH12  ,
			SD.nSeqNum,CAST(1 as int) as nDayNumber from WcCapacity WC INNER JOIN @strDays SD ON WC.DAY_START=SD.cDayName
		UNION ALL
			SELECT WCD.DEPT_ID,WCD.ACTIV_ID,WCD.SHIFT_NO ,WCD.Number,
			WCD.DHR_STRT,WCD.DMIN_STRT ,WCD.DHR_END,WCD.DMIN_END,
			WCD.Tot_min,WCD.Break_min,WcD.Lunch_min,
			WCD.NO_OF_DAYS,WCD.DAY_START, 
			WCD.STARTMONTH,WCD.RESMONTH1,
			WCD.RESMONTH2,WCD.RESMONTH3,WCD.RESMONTH4,WCD.RESMONTH5,WCD.RESMONTH6,
			WCD.RESMONTH7,WCD.RESMONTH8,WCD.RESMONTH9,WCD.RESMONTH10,WCD.RESMONTH11,WCD.RESMONTH12  ,
			WCD.nSeqNum+1 as nSeqNum,WCD.nDayNumber+1 as nDayNumber 
			FROM WcCapDays WCD WHERE WCD.nDayNumber+1<=WCD.NO_OF_DAYS ),
	SumWcCapDays AS
	(
		SELECT WC.DEPT_ID,WC.ACTIV_ID,WC.SHIFT_NO ,WC.Number,
			WC.DHR_STRT,WC.DMIN_STRT ,WC.DHR_END,WC.DMIN_END,
			WC.Tot_min,WC.Break_min,Wc.Lunch_min,
			WC.NO_OF_DAYS,WC.DAY_START, 
			WC.STARTMONTH,
			WC.RESMONTH1*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M1_TotWork_min,
			WC.RESMONTH2*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M2_TotWork_min,
			WC.RESMONTH3*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M3_TotWork_min,
			WC.RESMONTH4*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M4_TotWork_min,
			WC.RESMONTH5*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M5_TotWork_min,
			WC.RESMONTH6*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M6_TotWork_min,
			WC.RESMONTH7*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M7_TotWork_min,
			WC.RESMONTH8*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M8_TotWork_min,
			WC.RESMONTH9*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M9_TotWork_min,
			WC.RESMONTH10*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M10_TotWork_min,
			WC.RESMONTH11*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M11_TotWork_min,
			WC.RESMONTH12*(WC.TOT_MIN -WC.Break_min-Wc.Lunch_min) as M12_TotWork_min ,
			WC.nSeqNum
		from WcCapDays WC 
	)
	INSERT @cWorkCenterDOWCapacity 
	select WCD.DEPT_ID,WCD.ACTIV_ID,WCD.Number,nSeqNum as nDOW,CAST(0.00 as numeric(12,2)) as AvgCapacityMin,
		WCD.STARTMONTH, 
		SUM(M1_TotWork_min) as M1_totwork_min,
		SUM(M1_TotWork_min)/60 as M1_totwork_hrs,    
		SUM(M2_TotWork_min) as M2_totwork_min,
		SUM(M2_TotWork_min)/60 as M2_totwork_hrs,    
		SUM(M3_TotWork_min) as M3_totwork_min,    
		SUM(M3_TotWork_min)/60 as M3_totwork_hrs,    
		SUM(M4_TotWork_min) as M4_totwork_min,
		SUM(M4_TotWork_min)/60 as M4_totwork_hrs,    
		SUM(M5_TotWork_min) as M5_totwork_min,    
		SUM(M5_TotWork_min)/60 as M5_totwork_hrs,    
		SUM(M6_TotWork_min) as M6_totwork_min,
		SUM(M6_TotWork_min)/60 as M6_totwork_hrs,    
		SUM(M7_TotWork_min) as M7_totwork_min,    
		SUM(M7_TotWork_min)/60 as M7_totwork_hrs,    
		SUM(M8_TotWork_min) as M8_totwork_min,
		SUM(M8_TotWork_min)/60 as M8_totwork_hrs,    
		SUM(M9_TotWork_min) as M9_totwork_min,    
		SUM(M9_TotWork_min)/60 as M9_totwork_hrs,    
		SUM(M10_TotWork_min) as M10_totwork_min,
		SUM(M10_TotWork_min)/60 as M10_totwork_hrs,    
		SUM(M11_TotWork_min) as M11_totwork_min,
		SUM(M11_TotWork_min)/60 as M11_totwork_hrs,    
		SUM(M12_TotWork_min) as M12_totwork_min,
		SUM(M12_TotWork_min)/60 as M12_totwork_hrs
		from SumWcCapDays WCD 
	GROUP BY WCD.DEPT_ID,WCD.ACTIV_ID,WCD.Number,
		WCD.STARTMONTH,nSeqNum
	
	-- trying un-pivot
	-- crate dynamic column names based on start/end date
	DECLARE @clmnResource varchar(max),@lnCount int,@SQL as nvarchar(max)
	set @lnCount=@nStartMonth+1 
	SET @clmnResource='M'+RTRIM(CAST(@nStartMonth as CHAR(2)))+'_TotWork_min'
	WHILE @lnCount <= @nEndMonth 
	BEGIN
		SET @clmnResource=@clmnResource+',M'+RTRIM(CAST(@lnCount as CHAR(2)))+'_TotWork_min'
		SET @lnCount = @lnCount + 1
	END
	
	;with unpvtResources
	AS(
	select dept_id,Activ_id,Number,nDow,cResource,nResource
		FROM
		(
		SELECT dept_id,Activ_id,Number,nDow,M1_totwork_min,M2_totwork_min,M3_totwork_min,M4_totwork_min,
				M5_totwork_min,M6_totwork_min,M7_totwork_min,M8_totwork_min,
				M9_totwork_min,M10_totwork_min,M11_totwork_min,M12_totwork_min
				FROM @cWorkCenterDOWCapacity
				
		) t
		UNPIVOT
		(nResource
		
		FOR cResource IN (M1_totwork_min,M2_totwork_min,M3_totwork_min,M4_totwork_min,
				M5_totwork_min,M6_totwork_min,M7_totwork_min,M8_totwork_min,
				M9_totwork_min,M10_totwork_min,M11_totwork_min,M12_totwork_min ) )  unpvt
		),
		-- get number of days for a work center/activity
		wcActDays AS
		(
		select DEPT_id,activ_id,COUNT(*) as nDays  
			FROM @cWorkCenterDOWCapacity
			GROUP BY dept_id,activ_id
		),
		AvgResource as
		(
		SELECT UR.*,wcActDays.nDays,
			ROW_NUMBER () OVER(PARTITION BY ur.number,ur.activ_id,nDow ORDER BY cast(substring(cResource,2,CHARINDEX('_',cResource)-2) as int)) as nRec 
			from unpvtResources UR INNER JOIN wcActDays on UR.Dept_id=wcActDays.Dept_id and UR.Activ_id=wcActDays.Activ_id ),
		--select * from AvgResource	
		--select * from unpvtResources
		CalcAvg as(	
		SELECT A.Dept_id,A.Activ_id,SUM(A.nResource)/((@nEndMonth-@nStartMonth+1)*nDays) as  AvgCapacityMin
			FROM AvgResource A where A.nRec BETWEEN @nStartMonth and @nEndMonth
			GROUP BY A.Dept_id ,A.Activ_id ,A.nDays   )
		UPDATE @cWorkCenterDOWCapacity SET 	AvgCapacityMin=CalcAvg.AvgCapacityMin FROM CalcAvg INNER JOIN @cWorkCenterDOWCapacity W ON CalcAvg.Dept_id =W.Dept_id and CalcAvg.Activ_id =W.Activ_id   
		--SELECT * from @cWorkCenterDOWCapacity
		DECLARE @DeptsAvgTime TABLE (Dept_id char(4),Avg_Time_min numeric(11,3))
		INSERT INTO @DeptsAvgTime
				SELECT Dept_id,AVG(avgcapacitymin) as Avg_Time_min FROM 
					(SELECT DISTINCT Dept_id,Activ_id,avgcapacitymin FROM @cWorkCenterDOWCapacity) A 
						GROUP BY A.Dept_id 
		--- 07/30/13 YS change the output for this procedure to return result
		select * from @DeptsAvgTime				
END