-- =============================================  
-- Author:  <Yelena Shmidt>  
-- Create date: <01/07/2010>  
-- Description: <Generate records in the 'holidays' table according with HolidayList table>  
-- 10/11/2018 Nilesh Sa : remove the holidays excluding the past one year
-- 10/11/2018 Nilesh Sa : generate the holidays for future year only
-- 10/22/2018 Nilesh Sa : generate the holidays for future year only for variable logic
-- =============================================  
CREATE PROCEDURE [dbo].[sp_GeneratehoildaysTable]   
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
   
    -- Insert statements for procedure here  
 DECLARE @liDateFirst as Int;  
 -- save current @@DATEFIRST  
 SET @liDateFirst = @@DATEFIRST;  
 -- set first date of the week to Monday  
 SET DATEFIRST 1;  
 -- remove records from Holidays Table  
 -- 10/11/2018 Nilesh Sa : remove the holidays excluding the past one year
 -- DELETE FROM Holidays where 1=1;  
  DELETE FROM HOLIDAYS WHERE YEAR(date) >= YEAR(GETDATE());
  DELETE FROM HOLIDAYS WHERE YEAR(date) < (YEAR(GETDATE()) - 1);
 --generate dates for the fixed date holidays using CTE name zFixedHolidays  
 with zFixedHolidays as  
 (  
  select cholidayname,lFixedDate,nFixedDate,nMonth, nStartYear, nEndYear from holidaylist T where lFixedDate=1 and lCompObserve=1  
  union all  
  select cholidayname, lFixedDate,nFixedDate,nMonth,  
  CAST(nStartYear + 1 as smallint) as nStartYear,   
  nEndYear from zFixedHolidays where nStartYear < nEndYear and lFixedDate=1  
 )  
 INSERT INTO Holidays (Holiday,[Date]) 
 SELECT cholidayname,cast(convert(char(2),nMonth)+'/'+convert(char(2),nFixedDate)+'/'+convert(char(4),nStartYear) as smalldatetime) as [Date] 
 from zFixedHolidays  WHERE  nStartYear >= YEAR(GETDATE())  ORDER BY cholidayname,[Date];  
   -- 10/11/2018 Nilesh Sa : generate the holidays for future year only
 --generate dates for floating date holidays   
 -- find all the floating holidayes with the first occurrence in the month  
 with zFloat1Holidays as  
 (  
  select cholidayname,nMonth,nDayOfWeek,cDayOccurrence,lCompObserve,nOffsetFromDayOfWeek,  
    nStartYear, nEndYear from holidaylist T where lFixedDate=0 and cDayOccurrence='First' and lCompObserve=1 
  union all  
  select cholidayname,nMonth,nDayOfWeek,cDayOccurrence,lCompObserve,nOffsetFromDayOfWeek,  
  cast(nStartYear + 1 as smallint) as nStartYear,nEndYear from zFloat1Holidays where nStartYear < nEndYear   
 )  
 INSERT INTO Holidays (Holiday,[Date]) SELECT cholidayname,CASE WHEN DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))>nDayOfWeek   
     THEN   
      CASE WHEN nOffsetFromDayOfWeek=0   
      THEN DATEADD(DAY,7-DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))+nDayOfWeek,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))   
      ELSE   
      DATEADD(DAY,nOffsetFromDayOfWeek,DATEADD(DAY,7-DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))+nDayOfWeek,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))) END  
     WHEN DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))<nDayOfWeek  
     THEN   
      CASE WHEN nOffsetFromDayOfWeek=0   
      THEN DATEADD(DAY,nDayOfWeek-DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))),(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))  
      ELSE DATEADD(DAY,nOffsetFromDayOfWeek,DATEADD(DAY,nDayOfWeek-DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))),(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))) END  

     ELSE   
      CASE WHEN nOffsetFromDayOfWeek=0   
      THEN cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)   
      ELSE DATEADD(DAY,nOffsetFromDayOfWeek,cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)) END  
    END As Date FROM zFloat1Holidays
	WHERE nStartYear >= YEAR(GETDATE()) -- 10/22/2018 Nilesh Sa : generate the holidays for future year only for variable logic
	 ORDER BY cholidayname,[Date] ;  
