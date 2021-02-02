-- =============================================        
-- Author: Sachin B        
-- Create date: 23/01/2017        
-- Description: this procedure will be called from the SF module and Pull work order by WC and Wono        
-- 04/05/2017 Sachin b Remove leading Zeros of work order at last select statement for increase performance because it calls every Time        
-- 07/14/2017 Sachin b Combind class,type with description        
-- 08/22/2017 Sachin b Use DEPTKEY in Select Statements        
-- 08/25/2017 Sachin b add join with RoutingTemplate for get TemplateId and TemplateName and unused temp table #TEMP2        
-- 09/25/2017 Sachin b Add join with routingProductSetup because we remove templateid from woentry table        
-- 02/13/2018 Sachin B Add Uniquerout,WrkInstChk,EquipmentChk,ToolsChk in select Statement        
-- 10/11/2018 Sachin B Get ORDMULT same as it present on the Inventor      
-- 01/03/2019 Sachin B remove the condition for the d.CURR_QTY >0    
-- 01/14/2019 Sachin B Get PART_CLASS,PART_TYPE from inventor table    
-- 01/15/2019 Sachin B remove the condition OPENCLOS<>'closed'   
-- 04/24/2019 Sachin B Add Dept_ID In the Select Statement  
-- 09/17/2020 Sachin B Add KitStatus In the Select Statement 
-- GetWODetailsByDepartmentAndWono 'STAG','0000011485',1        
-- =============================================        
CREATE PROCEDURE GetWODetailsByDepartmentAndWono         
 @wcName CHAR(10),         
 @wono CHAR(10),        
 @number INT        
        
As        
DECLARE @SQL NVARCHAR(MAX)        
BEGIN        
        
SET NOCOUNT ON;         
        
IF OBJECT_ID('dbo.#TEMP', 'U') IS NOT NULL              
DROP TABLE dbo.#TEMP;        
        
IF OBJECT_ID('dbo.#TEMP1', 'U') IS NOT NULL              
DROP TABLE dbo.#TEMP1;        
        
IF OBJECT_ID('dbo.#TEMP2', 'U') IS NOT NULL              
DROP TABLE dbo.#TEMP2;        
        
