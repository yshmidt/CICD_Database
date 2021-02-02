-- =============================================
-- Author:		Rajendra K	
-- Create date: <05/29/2017>
-- Description:Get Work Order data
-- Moidification 
  -- 06/01/2017 Rajendra K : Added Uniq_Key in select list top get BOMParent for BOMNote
  -- 06/01/2017 Rajendra K : Added separate select list for closed kit records to avoid performance issue (select list only differ by order by clause)
  -- 06/02/2017 Rajendra K : Remove leading zeros from WONO
  -- 06/08/2017 Rajendra K : Replaced using PATINDEX(To remove leading zeros) by existing function 'fremoveLeadingZeros' on  
  -- 06/12/2017 Rajendra K : Added new condition to check WoEntry.KITCOMPLETE for differentiate between status 'Open and Complete' and 'Open and InComplete'
  -- 06/27/2017 Rajendra K : Incresed size of input parameter datatype from 10 to 30
  -- 06/30/2017 Rajendra K : Replaced B.Uniq_Key by B.BOMPARENT in join condition
  -- 07/14/2017 Rajendra K : Replaced  COUNT(k.KASEQNUM) by COUNT(DISTINCT k.KASEQNUM) in select list to get correct TotalBOMNo
  -- 07/14/2017 Rajendra K : Search condition applied for PartNumber and Revision
  -- 08/01/2017 Rajendra K : Replaced  COUNT(DISTINCT B.BOMPARENT) by  COUNT(B.UNIQ_KEY) in select list to get correct TotalBOMNo
  -- 09/28/2017 Rajendra K : Modified Stored procedure to improve performance 
							 --Combined @status search
							 --Divided KAMAIN and BOM_DET join
							 --Avoided removing zeros in select list for each row join call
							 --Added CompleteDate in select list
							 --Added condition in Ordery by clause
  -- 10/25/2017 Rajendra K : Removed function dbo.fremoveLeadingZeros to get WONO from select list
  -- 10/25/2017 Rajendra K : Removed white space from input parameter @wONO in set parameter section and used it in where condition
  -- 11/11/2017 Rajendra K : Delcared new parameter @originalWoNo
  -- 11/11/2017 Rajendra K : Added % for used to like condition for parameter @wONO in set parameter section 
  -- 11/11/2017 Rajendra K : Set paramters in camel case 
  -- 11/14/2017 Rajendra K : Used Dynamic SQL for Sort and Pagination
  -- 11/14/2017 Rajendra K : Remove CTE and replace with temp table for results
  -- 11/14/2017 Rajendra K : Added new input paramter @sortExpression for dynamic sorting
  -- 11/16/2017 Rajendra K : Changed Join condition from LEFT to INNER for tables KAMAIN and BOM_DET
  -- 12/22/2017 Rajendra K : Removed unneccessary columns ,W.COMPLETEDT,I.ITAR,I.Revision,I.Part_No,C.CUSTNAME,W.KITSTATUS,W.OPENCLOS and I.Part_Sourc from group by clause for record count
  -- 12/22/2017 Rajendra K : Removed condition for Closed kits from where cluase
  -- 12/22/2017 Rajendra K : Rmoved case from group by and separated columns
  -- 11/05/2018 Rajendra K : Renamed Param name from @wONO to @searchParam(used to search by WONO and PartNumber)
  -- 11/05/2018 Rajendra K : Commented old query to get total number of counts and added new query
  -- 11/05/2018 Rajendra K : Commented old query records and added new dynamic sql query
  -- 11/05/2018 Rajendra K : Added column ShortQty in select list
  --12/18/2018 Rajendra K : Added column Warehouse to apply filter
  -- 04/16/2019 Rajendra K : Added column "CUSTNO" in select list
  -- 04/16/2019 Rajendra K : Added column "CUSTNO" in group by 
  -- 05/06/2020 Rajendra K : Added outer join to getting Isshortage which having IGNOREKIT = 0
  -- 06/02/2020 Sachin B : Add KIT Column in the select statement
  -- 10/23/2020 YS : Wrong type for the ShortQty. The database is for (12,2) not (13,5) created a problem
  -- [dbo].[GETWONOList] '','Standard','',1,509,1  
