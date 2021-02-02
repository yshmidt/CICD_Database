-- =============================================
-- Author:		Satish B
-- Create date: <03/14/2018>
-- Description:	Get work center details
-- 01-29-2020 : MaheshB Added the delete conditions which was giving the worng calculations in hours
-- 03-03-2020 : Rajendra K : Added new parameters start date & end date
-- [dbo].[GetWorkCenterData] '0000010200','_1LR0NALBN',1,500,0,'2020-02-02 01:00:00.000', '2020-03-03 01:00:00.000'
-- =============================================
CREATE PROCEDURE GetWorkCenterData
	@woNo CHAR(10)='',
	@uniqKey CHAR(10)='',
	@startRecord INT =1,
    @endRecord INT =10, 
	@outTotalNumberOfRecord INT OUTPUT,
	@startDate DATETIME = NULL,
	@endDate DATETIME = NULL
AS
BEGIN
	SET NOCOUNT ON
	SELECT COUNT(dl.WONO) AS RowCnt -- Get total counts 
			 INTO #tempWoCenterData
	FROM DEPTS d   
	INNER JOIN DEPT_LGT dl ON dl.DEPT_ID=d.DEPT_ID
	INNER JOIN WOENTRY w ON w.wono=dl.wono
	INNER JOIN INVENTOR i ON i.uniq_key=w.uniq_key
	WHERE 
	-- 03-03-2020 : Rajendra K : Added new parameters start date & end date
    ((((@startDate IS NULL AND 1=1) AND (@endDate IS NULL AND 1=1)) OR (@startDate IS NOT NULL AND  dl.originalDateIn >= CAST(@startDate AS DATETIME)))
	OR ((DATE_IN IS NULL AND DATE_OUT IS NULL) AND ( dl.LastUpdatedDate >= CAST(@startDate AS DATETIME) AND dl.LastUpdatedDate <=  CAST(@endDate AS DATETIME))))
    AND dl.WONO=@woNo 
    AND i.Uniq_Key=@uniqKey
	GROUP BY 
			i.UNIQ_KEY
			,dl.WONO
			,d.DEPT_ID
	
	SELECT  d.DEPT_ID AS WorkCenter 
		   ,i.uniq_Key AS UniqKey
		   ,dbo.fRemoveLeadingZeros(dl.WONO) AS WorkOrder
		   --,CAST((SUM(dl.TIME_USED/60))  AS NUMERIC(10,2)) AS Hours  
		   ,depHours.Hours
	FROM DEPTS d   
	INNER JOIN DEPT_LGT dl ON dl.DEPT_ID=d.DEPT_ID
	INNER JOIN WOENTRY w ON w.wono=dl.wono
	INNER JOIN INVENTOR i ON i.uniq_key=w.uniq_key
	INNER JOIN
    (
		 SELECT DEPT_ID,
			    SUM(CASE WHEN ModTimeUsed > 0 THEN CAST((ModTimeUsed /60)  AS NUMERIC(10,2))
		 			ELSE CAST((TIME_USED/60)  AS NUMERIC(10,2)) END) AS Hours
   		 FROM DEPT_LGT 
   		 WHERE WONO = @woNo
		 AND  uDeleted = 0    
		 AND  ((((@startDate IS NULL AND 1=1) AND (@endDate IS NULL AND 1=1)) OR ((@startDate IS NOT NULL AND  originalDateIn >= CAST(@startDate AS DATETIME)) AND 
			  (@endDate IS NOT NULL AND  originalDateIn <= CAST(@endDate AS DATETIME))))
			  OR ((DATE_IN IS NULL AND DATE_OUT IS NULL) AND (CAST(LastUpdatedDate AS DATE) >= CAST(@startDate AS DATE) AND CAST(LastUpdatedDate AS DATE) <= CAST(@endDate AS DATE))))      
		GROUP BY DEPT_ID
    ) depHours ON depHours.DEPT_ID =dl.DEPT_ID
	WHERE 
	-- 03-03-2020 : Rajendra K : Added new parameters start date & end date
	  ((((@startDate IS NULL AND 1=1) AND (@endDate IS NULL AND 1=1)) OR ((@startDate IS NOT NULL AND  originalDateIn >= CAST(@startDate AS DATETIME)) AND 
			  (@endDate IS NOT NULL AND  originalDateIn <= CAST(@endDate AS DATETIME))))
			 OR ((DATE_IN IS NULL AND DATE_OUT IS NULL) AND (CAST(LastUpdatedDate AS DATE) >= CAST(@startDate AS DATE) AND CAST(LastUpdatedDate AS DATE) <= CAST(@endDate AS DATE))))      
    AND dl.WONO=@woNo 
	AND i.Uniq_Key=@uniqKey 
	AND dl.uDeleted = 0 -- 01-29-2020 : MaheshB Added the delete conditions which was giving the worng calculations in hours
	GROUP BY 
			 i.UNIQ_KEY
			,dl.WONO
			,d.DEPT_ID
			,depHours.Hours
	ORDER BY d.DEPT_ID
	OFFSET(@startRecord-1) ROWS
	FETCH NEXT @EndRecord ROWS ONLY;

	SET @outTotalNumberOfRecord = (SELECT COUNT(RowCnt) FROM #tempWoCenterData)
END