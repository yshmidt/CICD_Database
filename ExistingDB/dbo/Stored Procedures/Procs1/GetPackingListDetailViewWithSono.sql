-- Author:Sachin s
-- Create date:	07/13/2016
-- Description:	Return packing List Details with Sorting and Filtering
-- Modified : Sachin S 08-23-2016 Filter list by Slinke addresss
--          : Sachin S 08-23-2016 : Get SLinkAdd from sodetail
--          : Satish B 12-28-2016 : Combine part class,part type and description as one column
--          : Satish B 01-04-2017 : Added ITAR column
--          : Satish B 01-17-2017 : replace slash(/) with empty space id null value in variable e.g. if Part_Class is empty then do not display slash(/)
--          : Satish B 06-09-2017 : Check Part_Class,Part_Type with empty string e.g.Part_Class='' and remove white space from description
--			: Satish B 04-8-2018  : Replace Left join with Inner join 
--			: Satish B 04-10-2018 : Replace Inner join with Left join to display manual part which are added while creating sales order
--			: Satish B 04-16-2018 : Removed filter of UNIQUELN against PLDETAIL table
--			: Satish B 04-16-2018 : Added filter of UNIQUELN against PLDETAIL table
--			: Satish B 04-16-2018 : Select U_of_meas from sodetail table if inventor.U_OF_MEAS is null or empty
--			: Satish B 04-16-2018 : Select description from sodetail if description from Inventor is null or empty
--          : Satish B -06-04-2018 : Check ISNULL for description and select either from inventor or from PLDETAIL table
--			: Satish B- 06-04-2018 Check ISNULL and modify the selection of ClassTypeDescript
--			: Shrikant B 10-22-2018 : Added Collumn IsSFBL for SFBL warehouse identity
-- [dbo].GetPackingListDetailViewWithSono '0000000737','0000000838' ,0, 50,'' ,''
 -- ==========================================================================================
CREATE PROCEDURE [dbo].GetPackingListDetailViewWithSono
 @packListNo AS CHAR(10) = '',
 @sono AS CHAR(10) = '',
 @startRecord INT,
 @endRecord INT, 
 @sortExpression NVARCHAR(1000) = '',
 @filter NVARCHAR(1000) = null
