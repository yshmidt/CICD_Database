-- =============================================
-- Author:		Rajendra K	
-- Create date: <07/26/2018>
-- Description:Get simulation data
-- Modification 
   -- Rajendra K 11/05/2018 : Converted script ot Dynamic SQL
   -- Rajendra K 11/05/2018 : Addded new section to get number of records
   -- Rajendra K 11/05/2018 : Added new param @sortExpression
   -- Rajendra K 06/14/2018 : Added new param @days   
   -- Rajendra K 06/14/2018 : Added condition for days difference > 0
-- EXEC GetSimulationGridData '',1,40,1,10000,'','' ,''
-- =============================================
CREATE PROCEDURE [dbo].[GetSimulationGridData]
(
@woNumber AS CHAR(10),
@isDueTwenty BIT = 0,
@days INT = 0,  -- Rajendra K 11/05/2018 : Added new param @days   
@startRecord INT =1,
@endRecord INT =10000,
@sortExpression NVARCHAR(200)= '', -- Rajendra K 11/05/2018 : Added new param @sortExpression
@Filter NVARCHAR(1000) = null,
@out_TotalNumberOfRecord INT OUTPUT 
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @sqlQuery NVARCHAR(MAX);
	
	-- Rajendra K 11/05/2018 : Added new param @sortExpression
	SET @sortExpression = CASE WHEN @sortExpression IS NULL OR @sortExpression = '' THEN 'WONO' ELSE @sortExpression END 

	--Add new section to get number of records
	SET @out_TotalNumberOfRecord = (SELECT COUNT(DISTINCT WONO) FROM 
		WOENTRY W INNER JOIN INVENTOR I ON W.UNIQ_KEY = I.UNIQ_KEY 
		INNER JOIN BOM_DET B ON B.BOMPARENT=I.UNIQ_KEY 		
    WHERE (@woNumber IS NULL OR @isDueTwenty=1) 		 
    AND OPENCLOS NOT IN('Admin Hold','Mfg Hold','Closed','Cancel')   
   -- AND W.BLDQTY>W.BALANCE    -- Rajendra K 06/14/2018 : Added condition for days difference > 0
    AND (@isDueTwenty = 0 OR (DATEDIFF(DAY,GETDATE(),DUE_DATE) <= @days) AND (DATEDIFF(DAY,GETDATE(),DUE_DATE) >= 0 )))    
	Print @out_TotalNumberOfRecord

    --Rajendra K 11/05/2018 : Converted script ot Dynamic SQL
	SET @sqlQuery = 'SELECT DISTINCT W.WONO
		  ,W.DUE_DATE AS DueDate 
		  ,RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '''' THEN I.REVISION ELSE ''/''+ I.REVISION END) AS PART_NO
		  ,(CASE WHEN I.PART_CLASS IS NULL OR  I.PART_CLASS = '''' THEN I.PART_CLASS ELSE I.PART_CLASS +''/ '' END ) + 
		  (CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='''' THEN I.PART_TYPE ELSE I.PART_TYPE + ''/ ''+I.DESCRIPT END) AS Descript
		  ,W.BLDQTY AS Quantity
		  ,0.0 AS BuildQty
		  ,W.UNIQ_KEY AS UniqKey
	--INTO #assemblyDetails 
	FROM 
		WOENTRY W INNER JOIN INVENTOR I ON W.UNIQ_KEY = I.UNIQ_KEY 
		INNER JOIN BOM_DET B ON B.BOMPARENT=I.UNIQ_KEY 
		
    WHERE '+(CASE WHEN @filter IS NULL OR @filter ='' THEN '1=1' ELSE @filter END )+''
	   
	     +' AND ('+ (CASE WHEN @woNumber IS NULL OR  @woNumber = ''  OR @isDueTwenty = 1 THEN '1=1' ELSE '1=0' END ) +')
    AND OPENCLOS NOT IN(''Admin Hold'',''Mfg Hold'',''Closed'',''Cancel'')   
   '+-- AND W.BLDQTY>W.BALANCE   
    +'AND ('+CAST(@isDueTwenty AS CHAR(1))+' = 0 OR ((DATEDIFF(DAY,GETDATE(),DUE_DATE) <= '+CONVERT(VARCHAR(10), @days)+ ') 
				AND (DATEDIFF(DAY,GETDATE(),DUE_DATE) >= '+CONVERT(VARCHAR(1),'0')+')))'    -- Rajendra K 06/14/2018 : Added condition for days difference > 0  
    + 'ORDER BY ' + @sortExpression + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord-1)   
				  + ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'

	EXEC sp_executesql @sqlQuery
END