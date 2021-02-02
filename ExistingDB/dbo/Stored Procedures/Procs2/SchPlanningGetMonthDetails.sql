-- =============================================  
-- Author:  Yelena Shmidt  
-- Create date: 02/15/2013  
-- Description: This procedure will return all open order information for a given date range  
--- list of parameters   
--- 1. startDate  
-- 04/03/13 YS change cast the dates to avoid problem with time part of the datetime   
-- 04/05/13 YS link by Number not Dept_id, otherwise if the routing has the same dept multiple times the query will produce a wrong result and take too long to get it  
-- 04/09/13 YS filter WC without any process time
-- 06/02/14 Santosh L Changed WcProcessTimeM numeric(10,5) to WcProcessTimeM numeric(11,5) because it is causing error 'Arithmetic overflow error converting   numeric to data type numeric.'
--12/06/16 YS use dept_pri if not 0
--13/06/17 Shivshankar P : Get by sorting the slackpri 
--[dbo].[SchPlanningGetMonthDetails]'1/29/2017 12:00:00 AM','3/12/2017 11:59:59 PM','','STAG','49f80792-e15e-4b62-b720-21b360e3108a'
--[dbo].[SchPlanningGetMonthDetails] '1/30/2017 12:00:00 AM','1/30/2017 11:59:59 PM','','INSP','49f80792-e15e-4b62-b720-21b360e3108a'
--[dbo].[SchPlanningGetMonthDetails]'1/1/2017 12:00:00 AM','2/12/2017 11:59:59 PM','','STAG','49f80792-e15e-4b62-b720-21b360e3108a'
-- 07/01/19 YS per Shiv suggestion changed the 
   --DateAdd(d,1,dDate)<= ShopLoad.WCendDate  to Datediff(day,dDate,ShopLoad.WCendDate)>=1 condition
   -- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================  
