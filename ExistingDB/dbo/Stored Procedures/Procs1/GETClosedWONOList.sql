-- =============================================
-- Author:		Rajendra K	
-- Create date: <09/28/2017>
-- Description:Get Work Order data
-- Modification
  -- 11/14/2017 Rajendra K : Modify paramter value as suitable for where condition and performance improvement
  -- 11/14/2017 Rajendra K : Added CompleteDate in select list
  -- 11/14/2017 Rajendra K : Set paramters in camel case 
  -- 11/14/2017 Rajendra K : Used Dynamic SQL for Sort and Pagination
  -- 11/14/2017 Rajendra K : Remove CTE and replace with temp table for results
  -- 11/14/2017 Rajendra K : Add new input paramter @status
  -- 11/14/2017 Rajendra K : Add new input paramter @sortExpression for dynamic sorting
  -- 04/03/2019 Rajendra K : If the KIT is never put in proocess, then should not be apper in kit close, filter out KitStauts=0 records.
  -- 06/02/2020 Sachin B : Add KIT Column in the select statement
  -- [dbo].[GETClosedWONOList] '','WORec','',1,1000,1
-- =============================================
CREATE PROCEDURE [dbo].[GETClosedWONOList]
(
@wONO VARCHAR(50) = '',
@status VARCHAR(30) = '', -- 11/14/2017 Rajendra K : Added paramter 
@sortExpression NVARCHAR(200)= '', -- 11/14/2017 Rajendra K :Added sortExpression
@startRecord int =1,
@endRecord int =10,
@rowCount INT OUT
)
AS
BEGIN
	SET NOCOUNT ON;	

	DECLARE @originalWoNo VARCHAR(10) = @wONO -- 11/11/2017 Rajendra K : Declare and set @originalWoNo 
	DECLARE @qryMain  NVARCHAR(2000);  -- -- 11/11/2017 Rajendra K : Declare @qryMain for Dynamic sql 

	--11/14/2017 Rajendra K : Set @wONO for Where condition
	SET @wONO = '%'+RTRIM(LTRIM(@wONO))+'%'

	--11/14/2017 Rajendra K : Set Default value to @sortExpression
	IF(@sortExpression = NULL OR @sortExpression = '')
	BEGIN
	SET @sortExpression = 'COMPLETEDT, WONO'
	END

	SELECT  COUNT(W.WONO) AS CountRecords -- Get total counts 
	INTO #tempWODetails 
	FROM WoEntry W
		   INNER JOIN Inventor I ON W.UNIQ_KEY = I.Uniq_Key
	       INNER JOIN CUSTOMER C ON W.CUSTNO = C.CUSTNO
		   LEFT JOIN kamain K ON W.WONO = K.WONO 		  
	WHERE  (@originalWoNo = NULL OR @originalWoNo = '' OR W.WONO LIKE @originalWoNo -- 11/11/2017 Rajendra K : Set % in set section --11/11/2017 Replace @searchKey with @originalSearchKey
			 OR I.PART_NO  LIKE @wONO -- 11/14/2017 Rajendra K : Removed white spaces initially in set parameter section 
		    OR RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE ' /'+ RTRIM(I.REVISION) END) LIKE @wONO -- 11/14/2017 Rajendra K : Removed white spaces initially in set parameter section 
			)
			AND W.OPENCLOS ='Closed' AND W.KITSTATUS <> 'KIT CLOSED' AND  W.KITSTATUS <> ''   
      -- 04/03/2019 Rajendra K : If the KIT is never put in proocess, then should not be apper in kit close, filter out KitStauts=0 records.		
	GROUP BY  
	        W.WONO
		   ,I.UNIQ_KEY -- 07/14/2017 Rajendra K : Added to get BOMParent for BOMNote
		   ,Bldqty
		   ,I.PART_NO + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) 
		   ,(CASE WHEN I.PART_CLASS IS NULL OR  I.PART_CLASS = '' THEN I.PART_CLASS ELSE I.PART_CLASS +'/ ' END ) + 
		    (CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='' THEN I.PART_TYPE ELSE I.PART_TYPE + '/ '+I.DESCRIPT END)
		   ,W.COMPLETEDT
		   ,I.ITAR
		   ,I.Revision
		   ,I.Part_No
		   ,C.CUSTNAME
		   ,W.KITSTATUS
		   ,W.OPENCLOS
		   ,I.Part_Sourc
		   -- 06/02/2020 Sachin B : Add KIT Column in the select statement
		   ,W.KIT
	SELECT DISTINCT CAST(dbo.fremoveLeadingZeros(W.WONO) AS VARCHAR(MAX)) AS WONO
				  ,CAST(dbo.fremoveLeadingZeros(W.WONO) AS VARCHAR(MAX)) AS WorkOrderNumber
		   ,I.UNIQ_KEY -- Added to get BOMParent for BOMNote		   
		   ,W.DUE_DATE AS DueDate
		   ,I.ITAR 
		   ,'' AS DPAS
		   ,W.BLDQTY AS Bldqty
		   ,I.PART_NO + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) AS PartRevision
		   ,(CASE WHEN I.PART_CLASS IS NULL OR  I.PART_CLASS = '' THEN I.PART_CLASS ELSE I.PART_CLASS +'/ ' END ) + 
		    (CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='' THEN I.PART_TYPE ELSE I.PART_TYPE + '/ '+I.DESCRIPT END) AS Description
		   ,C.CUSTNAME AS CustName
		   ,COUNT(DISTINCT k.KASEQNUM) AS TotalBomItems -- 09/28/2017 Rajendra K : Removed COUNT(B.UNIQ_KEY)
		   ,(CASE WHEN COALESCE(COUNT(k.KASEQNUM),0) > 0 THEN 'Yes' ELSE 'No' END) AS Released
		   ,W.KITSTATUS AS KitStatus
		   ,W.OPENCLOS AS OpenClose
		   ,I.Part_Sourc AS PartSourc
		   ,W.COMPLETEDT -- 09/28/2017 Rajendra : Added to Sort for @status Close
		   ,W.COMPLETEDT AS CompleteDate -- 11/14/2017 Rajendra K : Added CompleteDate
		   -- 06/02/2020 Sachin B : Add KIT Column in the select statement
		   ,W.KIT
    INTO #tempResult -- 11/14/2017 Rajendra K : Insert records into temp table
	FROM WoEntry W
		   INNER JOIN Inventor I ON W.UNIQ_KEY = I.Uniq_Key
	       INNER JOIN CUSTOMER C ON W.CUSTNO = C.CUSTNO
		   LEFT JOIN kamain K ON W.WONO = K.WONO 
		   --  09/28/2017 Rajendra K : Removed BOM_DET table from join condition and added in second CTE 
	WHERE  (@wONO = NULL OR @wONO = '' OR W.WONO LIKE @wONO -- 11/14/2017 Rajendra K : Removed white spaces initially in set parameter section 
			 OR I.PART_NO  LIKE @wONO -- 11/14/2017 Rajendra K : Removed white spaces initially in set parameter section 
		    OR RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE ' /'+ RTRIM(I.REVISION) END) LIKE @wONO -- 11/14/2017 Rajendra K : Removed white spaces initially in set parameter section 
			)
			AND W.OPENCLOS ='Closed' AND W.KITSTATUS <> 'KIT CLOSED'  AND  W.KITSTATUS <> '' -- Get closed kit   
      -- 04/03/2019 Rajendra K : If the KIT is never put in proocess, then should not be apper in kit close , filter out KitStauts=0 records.
	GROUP BY  
	        W.WONO 
		   ,I.UNIQ_KEY 
		   ,Bldqty
		   ,I.PART_NO + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) 
		   ,(CASE WHEN I.PART_CLASS IS NULL OR  I.PART_CLASS = '' THEN I.PART_CLASS ELSE I.PART_CLASS +'/ ' END ) + 
		    (CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='' THEN I.PART_TYPE ELSE I.PART_TYPE + '/ '+I.DESCRIPT END)
		   ,W.DUE_DATE
		   ,I.ITAR
		   ,I.Revision
		   ,I.Part_No
		   ,C.CUSTNAME
		   ,W.KITSTATUS
		   ,W.OPENCLOS
		   ,I.Part_Sourc
		   ,W.COMPLETEDT 
		   ,W.KIT
			 --11/14/2017  Rajendra K : Moved pagination in dynamic sql(@qryMain)

	-- 11/14/2017 Rajendra K : Used Dynamic SQL for Sort and Pagination
	SET @qryMain ='SELECT *
				  FROM #tempResult ORDER BY ' 
				  + @sortExpression + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord-1)
				  + ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;' 

	SET @rowCount = (SELECT COUNT(1) FROM #tempWODetails) -- Set total count to Out parameter 

	EXEC sp_executesql @qryMain -- 11/14/2017 Rajendra K : Get result
END						