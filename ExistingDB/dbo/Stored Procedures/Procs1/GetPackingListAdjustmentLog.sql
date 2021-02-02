-- =============================================
-- Author:		Sachin Shevale
-- Create date: 05/26/2016
-- Description:	Get Packing list Adjustment log
-- Modified : 03-10-2016 Sachin S: Get uniq line number from pladj  
-- Modified : 03-10-2016 Sachin S: Get description from Inventor and pldetail for manual items
-- Modified : 03-10-2016 Sachin S: Get sum of shipped quantity from pladj and Invt_issue
-- Modified : 03-10-2016 Sachin S: Get Qty issue from Invt_Issue
-- Modified : 03-10-2016 Sachin S: Get list by column name
-- Modified : 11-24-2016 Satish B: Drop TEMP table if present initially 
-- Modified : 11-24-2016 Satish B: No need to check INVT_ISU,PLMAIN,sodetail tables
-- Modified : 11-24-2016 Satish B: Make Partition based on UNIQUELN
-- Modified : 11-24-2016 Satish B: Calculate AdjustedQuantity
-- Modified : 07-18-2017 Satish B: Comment part_class and part_type to combine them into single column value
-- Modified : 07-18-2017 Satish B: Combine part_class and part_type and descript to single column ClassTypeDescript
-- Modified : 07-18-2017 Satish B: Comment descript and combine it with part_class and part_type
-- Modified : 07-18-2017 Satish B: Comment selection of part_class and part_type and select ClassTypeDescript
-- Modified : 10-03-2017 Satish B: Select PLDETAIL.cDESCR, for manual part
-- Modified : 10-03-2017 Satish B: Added the case to select Description for manual part 
-- Modified : 10-25-2017 Satish B: Select  pldetail.cDESCR when the inventor.Descript is null (Use to select description of manual and SO part)
-- Modified : 10-25-2017 Satish B: Select Line_no
-- Modified : 10-25-2017 Satish B: Uncomment the join of sodetail
-- Modified : 11/11/2017 : Satish B : Select Initials of user from aspnet_Profile
-- Modified : 11/11/2017 : Satish B : Added left join of aspnet_Profile table
-- Modified : 11-11-2017 Satish B- Select Initials
-- GetPackingListAdjustmentLog   '0000000659' ,'9THZQON12E','_0TG0WQ2A0',0,200,'',''
-- =============================================
CREATE PROCEDURE GetPackingListAdjustmentLog   
	-- Add the parameters for the stored procedure here