CREATE PROCEDURE [dbo].[SchPlanningGetMonthDetails]  
 -- Add the parameters for the stored procedure here  
 @startDate as smalldatetime = NULL,   
 @endDate as smalldatetime = NULL,  
 @custno as char(10)=' ',  /* if empty custno select all customers that can be viewd by a userid */  
 @deptid as char(10)=' ',  
 @userid as uniqueidentifier = NULL     
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
 DECLARE @tCustomers Table (Custno char(10),CustName char(35)) ;  
 IF (@custno=' ')  
 BEGIN  
   -- take all customers that user wit @userid allowe to see  
  INSERT INTO @tCustomers EXEC [aspmnxSP_GetCustomers4User] @userid ;  
 END -- if @custno=' '  
 ELSE  
 BEGIN -- else if @custno=' '  
  INSERT INTO @tCustomers (Custno,custname) SELECT Custno,CustName from CUSTOMER where CUSTNO=@custno ;  
 END  -- else if @custno=' '  
 -- populate calendar information  
 declare @calendar Table (dDate smalldatetime,WorkingDay bit default 0)  
   
 ;with Calendar  
 as  
 (      
    Select @StartDate As [dDate]  
  Union All  
    Select DateAdd(d,1,[dDate])  
    From Calendar    
    Where [dDate] < @EndDate  
    )  
    -- populate calendar with working date flag  
    INSERT INTO @calendar Select [dDate],  
   CASE WHEN S.lProdWorkDay=0 OR NOT Holidays.HOLIDAY IS NULL THEN 0 ELSE 1 END as  WorkingDay  
  From Calendar C INNER JOIN CalendarSetup S ON S.cDayOfWeek =DATENAME(dw,c.dDate)   
  left outer join HOLIDAYS on C.dDate=Holidays.DATE    
 -- different SQL for all WC  
 -- 03/19/13 YS added process time for a WC if provided  
 -- 06/02/14 Santosh L Changed WcProcessTimeM numeric(10,5) to WcProcessTimeM numeric(11,5) because it is causing error 'Arithmetic overflow error converting   numeric to data type numeric.'
 -- 09/26/19 YS modified part number/customer part number char(25) to char(35)
 DECLARE @tJobs TABLE (wono char(10),Number numeric (4,0), WCcompl_dts smalldatetime DEFAULT NULL,WCSTART_DTS smalldatetime DEFAULT NULL,WcProcessTimeM numeric(11,5), part_no char(35),revision char(8),custname char(35), bldqty numeric(7,0),complete numeric (7,0),balance numeric(7,0),START_DTS smalldatetime DEFAULT NULL,   
   DUE_DATE smalldatetime default NULL,compl_dts smalldatetime default null,slackpri numeric(10,5), processtm numeric(10,5),AutoScheduled bit DEFAULT 0,KIT bit DEFAULT 0,KITSTATUS char(10),OPENCLOS char(10),  
   LatebySchd bit default 0,LatebyWoDue bit default 0,WCBehindJob bit default 0)  
 IF (@deptid=' ')  
 BEGIN  
  ;WITH WcLate  
  AS  
  (SELECT Dept_qty.wono,MIN(number) as Number  
   from DEPT_QTY  
   CROSS APPLY (SELECT Wono from WOENTRY where Woentry.openclos NOT IN ('Closed','Cancel','Closeshrt','Admin Hold','Mfg Hold') and Dept_qty.WONO=Woentry.Wono) W   
   WHERE CURR_QTY<>0  
   and NOT DUEOUTDT IS NULL AND DATEDIFF(day,DUEOUTDT ,GETDATE())>0   
   GROUP BY Dept_qty.WONO  
  )  
  INSERT INTO @tJobs  
  SELECT DISTINCT Prod_dts.wono,0 as number,CAST(NULL as smalldatetime)as WCcompl_dts ,CAST(NULL as smalldatetime) as  WCSTART_DTS, 0.00 as WcProcessTimeM,  
   Inventor.part_no, Inventor.revision,  
   C.custname, Woentry.bldqty, Woentry.complete, Woentry.balance,Prod_dts.START_DTS, Woentry.DUE_DATE,   
   Prod_dts.compl_dts, Prod_dts.slackpri, Prod_dts.processtm,Prod_dts.AutoScheduled,Woentry.KIT,Woentry.KITSTATUS ,woentry.OPENCLOS ,  
   CAST(CASE WHEN DATEDIFF(Day,Prod_dts.compl_dts,GETDATE())>0 THEN 1 ELSE 0 END as bit) AS LatebySchd,  
   CAST(CASE WHEN DATEDIFF(Day,Woentry.DUE_DATE,GETDATE())>0 THEN 1 ELSE 0 END as bit) AS LatebyWoDue,  
   CAST(CASE WHEN WcLate.Wono IS NULL THEN 0 ELSE 1 END as bit) AS WCBehindJob  
  FROM prod_dts INNER JOIN WOENTRY ON Woentry.wono = Prod_dts.wono  
  INNER JOIN inventor ON Inventor.uniq_key = Woentry.uniq_key  
  INNER JOIN @tCustomers C ON Woentry.CUSTNO=C.Custno   
  LEFT OUTER JOIN WcLate ON Woentry.wono=WcLate.WONO  
  WHERE Woentry.openclos NOT IN ('Closed','Cancel','Closeshrt','Admin Hold','Mfg Hold')  
   AND  Woentry.balance <>  0   
   AND (Prod_dts.START_DTS BETWEEN @startDate and DATEADD(Day,1,@endDate)    --- job started between start date and end date ranges  
   OR  Prod_dts.compl_dts BETWEEN @startDate and DATEADD(Day,1,@endDate)    --- job ended between start date and end date ranges  
   OR  (@startDate BETWEEN Prod_dts.START_DTS and DATEADD(Day,1,Prod_dts.compl_dts) AND @endDate BETWEEN Prod_dts.START_DTS and DATEADD(Day,1,Prod_dts.compl_dts)))   --- start and end date range is between job start and end  
   
   
   
 END -- @deptid=' '  
 ELSE   
 BEGIN -- else @deptid=' '  
  -- find all the open qty location  
  ;WITH WcQtyLocation  
  AS  
  (SELECT Dept_qty.wono,MIN(number) as Number  
   from DEPT_QTY  
   CROSS APPLY (SELECT Wono from WOENTRY where Woentry.openclos NOT IN ('Closed','Cancel','Closeshrt','Admin Hold','Mfg Hold') and Dept_qty.WONO=Woentry.Wono) W   
   WHERE CURR_QTY<>0  
   GROUP BY Dept_qty.WONO  
  )  
   
  INSERT INTO @tJobs  
  select DI.wono , DI.Number,DI.DUEOUTDT as WCcompl_dts ,DO.Dueoutdt as WCSTART_DTS,DI.CAPCTYNEED/60 as WcProcessTimeM,  
  I.part_no, I.revision,  
  C.CustName,W.bldqty, W.complete, W.balance,Prod_dts.START_DTS,W.DUE_DATE,Prod_dts.compl_dts,
  case when di.DEPT_PRI<>0.000 then di.dept_pri else Prod_dts.slackpri end as slackpri,Prod_dts.processtm,  
   Prod_dts.AutoScheduled,W.Kit,W.KITSTATUS ,W.OPENCLOS ,  
   CAST(CASE WHEN DATEDIFF(Day,Prod_dts.compl_dts,GETDATE())>0 THEN 1 ELSE 0 END as bit) AS LatebySchd,  
  CAST(CASE WHEN DATEDIFF(Day,W.DUE_DATE,GETDATE())>0 THEN 1 ELSE 0 END as bit) AS LatebyWoDue,  
  CAST(CASE WHEN DATEDIFF(Day,DI.DUEOUTDT,GETDATE())>0 THEN 1 ELSE 0 END as bit) AS WCBehindJob  
   FROm Dept_qty DI  
  INNER JOIN WOENTRY W ON DI.WONO=W.Wono  
  INNER JOIN Inventor I ON W.UNIQ_KEY=I.Uniq_key  
  INNER JOIN @tCustomers C ON W.CUSTNO=C.Custno  
  INNER JOIN PROD_DTS ON DI.WONO=Prod_dts.Wono  
  INNER JOIN WcQtyLocation ON DI.WONO=WcQtyLocation.WONO and DI.NUMBER>=WcQtyLocation.Number  
  OUTER APPLY (SELECT Top 1 NUMBER,Dueoutdt from DEPT_QTY where Dept_qty.WONO=DI.WONO and Dept_qty.NUMBER<DI.NUMBER ORDER By NUMBER DESC) DO  
  WHERE DI.DEPT_ID=@deptid   
   AND W.openclos NOT IN ('Closed','Cancel','Closeshrt','Admin Hold','Mfg Hold')  
   AND NOT DI.DUEOUTDT IS NULL  
   AND ((NOT DO.DUEOUTDT IS NULL AND  DO.DUEOUTDT BETWEEN @startDate and DATEADD(Day,1,@endDate))    --- job started between start date and end date ranges  
   OR  (NOT DI.DUEOUTDT IS NULL AND DI.DUEOUTDT BETWEEN @startDate and DATEADD(Day,1,@endDate))    --- job ended between start date and end date ranges  
   OR  (@startDate BETWEEN DO.DUEOUTDT and DATEADD(Day,1,DI.DUEOUTDT) AND @endDate BETWEEN DO.DUEOUTDT and DATEADD(Day,1,DI.DUEOUTDT)))   --- start and end date range is between job start and end  
   
 END -- else @deptid=' '  
   
 declare @ShopLoad Table (wono char(10),WcStartDate smalldatetime, WCendDate smalldatetime,number numeric(4,0),LoadinSeconds numeric(12,0),LoadinMin numeric(10,2),LoadinH numeric(10,2),Dept_id char(4),  
  nNotworking numeric(3),NumOfDaysinWC numeric(3),LoadDistrPerDayH numeric(12,2))  
 INSERT INTO @ShopLoad  
 select DI.WONO,ISNULL(DO.DUEOUTDT,t.START_DTS) as WcStartDate,DI.DUEOUTDT as WCendDate, DI.NUMBER ,  
  Di.CAPCTYNEED as LoadinSeconds,Di.CAPCTYNEED/60 as LoadinMin, Di.CAPCTYNEED/3600 as LoadinH, Di.DEPT_ID ,  
  nW.nNotworking,DATEDIFF(Day,ISNULL(DO.DUEOUTDT,t.START_DTS),DI.DUEOUTDT)+1- nW.nNotworking as NumOfDaysinWC,  
  CASE WHEN Di.CAPCTYNEED =0.00 OR DATEDIFF(Day,ISNULL(DO.DUEOUTDT,t.START_DTS),DI.DUEOUTDT)+1-nW.nNotworking=0 THEN 0.00   
   ELSE  (Di.CAPCTYNEED/3600)/(DATEDIFF(Day,ISNULL(DO.DUEOUTDT,t.START_DTS),DI.DUEOUTDT)+1-nW.nNotworking) END as LoadDistrPerDayH   
  from DEPT_QTY DI   
  OUTER APPLY (SELECT Top 1 NUMBER,Dueoutdt from DEPT_QTY where Dept_qty.WONO=DI.WONO and Dept_qty.NUMBER<DI.NUMBER ORDER By NUMBER DESC) DO  
  INNER JOIN @tJobs t on DI.WONO=t.wono AND DI.Dept_id=CASE WHEN @deptid<>' ' THEN @deptid ELSE DI.Dept_id END  
  OUTER APPLY (SELECT COUNT(*) as nNotworking FROM @calendar Cal   
  WHERE Cal.WorkingDay = 0 and Cal.dDate BETWEEN ISNULL(DO.DUEOUTDT,t.START_DTS) and DI.DUEOUTDT) nW  
   

    
 --SELECT * from @ShopLoad order by wono,number  
 -- 04/05/13 YS link by Number not Dept_id, otherwise if the routing has the same dept multiple times the query will produce a wrong result and take too long to get it  
 DECLARE @DateDistr TABLE (Wono char(10),dDate smalldatetime,DEPT_ID char(4),Number numeric(4),LoadDistrPerDayH numeric(10,2))  
 ;WITH DateDistr  
 as(  
 SELECT ShopLoad.WONO,WcStartDate as dDate,DEPT_ID,Number,LoadDistrPerDayH from @ShopLoad ShopLoad  
  UNION ALL  
  SELECT  ShopLoad.WONO,DateAdd(d,1,dDate),ShopLoad.DEPT_ID,Shopload.number,ShopLoad.LoadDistrPerDayH   
   from @ShopLoad as ShopLoad INNER JOIN DateDistr On ShopLoad.WONO =DateDistr.WONO and ShopLoad.Number = DateDistr.Number 
   -- 07/01/19 YS per Shiv suggestion changed the 
   --DateAdd(d,1,dDate)<= ShopLoad.WCendDate  to Datediff(day,dDate,ShopLoad.WCendDate)>=0 condition
   and Datediff(day,dDate,ShopLoad.WCendDate)>=1 
 )  
 --SELECT * from DateDistr order by WONO,Number,dDate  
 -- 04/03/13 YS change cast the dates to avoid problem with time part of the datetime   
 --04/09/13 YS filter WC without any process time  
 INSERT INTO @DateDistr  
 SELECT DateDistr.*   
  from DateDistr INNER JOIN @calendar CAL ON cast(DateDistr.dDate as date)= cast(CAL.dDate as date)  
  WHERE Cal.WorkingDay=1 and DateDistr.LoadDistrPerDayH <>0  
   
 --select * from @DateDistr order by Wono,Number,ddate  
 -- get capacity information  
 DECLARE @tCapacity Table (nDow int,dDate smalldatetime, CapacityA numeric(12,2) default 0.00,CapacityN numeric(12,2) default 0.00,Dept_id Char(4) default '',Activ_id char(4) default '')  
 Declare @tDOW TABLE (cDOW char(10),nrec int IDENTITY)  
 INSERT INTO @tDOW (cDOW) VALUES   
    ('Monday'),  
    ('Tuesday'),  
    ('Wednesday'),  
    ('Thursday'),  
    ('Friday'),  
    ('Saturday'),  
    ('Sunday')  
 --SELECT * from @tDOW      
       
 -- save current @@DATEFIRST  
 DECLARE @liDateFirst as int  
 SET @liDateFirst = @@DATEFIRST;  
 -- set first date of the week to Monday  
 SET DATEFIRST 1;  
 INSERT INTO @tCapacity (nDow,dDate,Dept_id,Activ_id)   
  SELECT  DATEPART(dw,dDate), dDate,depts.dept_id,ISNULL(deptsdet.ACTIV_ID ,SPACE(4))   
   from @Calendar CROSS JOIN Depts LEFT OUTER JOIN DEPTSDET on Depts.DEPT_ID = deptsdet.DEPT_ID ORDER BY Depts.NUMBER,Deptsdet.NUMBER ,dDate   
    --select * from @tCapacity   
      
      
    declare @CapacityInfo Table (DEPT_ID char(4),Tot_min numeric(12,2),Break_min numeric(12,2),Lunch_min numeric(12,2) ,  
  DAY_START char(10),nDayStart int,NO_OF_DAYS numeric(3,0),SHIFT_NO numeric (3,0),STARTMONTH numeric(2,0),ACTIV_ID char(4),  
  RESMONTH1 numeric(3,0),RESMONTH2 numeric(3,0),RESMONTH3 numeric(3,0),RESMONTH4 numeric(3,0),  
  RESMONTH5 numeric(3,0),RESMONTH6 numeric(3,0),RESMONTH7 numeric(3,0),RESMONTH8 numeric(3,0),  
  RESMONTH9 numeric(3,0),RESMONTH10 numeric(3,0),RESMONTH11 numeric(3,0),RESMONTH12 numeric(3,0))  
     
   INSERT INTO @CapacityInfo select DEPTSHFT.DEPT_ID,WrkShift.Tot_min ,WrkShift.Break_min,WrkShift.Lunch_min ,  
  WRKSHIFT.DAY_START,D.nrec as nDayStart,WRKSHIFT.NO_OF_DAYS,WrkShift.SHIFT_NO, ActCap.STARTMONTH,ActCap.ACTIV_ID,  
  ActCap.RESMONTH1,ActCap.RESMONTH2,ActCap.RESMONTH3,ActCap.RESMONTH4,  
  ActCap.RESMONTH5,ActCap.RESMONTH6,ActCap.RESMONTH7,ActCap.RESMONTH8,  
  ActCap.RESMONTH9,ActCap.RESMONTH10,ActCap.RESMONTH11,ActCap.RESMONTH12  
  from DEPTSHFT  INNER JOIN WRKSHIFT ON Deptshft.SHIFT_NO =WRKSHIFT.SHIFT_NO   
  INNER JOIN ACTCAP ON DeptShft.DEPT_ID = ActCap.DEPT_ID and DEPTSHFT.SHIFT_NO =ACTCAP.SHIFT_NO   
  INNER JOIN @tDOW D ON WRKSHIFT.DAY_START=D.cDOW  
  ORDER BY DEPTSHFT.DEPT_ID,actcap.ACTIV_ID,actcap.SHIFT_NO    
   
 --select * from @CapacityInfo  
 DECLARE @CalcCap TABLE (dept_id char(4),activ_id char(4),Shift_no Numeric(3,0),dDate smalldatetime,CapacityA numeric (12,2))  
   
 INSERT INTO @CalcCap SELECT distinct t.dept_id ,c.Activ_id,c.Shift_no,dDate, CASE WHEN DATEPART(M,dDate)-C.STARTMONTH+1=1 THEN C.RESMONTH1  
             WHEN DATEPART(M,dDate)-C.STARTMONTH+1=2 THEN C.RESMONTH2  
             WHEN DATEPART(M,dDate)-C.STARTMONTH+1=3 THEN C.RESMONTH3  
             WHEN DATEPART(M,dDate)-C.STARTMONTH+1=4 THEN C.RESMONTH4  
             WHEN DATEPART(M,dDate)-C.STARTMONTH+1=5 THEN C.RESMONTH5  
             WHEN DATEPART(M,dDate)-C.STARTMONTH+1=6 THEN C.RESMONTH6  
             WHEN DATEPART(M,dDate)-C.STARTMONTH+1=7 THEN C.RESMONTH7  
             WHEN DATEPART(M,dDate)-C.STARTMONTH+1=8 THEN C.RESMONTH8  
             WHEN DATEPART(M,dDate)-C.STARTMONTH+1=1 THEN C.RESMONTH9  
             WHEN DATEPART(M,dDate)-C.STARTMONTH+1=2 THEN C.RESMONTH10  
             WHEN DATEPART(M,dDate)-C.STARTMONTH+1=3 THEN C.RESMONTH11  
             WHEN DATEPART(M,dDate)-C.STARTMONTH+1=4 THEN C.RESMONTH12  
             ELSE 0 END * (C.TOT_MIN-C.BREAK_MIN-C.LUNCH_MIN ) as CapacityA  
 FROM @CapacityInfo C INNER JOIN @tCapacity t ON C.DEPT_ID=t.Dept_id WHERE t.nDow BETWEEN c.nDayStart and c.NO_OF_DAYS order by t.Dept_id,c.ACTIV_ID   
 ;WITH SumCap  
 as  
 (select dept_id,activ_id,dDate,SUM(capacityA) as CapacityA  
  FROM @CalcCap C   
  group by dept_id,activ_id,dDate )  
    
   
 update @tCapacity  SET CapacityA= C.CapacityA from SumCap C inner join @tCapacity t on C.activ_id =t.Activ_id and c.dept_id =t.Dept_id and c.dDate =t.dDate   
   
 --select cap.nDow ,cap.dDate ,SUM(cap.CapacityA) as capacityAMin,SUM(cap.CapacityA/60) as CapacityAHr,CapacityN ,Dept_id   from @tCapacity cap group by cap.nDow ,cap.dDate,CapacityN ,Dept_id order by ddate  
   