-- find all the floating holidayes with the second occurrence in the month  
 with zFloat2Holidays as  
 (  
  select cholidayname,nMonth,nDayOfWeek,cDayOccurrence,lCompObserve,nOffsetFromDayOfWeek,  
    nStartYear, nEndYear from holidaylist T where lFixedDate=0 and cDayOccurrence='Second' and lCompObserve=1  
  union all  
  select cholidayname,nMonth,nDayOfWeek,cDayOccurrence,lCompObserve,nOffsetFromDayOfWeek,  
  cast(nStartYear + 1 as smallint) as nStartYear,nEndYear from zFloat2Holidays where nStartYear < nEndYear   
 )  
 INSERT INTO Holidays (Holiday,[Date]) SELECT cholidayname,CASE WHEN DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))>nDayOfWeek   
     THEN   
      CASE WHEN nOffsetFromDayOfWeek=0   
      THEN DATEADD(DAY,7,DATEADD(DAY,7-DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))+nDayOfWeek,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))))   
      ELSE   
      DATEADD(DAY,nOffsetFromDayOfWeek,DATEADD(DAY,7,DATEADD(DAY,7-DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))+nDayOfWeek,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))))) END  
     WHEN DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))<nDayOfWeek  
     THEN   
      CASE WHEN nOffsetFromDayOfWeek=0   
      THEN DATEADD(DAY,7,DATEADD(DAY,nDayOfWeek-DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))),(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))))  
      ELSE DATEADD(DAY,nOffsetFromDayOfWeek,DATEADD(DAY,7,DATEADD(DAY,nDayOfWeek-DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))),(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))))) END  
     ELSE   
      CASE WHEN nOffsetFromDayOfWeek=0   
      THEN DATEADD(DAY,7,cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))   
      ELSE DATEADD(DAY,nOffsetFromDayOfWeek,DATEADD(DAY,7,cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))) END  
    END As Date FROM zFloat2Holidays 
	WHERE nStartYear >= YEAR(GETDATE()) -- 10/22/2018 Nilesh Sa : generate the holidays for future year only for variable logic
	ORDER BY cholidayname,[Date];  
-- find all the floating holidayes with the Third occurrence in the month  
 with zFloat3Holidays as  
 (  
  select cholidayname,nMonth,nDayOfWeek,cDayOccurrence,lCompObserve,nOffsetFromDayOfWeek,  
    nStartYear, nEndYear from holidaylist T where lFixedDate=0 and cDayOccurrence='Third' and lCompObserve=1 
  union all  
  select cholidayname,nMonth,nDayOfWeek,cDayOccurrence,lCompObserve,nOffsetFromDayOfWeek,  
  cast(nStartYear + 1 as smallint) as nStartYear,nEndYear from zFloat3Holidays where nStartYear < nEndYear   
 )  
 INSERT INTO Holidays (Holiday,[Date]) SELECT cholidayname,CASE WHEN DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))>nDayOfWeek   
     THEN   
      CASE WHEN nOffsetFromDayOfWeek=0   
      THEN DATEADD(DAY,7*2,DATEADD(DAY,7-DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))+nDayOfWeek,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))))   
      ELSE   
      DATEADD(DAY,nOffsetFromDayOfWeek,DATEADD(DAY,7*2,DATEADD(DAY,7-DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))+nDayOfWeek,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))))) END  
     WHEN DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))<nDayOfWeek  
     THEN   
      CASE WHEN nOffsetFromDayOfWeek=0   
      THEN DATEADD(DAY,7*2,DATEADD(DAY,nDayOfWeek-DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))),(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))))  
      ELSE DATEADD(DAY,nOffsetFromDayOfWeek,DATEADD(DAY,7*2,DATEADD(DAY,nDayOfWeek-DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))),(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))))) END  
     ELSE   
      CASE WHEN nOffsetFromDayOfWeek=0   
      THEN DATEADD(DAY,7*2,cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))   
      ELSE DATEADD(DAY,nOffsetFromDayOfWeek,DATEADD(DAY,7*2,cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))) END  
    END As Date FROM zFloat3Holidays
	WHERE nStartYear >= YEAR(GETDATE()) -- 10/22/2018 Nilesh Sa : generate the holidays for future year only for variable logic
	 ORDER BY cholidayname,[Date];  
