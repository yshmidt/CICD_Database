-- =============================================
-- Author:	Anuj K
-- Create date: 05/13/2016
-- Description:	this procedure will be called from the SF module and Pull the working work orders for provided work center
-- 09/21/2016 Sachin b remove qty  perpackage from MfgrMaster get it from inventor table ORDMULT column
-- 12/22/2016 Sachin b Add ITAR Column Remove Commented Code
-- 01/09/16 Sachin b Add INOUTSVS Column as OutSourced
-- 01/12/16 Sachin b Add Conditions for Check the CheckList is checked or not
-- 02/09/16 Sachin b Add column WOSerialStartNumber for get the Number of department WHERE it become serialized
-- 03/29/2017 Sachin b Remove leading Zeros of work order at last select statement for increase performance because it calls every Time
-- 07/14/2017 Sachin b Combind class,type with description
-- 11/22/2017 Sachin B Apply Code Review Comments
-- 02/13/2018 Sachin B Add Uniquerout,WrkInstChk,EquipmentChk,ToolsChk in select Statement
-- 04/25/2018 Sachin B Add Column WonoWithZero for Fix WC Summary Grid Shorting Issue
-- 09/08/2018 Sachin B Fix the Issue for the Calculation of runtime and Setup time
-- 11/16/2018 Sachin B Add d.DEPT_ID DeptId,d.DEPTKEY in the Select Statement
-- 11/16/2018 Sachin B ReName Column WcDueDate WcDueOut
-- 01/14/2019 Sachin B Get PART_CLASS,PART_TYPE from inventor table
-- 06/02/2020 Sachin B : Add KIT Column in the select statement
-- 08/27/2020 Sachin B : Add ECStatus in the Select statement
-- 09/15/2020 Sachin B Added OpenClose in the select statement
-- 10/26/2020 Sachin B : Added the Condition for the Daviation for ECO Status 
-- 11/05/2020 Sachin B : Added the Condition ec.ECSTATUS in ('Approved','Approved Internally') in join for remove duplicate records
---12/03/20 YS added Act_qty to claculate Buildable
--- 12/04/20 YS one more change to get minimum between calculated buldable and Woentry.bldQTy, Otherwise we can build more than we need if over-allocated 
--   21/12/20 DT added new fields isMSL,isMSlLate, isMSStarted and isMslStartedAndStopped
--- this sp is called in the landing screen of the MOC module
-- GetWorkOrderSummaryByDepartment 'STAG',1,3000,'WonoWithZero asc',''
-- =============================================
CREATE PROCEDURE [dbo].[GetWorkOrderSummaryByDepartment] 
 @wcName CHAR(10), 
 @StartRecord INT,
 @EndRecord INT, 
 @SortExpression CHAR(1000) = null,
 @Filter NVARCHAR(1000) = null
As
DECLARE @SQL NVARCHAR(max)
BEGIN

SET NOCOUNT ON; 

IF OBJECT_ID('dbo.#TEMP', 'U') IS NOT NULL      
DROP TABLE dbo.#TEMP;

IF OBJECT_ID('dbo.#TEMP1', 'U') IS NOT NULL      
DROP TABLE dbo.#TEMP1;

IF OBJECT_ID('dbo.#TEMP2', 'U') IS NOT NULL      
DROP TABLE dbo.#TEMP2;

IF OBJECT_ID('dbo.#TEMP3', 'U') IS NOT NULL      
DROP TABLE dbo.#TEMP3;