AS
DECLARE @SQL nvarchar(max)
BEGIN
;WITH packingList AS(

SELECT DISTINCT
		ISNULL(Sodetail.Uniq_key,SPACE(10)) AS UNIQ_KEY,
		(ISNULL(Sodetail.Line_no,Pldetail.Uniqueln)) AS  LINE_NO,
		ISNULL(Part_no,SPACE(25))  AS Part_no, 
		ISNULL(Revision,SPACE(8)) AS Revision, 
		--Satish B- 12-28-2016 Combine part class,part type and description as one column
		--Satish B- 01-17-2017 replace slash(/) with empty space id null value in variable e.g. if Part_Class is empty then do not display slash(/)
		--Satish B -06-09-2017 : Check Part_Class,Part_Type with empty string e.g.Part_Class='' and remove white space from description
		--Satish B -06-04-2018 : Check ISNULL for description and select either from inventor or from PLDETAIL table
		ISNULL(Part_Class,'') + (CASE  WHEN Part_Class IS NULL OR Part_Class='' THEN '' ELSE '/' END ) +' '+ ISNULL(Part_Type,'') 
		  +(CASE  WHEN Part_Type IS NULL OR Part_Type='' THEN '' ELSE '/' END )+' '+ RTRIM(ISNULL(inventor.DESCRIPT,PLDETAIL.cDESCR)) AS ClassTypeDescript,
		--ISNULL(Part_Class,SPACE(8)) AS Part_Class
		--ISNULL(Part_Type,SPACE(8)) AS Part_Type, 
		--PLDETAIL.cDESCR	AS Descript,
    
		PLDETAIL.UOFMEAS	AS U_of_meas,
		ISNULL(Ord_Qty,0.00) AS Ord_Qty, 
		ISNULL(sodetail.BALANCE, 0.00) AS BALANCE, 
		sodetail.BALANCE AS BaseBalance	,
		PLDETAIL.SHIPPEDQTY AS BaseShippedQty,	
		PLDETAIL.SHIPPEDQTY AS SHIPPEDQTY,
		ISNULL(Sodetail.Sono,SPACE(10)) AS Sono,
		ISNULL(Part_Sourc, SPACE(10)) AS Part_Sourc, 
		ISNULL(Inventor.SerialYes, 0) AS SerialYes,
		ISNULL(Inventor.Cert_Req, 0) AS CERT_REQ,
		--Satish B- 01-04-2017 Added ITAR column
		ISNULL(Inventor.ITAR, 0) AS ITAR, 	
		(SELECT p.LOTDETAIL from PARTTYPE p WHERE p.PART_TYPE = inventor.PART_TYPE AND p.PART_CLASS = inventor.PART_CLASS) AS LOTDETAIL
		,sodetail.W_KEY	
 		,ISNULL(Sodetail.UNIQUELN,Pldetail.Uniqueln) UNIQUELN
		,LTRIM(RTRIM(Pldetail.SHIPPEDREV)) SHIPPEDREV
		,Pldetail.plpl_gl_nbr As PLPL_GL_NBR 
		,Pldetail.plcog_gl_nbr  As PLCOG_GL_NBR 	
		,ISNULL(Pldetail.INV_LINK, SPACE(10)) AS INV_LINK
		,inventor.USEIPKEY 
		,ISNULL(sodetail.SHIPPEDQTY, 0.00) AS totalShippedQty
		 --Sachin s : 08-23-2016 Filter list by Slinke addresss
		,sodetail.SLinkAdd AS SLinkAdd,
		-- Shrikant B 10-22-2018 : Added Collumn IsSFBL for SFBL warehouse identity
		sodetail.IsSFBL
	FROM Pldetail pldetail 
	INNER JOIN Plmain plmain ON pldetail.PACKLISTNO=plmain.PACKLISTNO
    LEFT OUTER JOIN Sodetail ON Pldetail.Uniqueln = Sodetail.Uniqueln
    LEFT OUTER JOIN Inventor ON Sodetail.uniq_key = Inventor.uniq_key
	WHERE PLmain.Packlistno = @packListNo 	
UNION 

SELECT DISTINCT 
		--Trim the zero's
		inventor.UNIQ_KEY,
		sodetail.LINE_NO AS LINE_NO,
		ISNULL(Part_no,SPACE(25)) AS Part_no,	
		ISNULL(Revision,SPACE(8)) AS Revision, 
		--Satish B- 12-28-2016 Combine part class,part type and description as one column
		--Satish B- 04-16-2018 Select description from sodetail if description from Inventor is null or empty
		--Satish B- 06-04-2018 Check ISNULL and modify the selection of ClassTypeDescript
		--ISNULL(ISNULL(Part_Class,SPACE(8)) +'/'+' '+ ISNULL(Part_Type,SPACE(8)) +'/'+' '+ inventor.DESCRIPT,sodetail.Sodet_Desc) AS ClassTypeDescript,
		ISNULL(Part_Class,'') + (CASE  WHEN Part_Class IS NULL OR Part_Class='' THEN '' ELSE '/' END ) +' '+ ISNULL(Part_Type,'') 
		  +(CASE  WHEN Part_Type IS NULL OR Part_Type='' THEN '' ELSE '/' END )+' '+ RTRIM(ISNULL(inventor.DESCRIPT,sodetail.Sodet_Desc)) AS ClassTypeDescript,
		
		--ISNULL(Part_Class,SPACE(8)) AS Part_Class, 
		--ISNULL(Part_Type,SPACE(8)) AS Part_Type, 
		--inventor.DESCRIPT	AS Descript,
		--Satish B- 04-16-2018 Select U_of_meas from sodetail table if inventor.U_OF_MEAS is null or empty
		ISNULL(inventor.U_OF_MEAS,sodetail.UOFMEAS) AS U_of_meas,
		--inventor.U_OF_MEAS	AS U_of_meas,
		ISNULL(sodetail.Ord_Qty,0.00) AS Ord_Qty,
		ISNULL(sodetail.BALANCE, 0.00) AS BALANCE, 
		ISNULL(sodetail.BALANCE, 0.00) AS BaseBalance,
		0 AS BaseShippedQty,	
		0 AS SHIPPEDQTY,
		sodetail.SONO Sono,
	 	ISNULL(Part_Sourc, SPACE(10)) AS Part_Sourc, 
		ISNULL(Inventor.SerialYes, 0) AS SerialYes,
		ISNULL(Inventor.Cert_Req, 0) AS CERT_REQ,
		--Satish B- 01-04-2017 Added ITAR column
		ISNULL(Inventor.ITAR, 0) AS ITAR 	
		,'' AS LOTDETAIL
		,sodetail.W_KEY	
		,Sodetail.UNIQUELN 
		,'' AS SHIPPEDREV
		,'' As PLPL_GL_NBR 
		,'' As PLCOG_GL_NBR
		,'' AS INV_LINK 
		,inventor.USEIPKEY
		,ISNULL(sodetail.SHIPPEDQTY, 0.00) AS totalShippedQty 	
		--Sachin s : 08-23-2016 Get SLinkAdd from sodetail
		,sodetail.SLinkAdd AS SLinkAdd,
		-- Shrikant B 10-22-2018 : Added Collumn IsSFBL for SFBL  
		sodetail.IsSFBL
			--Satish B : 04-8-2018 Replace Left join with Inner join 
		--Satish B : 04-10-2018 Replace Inner join with Left join to display manual part which are added while creating sales order
	FROM Sodetail sodetail LEFT JOIN Inventor 
	--Satish B : 04-16-2018 Removed filter of UNIQUELN against PLDETAIL table
	ON Sodetail.Uniq_key = Inventor.Uniq_key --AND sodetail.UNIQUELN NOT IN (SELECT UNIQUELN FROM PLDETAIL WHERE PACKLISTNO =@packListNo)	
	WHERE Sono = @sono 
		AND ISNULL(sodetail.BALANCE, 0) > 0 
		--Satish B : 12-22-2016 : Check sodetail.ORD_QTY with sodetail.BALANCE instade of sodetail.SHIPPEDQTY
		--AND ISNULL(sodetail.SHIPPEDQTY, 0) 	< ISNULL(sodetail.BALANCE, 0)	
		AND ISNULL(sodetail.ORD_QTY, 0) >= ISNULL(sodetail.BALANCE, 0)
		--Satish B : 04-16-2018 Added filter of UNIQUELN against PLDETAIL table
		AND sodetail.UNIQUELN NOT IN (SELECT UNIQUELN FROM PLDETAIL WHERE PACKLISTNO =@packListNo)),

	temptable as(SELECT  DISTINCT *  from	packingList )	

SELECT identity(INT,1,1) AS RowNumber,*INTO #TEMP FROM temptable 
IF @filter <> '' AND @sortExpression <> ''
  BEGIN
   SET @SQL=N'select  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE '+@filter+' and
   RowNumber BETWEEN '+Convert(VARCHAR,@startRecord)+' AND '+Convert(VARCHAR,@endRecord)+' ORDER BY '+ @sortExpression+''
   END
  ELSE IF @filter = '' AND @sortExpression <> ''
  BEGIN
SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE 
    RowNumber BETWEEN '+Convert(VARCHAR,@startRecord)+' AND '+Convert(VARCHAR,@endRecord)+' ORDER BY '+ @sortExpression+''
	END
  ELSE IF @filter <> '' AND @sortExpression = ''
  BEGIN
      SET @SQL=N'select  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE  '+@filter+' and
      RowNumber BETWEEN '+Convert(VARCHAR,@startRecord)+' AND '+Convert(VARCHAR,@endRecord)+''
   END
   ELSE
     BEGIN
      SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE 
   RowNumber BETWEEN '+Convert(VARCHAR,@startRecord)+' AND '+Convert(VARCHAR,@endRecord)+''
   END
   exec sp_executesql @SQL

   END