-- =============================================
CREATE PROCEDURE [dbo].[GETWONOList]  
(
@wONO VARCHAR(50) = '',
--@searchParam VARCHAR(50) = '', -- 11/05/2018 Rajendra K : Renamed Param name from @wONO to @searchParam(used to search by WONO and PartNumber)
@status VARCHAR(30) = '', -- 06/27/2017 Rajendra K : Incresed size of input parameter datatype from 10 to 30
@sortExpression NVARCHAR(200)= '', -- 11/14/2017 Rajendra K :Added sortExpression
@startRecord int =1,
@endRecord int =10,
@rowCount INT OUT
)
AS
BEGIN
	SET NOCOUNT ON;	

	-- 09/28/2017 Rajendra K : Declare and Set new parameter @kITCOMPLETE for comparing with WOENTRY.KITCOMPLETE
	DECLARE @kITCOMPLETE BIT = CASE WHEN @status ='Standard' THEN 0 WHEN @status = 'OpenComplete' THEN 1 END
	--DECLARE @originalWoNo VARCHAR(10) = @wONO -- 11/11/2017 Rajendra K : Declare and set @originalWoNo 
	DECLARE @qryMain  NVARCHAR(MAX);  -- -- 11/11/2017 Rajendra K : Declare @qryMain for Dynamic sql 

	-- 09/28/2017 Rajendra K : SET value for @status (Will be use to avoid switch case in where condition)
	SET @status = CASE WHEN @status IN ('Standard','OpenComplete') THEN 'OPEN' ELSE 'Closed' END
	-- 10/25/2017 Rajendra K : Removed white space from input parameter @wONO and used it to where condition
	--SET @wONO = '%'+RTRIM(LTRIM(@wONO))+'%' -- 11/11/2017 Rajendra K : Added % for used to like condition

	-- 11/05/2018 Rajendra K : Set Default value to @wONO & @sortExpression
	SET @wONO = CASE WHEN @wONO IS NULL THEN '' ELSE RTRIM(LTRIM(@wONO)) END
	SET @sortExpression = CASE WHEN @sortExpression IS NULL OR @sortExpression = '' THEN 'W.WONO' ELSE RTRIM(LTRIM(@sortExpression)) END

------ 11/05/2018 Rajendra K : Commented old query to get total number of counts and added new query
	SELECT @rowCount = COUNT(DISTINCT W.WONO) 
	FROM WoEntry W
		   INNER JOIN Inventor I ON W.UNIQ_KEY = I.Uniq_Key
	WHERE  W.KITCOMPLETE = @kITCOMPLETE AND (@wONO = '' OR W.WONO LIKE '%' + @wONO + '%'
		    OR RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE ' /'+ RTRIM(I.REVISION) END) 
			LIKE '%' + @wONO + '%')
		    AND (W.OPENCLOS NOT IN('Cancel','Closed'))

------ 11/05/2018 Rajendra K : Commented old query to get total number of counts and added new query
	    --SELECT  COUNT(W.WONO) AS CountRecords -- Get total counts 
	    --INTO #tempWODetails 
	    --FROM WoEntry W
	    --	   INNER JOIN Inventor I ON W.UNIQ_KEY = I.Uniq_Key
	    --       INNER JOIN CUSTOMER C ON W.CUSTNO = C.CUSTNO
	    --	   LEFT JOIN kamain K ON W.WONO = K.WONO 
	    --	   LEFT JOIN BOM_DET B ON W.UNIQ_KEY = B.BOMPARENT -- 06/30/2017 Rajendra K : Replaced B.Uniq_Key by B.BOMPARENT in join condition
	    --WHERE  (@originalWoNo = NULL OR @originalWoNo = '' OR W.WONO LIKE @wONO  -- 11/11/2017 Rajendra K : Set % in set section --11/11/2017 Replace @searchKey with @originalSearchKey
	    --		 OR I.PART_NO  LIKE @wONO -- 10/25/2017 Rajendra K : Removed white spaces initially in set parameter section 
	    --									-- 11/11/2017 Rajendra K : Set % in set section
	    --	    OR RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE ' /'+ RTRIM(I.REVISION) END) LIKE 
	    --		@wONO -- 10/25/2017 Rajendra K : Removed white spaces initially in set parameter section
	    --		-- 11/11/2017 Rajendra K : Set % in set section
	    --		)-- 07/14/2017 Rajendra K : Search condition applied for PartNumber and Revision
	    --							--06/12/2017 : Added new condition to check WoEntry.KITCOMPLETE for differentiate between status 'Open and Complete' and 'Open and InComplete' 
	    --	    AND (@status = NULL OR @status = '' OR (1 = (CASE WHEN @status ='OPEN' AND W.OPENCLOS NOT IN ('Closed' ,'Cancel') AND W.KITCOMPLETE = @kITCOMPLETE THEN 1
	    --													-- 09/28/2017 Rajendra K : Combined Status 'Standard' and 'OpenComplete'														
	    --													-- 12/22/2017 Rajendra K :Removed condition for Closed kits
	    --													WHEN @status NOT IN('Standard','WORec') AND W.OPENCLOS = @status THEN 1 --When Input status other than 'Standard' and 'WORec'
	    --													ELSE 0 END)))
	    
	    --	  -- 07/14/2017 Rajendra K : Added parameter @AssemblyNo to get row filter by PartNumber and Revision
	    --GROUP BY  
	    --        W.WONO
	    --	   ,I.UNIQ_KEY -- 07/14/2017 Rajendra K : Added to get BOMParent for BOMNote
	    --	   ,Bldqty
	    --	   ,C.CUSTNAME
	    --	   --12/22/2017 Rajendra K : Removed unneccessary columns from group by clause for record count
	    	
        --IF (@status = 'OPEN')  -- 06/08/2017 Rajendra K :Added separate select list for closed kit records to avoid performance issue
        --09/28/2017 Rajendra K : Removed @status check If condition 