-- list of jobs output  
SELECT * from @tJobs  order by slackpri   -- 13/06/17 Shivshankar P : Get by sorting the slackpri 
-- detail dept/capacity/jobs count  
 -- 04/03/13 YS change cast the dates to avoid problem with time part of the datetime   
 -- 04/03/13 added wcOrder column to order in the original order and group by date not date time  
 -- 04/04/13 added distinct to count wono  
 SELECT D.DEPT_ID,cast(D.dDate as DATE) as dDate,SUM(d.LoadDistrPerDayH) as LoadDistrPerDayH  ,Cap.CapacityAHr ,COUNT(distinct Wono) as nWos,  
  CAST(case when  SUM(d.LoadDistrPerDayH)  >Cap.CapacityAHr THEN 1 ELSE 0 end as bit) as OverLoad,Depts.Number as WcOrder  
  from @DateDistr D inner join   
   (select SUM(CapacityA/60) as CapacityAHr,Dept_id,dDate  from @tCapacity group by dDate,Dept_id) cap   
  ON cast(D.dDate as date) =cast(Cap.dDate as DATE) and D.DEPT_ID =Cap.Dept_id  
  inner join DEPTS on d.DEPT_ID=depts.DEPT_ID   
  GROUP BY  D.DEPT_ID,cast(D.dDate as DATE),Cap.CapacityAHr,depts.number  
  ORDER BY dDate,Depts.number  
 -- list of none working days  
 select * from @calendar where WorkingDay=0  
   
-- ---Get grid columns configuration  
--SELECT [userId],[gridId],[colModel],[colNames],[groupedCol] FROM [dbo].[wmUserGridConfig] WHERE gridId = 'gvWorkOrdersForWorkCenter'  
  
 -- re-set to default  
 SET @liDateFirst = @liDateFirst  
END