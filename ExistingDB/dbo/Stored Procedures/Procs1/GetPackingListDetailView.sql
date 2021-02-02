-- Author:Sachin s
-- Create date:	03/10/2016
-- Description:	Return packing List Details with Sorting and Filtering
-- Modified : 08-10-2016: Sachin s- Remove usused columns,Store the BaseBalance,BaseShippedQty and SHIPPEDQTY
-- [dbo].GetPackingListDetailView '0000000736',0,50,'','' 
-- ==========================================================================================
CREATE PROCEDURE [dbo].GetPackingListDetailView
 @packListNo AS char(10) = '',
 @startRecord int,
 @endRecord int, 
 @sortExpression nvarchar(1000) = null,
 @filter nvarchar(1000) = null
AS
DECLARE @SQL nvarchar(max)
BEGIN
;WITH packingList as(
SELECT 
	--Sachin s 08-10-2016 Remove usused columns
	 --Pldetail.*,
	ISNULL(Sodetail.Uniq_key,SPACE(10)) AS UNIQ_KEY,
	ISNULL(Part_no,SPACE(25)) AS Part_no, 
	ISNULL(Revision,SPACE(8)) AS Revision, 
	ISNULL(Part_Class,SPACE(8)) AS Part_Class, 
	ISNULL(Part_Type,SPACE(8)) AS Part_Type, 
	PLDETAIL.cDESCR	AS Descript,
    PLDETAIL.UOFMEAS	AS U_of_meas,
	--ISNULL(U_of_meas,SPACE(4)) AS U_of_meas,

	ISNULL(Ord_Qty,0.00) AS Ord_Qty, 
	ISNULL(sodetail.BALANCE, 0.00) AS BALANCE, 
	--Sachin s
	--08-10-2016 Store the BaseBalance,BaseShippedQty and SHIPPEDQTY
	sodetail.BALANCE AS BaseBalance	,
	PLDETAIL.SHIPPEDQTY AS BaseShippedQty,	
	PLDETAIL.SHIPPEDQTY AS SHIPPEDQTY,


	ISNULL(Sodetail.Sono,SPACE(10)) AS Sono,
	ISNULL(Part_Sourc, SPACE(10)) AS PART_SOURC, 
	ISNULL(Inventor.SerialYes, 0) AS SerialYes,
	ISNULL(Sodetail.Prodtpuniq, SPACE(10)) AS Prodtpuniq, 
	ISNULL(Sodetail.ProdtpUkln, SPACE(10)) AS ProdtpUkln,
	ISNULL(Sodetail.CnfgQtyPer, 0) AS CnfgQtyPer,
	ISNULL(Inventor.Cert_Req, 0) AS CERT_REQ, 
	ISNULL(Inventor.Cert_Type, SPACE(10)) AS Cert_Type,	
	dbo.fRemoveLeadingZeros(ISNULL(Sodetail.Line_no,Pldetail.Uniqueln)) AS  LINE_NO, 
	IsFromso = CAST(CASE WHEN Sodetail.Uniqueln IS NULL THEN 0 ELSE 1 END AS Bit),
	
	ISNULL(Sodetail.PrjUnique, SPACE(10)) AS PrjUnique
	  ,inventor.USEIPKEY	
	  ,(SELECT p.LOTDETAIL from PARTTYPE p WHERE p.PART_TYPE = inventor.PART_TYPE AND p.PART_CLASS = inventor.PART_CLASS) AS LOTDETAIL

	--PLDETAIL.SHIPPEDQTY AS  SHIPPEDQTY,
	--inventor.CERT_REQ
	--,inventor.SERIALYES
	--Sachin s- 05/17/2016  Need warehouse key
	,sodetail.W_KEY	
	--,sodetail.UNIQUELN
 	,ISNULL(Sodetail.UNIQUELN,Pldetail.Uniqueln) UNIQUELN
	,'' AS SHIPPEDREV
	--,sodetail.SHIPPEDQTY AS BaseShippedQty
	--,sodetail.BALANCE AS BaseBalance	 
	 --bind the grid data
	 ,'' As PLPL_GL_NBR 
	 ,''As PLCOG_GL_NBR 	
	 ,ISNULL(Pldetail.INV_LINK, SPACE(10)) AS INV_LINK 
	FROM Pldetail
    LEFT OUTER JOIN Sodetail	ON Pldetail.Uniqueln = Sodetail.Uniqueln
    LEFT OUTER JOIN Inventor
	ON Sodetail.uniq_key = Inventor.uniq_key
	WHERE Packlistno = @packListNo
	--ORDER BY ISNULL(sodetail.line_no,'X'+dbo.padl(rtrim(substring(pldetail.uniqueln,2,6)),6,'0'))
	),
temptable as(SELECT *  from	packingList )
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