------ 11/05/2018 Rajendra K : Commented old query records and added new dynamic sql query
		--	-- 09/28/2017 Rajendra K : Added CTE to avoid removing leading zeros on select statement from each join call and separate Kamin and Bom_Det join with WOEntry 
		--	;WITH CTEKMainWOTable AS
		--	(
		--	SELECT DISTINCT W.WONO AS WONO -- 06/08/2017 Rajendra K : Replaced using 
		--														--PATINDEX(To remove leading zeros)by existing function 'fremoveLeadingZeros'
		--		   ,I.UNIQ_KEY -- Added to get BOMParent for BOMNote		   
		--		   ,W.DUE_DATE AS DueDate
		--		   ,I.ITAR 
		--		   ,'' AS DPAS
		--		   ,W.BLDQTY AS Bldqty
		--		   ,I.PART_NO + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) AS PartRevision
		--		   ,(CASE WHEN I.PART_CLASS IS NULL OR  I.PART_CLASS = '' THEN I.PART_CLASS ELSE I.PART_CLASS +'/ ' END ) + 
		--		    (CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='' THEN I.PART_TYPE ELSE I.PART_TYPE + '/ '+I.DESCRIPT END) AS Description
		--		   ,C.CUSTNAME AS CustName
		--		   ,COUNT(DISTINCT k.KASEQNUM) AS TotalBomItems -- 09/28/2017 Rajendra K : Removed COUNT(B.UNIQ_KEY)
		--		   ,(CASE WHEN COALESCE(COUNT(k.KASEQNUM),0) > 0 THEN 'Yes' ELSE 'No' END) AS Released
		--		   ,W.KITSTATUS AS KitStatus
		--		   ,W.OPENCLOS AS OpenClose
		--		   ,I.Part_Sourc AS PartSourc
		--	FROM WoEntry W
		--		   INNER JOIN Inventor I ON W.UNIQ_KEY = I.Uniq_Key
		--	       INNER JOIN CUSTOMER C ON W.CUSTNO = C.CUSTNO
		--		   INNER JOIN kamain K ON W.WONO = K.WONO  -- 11/16/2017 Rajendra K : Changed Join condition from LEFT to INNER
		--		   --  09/28/2017 Rajendra K : Removed BOM_DET table from join condition and added in second CTE 
		--	WHERE  (@originalWoNo = NULL OR @originalWoNo = '' OR W.WONO LIKE @wONO  -- 11/11/2017 Rajendra K : Set % in set section --11/11/2017 Replace @searchKey with @originalSearchKey
		--			 OR I.PART_NO  LIKE @wONO -- 10/25/2017 Rajendra K : Removed white spaces initially in set parameter section -- 11/11/2017 Rajendra K : Set % in set section
		--		    OR RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE ' /'+ RTRIM(I.REVISION) END) 
		--			LIKE @wONO -- 10/25/2017 Rajendra K : Removed white spaces initially in set parameter section
		--			-- 11/11/2017 Rajendra K : Set % in set section
		--			)-- 07/14/2017 Rajendra K : Search condition applied for PartNumber and Revision
		--							-- 06/12/2017 Rajendra K : Added new condition to check WoEntry.KITCOMPLETE for differentiate between status 'Open and Complete' and 'Open and InComplete'
		--		    AND (@status = NULL OR @status = '' OR ((@status = 'OPEN' AND W.OPENCLOS NOT IN ('Closed' ,'Cancel') AND W.KITCOMPLETE = @kITCOMPLETE)
		--			)) -- 09/28/2017 Rajendra : Combined where condition for all Status search @status
		--			   -- 12/22/2017 Rajendra K :Removed condition for Closed kits
		--	GROUP BY  
		--	        W.WONO -- 06/12/2017 Rajendra K : Replaced using PATINDEX(To remove leading zeros) 
		--																  --by existing function 'fremoveLeadingZeros' on 06/08/2017 -Rajendra K 
		--		   ,I.UNIQ_KEY -- 06/12/2017 Rajendra K : Added to get BOMParent for BOMNote
		--		   ,Bldqty
		--		   -- 12/22/2017 Rajendra K : Rmoved case from group by and separated columns
		--		   ,I.PART_CLASS 
		--		   ,I.DESCRIPT
		--		   ,I.PART_TYPE
		--		   ,W.DUE_DATE
		--		   ,I.ITAR
		--		   ,I.Revision
		--		   ,I.Part_No
		--		   ,C.CUSTNAME
		--		   ,W.KITSTATUS
		--		   ,W.OPENCLOS
		--		   ,I.Part_Sourc
		--	)
		
		--	-- 09/28/2017 Rajendra K : Added CTE to avoid removing leading zeros on select statement from each join call and separate Kamin and Bom_Det join with WOEntry 
		--	,CTEBOMWOTable AS(
		--	SELECT DISTINCT W.WONO AS WONO -- 06/08/2017 Rajendra K : Replaced using 
		--														--PATINDEX(To remove leading zeros)by existing function 'fremoveLeadingZeros'
		--		   ,I.UNIQ_KEY -- Added to get BOMParent for BOMNote		
		--		   ,W.DUE_DATE AS DueDate
		--		   ,I.ITAR 
		--		   ,'' AS DPAS
		--		   ,W.BLDQTY AS Bldqty
		--		   ,I.PART_NO + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) AS PartRevision
		--		   ,(CASE WHEN I.PART_CLASS IS NULL OR  I.PART_CLASS = '' THEN I.PART_CLASS ELSE I.PART_CLASS +'/ ' END ) + 
		--		    (CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='' THEN I.PART_TYPE ELSE I.PART_TYPE + '/ '+I.DESCRIPT END) AS Description
		--		   ,C.CUSTNAME AS CustName
		--		   ,COUNT(DISTINCT B.UNIQ_KEY) AS TotalBomItems 
		--							-- 07/14/2017 Rajendra K : Replaced  COUNT(k.KASEQNUM) by COUNT(DISTINCT k.KASEQNUM) in select list to get correct TotalBOMNo
		--							-- 08/01/2017 Rajendra K : Replaced  COUNT(DISTINCT B.BOMPARENT) by  COUNT(B.UNIQ_KEY) in select list to get correct TotalBOMNo
		--		   ,'No' AS Released
		--		   ,W.KITSTATUS AS KitStatus
		--		   ,W.OPENCLOS AS OpenClose
		--		   ,I.Part_Sourc AS PartSourc
		--	FROM WoEntry W
		--		   INNER JOIN Inventor I ON W.UNIQ_KEY = I.Uniq_Key
		--	       INNER JOIN CUSTOMER C ON W.CUSTNO = C.CUSTNO
		--		   --LEFT JOIN kamain K ON W.WONO = K.WONO 
		--		   INNER JOIN BOM_DET B ON W.UNIQ_KEY = B.BOMPARENT -- 06/30/2017 Rajendra K : Replaced B.Uniq_Key by B.BOMPARENT in join condition
		--  														    -- 11/16/2017 Rajendra K : Changed Join condition from LEFT to INNER
		--	WHERE W.WONO NOT IN(SELECT WONO FROM CTEKMainWOTable) AND  (@originalWoNo = NULL OR @originalWoNo = '' OR W.WONO LIKE @wONO  -- 11/11/2017 Rajendra K : Set % in set section --11/11/2017 Replace @searchKey with @originalSearchKey
		--			 OR I.PART_NO  LIKE @wONO -- 10/25/2017 Rajendra K : Removed white spaces initially in set parameter section
		--			 -- 11/11/2017 Rajendra K : Set % in set section
		--		    OR RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE ' /'+ RTRIM(I.REVISION) END) 
		--			LIKE @wONO -- 10/25/2017 Rajendra K : Removed white spaces initially in set parameter section
		--			-- 11/11/2017 Rajendra K : Set % in set section
		--			)-- 07/14/2017 Rajendra K : Search condition applied for PartNumber and Revision
		--							-- 06/12/2017 Rajendra K : Added new condition to check WoEntry.KITCOMPLETE for differentiate between status 'Open and Complete' and 'Open and InComplete'
		--		    AND (@status = NULL OR @status = '' OR (@status = 'OPEN' AND W.OPENCLOS NOT IN ('Closed' ,'Cancel') AND W.KITCOMPLETE = @kITCOMPLETE))
		--	GROUP BY  
		--	        W.WONO -- 06/12/2017 Rajendra K : Replaced using PATINDEX(To remove leading zeros) 
		--																  --by existing function 'fremoveLeadingZeros' on 06/08/2017 -Rajendra K 
		--		   ,I.UNIQ_KEY -- 06/12/2017 Rajendra K : Added to get BOMParent for BOMNote
		--		   ,Bldqty
		--		  -- 12/22/2017 Rajendra K : Rmoved case from group by and separated columns
		--		   ,I.PART_CLASS 
		--		   ,I.DESCRIPT
		--		   ,I.PART_TYPE
		--		   ,W.DUE_DATE
		--		   ,I.ITAR
		--		   ,I.Revision
		--		   ,I.Part_No
		--		   ,C.CUSTNAME
		--		   ,W.KITSTATUS
		--		   ,W.OPENCLOS
		--		   ,I.Part_Sourc
		--		)
		
		----09/28/2017 Rajendra K : UNION two CTEs CTEKMainWOTable & CTEBOMWOTable into result CTE CTEWOResult
		--	 -- 11/14/2017 Rajendra K : Remove CTE and replace with temp table for results
		--			SELECT  Wono
		--					,UNIQ_KEY
		--					,DueDate
		--					,ITAR
		--					,DPAS
		--					,Bldqty
		--					,PartRevision
		--					,CustName
		--					,TotalBomItems
		--					,Released
		--					,KitStatus
		--					,OpenClose
		--					,PartSourc 
		--					,Description
		--			INTO #tempResult -- 11/14/2017 Rajendra K : Remove CTE and replace with temp table for results
		--			FROM CTEKMainWOTable 
		--			UNION 
		--			SELECT Wono
		--					,UNIQ_KEY
		--					,DueDate
		--					,ITAR
		--					,DPAS
		--					,Bldqty
		--					,PartRevision
		--					,CustName
		--					,TotalBomItems
		--					,Released
		--					,KitStatus
		--					,OpenClose
		--					,PartSourc 
		--					,Description
		--			FROM CTEBOMWOTable -- 11/14/2017 Rajendra K : Replace CTEBOMWOTable 			
		 
		--	-- 09/28/2017 Rajendra K : Get finale result with page size and order by conditions
		--	-- 11/14/2017 Rajendra K : Used Dynamic SQL for Sort and Pagination
		--	SET @qryMain ='SELECT WONO
		--				  ,CAST(dbo.fremoveLeadingZeros(WONO) AS VARCHAR(MAX)) AS WorkOrderNumber
		--				  ,UNIQ_KEY
		--				  ,DueDate
		--				  ,ITAR
		--				  ,DPAS
		--				  ,Bldqty
		--				  ,PartRevision
		--				  ,CustName
		--				  ,TotalBomItems
		--				  ,Released
		--				  ,KitStatus
		--				  ,OpenClose
		--				  ,PartSourc 
		--				  ,Description
		--				  FROM #tempResult ORDER BY ' 
		--				  + @sortExpression + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord-1)
		--				  + ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;' 
					
		--	SET @rowCount = (SELECT COUNT(1) FROM #tempWODetails) -- Set total count to Out parameter 
		
		--	EXEC sp_executesql @qryMain -- 11/14/2017 Rajendra K : Get result

------ 11/05/2018 Rajendra K : Commented old query records and added new dynamic sql query
    SET @qryMain = 'SELECT DISTINCT wh.WAREHOUSE, W.WONO AS WONO '   
		   +',dbo.fremoveLeadingZeros(W.WONO) AS WorkOrderNumber '
		   +',I.UNIQ_KEY ' 
		   +',W.DUE_DATE AS DueDate '
		   +',I.ITAR '
		   +','''' AS DPAS '
		   +',W.BLDQTY AS Bldqty '
		   +',I.PART_NO + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '''' THEN I.REVISION ELSE ''/''+ I.REVISION END) AS PartRevision '
		   +',I.PART_CLASS +''/ '' + '
		   +' (CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='''' THEN I.PART_TYPE ELSE I.PART_TYPE + ''/ ''+I.DESCRIPT END) AS Description '
		   +',C.CUSTNAME AS CustName '
		   +',COUNT(DISTINCT k.KASEQNUM) AS TotalBomItems '
		   +',(CASE WHEN COALESCE(COUNT(k.KASEQNUM),0) > 0 THEN ''Yes'' ELSE ''No'' END) AS Released '
		   +',W.KITSTATUS AS KitStatus '
		   +',W.OPENCLOS AS OpenClose '
		   +',I.Part_Sourc AS PartSourc '
     --+',CAST(CASE WHEN SUM(CASE WHEN K.ShortQty < 0 THEN ''0'' ELSE K.ShortQty END ) > 0 THEN 1 ELSE 0  END AS BIT) AS IsShortage '   
	 +',shortages.IsShortage'-- 05/06/2020 Rajendra K : Added outer join to getting Isshortage which having IGNOREKIT = 0
	       -- 06/02/2020 Sachin B : Add KIT Column in the select statement
		     -- 10/23/2020 YS : Wrong type for the ShortQty. The database is for (12,2) not (13,5) created a problem
		   +',CAST(SUM(CASE WHEN K.ShortQty < 0 THEN ''0'' ELSE K.ShortQty END ) AS NUMERIC(12,2)) AS ShortQty '
		   +',I.BOMCUSTNO AS CUSTNO,W.KIT '   -- 04/16/2019 Rajendra K : Added column "CUSTNO" in select list
		   +'FROM WoEntry W '
		   +'INNER JOIN Inventor I ON W.UNIQ_KEY = I.Uniq_Key '
	       +'INNER JOIN CUSTOMER C ON W.CUSTNO = C.CUSTNO '
		   +'INNER JOIN kamain K ON W.WONO = K.WONO ' 
	 + 'LEFT JOIN WAREHOUS wh ON W.KitUniqwh = wh.UNIQWH ' 
   +' OUTER APPLY (
   SELECT CAST(CASE WHEN SUM(CASE WHEN ShortQty < 0 THEN ''0'' ELSE ShortQty END ) > 0 THEN 1 ELSE 0  END AS BIT) AS IsShortage
    FROM KAMAIN WHERE WONO = W.WONO AND IGNOREKIT = 0
   ) AS shortages '  -- 05/06/2020 Rajendra K : Added outer join to getting Isshortage which having IGNOREKIT = 0
	+'WHERE  '
	+'(1= ('+ CASE WHEN  @wONO = '' THEN ' 1' ELSE '0' END +')'  
			+'OR W.WONO  LIKE ''%'+@wONO+'%''' 
		    +'OR (RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '''' THEN I.REVISION ELSE '' /''+ RTRIM(I.REVISION) END) '
			+'LIKE ''%'+@wONO+'%'' ))'
			+'AND ('''+@status +'''= ''OPEN'' AND W.OPENCLOS NOT IN (''Closed'',''Cancel'') AND CAST(W.KITCOMPLETE AS CHAR(1))= '+CAST(@kITCOMPLETE AS CHAR(1))+') '
	+'GROUP BY '  
	       +'wh.WAREHOUSE '
           +',W.WONO '   
		   +',I.UNIQ_KEY ' 
		   +',Bldqty '
		   +',I.PART_CLASS '
		   +',I.DESCRIPT '
		   +',I.PART_TYPE '
		   +',W.DUE_DATE '
		   +',I.ITAR '
		   +',I.Revision '
		   +',I.Part_No '
		   +',C.CUSTNAME '
		   +',W.KITSTATUS '
		   +',W.OPENCLOS '
		   +',I.Part_Sourc '
		   +',I.BOMCUSTNO '   -- 04/16/2019 Rajendra K : Added column "CUSTNO" in group by 
		   -- 06/02/2020 Sachin B : Add KIT Column in the select statement
       +',shortages.IsShortage,W.KIT ' -- 05/06/2020 Rajendra K : Added outer join to getting Isshortage which having IGNOREKIT = 0
		   +' UNION '
                   +' SELECT DISTINCT wh.WAREHOUSE '
                +',W.WONO AS WONO '   
		  +',dbo.fremoveLeadingZeros(W.WONO) AS WorkOrderNumber '
		  +',I.UNIQ_KEY '
		  +',W.DUE_DATE AS DueDate '
		  +',I.ITAR '
		  +','''' AS DPAS '
		  +',W.BLDQTY AS Bldqty '
		  +',I.PART_NO + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '''' THEN I.REVISION ELSE ''/''+ I.REVISION END) AS PartRevision '
		  +',I.PART_CLASS +''/ '' + '
		  +' (CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='''' THEN I.PART_TYPE ELSE I.PART_TYPE + ''/ ''+I.DESCRIPT END) AS Description '
		  +',C.CUSTNAME AS CustName '
		  +',COUNT(B.UNIQ_KEY) AS TotalBomItems '
		  +',''No'' AS Released '
		  +',W.KITSTATUS AS KitStatus '
		  +',W.OPENCLOS AS OpenClose '
		  +',I.Part_Sourc AS PartSourc '
		  +',CAST(0 AS BIT) AS IsShortage '
		    -- 10/23/2020 YS : Wrong type for the ShortQty. The database is for (12,2) not (13,5) created a problem
		  +',CAST(0 AS NUMERIC(12,2)) AS ShortQty '
		  -- 06/02/2020 Sachin B : Add KIT Column in the select statement
		  +',I.BOMCUSTNO AS CUSTNO,W.KIT '   -- 04/16/2019 Rajendra K : Added column "CUSTNO" in select list
	+'FROM WoEntry W '
		   +'INNER JOIN Inventor I ON W.UNIQ_KEY = I.Uniq_Key '
	       +'INNER JOIN CUSTOMER C ON W.CUSTNO = C.CUSTNO ' 
		   +'LEFT JOIN BOM_DET B ON W.UNIQ_KEY = B.BOMPARENT '
	 + 'LEFT JOIN WAREHOUS wh ON W.KitUniqwh = wh.UNIQWH '
	+'WHERE W.WONO NOT IN(SELECT WONO FROM KAMAIN) AND ('
			+'(1= ('+ CASE WHEN @wONO = '' THEN ' 1' ELSE '0' END +')'  
			+'OR W.WONO  LIKE ''%'+@wONO+'%''' 
		    +'OR (RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '''' THEN I.REVISION ELSE '' /''+ RTRIM(I.REVISION) END) '
			+'LIKE ''%'+@wONO+'%'' )'
			+') AND ('''+@status +'''= ''OPEN'' AND W.OPENCLOS NOT IN (''Closed'',''Cancel'') AND CAST(W.KITCOMPLETE AS CHAR(1))= '+CAST(@kITCOMPLETE AS CHAR(1))+') )'
	+'GROUP BY ' 
	       +'wh.WAREHOUSE ' 
           +',W.WONO '  
		   +',I.UNIQ_KEY '
		   +',Bldqty ' 		  
		   +',I.PART_CLASS '
		   +',I.DESCRIPT '
		   +',I.PART_TYPE '
		   +',W.DUE_DATE '
		   +',I.ITAR '
		   +',I.Revision '
		   +',I.Part_No '
		   +',C.CUSTNAME '
		   +',W.KITSTATUS '
		   +',W.OPENCLOS '
		   +',I.Part_Sourc '
		   -- 06/02/2020 Sachin B : Add KIT Column in the select statement
		   +',I.BOMCUSTNO,W.KIT '   -- 04/16/2019 Rajendra K : Added column "CUSTNO" in group by 
		   +' ORDER BY '
		   + @sortExpression + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord-1)
		   + ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'
		   
		   EXEC sp_executesql @qryMain 
END						