SELECT * 
INTO #TEMP
from
(   
  SELECT DISTINCT
	 ROW_NUMBER() OVER (ORDER BY 
	    CASE COALESCE(NULLIF(d.DEPT_PRI,0), 0) 
		When 0 then COALESCE(NULLIF(pd.SLACKPRI,0), 0) 
		ELSE d.DEPT_PRI END,
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
	-- 03/29/2017 Sachin b Remove leading Zeros of work order at last select statement for increase performance because it calls every Time
	-- 07/14/2017 Sachin b Combind class,type with description
	-- 01/14/2019 Sachin B Get PART_CLASS,PART_TYPE from inventor table
    ELSE d.DEPT_PRI End AS [Priority], inv.PART_CLASS+' / '+inv.PART_TYPE+' / '+ inv.DESCRIPT AS [Description], w.UNIQ_KEY AS UniqKey, w.WONO, inv.Revision, inv.part_no AS PartNo,
  CASE COALESCE(NULLIF(inv.REVISION,''), '')
	WHEN '' THEN  LTRIM(RTRIM(inv.PART_NO)) 
	ELSE LTRIM(RTRIM(inv.PART_NO)) + '/' + inv.REVISION 
	END AS PartNoWithRev, (w.COMPLETE + w.BALANCE) AS WoQty , 
	-- 11/16/2018 Sachin B ReName Column WcDueDate WcDueOut
	w.BALANCE , w.DUE_DATE AS WoDueDate, inv.SERIALYES, pt.LOTDETAIL, d.DUEOUTDT AS WcDueOut, d.SCHED_STAT AS [Status],
  c.CUSTNAME, d.UNIQUEREC, d.operator AS Assigned, d.equipment , 
  -- 09/08/2018 Sachin B Fix the Issue for the Calculation of runtime and Setup time
  CASE WHEN d.NUMBER<=2 THEN [dbo].[GetTimeInHoursAndMinByTimeInSeconds](((q.RUNTIMESEC * w.BLDQTY )))      
	   ELSE [dbo].[GetTimeInHoursAndMinByTimeInSeconds](((q.RUNTIMESEC * d.CURR_QTY)))
       END AS 'ProcessTime',
  CASE WHEN d.NUMBER<=2 THEN [dbo].[GetTimeInHoursAndMinByTimeInSeconds](((q.RUNTIMESEC * w.BLDQTY )+q.SETUPSEC ))      
	   ELSE [dbo].[GetTimeInHoursAndMinByTimeInSeconds](((q.RUNTIMESEC * d.CURR_QTY)+q.SETUPSEC))
       END AS 'TotalTime',
  d.CURR_QTY AS WcQty, pd.PROCESSTM AS WoProcessTime, pt.AUTODT , pt.FGIEXPDAYS,
  [dbo].[GetTimeInHoursAndMinByTimeInSeconds](q.SETUPSEC) AS 'SetupTime',
  --- 09/21/16 Sachin b remove qty  perpackage from MfgrMaster get it from inventor table ORDMULT column
  CASE COALESCE(NULLIF(inv.ORDMULT,0), 0) 
  WHEN 0 then 1 
  ELSE inv.ORDMULT END AS 'ORDMULT',  
  inv.useipkey AS 'UseIpKey',
  d.NUMBER,
  -- 12/22/16 Sachin b Add ITAR Column
  inv.ITAR,
  -- 01/09/16 Sachin b Add INOUTSVS Column as OutSourced
  CASE
       WHEN dep.INOUTSVS = 'O' THEN CAST(1 AS BIT)
	   WHEN dep.INOUTSVS = 'I' THEN CAST(0 AS BIT)
      END AS OutSourced
  -- 01/12/16 Sachin b Add Conditions for Check the CheckList is checked or not
  -- 02/13/2018 Sachin B Add Uniquerout,WrkInstChk,EquipmentChk,ToolsChk in select Statement
  -- 06/02/2020 Sachin B : Add KIT Column in the select statement
  -- 09/15/2020 Sachin B Added OpenClose in the select statement
  ,bldqty,w.uniquerout,WrkInstChk,EquipmentChk,ToolsChk,KIT,w.OPENCLOS AS OpenClose,
  --- 10/22/20 YS add indicator if parts with MSL level are set
  CASE WHEN t.wono is null then 0 else 1 end as IsMsl,
    --- 11/02/20 DT added field IsMslLate for showing late msl field
   (
	  SELECT COUNT(1)
	  FROM MSLLOGS MSLO
	  LEFT JOIN MNXMSLLevel MNSL ON MSLO.MSL=MNSL.MSL
	  WHERE dbo.fRemoveLeadingZeros(MSLO.Wono)=dbo.fRemoveLeadingZeros(t.wono)
	  AND MSLO.StartTime IS NOT NULL
	  AND MSLO.StopTime IS NULL
	  AND DATEADD(HOUR,MNSL.Hours,MSLO.StartTime)<=GETDATE()
	  AND MNSL.Hours!=0
  ) AS IsMSLLate,
  --- 02/11/20 DT added field IsMSLStarted for showing started msl field
  (
	  SELECT COUNT(1)
	  FROM MSLLOGS MSLO
	  WHERE dbo.fRemoveLeadingZeros(MSLO.Wono)=dbo.fRemoveLeadingZeros(t.wono)
	  AND MSLO.StartTime IS NOT NULL
	  AND MSLO.StopTime IS NULL
  ) AS IsMSLStarted,
    --- 03/11/20 DT added field IsMSLStarted for showing started and stopped msl field
  (
	  SELECT COUNT(1)
	  FROM MSLLOGS MSLO
	  WHERE dbo.fRemoveLeadingZeros(MSLO.Wono)=dbo.fRemoveLeadingZeros(t.wono)
	  AND MSLO.StartTime IS NOT NULL
	  AND MSLO.StopTime IS NOT NULL
  ) AS IsMSLStartedAndStopped
  FROM WOENTRY w 
  LEFT OUTER JOIN DEPT_QTY d ON w.WONO = d.WONO
  LEFT OUTER JOIN Depts dep ON d.DEPT_ID =dep.DEPT_ID
  LEFT OUTER JOIN QuotDept q ON q.UNIQNUMBER = d.DEPTKEY 
  LEFT OUTER JOIN Inventor inv ON inv.UNIQ_KEY = w.UNIQ_KEY
  -- 09/21/16 Sachin b remove qty  perpackage from MfgrMaster get it from inventor table ORDMULT column
  --left outer join InvtMPNLink mp ON mp.uniq_key = inv.UNIQ_KEY
  --left outer join MfgrMaster mf ON mf.MfgrMasterId =mp.MfgrMasterId
  LEFT OUTER JOIN PARTTYPE pt ON pt.PART_CLASS = inv.PART_CLASS AND pt.PART_TYPE = inv.PART_TYPE
  LEFT OUTER JOIN Customer c ON c.CUSTNO = w.CUSTNO
  LEFT OUTER JOIN PROD_DTS pd ON pd.WONO = w.WONO
   ---10/22/20 YS  check if any parts with MSL
  OUTER APPLY
  ( select distinct r.wono
	from iReserveIpKey IR left outer join iReserveIpKey IU on ir.ipkeyunique=iu.ipkeyunique and ir.KaSeqnum=iu.KaSeqnum and iu.qtyAllocated<0
	inner join invt_res r on ir.invtres_no=r.INVTRES_NO
	inner join invtmfgr q on r.W_KEY=q.W_KEY
	inner join InvtMPNLink l on q.UNIQMFGRHD=l.uniqmfgrhd
	inner join MfgrMaster m on l.MfgrMasterId=m.MfgrMasterId
	where r.wono=w.wono and m.MOISTURE<>'' and ir.qtyAllocated>0 and
	exists (select 1 from kamain where wono=r.wono and DEPT_ID=@wcName and kamain.KASEQNUM=ir.KaSeqnum)
	group by r.wono,ir.qtyAllocated
	HAVING ir.qtyAllocated-isnull(sum(iu.qtyallocated),0.00) >0) T
  WHERE d.DEPT_ID = @wcName AND w.OPENCLOS<>'closed' AND w.OPENCLOS<>'cancel' AND d.CURR_QTY >0
  ) As a

-- 02/09/16 Sachin b Add column WOSerialStartNumber for get the Number of department WHERE it become serialized
  SELECT * INTO #TEMP1 FROM #TEMP t2 LEFT OUTER JOIN
(
	SELECT ISNULL(dep.NUMBER,0) AS WOSerialStartNumber,
	-- 03/29/2017 Sachin b Remove leading Zeros of work order at last select statement for increase performance because it calls every Time
	w.wono AS WonoNumber FROM woentry w
	LEFT OUTER JOIN DEPT_QTY dep ON dep.WONO =w.WONO AND dep.SERIALSTRT =1
	WHERE w.OPENCLOS<>'closed' AND w.OPENCLOS<>'cancel'
)b
ON b.WonoNumber = t2.Wono

  --Because it need one select statement after the temp table creation 
  SELECT * INTO #TEMP2 from #TEMP1 t2 LEFT OUTER JOIN
(
--- 12/03/20 YS added Act_qty to claculate Buildable
--- 12/04/20 YS one more change to get minimum between calculated buldable and Woentry.bldQTy, Otherwise we can build more than we need if over-allocated 
	--SELECT CONVERT(INT,min((k.allocatedQty+K.Act_qty)/NULLIF(QTY, 0))) AS BuildQty
	SELECT CASE WHEN CONVERT(INT,min((k.allocatedQty+K.Act_qty)/NULLIF(QTY, 0))) <=w.bldqty then
	CONVERT(INT,min((k.allocatedQty+K.Act_qty)/NULLIF(QTY, 0))) 
	ELSE CONVERT(INT,w.BldQty) END
	AS BuildQty
	-- 01/12/16 Sachin b Add Conditions for Check the CheckList is checked or not
	,CASE 
	WHEN Max(ISNULL((ISNULL(w.bldqty,0) * ISNULL(k.qty,0))- ISNULL(k.act_qty,0) - ISNULL(k.allocatedQty,0),0)) > 0 
	THEN CAST(0 AS BIT)
	ELSE CAST(1 AS BIT)
	END AS IsCheckList,
	-- 03/29/2017 Sachin b Remove leading Zeros of work order at last select statement for increase performance because it calls every Time
	k.wono AS WoNumber  FROM KAMAIN k
	INNER JOIN woentry w ON k.wono =w.wono
	WHERE w.OPENCLOS<>'closed' AND w.OPENCLOS<>'cancel'
	---12/04/20 YS added w.bldqty to the groupby
	GROUP BY k.wono,w.bldqty
)b
ON b.WoNumber = t2.Wono

-- 01/12/16 Sachin b Add Conditions for Check the CheckList is checked or not
-- 04/25/2018 Sachin B Add Column WonoWithZero for Fix WC Summary Grid Shorting Issue
-- 06/02/2020 Sachin B : Add KIT Column in the select statement
SELECT RowNum, t1.SERIALSTRT,KITCOMPLETE,[Priority],[Description],UniqKey,dbo.fRemoveLeadingZeros(t1.Wono) AS Wono,t1.Wono AS WonoWithZero,Revision,PartNo,PartNoWithRev,WoQty,BALANCE,WoDueDate,SERIALYES,
LOTDETAIL,WcDueOut,[Status],CUSTNAME,t1.UNIQUEREC,Assigned,t1.equipment,ProcessTime,TotalTime,WcQty,WoProcessTime,AUTODT,FGIEXPDAYS,SetupTime,ORDMULT,UseIpKey,t1.NUMBER,ITAR,
-- 11/16/2018 Sachin B Add d.DEPT_ID DeptId,d.DEPTKEY in the Select Statement
OutSourced,BuildQty,d.DEPT_ID DeptId,d.DEPTKEY
,CAST(ISNULL(IsCheckList,0) AS BIT) AS IsCheckList 
-- 02/13/2018 Sachin B Add Uniquerout,WrkInstChk,EquipmentChk,ToolsChk in select Statement
,COUNT(j.JBSHPCHKUK)  AS PDMCount,ISNULL(WOSerialStartNumber,0) AS WOSerialStartNumber,t1.uniquerout,WrkInstChk as WKInstCheck,EquipmentChk as EquipmentCheck,
-- 08/27/2020 Sachin B : Add ECStatus in the Select statement
ToolsChk as ToolsCheck,KIT
,--ec.ECSTATUS 
CASE WHEN ec.ECSTATUS IS NULL THEN ''
     WHEN ec.ECSTATUS IN ('Approved','Approved Internally') AND TRIM(ec.CHANGETYPE)='ECO' THEN ec.ECSTATUS  --'ECO Pending'
	 -- 10/26/2020 Sachin B : Added the Condition for the Daviation for ECO Status 
	 WHEN ec.ECSTATUS IN ('Approved','Approved Internally') AND trim(ec.CHANGETYPE)='DEVIATION' AND ec.EFFECTIVEDT <= GETDATE() AND ec.EXPDATE > GETDATE() THEN ec.ECSTATUS
	 ELSE '' END AS ECOStatus,OpenClose,
	 -- 23/12/2020 DT added field isMSL,isMSLLate,IsMSLStarted,IsMSLStartedAndStopped
	 CAST(IsMsl AS BIT) as IsMSL,CAST(case when IsMSLLate>0 then 1 else 0 end AS BIT) as IsMSLLate,CAST(case when IsMSLStarted>0 then 1 else 0 end AS BIT) as IsMSLStarted,CAST(case when IsMSLStartedAndStopped>0 then 1 else 0 end AS BIT) as IsMSLStartedAndStopped
INTO #TEMP3 FROM #TEMP2 t1
INNER JOIN DEPT_QTY d ON t1.Wono = d.WONO AND t1.NUMBER =d.NUMBER
-- 11/05/2020 Sachin B : Added the Condition ec.ECSTATUS in ('Approved','Approved Internally') in join for remove duplicate records
LEFT JOIN ECMAIN ec on t1.UniqKey =ec.UNIQ_KEY AND ec.ECSTATUS in ('Approved','Approved Internally')
LEFT OUTER JOIN JBSHPCHK j ON j.WONO = d.WONO AND j.DEPTKEY =d.DEPTKEY AND j.isMnxCheck =1 AND j.CHKFLAG =1
--WHERE ec.ECSTATUS in ('Approved','Approved Internally') OR ec.ECSTATUS is null
GROUP BY 
RowNum,t1.SERIALSTRT,KITCOMPLETE,[Priority],[Description],UniqKey,t1.Wono,Revision,PartNo,PartNoWithRev,WoQty,BALANCE,WoDueDate,SERIALYES,LOTDETAIL,WcDueOut,[Status],CUSTNAME,
t1.UNIQUEREC,Assigned,t1.equipment,ProcessTime,TotalTime,WcQty,WoProcessTime,AUTODT,FGIEXPDAYS,SetupTime,ORDMULT,UseIpKey,t1.NUMBER,ITAR,OutSourced,BuildQty,IsCheckList,
WOSerialStartNumber,t1.uniquerout,WrkInstChk,EquipmentChk,ToolsChk,d.DEPT_ID,d.DEPTKEY,KIT,ec.ECSTATUS,OpenClose,ec.CHANGETYPE,ec.EFFECTIVEDT,ec.EXPDATE,IsMsl,IsMSLStarted,IsMSLLate,IsMSLStartedAndStopped


IF @filter <> '' AND @sortExpression <> ''
  BEGIN
	SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY '+CONVERT(VARCHAR,@sortExpression)+') AS RowNumber,*  from #TEMP3 )
	select  t.* ,(SELECT COUNT(RowNumber) FROM CETTemp WHERE '+@filter+') AS TotalCount 
	from CETTemp  t  WHERE '+@filter+' AND
	RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)--+' ORDER BY '+ @SortExpression+''
   END
ELSE IF @filter = '' AND @sortExpression <> ''
   BEGIN
    SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY '+Convert(varchar,@sortExpression)+') AS RowNumber,*  from #TEMP3 )
	select  t.*,(SELECT COUNT(RowNumber) FROM CETTemp ) AS TotalCount from CETTemp  t  WHERE 
    RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)--+' ORDER BY '+ @sortExpression+''
   END
ELSE IF @filter <> '' AND @sortExpression = ''
   BEGIN
	SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY RowNum ASC) AS RowNumber,*  from #TEMP3 )
	select  t.* ,(SELECT COUNT(RowNumber) FROM CETTemp WHERE '+@filter+') AS TotalCount from CETTemp  t  WHERE  '+@filter+' AND
	RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+''
   END
ELSE
   BEGIN
	SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY RowNum ASC) AS RowNumber,*  from #TEMP3 )
	select  t.*,(SELECT COUNT(RowNumber) FROM CETTemp) AS TotalCount from CETTemp  t  WHERE 
	RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+''
   END

EXEC sp_executesql @SQL

END