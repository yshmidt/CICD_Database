-- =============================================  
-- Author: Shivshankar P  
-- Create date: <27/06/2017>  
-- Description: Get Usage History  
-- 02/07/2019 Rajendra k : Added three parameter as "@startRecord","@endRecord","@sortExpression"  
-- 02/07/2019 Rajendra k : Added Joins for getting Details of Reserved parts  
-- 02/07/2019 Nitesh B : Added joins for getting Details of issued parts  
-- 02/12/2019 Nitesh B : Added new colomn PONUM and @sortExpression = 'DATE asc'  
-- 02/15/2019 Nitesh B : Removed leading zeros ' dbo.fRemoveLeadingZeros(INVT_ISU.PONUM)'
-- GetUsageHistory '_1LR0NAL9P','01-01-2010 17:25:45','05-09-2019 17:25:45',1,300,'DATE desc'  
-- =============================================  
CREATE PROCEDURE [dbo].[GetUsageHistory]  
--declare  
 @Uniq_key CHAR(10) = '',  
 @DateStart AS SMALLDATETIME= null,  
 @DateEnd AS SMALLDATETIME = null,  
 @startRecord INT,-- 02/07/2019 Rajendra k : Added three parameter as "@startRecord","@endRecord","@sortExpression"  
 @endRecord INT,   
 @sortExpression NVARCHAR(1000) = null  
AS  
BEGIN   
  
SET NOCOUNT ON;    
 DECLARE @sqlQuery NVARCHAR(MAX);   
  
