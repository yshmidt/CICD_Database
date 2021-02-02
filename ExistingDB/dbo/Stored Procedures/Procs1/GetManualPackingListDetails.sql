-- =============================================
-- Author:Sachin Shevale
-- Create date: 10/09/2014
-- Description:	 Get warehouse details based on inventor For get updated Qty
-- Modified : 
-- Satish B- 12-28-2016 Combine part class,part type and description as one column
-- Satish B- 01-17-2017 Display only description in grid
-- Nitesh B- 01/11/2019: Add Pldetail.INV_LINK to get INV_LINK
-- [GetManualPackingListDetails] '0000000439',1,50,' ','' 
-- =============================================
CREATE PROCEDURE [dbo].[GetManualPackingListDetails] 
	-- Add the parameters for the stored procedure here
 @packingListNo char(10)='' , 
 @startRecord int=0,
 @endRecord int=50,   
 @sortExpression nvarchar(1000) = null, --'WHLOC ASC'
 @filter nvarchar(1000) = null --'Order by WHLOC ' 
AS
DECLARE @SQL nvarchar(max)
BEGIN
;WITH ManualList
AS
-- 10/09/14 replace invtmfhd table with 2 new tables
(
SELECT     
    ISNULL(Inventor.UNIQ_KEY,SPACE(10)) AS UNIQ_KEY,	
	ISNULL(Part_no,SPACE(25)) AS Part_no,	
	ISNULL(Revision,SPACE(8)) AS Revision, 
	--Satish B- 12-28-2016 Combine part class,part type and description as one column
	--ISNULL(Part_Class,SPACE(8)) +'/'+' '+ ISNULL(Part_Type,SPACE(8)) +'/'+' '+ Pldetail.cDESCR AS ClassTypeDescript,
	--ISNULL(Part_Class,SPACE(8)) AS Part_Class, 
	--ISNULL(Part_Type,SPACE(8)) AS Part_Type, 
	--Satish B- 01-17-2017 Display only description in grid
	Pldetail.cDESCR	AS ClassTypeDescript,
    Pldetail.UOFMEAS	AS U_of_meas,
	ISNULL(sodetail.Ord_Qty,0.00) AS Ord_Qty,
	0 BALANCE, 
	0 BaseBalance,
	Pldetail.SHIPPEDQTY AS BaseShippedQty,	
	Pldetail.SHIPPEDQTY, 
	 ISNULL(sodetail.SONO,SPACE(10)) AS Sono , 
	 	ISNULL(Part_Sourc, SPACE(10)) AS Part_Sourc, 
	ISNULL(Inventor.SerialYes, 0) AS SerialYes,
	ISNULL(Inventor.Cert_Req, 0) AS CERT_REQ, 
	dbo.fRemoveLeadingZeros(Pldetail.UNIQUELN) AS LINE_NO	
	,'' AS LOTDETAIL
		,sodetail.W_KEY	
		,Pldetail.UNIQUELN 
	,LTRIM(RTRIM(Pldetail.SHIPPEDREV)) SHIPPEDREV
	,Pldetail.PLPL_GL_NBR 
	,Pldetail.PLCOG_GL_NBR
	,Pldetail.INV_LINK  AS INV_LINK   -- Nitesh B- 01/11/2019: Add Pldetail.INV_LINK to get INV_LINK
	,inventor.USEIPKEY
	,ISNULL(Pldetail.SHIPPEDQTY, 0.00) AS totalShippedQty 	
	,Pldetail.SHIPPEDQTY AS OldShippedQty
	FROM Pldetail
		LEFT OUTER JOIN Sodetail ON Pldetail.Uniqueln = Sodetail.Uniqueln
		LEFT OUTER JOIN Inventor ON Sodetail.uniq_key = Inventor.uniq_key
	WHERE Packlistno = @packingListNo			
	),	
	--temptable as(SELECT *  from	AvailableFgiList WHERE AvailableQty > 0 OR PKALLOCQTY IS NOT NULL )
	temptable as(SELECT *  from	ManualList)
	SELECT identity(int,1,1) as RowNumber,*INTO #TEMP from temptable 
	IF @filter <> '' AND @sortExpression <> ''
	  BEGIN
	   SET @SQL=N'select  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE '+@filter+' and
	   RowNumber BETWEEN '+Convert(varchar,@startRecord)+' AND '+Convert(varchar,@endRecord)+' ORDER BY '+ @sortExpression+''
	   END
	  ELSE IF @filter = '' AND @sortExpression <> ''
	  BEGIN
		SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE 
		RowNumber BETWEEN '+Convert(varchar,@startRecord)+' AND '+Convert(varchar,@endRecord)+' ORDER BY '+ @sortExpression+''
		END
	  ELSE IF @filter <> '' AND @sortExpression = ''
	  BEGIN
		  SET @SQL=N'select  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE  '+@filter+' and
		 RowNumber BETWEEN '+Convert(varchar,@startRecord)+' AND '+Convert(varchar,@endRecord)+''
	   END
	   ELSE
		 BEGIN
		  SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE 
	   RowNumber BETWEEN '+Convert(varchar,@startRecord)+' AND '+Convert(varchar,@endRecord)+''
	   END
	 exec sp_executesql @SQL
END

