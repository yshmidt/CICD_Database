-- =============================================
-- Author:	Sachin B
-- Create date: 11/15/2017
-- Description:	this procedure will be called from the SF module for getting WO List for Quick Transfer
-- GetWOListForQuickTransfer 'STAG'
-- 12/14/2017 Sachin B Remove Unused Temp Table TEMP3 and Also Update Query for get the WO which having serial items in his Center by adding join with invtser table
-- 05/03/2017 Sachin B @wcName Parameter length from 10 to 4
-- =============================================
CREATE PROCEDURE GetWOListForQuickTransfer
 @wcName CHAR(4)

As
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
		ELSE d.DEPT_PRI End AS [Priority], pt.PART_CLASS+' / '+pt.PART_TYPE+' / '+ inv.DESCRIPT AS [Description], w.UNIQ_KEY AS UniqKey, w.WONO, inv.Revision, inv.part_no AS PartNo,
	  CASE COALESCE(NULLIF(inv.REVISION,''), '')
		WHEN '' THEN  LTRIM(RTRIM(inv.PART_NO)) 
		ELSE LTRIM(RTRIM(inv.PART_NO)) + '/' + inv.REVISION 
		END AS PartNoWithRev, (w.COMPLETE + w.BALANCE) AS WoQty , 
		w.BALANCE , w.DUE_DATE AS WoDueDate, inv.SERIALYES, pt.LOTDETAIL, d.DUEOUTDT AS WcDueDate, d.SCHED_STAT AS [Status],
	  c.CUSTNAME, d.UNIQUEREC, d.operator AS Assigned, d.equipment , 
	  CASE WHEN d.NUMBER<=2 THEN [dbo].[GetTimeInHoursAndMinByTimeInSeconds](((q.RUNTIMESEC * w.BLDQTY ))/60)      
		   ELSE [dbo].[GetTimeInHoursAndMinByTimeInSeconds](((q.RUNTIMESEC * d.CURR_QTY))/60)
		   END AS 'ProcessTime',
	  CASE WHEN d.NUMBER<=2 THEN [dbo].[GetTimeInHoursAndMinByTimeInSeconds](((q.RUNTIMESEC * w.BLDQTY )+q.SETUPSEC )/60)      
		   ELSE [dbo].[GetTimeInHoursAndMinByTimeInSeconds](((q.RUNTIMESEC * d.CURR_QTY)+q.SETUPSEC)/60)
		   END AS 'TotalTime',
	  d.CURR_QTY AS WcQty, pd.PROCESSTM AS WoProcessTime, pt.AUTODT , pt.FGIEXPDAYS,
	  [dbo].[GetTimeInHoursAndMinByTimeInSeconds](q.SETUPSEC/60) AS 'SetupTime',
	  CASE COALESCE(NULLIF(inv.ORDMULT,0), 0) 
	  WHEN 0 then 1 
	  ELSE inv.ORDMULT END AS 'ORDMULT',  
	  inv.useipkey AS 'UseIpKey',
	  d.NUMBER,
	  inv.ITAR,
	  CASE
		   WHEN dep.INOUTSVS = 'O' THEN CAST(1 AS BIT)
		   WHEN dep.INOUTSVS = 'I' THEN CAST(0 AS BIT)
		  END AS OutSourced
	  ,bldqty
	  FROM WOENTRY w 
	  LEFT OUTER JOIN DEPT_QTY d ON w.WONO = d.WONO
	  LEFT OUTER JOIN Depts dep ON d.DEPT_ID =dep.DEPT_ID
	  LEFT OUTER JOIN QuotDept q ON q.UNIQNUMBER = d.DEPTKEY 
	  LEFT OUTER JOIN Inventor inv ON inv.UNIQ_KEY = w.UNIQ_KEY
	  LEFT OUTER JOIN PARTTYPE pt ON pt.PART_CLASS = inv.PART_CLASS AND pt.PART_TYPE = inv.PART_TYPE
	  LEFT OUTER JOIN Customer c ON c.CUSTNO = w.CUSTNO
	  LEFT OUTER JOIN PROD_DTS pd ON pd.WONO = w.WONO
	  WHERE d.DEPT_ID = @wcName AND w.OPENCLOS<>'closed' AND w.OPENCLOS<>'cancel' AND d.CURR_QTY >0
	  ) As a

	 -- Select * from #TEMP

	SELECT * INTO #TEMP1 FROM #TEMP t2 LEFT OUTER JOIN
	(
		SELECT ISNULL(dep.NUMBER,0) AS WOSerialStartNumber,w.wono AS WonoNumber 
		FROM woentry w
		INNER JOIN DEPT_QTY dep ON dep.WONO =w.WONO AND dep.SERIALSTRT =1
		WHERE w.OPENCLOS<>'closed' AND w.OPENCLOS<>'cancel'
	)b
	ON b.WonoNumber = t2.Wono

	SELECT RowNum, t1.SERIALSTRT,KITCOMPLETE,[Priority],[Description],UniqKey,t1.Wono,Revision,PartNo,PartNoWithRev,WoQty,BALANCE,WoDueDate,SERIALYES,
	LOTDETAIL,WcDueDate,[Status],CUSTNAME,t1.UNIQUEREC,Assigned,t1.equipment,ProcessTime,TotalTime,WcQty,WoProcessTime,AUTODT,FGIEXPDAYS,SetupTime,ORDMULT,UseIpKey,t1.NUMBER,ITAR,
	OutSourced,
	COUNT(j.JBSHPCHKUK)  AS PDMCount,ISNULL(WOSerialStartNumber,0) AS WOSerialStartNumber
	,d.DEPT_ID as FromWC,d.DEPTKEY as FromDeptKey
	INTO #TEMP2 
	FROM #TEMP1 t1 
	INNER JOIN DEPT_QTY d ON t1.Wono = d.WONO AND t1.NUMBER =d.NUMBER
	-- 12/14/2017 Sachin B Remove Unused Temp Table TEMP3 and Also Update Query for get the WO which having serial items in his Center by adding join with invtser table
	Inner join INVTSER ser on d.DEPTKEY =ser.ID_VALUE and ID_KEY ='DEPTKEY'  and t1.Wono = ser.WONO
	LEFT OUTER JOIN JBSHPCHK j ON j.WONO = d.WONO AND j.DEPTKEY =d.DEPTKEY AND j.isMnxCheck =1 AND j.CHKFLAG =1
	WHERE WOSerialStartNumber is not null
	GROUP BY RowNum,t1.SERIALSTRT,KITCOMPLETE,[Priority],[Description],UniqKey,t1.Wono,Revision,PartNo,PartNoWithRev,WoQty,BALANCE,WoDueDate,SERIALYES,LOTDETAIL,WcDueDate,[Status],
	CUSTNAME,t1.UNIQUEREC,Assigned,t1.equipment,ProcessTime,TotalTime,WcQty,WoProcessTime,AUTODT,FGIEXPDAYS,SetupTime,ORDMULT,UseIpKey,t1.NUMBER,ITAR,OutSourced,--BuildQty,IsCheckList,
	WOSerialStartNumber,d.DEPT_ID,d.DEPTKEY 

	-- 11/17/2017 Sachin b Add code for the getting each WO next DeptId and apply Code review Comments
	SELECT RowNum, tempData.SERIALSTRT,KITCOMPLETE,[Priority],[Description],UniqKey,dbo.fRemoveLeadingZeros(tempData.Wono) AS Wono,Revision,PartNo,PartNoWithRev,WoQty,BALANCE,
	WoDueDate,SERIALYES,LOTDETAIL,WcDueDate,[Status],CUSTNAME,tempData.UNIQUEREC,Assigned,tempData.equipment,ProcessTime,TotalTime,WcQty,WoProcessTime,AUTODT,FGIEXPDAYS,SetupTime,
	ORDMULT,UseIpKey,tempData.NUMBER,ITAR,OutSourced,FromWC,FromDeptKey,d.DEPT_ID AS ToWC ,d.DEPTKEY as ToDeptKey
	FROM #TEMP2 tempData
	INNER JOIN DEPT_QTY d ON tempData.Wono = d.WONO AND tempData.NUMBER+1 =d.NUMBER
	WHERE LTRIM(RTRIM(d.DEPT_ID))<>'FGI'

END