IF OBJECT_ID(N'tempdb..#TEMP') IS NOT NULL  
     DROP TABLE #TEMP ; -- 02/07/2019 Rajendra k : Added #Temp table   
  
 SET @sortExpression = CASE WHEN @sortExpression IS NULL OR @sortExpression = '' THEN 'DATE asc' ELSE @sortExpression END   
 -- 02/07/2019 Rajendra k : Added three parameter as "@sortExpression"  
  
 SELECT IDENTITY(INT,1,1) AS RowNumber,* INTO #TEMP FROM   -- 02/07/2019 Rajendra k : Added Joins for getting Details of Reserved parts  
 (SELECT DISTINCT CONCAT(WAREHOUS.WAREHOUSE,'/',INVTMFGR.LOCATION) AS WHLOC  
  ,MfgrMaster.PartMfgr  
  ,MfgrMaster.mfgr_pt_no  
  ,INVT_RES.LOTCODE  
  ,INVT_RES.EXPDATE  
  ,INVT_RES.REFERENCE AS datecode  
  ,dbo.fRemoveLeadingZeros(INVT_RES.PONUM) AS PONUM -- 02/12/2019 Nitesh B : Added new colomn PONUM and @sortExpression = 'DATE asc'  
													-- 02/15/2019 Nitesh B : Removed leading zeros ' dbo.fRemoveLeadingZeros(INVT_ISU.PONUM)'
  ,CAST(0 AS BIT)  AS IsIssue  
  ,CAST(1 AS BIT) AS IsReserve  
  ,CONCAT(CASE WHEN PJCTMAIN.PRJNUMBER IS NULL  THEN 'WO:' ELSE 'PJ:' END ,ISNULL(PJCTMAIN.PRJNUMBER,INVT_RES.WONO))  AS ISSUEDTO  
  ,RTRIM(LTRIM(WORecord.PART_NO)) + '/' + RTRIM(LTRIM(WORecord.REVISION)) AS PartRev
  ,DATETIME AS DATE  
  ,QTYALLOC AS QTYISU  
  ,KAMAIN.DEPT_ID AS WorkCenter
 FROM INVT_RES  
  JOIN INVTMFGR ON INVT_RES.W_KEY = INVTMFGR.W_KEY  
  JOIN WAREHOUS ON INVTMFGR.UNIQWH = WAREHOUS.UNIQWH AND INVTMFGR.UNIQ_KEY=INVT_RES.UNIQ_KEY  
  JOIN InvtMPNLink ON InvtMPNLink.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD  AND INVTMFGR.UNIQ_KEY=INVT_RES.UNIQ_KEY  
  JOIN MfgrMaster ON InvtMPNLink.MfgrMasterId = MfgrMaster.MfgrMasterId   
  JOIN INVENTOR ON  INVT_RES.UNIQ_KEY = INVENTOR.UNIQ_KEY  
  LEFT JOIN KAMAIN ON KAMAIN.UNIQ_KEY = INVT_RES.UNIQ_KEY AND KAMAIN.WONO = INVT_RES.WONO
  LEFT OUTER JOIN PJCTMAIN ON INVT_RES.FK_PRJUNIQUE =PJCTMAIN.PRJUNIQUE
  OUTER APPLY (   
	     SELECT INVENTOR.PART_NO , INVENTOR.REVISION    
       	 FROM WOENTRY 
		 INNER JOIN INVENTOR ON WOENTRY.UNIQ_KEY = INVENTOR.UNIQ_KEY
		 WHERE WOENTRY.WONO = INVT_RES.WONO     
		) AS WORecord 
 WHERE   INVT_RES.UNIQ_KEY = @Uniq_key AND DATETIME >= @DateStart and DATETIME < @DateEnd+1   
    
UNION  
 -- 02/07/2019 Nitesh B : Added joins for getting Details of issued parts  
 SELECT  DISTINCT CONCAT(WAREHOUS.WAREHOUSE,'/',INVTMFGR.LOCATION) AS WHLOC  
  ,MfgrMaster.PartMfgr  
  ,MfgrMaster.mfgr_pt_no  
  ,INVT_ISU.LOTCODE  
  ,INVT_ISU.EXPDATE  
  ,INVT_ISU.REFERENCE AS datecode  
  ,dbo.fRemoveLeadingZeros(INVT_ISU.PONUM) AS PONUM -- 02/12/2019 Nitesh B : Added new colomn PONUM and @sortExpression = 'DATE asc'  
													-- 02/15/2019 Nitesh B : Removed leading zeros ' dbo.fRemoveLeadingZeros(INVT_ISU.PONUM)'
  ,CAST(1 AS BIT) AS IsIssue  
  ,CAST(0 AS BIT) AS IsReserve  
  ,CASE WHEN INVT_ISU.ISSUEDTO IS NOT NULL  THEN   -- 02/08/2019 Rajendra k : Added case statment       
   CASE WHEN CHARINDEX('(WO:',INVT_ISU.ISSUEDTO) > 0 THEN REPLACE(INVT_ISU.ISSUEDTO, '(', '') ELSE   
   CASE WHEN CHARINDEX('REQ PKLST-',INVT_ISU.ISSUEDTO) > 0 THEN REPLACE(INVT_ISU.ISSUEDTO, 'REQ PKLST-', 'PL:') ELSE INVT_ISU.ISSUEDTO END  
   END   
   ELSE '' END  AS ISSUEDTO
  ,RTRIM(LTRIM(WORecord.PART_NO)) + '/' + RTRIM(LTRIM(WORecord.REVISION)) AS PartRev
  ,INVT_ISU.Date AS DATE  
  ,QTYIsu AS QTYISU   
  ,KAMAIN.DEPT_ID AS WorkCenter   
 FROM INVT_ISU  
  JOIN INVTMFGR ON INVT_ISU.W_KEY = INVTMFGR.W_KEY  
  JOIN WAREHOUS ON INVTMFGR.UNIQWH = WAREHOUS.UNIQWH AND INVTMFGR.UNIQ_KEY=INVT_ISU.UNIQ_KEY  
  JOIN InvtMPNLink ON InvtMPNLink.UNIQMFGRHD = INVTMFGR.UNIQMFGRHD  AND INVTMFGR.UNIQ_KEY=INVT_ISU.UNIQ_KEY  
  JOIN MfgrMaster ON InvtMPNLink.MfgrMasterId = MfgrMaster.MfgrMasterId   
  JOIN INVENTOR ON  INVT_ISU.UNIQ_KEY = INVENTOR.UNIQ_KEY 
  LEFT JOIN KAMAIN ON KAMAIN.UNIQ_KEY = INVT_ISU.UNIQ_KEY AND KAMAIN.WONO = INVT_ISU.WONO 
  OUTER APPLY (   
	     SELECT INVENTOR.PART_NO , INVENTOR.REVISION    
       	 FROM WOENTRY 
		 INNER JOIN INVENTOR ON WOENTRY.UNIQ_KEY = INVENTOR.UNIQ_KEY
		 WHERE WOENTRY.WONO = INVT_ISU.WONO     
		) AS WORecord  
  WHERE  INVT_ISU.UNIQ_KEY = @Uniq_key AND INVT_ISU.ISSUEDTO NOT LIKE '%FGI-WIP%' AND INVT_ISU.Date >= @DateStart AND INVT_ISU.Date < @DateEnd+1   
 ) t  
  
 SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalRowCntt from #TEMP  t ','',@sortExpression,'','',@startRecord,@endRecord))     
 EXEC sp_executesql @sqlQuery -- 02/07/2019 Rajendra k : Added Dynamic Query  
END   