-- find all the floating holidayes with the Fourh occurrence in the month  
 with zFloat4Holidays as  
 (  
  select cholidayname,nMonth,nDayOfWeek,cDayOccurrence,lCompObserve,nOffsetFromDayOfWeek,  
    nStartYear, nEndYear from holidaylist T where lFixedDate=0 and cDayOccurrence='Fourth' and lCompObserve=1 
  union all  
  select cholidayname,nMonth,nDayOfWeek,cDayOccurrence,lCompObserve,nOffsetFromDayOfWeek,  
  cast(nStartYear + 1 as smallint) as nStartYear,nEndYear from zFloat4Holidays where nStartYear < nEndYear   
 )  
 INSERT INTO Holidays (Holiday,[Date]) SELECT cholidayname,CASE WHEN DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))>nDayOfWeek   
     THEN   
      CASE WHEN nOffsetFromDayOfWeek=0   
      THEN DATEADD(DAY,7*3,DATEADD(DAY,7-DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))+nDayOfWeek,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))))   
      ELSE   
      DATEADD(DAY,nOffsetFromDayOfWeek,DATEADD(DAY,7*3,DATEADD(DAY,7-DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))+nDayOfWeek,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))))) END  
     WHEN DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime)))<nDayOfWeek  
     THEN   
      CASE WHEN nOffsetFromDayOfWeek=0   
      THEN DATEADD(DAY,7*3,DATEADD(DAY,nDayOfWeek-DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))),(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))))  
      ELSE DATEADD(DAY,nOffsetFromDayOfWeek,DATEADD(DAY,7*3,DATEADD(DAY,nDayOfWeek-DATEPART(dw,(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))),(cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))))) END  
     ELSE   
      CASE WHEN nOffsetFromDayOfWeek=0   
      THEN DATEADD(DAY,7*3,cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))   
      ELSE DATEADD(DAY,nOffsetFromDayOfWeek,DATEADD(DAY,7*3,cast(convert(char(2),nMonth)+'/01/'+convert(char(4),nStartYear) as smalldatetime))) END  
    END As Date FROM zFloat4Holidays
	WHERE nStartYear >= YEAR(GETDATE()) -- 10/22/2018 Nilesh Sa : generate the holidays for future year only for variable logic
	 ORDER BY cholidayname,[Date];  
  
--find all the floating holidayes with the Last occurrence in the month  
  
with zFloatLastHolidays as  
 (  
  select cholidayname,nMonth,nDayOfWeek,cDayOccurrence,lCompObserve,nOffsetFromDayOfWeek,  
    nStartYear, nEndYear from holidaylist T where lFixedDate=0 and cDayOccurrence='Last' and lCompObserve=1 
  union all  
  select cholidayname,nMonth,nDayOfWeek,cDayOccurrence,lCompObserve,nOffsetFromDayOfWeek,  
  cast(nStartYear + 1 as smallint) as nStartYear,nEndYear from zFloatLastHolidays where nStartYear < nEndYear   
 ),  
 zLastDayOfMonth AS   
 (   
  SELECT cholidayname,nMonth,nDayOfWeek,nOffsetFromDayOfWeek,  
  DATEADD(DAY,-1,CAST(convert(char(2),CASE WHEN nMonth<12 THEN nMonth+1 ELSE 1 END)+'/01/'+convert(char(4),CASE WHEN nMonth<12 THEN nStartYear ELSE nStartYear+1 END) as smalldatetime)) as dLDOM,  
  DATEPART(dw,DATEADD(Day,-1,CAST(convert(char(2),CASE WHEN nMonth<12 THEN nMonth+1 ELSE 1 END)+'/01/'+convert(char(4),CASE WHEN nMonth<12 THEN nStartYear ELSE nStartYear+1 END) as smalldatetime))) as nLDOW,  
  nStartYear,nEndYear FROM zFloatLastHolidays   
  WHERE nStartYear >= YEAR(GETDATE()) -- 10/22/2018 Nilesh Sa : generate the holidays for future year only for variable logic
 ),  
 zLast AS  
 (  
  SELECT cholidayname,CASE WHEN nLDOW>nDayOfWeek   
     THEN   
      CASE WHEN nOffsetFromDayOfWeek=0   
      THEN DATEADD(DAY,-(nLDOW-nDayOfWeek),dLDOM)   
      ELSE   
      DATEADD(DAY,nOffsetFromDayOfWeek,DATEADD(DAY,-(nLDOW-nDayOfWeek),dLDOM)) END  
     WHEN nLDOW<nDayOfWeek   
     THEN   
      CASE WHEN nOffsetFromDayOfWeek=0   
      THEN DATEADD(WEEK,-1,DATEADD(DAY,(nDayOfWeek-nLDOW),dLDOM))    
      ELSE DATEADD(DAY,nOffsetFromDayOfWeek,DATEADD(WEEK,-1,DATEADD(DAY,(nDayOfWeek-nLDOW),dLDOM))) END  
     ELSE   
      CASE WHEN nOffsetFromDayOfWeek=0   
      THEN dLDOM   
      ELSE DATEADD(DAY,nOffsetFromDayOfWeek,dLDOM) END  
    END As Date FROM zLastDayOfMonth   
 )  
 INSERT INTO Holidays (Holiday,[Date]) SELECT cholidayname,[Date] FROM zLast 
 ORDER BY cholidayname,[Date]  
  
 -- re-set first date of the week to whatever  
 SET DATEFIRST @liDateFirst;  
END 