SELECT *         
INTO #TEMP        
FROM        
(           
  SELECT DISTINCT        
  ROW_NUMBER() OVER (ORDER BY         
     case COALESCE(NULLIF(d.DEPT_PRI,0), 0)         
  When 0 then COALESCE(NULLIF(pd.SLACKPRI,0), 0)         
  Else d.DEPT_PRI End,        
     CASE        
       WHEN d.SCHED_STAT = '' THEN 6        
     WHEN d.SCHED_STAT = 'Closed' THEN 5        
  WHEN d.SCHED_STAT = 'Hold'  THEN 4        
  WHEN d.SCHED_STAT = 'Unscheduled' THEN 3        
  WHEN d.SCHED_STAT = 'Scheduled' THEN 2        
       WHEN d.SCHED_STAT = 'In Progress' THEN 1        
  END ASC,        
  w.DUE_DATE) AS RowNum,        
  d.SERIALSTRT, w.KITCOMPLETE,        
  CASE COALESCE(NULLIF(d.DEPT_PRI,0), 0)         
    WHEN 0 THEN COALESCE(NULLIF(pd.SLACKPRI,0), 0)         
    ELSE d.DEPT_PRI End AS PRIORITY,        
 -- 07/14/2017 Sachin b Combind class,type with description      
 -- 01/14/2019 Sachin B Get PART_CLASS,PART_TYPE from inventor table      
 inv.PART_CLASS+' / '+inv.PART_TYPE+' / '+ inv.DESCRIPT AS DESCRIPTION, w.UNIQ_KEY AS UniqKey, w.WONO AS Wono, inv.Revision, inv.part_no AS PartNo,        
  CASE COALESCE(NULLIF(inv.REVISION,''), '')        
 WHEN '' THEN  LTRIM(RTRIM(inv.PART_NO))         
 ELSE LTRIM(RTRIM(inv.PART_NO)) + '/' + inv.REVISION         
 END AS PartNoWithRev, (w.COMPLETE + w.BALANCE) AS WoQty ,         
 w.BALANCE , w.DUE_DATE as WoDueDate, inv.SERIALYES, pt.LOTDETAIL, d.DUEOUTDT AS WcDueDate, d.SCHED_STAT AS STATUS,        
  c.CUSTNAME, d.UNIQUEREC, d.operator AS Assigned, d.equipment ,         
  CASE WHEN d.NUMBER<=2 THEN [dbo].[GetTimeInHoursAndMinByTimeInSeconds](((q.RUNTIMESEC * w.BLDQTY ))/60)              
    ELSE [dbo].[GetTimeInHoursAndMinByTimeInSeconds](((q.RUNTIMESEC * d.CURR_QTY))/60)        
       END AS 'ProcessTime',        
  CASE WHEN d.NUMBER<=2 THEN [dbo].[GetTimeInHoursAndMinByTimeInSeconds](((q.RUNTIMESEC * w.BLDQTY )+q.SETUPSEC )/60)              
    ELSE [dbo].[GetTimeInHoursAndMinByTimeInSeconds](((q.RUNTIMESEC * d.CURR_QTY)+q.SETUPSEC)/60)        
       END AS 'TotalTime',        
  d.CURR_QTY AS WcQty, pd.PROCESSTM AS WoProcessTime, pt.AUTODT , pt.FGIEXPDAYS,        
  [dbo].[GetTimeInHoursAndMinByTimeInSeconds](q.SETUPSEC/60) AS 'SetupTime',       
  -- 10/11/2018 Sachin B Get ORDMULT same as it present on the Inventor      
  inv.ORDMULT,        
  --CASE COALESCE(NULLIF(inv.ORDMULT,0), 0)         
  --WHEN 0 THEN 1         
  --ELSE inv.ORDMULT END AS 'ORDMULT',          
  inv.useipkey AS 'UseIpKey',        
  d.NUMBER,        
  inv.ITAR,        
  CASE        
       WHEN dep.INOUTSVS = 'O' THEN CAST(1 AS BIT)        
    WHEN dep.INOUTSVS = 'I' THEN CAST(0 AS BIT)        
       END AS OutSourced        
  ,bldqty,        
  rout.TemplateID,ISNULL(rout.TemplateName,'') AS TemplateName,        
  -- 02/13/2018 Sachin B Add Uniquerout,WrkInstChk,EquipmentChk,ToolsChk in select Statement        
  w.Uniquerout,WrkInstChk,EquipmentChk,ToolsChk,w.KITSTATUS        
   FROM         
  WOENTRY w         
  LEFT OUTER JOIN DEPT_QTY d ON w.WONO = d.WONO        
  LEFT OUTER JOIN Depts dep ON d.DEPT_ID =dep.DEPT_ID        
  LEFT OUTER JOIN QuotDept q ON q.UNIQNUMBER = d.DEPTKEY         
  LEFT OUTER JOIN Inventor inv ON inv.UNIQ_KEY = w.UNIQ_KEY        
  LEFT OUTER JOIN PARTTYPE pt ON pt.PART_CLASS = inv.PART_CLASS AND pt.PART_TYPE = inv.PART_TYPE        
  LEFT OUTER JOIN Customer c ON c.CUSTNO = w.CUSTNO        
  LEFT OUTER JOIN PROD_DTS pd ON pd.WONO = w.WONO        
  -- 08/25/2017 Sachin b add join with RoutingTemplate for get TemplateId and TemplateName and unused temp table #TEMP2        
  -- 09/25/2017 Sachin b Add join with routingProductSetup because we remove templateid from woentry table        
  LEFT OUTER JOIN routingProductSetup rp ON w.uniquerout =rp.uniquerout        
  LEFT OUTER JOIN RoutingTemplate rout ON rout.TemplateID = rp.TemplateID     
  -- 01/03/2019 Sachin B remove the condition for the d.CURR_QTY >0     
  -- 01/15/2019 Sachin B remove the condition OPENCLOS<>'closed'       
  WHERE d.DEPT_ID = @wcName AND w.OPENCLOS<>'cancel' AND w.WONO =@wono AND d.NUMBER = @number  --and d.CURR_QTY >0 --AND w.OPENCLOS<>'closed'      
  ) As a        
        