@packlistno AS nvarchar(10) = null,---'0000000443'
@uniqKey AS nvarchar(10) = null,--'_33P0R73ZH'
@slinkAdd AS nvarchar(10) = null, -- '_0TG0WQ2A0'
@startRecord int,--'0'
@endRecord int, --'50'
@sortExpression nvarchar(1000) = null,--''
@filter nvarchar(1000) = null--''
AS
BEGIN
	
	SET NOCOUNT ON;	
	--11-24-2016 Satish B- Drop TEMP table if present initially 
	IF OBJECT_ID('dbo.#TEMP', 'U') IS NOT NULL      
    DROP TABLE dbo.#TEMP;
	DECLARE @SQL nvarchar(max)
   ;WITH packingList AS
	(
		SELECT DISTINCT
    --03-10-2016 Sachin S- Get uniq line number from pladj  
		pladj.UNIQUELN, 
		pladj.SavedDate,
    --03-10-2016 Sachin S- Get packlistno number from PLDETAIL  
		 PLDETAIL.packlistno,
	--Modified : Satish B  10-03-2017 : Select PLDETAIL.cDESCR, for manual part
		 PLDETAIL.cDESCR,
	--Modified : Satish B  07-18-2017 : Comment part_class and part_type to combine them into single column value
		 --Inventor.part_class, 
		 --Inventor.part_type,
	-- Modified : Satish B  07-18-2017 : Combine part_class and part_type and descript to single column ClassTypeDescript
	-- Modified : Satish B  10-25-2017 : Select  pldetail.cDESCR when the inventor.Descript is null (Use to select description of manual and SO part)
	  ISNULL(inventor.Part_Class +'/'+' '+ inventor.Part_Type +'/'+' '+ inventor.Descript,pldetail.cDESCR)  AS ClassTypeDescript
    
	--03-10-2016 Sachin S- Get description from Inventor and pldetail for manual items
		--Modified : Satish B  07-18-2017 : Comment descript and combine it with part_class and part_type
		--,ISNULL(Inventor.descript,pldetail.cDESCR) AS descript,	
		 ,Inventor.part_no,
    --03-10-2016 Sachin S- Get sum of shipped quantity from pladj and Invt_issue
		ISNULL(Inventor.Revision,pldetail.SHIPPEDREV) AS Revision,
		--11-24-2016 Satish B- Make Partition based on UNIQUELN
		ROW_NUMBER() OVER(PARTITION BY pladj.UNIQUELN ORDER BY saveddate) AS RowNumbers, pladj.ShippedQty ,
		--10-25-2017 Satish B- Select Line_no
		ISNULL(dbo.fRemoveLeadingZeros(sodetail.Line_no),dbo.fRemoveLeadingZeros(pldetail.UNIQUELN)) AS Line_no
		--11/11/2017 : Satish B : Select Initials of user from aspnet_Profile
		,ISNULL(aspProf.Initials,'') AS Initials
		FROM PLADJ pladj    
			INNER JOIN PLDETAIL  pldetail On pladj.PACKLISTNO =PLDETAIL.PACKLISTNO and pladj.UNIQUELN=pldetail.UNIQUELN
	        --03-10-2016 Sachin S- Get Qty issue from Invt_Issue
			--11-24-2016 Satish B- No need to check INVT_ISU,PLMAIN,sodetail tables
			--INNER JOIN INVT_ISU  invtIssue On invtIssue.UNIQ_KEY = PLDETAIL.UNIQ_KEY  AND invtIssue.UNIQUELN=PLDETAIL.UNIQUELN 
			--INNER JOIN PLMAIN plmain ON plmain.PACKLISTNO=pldetail.PACKLISTNO 
			--10-25-2017 Satish B- Uncomment the join of sodetail
			LEFT OUTER JOIN sodetail on sodetail.UNIQUELN=PLDETAIL.UNIQUELN
			LEFT OUTER JOIN Inventor inventor ON inventor.UNIQ_KEY=pldetail.UNIQ_KEY
			--11/11/2017 : Satish B : Added left join of aspnet_Profile table
			LEFT JOIN aspnet_Profile aspProf ON aspProf.UserId=pladj.fk_userId
		WHERE (pldetail.PACKLISTNO is null or pldetail.PACKLISTNO=@packlistno)
	)
	--11-24-2016 Satish B- Calculate AdjustedQuantity
	SELECT identity(int,1,1) as RowNumber,previous.UNIQUELN,previous.SavedDate,previous.packlistno,
	-- Modified : Satish B  07-18-2017 : Comment selection of part_class and part_type and select ClassTypeDescript
	--previous.part_class,previous.part_type,previous.descript, 
	--Modified : Satish B  10-03-2017 : Added the case to select Description for manual part 
	 CASE WHEN previous.part_no IS NULL THEN cDESCR ELSE previous.ClassTypeDescript END AS ClassTypeDescript,previous.part_no,previous.Revision, previous.ShippedQty,cDESCR
	 --10-25-2017 Satish B- Select Line_no
	 --11-11-2017 Satish B- Select Initials
	 ,previous.Line_no,previous.Initials
		  ,previous.ShippedQty -  ( SELECT top 1 packList.ShippedQty 
								    FROM packingList packList
									WHERE packList.saveddate <previous.saveddate and packList.UNIQUELN=previous.UNIQUELN ORDER BY saveddate DESC) AS AdjustedQuantity
									INTO #TEMP
	FROM packingList previous
  --03-10-2016 Sachin S- Get list by column name
	--SELECT identity(int,1,1) as RowNumber,* INTO #TEMP from packingList ORDER BY UNIQUELN

	IF @filter <> '' AND @sortExpression <> ''
	  BEGIN
	   SET @SQL=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #TEMP WHERE '+@filter+') AS TotalCount from #TEMP  t  WHERE '+@filter+' and
	   RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+' ORDER BY '+ @SortExpression+''
	   END
	  ELSE IF @filter = '' AND @sortExpression <> ''
	  BEGIN
		SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE 
		RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+' ORDER BY '+ @sortExpression+''
		END
	  ELSE IF @filter <> '' AND @sortExpression = ''
	  BEGIN
		  SET @SQL=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #TEMP WHERE '+@filter+') AS TotalCount from #TEMP  t  WHERE  '+@filter+' and
		  RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+''
	   END
	   ELSE
		 BEGIN
		  SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE 
	   RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+''
	   END
	   exec sp_executesql @SQL
END