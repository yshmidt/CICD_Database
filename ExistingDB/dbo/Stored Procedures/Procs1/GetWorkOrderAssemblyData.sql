-- =============================================            
-- Author:  Satish B            
-- Create date: <03/14/2018>            
-- Description: Get work order and assembly number            
-- 01-10-2020 : MaheshB :  Added parameters (@startDate, @endDate) for specific dates records should appear          
-- 01-29-2020 : MaheshB : Added the changes for make the calculation properly      
-- 03/04/2020 Rajendra K : Added new parameter @itar and added condition to get part on the basis of itar
-- [dbo].[GetWorkOrderAssemblyData] 1,500,0 , '2019-02-02 01:00:00.000', '2020-03-03 01:00:00.000' ,'','','00000000-0000-0000-0000-000000000000'        
-- =============================================            
CREATE PROCEDURE GetWorkOrderAssemblyData            
    @startRecord INT = 1,            
    @endRecord INT = 10,           
-- 01-10-2020 : MaheshB :  Added parameters for specific dates records should appear          
    @outTotalNumberOfRecord INT OUTPUT,            
    @startDate DATETIME = NULL,          
    @endDate DATETIME = NULL  ,        
    @assemblyUniqKey VARCHAR(100) = '',        
    @WONO VARCHAR(MAX) = '',        
    @userId UNIQUEIDENTIFIER = NULL,
	@itar BIT = 0   -- 03/04/2020 Rajendra K : Added new parameter @itar and added condition to get part on the basis of itar 
AS            
BEGIN            
 SET NOCOUNT ON            

     SELECT  ROW_NUMBER() OVER(ORDER BY d.WONO ASC) AS RowCnt,i.uniq_Key AS UniqKey            
     ,dbo.fRemoveLeadingZeros(d.WONO) AS WorkOrder            
     ,RTRIM(i.PART_NO) + CASE WHEN i.REVISION IS NULL OR i.REVISION='' THEN '' ELSE '/' END + i.REVISION AS AssemblyNumber            
	 ,ISNULL(depHours.Hours,0) Hours -- 01-29-2020 : MaheshB : Added the changes for make the calculation properly     
	 INTO #tempWoLogMainData 
     FROM DEPT_LGT d               
     INNER JOIN WOENTRY  w ON w.wono = d.wono            
     INNER JOIN INVENTOR i ON i.uniq_key = w.uniq_key        
     OUTER APPLY       
     (       
			SELECT SUM(CASE WHEN ModTimeUsed > 0 THEN CAST((ModTimeUsed /60)  AS NUMERIC(10,2))
							ELSE CAST((TIME_USED/60)  AS NUMERIC(10,2)) END) AS Hours        
		  FROM DEPT_LGT       
		  WHERE WONO = d.WONO 
				AND  ((((@startDate IS NULL AND 1=1) AND (@endDate IS NULL AND 1=1)) OR ((@startDate IS NOT NULL AND  originalDateIn >= CAST(@startDate AS DATETIME)) AND 
					 (@endDate IS NOT NULL AND originalDateIn <= CAST(@endDate AS DATETIME))))
					  OR ((DATE_IN IS NULL AND DATE_OUT IS NULL) AND (CAST(LastUpdatedDate AS DATE) >= CAST(@startDate AS DATE) AND CAST(LastUpdatedDate AS DATE) <= CAST(@endDate AS DATE))))      
				AND uDeleted = 0       
      ) AS depHours        
      -- 01-10-2020 : MaheshB :  Added parameters (@startDate, @endDate) for specific dates records should appear          
      WHERE          
      --(((@startDate IS NULL AND 1=1) AND (@endDate IS NULL AND 1=1)) OR (@startDate IS NOT NULL AND  d.originalDateIn >= CAST(@startDate AS DATETIME)       
      --AND d.originalDateIn <= CAST(DATEADD(DAY, 1, @endDate) AS DATETIME))) 
	    ((((@startDate IS NULL AND 1=1) AND (@endDate IS NULL AND 1=1)) OR ((@startDate IS NOT NULL AND  originalDateIn >= CAST(@startDate AS DATETIME)) AND 
		 (@endDate IS NOT NULL AND originalDateIn <= CAST(@endDate AS DATETIME))))
		 OR ((DATE_IN IS NULL AND DATE_OUT IS NULL) AND (CAST(LastUpdatedDate AS DATE) >= CAST(@startDate AS DATE) AND CAST(LastUpdatedDate AS DATE) <= CAST(@endDate AS DATE))))         
      AND  ((ISNULL(@assemblyUniqKey,'') = '' AND 1=1) OR (ISNULL(@assemblyUniqKey,'') <>'' AND i.UNIQ_KEY = @assemblyUniqKey ))        
      AND  ((ISNULL(@WONO,'') = ''  AND 1=1) OR (ISNULL(@WONO,'') <> '' AND w.WONO LIKE '%' + @WONO + '%')) --(TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR, @WONO),10)))))        
      AND  (((SELECT CAST(CAST(0 AS BINARY) AS UNIQUEIDENTIFIER)) = @userId AND 1=1) OR ((SELECT CAST(CAST(0 AS BINARY) AS UNIQUEIDENTIFIER)) <> @userId AND d.inUserId = @userId ))        
      AND  d.uDeleted = 0  
	  AND ((@itar = 1 AND 1=1) OR (@itar= 0 AND ITAR = 0)) -- 03/04/2020 Rajendra K : Added new parameter @itar and added condition to get part on the basis of itar     
    GROUP BY             
     i.UNIQ_KEY            
    ,d.WONO            
    ,i.PART_NO            
    ,i.REVISION       
    ,depHours.Hours        
           
    ORDER BY d.WONO ASC             
    OFFSET(@startRecord-1) ROWS            
    FETCH NEXT @EndRecord ROWS ONLY;            
    SELECT * FROM #tempWoLogMainData

    SET @outTotalNumberOfRecord = (SELECT MAX(RowCnt) FROM #tempWoLogMainData)            
END 