SELECT * INTO #TEMP1 FROM #TEMP t2 LEFT OUTER JOIN        
(        
 SELECT CONVERT(INT,min(k.allocatedQty/NULLIF(QTY, 0))) AS BuildQty        
 ,CASE         
 WHEN Max(ISNULL((ISNULL(w.bldqty,0) * ISNULL(k.qty,0))- ISNULL(k.act_qty,0) - ISNULL(k.allocatedQty,0),0)) > 0 THEN CAST(0 AS BIT)        
 ELSE CAST(1 AS BIT)        
 END AS IsCheckList,        
 k.wono AS WonoNumber  FROM KAMAIN k        
 INNER JOIN woentry w ON k.wono =w.wono        
 GROUP BY k.wono        
)b        
ON b.WonoNumber = t2.Wono        
        
-- 08/22/2017 Sachin b Use DEPTKEY in Select Statements        
SELECT RowNum, t1.SERIALSTRT,KITCOMPLETE,[Priority],[Description],UniqKey,dbo.fRemoveLeadingZeros(t1.Wono) AS Wono,Revision,PartNo,PartNoWithRev,WoQty,BALANCE,WoDueDate,SERIALYES,        
LOTDETAIL,WcDueDate,[Status],CUSTNAME,t1.UNIQUEREC,Assigned,t1.equipment,ProcessTime,TotalTime,WcQty,WoProcessTime,AUTODT,FGIEXPDAYS,SetupTime,ORDMULT,UseIpKey,t1.NUMBER,ITAR,        
-- 02/13/2018 Sachin B Add Uniquerout,WrkInstChk,EquipmentChk,ToolsChk in select Statement        
OutSourced,BuildQty,d.DEPTKEY,t1.TemplateID,t1.TemplateName,t1.Uniquerout,WrkInstChk AS WKInstCheck,EquipmentChk AS EquipmentCheck,ToolsChk AS ToolsCheck        
,CAST(ISNULL(IsCheckList,0) AS BIT) AS IsCheckList  
-- 04/24/2019 Sachin B Add Dept_ID In the Select Statement         
,count(j.JBSHPCHKUK)  AS PDMCount,d.DEPT_ID as DeptId ,KitStatus       
FROM #TEMP1 t1        
-- 04/05/2017 Sachin b Remove leading Zeros of work order at last select statement for increase performance because it calls every Time        
INNER JOIN DEPT_QTY d ON t1.Wono = d.WONO and t1.NUMBER =d.NUMBER        
LEFT OUTER JOIN JBSHPCHK j ON j.WONO = d.WONO AND j.DEPTKEY =d.DEPTKEY AND j.isMnxCheck =1 AND j.CHKFLAG =1        
GROUP BY RowNum,t1.SERIALSTRT,KITCOMPLETE,[Priority],[Description],UniqKey,t1.Wono,Revision,PartNo,PartNoWithRev,WoQty,BALANCE,WoDueDate,SERIALYES,LOTDETAIL,WcDueDate,  
[Status],CUSTNAME,t1.UNIQUEREC,Assigned,t1.equipment,ProcessTime,TotalTime,WcQty,WoProcessTime,AUTODT,FGIEXPDAYS,SetupTime,ORDMULT,UseIpKey,t1.NUMBER,ITAR,OutSourced,BuildQty,  
d.DEPTKEY,IsCheckList,t1.TemplateID,t1.TemplateName,t1.Uniquerout,WrkInstChk,EquipmentChk,ToolsChk,d.DEPT_ID ,KitStatus       
        
END 