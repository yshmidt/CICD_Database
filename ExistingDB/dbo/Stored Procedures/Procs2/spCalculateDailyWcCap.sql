-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/28/2013
-- Description:	Calculate capacity for work center/activities for a given month monday through friday
-- =============================================
CREATE PROCEDURE [dbo].[spCalculateDailyWcCap] 
	-- Add the parameters for the stored procedure here
	@nGivenMonth int = 0
	   
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- currently we have resources defined for each month. Will be changed later
	SELECT @nGivenMonth = CASE WHEN @nGivenMonth=0 THEN 
		-- current month
		DATEPART(month,GETDATE()) 
		ELSE @nGivenMonth END
		
	
	
	DECLARE @tCapacity Table (CapacityA numeric(12,2) default 0.00,Dept_id Char(4) default '',Activ_id char(4) default '',cDow char(10))
	
	Declare @tDOW TABLE (cDOW char(10),nrec int IDENTITY)
	INSERT INTO @tDOW (cDOW) VALUES 
				('Monday'),
				('Tuesday'),
				('Wednesday'),
				('Thursday'),
				('Friday'),
				('Saturday'),
				('Sunday')
	
	
	INSERT INTO @tCapacity (Dept_id,Activ_id,cDow) 
		SELECT  depts.dept_id,ISNULL(deptsdet.ACTIV_ID ,SPACE(4)),cDOW  
			from Depts LEFT OUTER JOIN DEPTSDET on Depts.DEPT_ID = deptsdet.DEPT_ID 
			CROSS JOIN @tDow D  
			ORDER BY Depts.NUMBER,Deptsdet.NUMBER
    
    
  ;WITH  CapacityInfo
	AS
	(
    select DEPTSHFT.DEPT_ID,WrkShift.Tot_min ,WrkShift.Break_min,WrkShift.Lunch_min ,
		WRKSHIFT.DAY_START,D.nrec as nDayStart,WRKSHIFT.NO_OF_DAYS,WrkShift.SHIFT_NO, ActCap.STARTMONTH,ActCap.ACTIV_ID,
		ActCap.RESMONTH1,ActCap.RESMONTH2,ActCap.RESMONTH3,ActCap.RESMONTH4,
		ActCap.RESMONTH5,ActCap.RESMONTH6,ActCap.RESMONTH7,ActCap.RESMONTH8,
		ActCap.RESMONTH9,ActCap.RESMONTH10,ActCap.RESMONTH11,ActCap.RESMONTH12
		from DEPTSHFT  INNER JOIN WRKSHIFT ON Deptshft.SHIFT_NO =WRKSHIFT.SHIFT_NO 
		INNER JOIN ACTCAP ON DeptShft.DEPT_ID = ActCap.DEPT_ID and DEPTSHFT.SHIFT_NO =ACTCAP.SHIFT_NO 
		INNER JOIN @tDOW D ON WRKSHIFT.DAY_START=D.cDOW
		 ),
	
	CalcCap 
	AS
	(
	SELECT distinct t.dept_id ,c.Activ_id,c.Shift_no,t.cDow, 
										  CASE WHEN @nGivenMonth-C.STARTMONTH+1=1 THEN C.RESMONTH1
										   WHEN @nGivenMonth-C.STARTMONTH+1=2 THEN C.RESMONTH2
										   WHEN @nGivenMonth-C.STARTMONTH+1=3 THEN C.RESMONTH3
										   WHEN @nGivenMonth-C.STARTMONTH+1=4 THEN C.RESMONTH4
										   WHEN @nGivenMonth-C.STARTMONTH+1=5 THEN C.RESMONTH5
										   WHEN @nGivenMonth-C.STARTMONTH+1=6 THEN C.RESMONTH6
										   WHEN @nGivenMonth-C.STARTMONTH+1=7 THEN C.RESMONTH7
										   WHEN @nGivenMonth-C.STARTMONTH+1=8 THEN C.RESMONTH8
										   WHEN @nGivenMonth-C.STARTMONTH+1=1 THEN C.RESMONTH9
										   WHEN @nGivenMonth-C.STARTMONTH+1=2 THEN C.RESMONTH10
										   WHEN @nGivenMonth-C.STARTMONTH+1=3 THEN C.RESMONTH11
										   WHEN @nGivenMonth-C.STARTMONTH+1=4 THEN C.RESMONTH12
										   ELSE 0 END * (C.TOT_MIN-C.BREAK_MIN-C.LUNCH_MIN ) as CapacityA
	FROM CapacityInfo C INNER JOIN @tCapacity t ON C.DEPT_ID=t.Dept_id 
	INNER JOIN @tDOW DOW on t.cDow =DOW.cDOW 
	WHERE Dow.nrec BETWEEN c.nDayStart and c.NO_OF_DAYS), 
	SumCap
	as
	(select dept_id,activ_id,cDow,SUM(capacityA) as CapacityA
		FROM CalcCap C 
		group by dept_id,activ_id,cDow)
		
	
	update @tCapacity  SET CapacityA= C.CapacityA from SumCap C inner join @tCapacity t on C.activ_id =t.Activ_id and c.dept_id =t.Dept_id and c.cDoW  =t.cDow  
	
	--04/01/13 YS added Std_rate from activity table
	SELECT Dept_id,activ_id,Std_rate,[Monday],[Tuesday],[Wednesday],[Thursday],[Friday],[Saturday],[Sunday]
	FROM
	(	
	SELECT dept_id,tc.activ_id, cDow, ISNULL(Activity.STD_RATE,cast(0.00 as numeric(8,2))) as Std_rate,  SUM(CapacityA) as Sum_CapacityA
	FROM @tCapacity tC LEFT OUTER JOIN ACTIVITY ON tC.Activ_id =Activity.ACTIV_ID
	GROUP BY dept_id,tc.activ_id ,cDow,ISNULL(Activity.STD_RATE,cast(0.00 as numeric(8,2)))
	) base
	PIVOT
    (
    	SUM(Sum_CapacityA)
    	FOR cDow IN ([Monday],[Tuesday],[Wednesday],[Thursday],[Friday],[Saturday],[Sunday])
    ) pvt
   order by Dept_id,activ_id
	
	
	
END