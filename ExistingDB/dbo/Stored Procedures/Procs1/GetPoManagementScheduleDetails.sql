-- =============================================
-- Author:Satish B
-- Create date: 08/24/2017
-- Description : get Po Management detail fields
-- Modified : 09/08/2017 Satish B : change selection of count on basis of schddate
--          : 09/08/2017 Satish B : change join of tables
--          : 09/08/2017 Satish B : Remove leading zeros from WOPRJNUMBER
--          : 11/09/2017 Satish B : Change INNER join of WAREHOUS table to LEFT join
--          : 11/14/2017 Satish B : Change INNER join of POITEMS table to LEFT join
--          : 11/14/2017 Satish B : Change INNER join of WAREHOUS table to LEFT join
--          : 12/007/2017 Satish B : Select poitschd.UNIQDETNO ,warehouse.UNIQWH, ,poitem.UNIQ_KEY,,poitem.UNIQMFGRHD
--          : 03/23/2018 Satish B : Select RequestType,NA as WoNo and DistributeTo conditionally against mro and invt part
--          :01/31/2018 Comment "poitschd.GL_NBR AS GLNumber" and select GL_NBR + GL_DESCR As Glnumber
--			:02/14/2018 Satish B: Cast SchdQty and Balance feild as varchar
--			:02/25/2018 Satish B: add ('/') to warehouse in any case location exist or empty
--          :10/04/2019 Nitesh B: Get DistributeTo for 'In Store' item
-- exec GetPoManagementScheduleDetails 'XR2Y9JST35',1,10,0
-- =============================================
CREATE PROCEDURE GetPoManagementScheduleDetails
	@uniqLnNo char(10) ='',
	@startRecord int ='',
    @endRecord int =10, 
	@outTotalNumberOfRecord int OUTpUT
 AS
 BEGIN
	 SET NOCOUNT ON	 
	 --09/08/2017 Satish B : change selection of count on basis of schddate
	 SELECT COUNT(poitschd.SCHD_DATE) AS RowCnt -- Get total counts 
	 --SELECT COUNT(poitemTax.TAX_ID) AS RowCnt -- Get total counts 
	 INTO #tempPoTaxGidData
	 --09/08/2017 Satish B : change join of tables
		--FROM POITEMSTAX poitemTax
		-- INNER JOIN POITEMS poitem ON poitem.UNIQLNNO=poitemTax.UNIQLNNO
		-- INNER JOIN TAXTABL taxtable ON taxtable.TAX_ID=poitemTax.TAX_ID
		FROM POITSCHD poitschd
		--11/14/2017 Satish B : Change INNER join of POITEMS table to LEFT join
		LEFT JOIN POITEMS poitem ON poitem.UNIQLNNO=poitschd.UNIQLNNO
		--11/14/2017 Satish B : Change INNER join of WAREHOUS table to LEFT join
		LEFT JOIN WAREHOUS warehouse ON warehouse.UNIQWH=poitschd.UNIQWH
	 WHERE poitem.UNIQLNNO=@uniqLnNo
     SELECT poitschd.SCHD_DATE AS SchdDate
		  ,poitschd.REQ_DATE AS ReqDate
		  ,poitschd.ORIGCOMMITDT AS CommitDate
		  --02/14/2018 Satish B: Cast SchdQty and Balance feild as varchar
		  ,CAST(poitschd.SCHD_QTY AS VARCHAR(15)) AS QtySchd
		  --,poitschd.BALANCE 
		  --02/14/2018 Satish B: Cast SchdQty and Balance feild as varchar
		  ,CAST(poitschd.BALANCE AS VARCHAR(15))AS Balance
		  --02/25/2018 Satish B: add ('/') to warehouse in any case location exist or empty
		  ,RTRIM(warehouse.WAREHOUSE) +  '/'  + poitschd.LOCATION AS WhLoc
		  --03/23/2018 Satish B : Select RequestType,NA as WoNo and DistributeTo conditionally against mro and invt part
		  --,poitschd.REQUESTTP AS DistributeTo
		  ,poitschd.REQUESTTP  AS RequestType
		  ,poitschd.WOPRJNUMBER  AS NA
		  --10/04/2019 Nitesh B: Get DistributeTo for 'In Store' item
		  ,CASE WHEN (poitem.POITTYPE <> 'Invt Part' AND poitem.POITTYPE <> 'In Store') THEN TRIM(poitschd.REQUESTOR) ELSE TRIM(poitschd.REQUESTTP) END  AS DistributeTo
		  --09/08/2017 Satish B : Remove leading zeros from WOPRJNUMBER
		  --,poitschd.WOPRJNUMBER AS Reserve
		  ,CAST(dbo.fremoveLeadingZeros(poitschd.WOPRJNUMBER) AS VARCHAR(MAX)) AS Reserve
		  --01/31/2018 Comment "poitschd.GL_NBR AS GLNumber" and select GL_NBR + GL_DESCR As Glnumber
		  ,(select (GL_NBR) + ' ( ' +(GL_DESCR)+ ' ) ' from GL_NBRS where GL_NBR = poitschd.GL_NBR) AS GLNumber
		  --,poitschd.GL_NBR AS GLNumber

		  ,poitschd.SCHDNOTES
		  ,poitem.UNIQLNNO
		  --12/007/2017 Satish B : Select poitschd.UNIQDETNO ,warehouse.UNIQWH, ,poitem.UNIQ_KEY,,poitem.UNIQMFGRHD
		  ,poitschd.UNIQDETNO
		  ,warehouse.UNIQWH
		  ,poitem.UNIQ_KEY
		  ,poitem.UNIQMFGRHD

	FROM POITSCHD poitschd
	--11/14/2017 Satish B : Change INNER join of POITEMS table to LEFT join
	LEFT JOIN POITEMS poitem ON poitem.UNIQLNNO=poitschd.UNIQLNNO
	--11/09/2017 Satish B : Change INNER join of WAREHOUS table to LEFT join
	LEFT JOIN WAREHOUS warehouse ON warehouse.UNIQWH=poitschd.UNIQWH
	WHERE poitem.UNIQLNNO=@uniqLnNo
	ORDER BY poitschd.SCHD_DATE
	OFFSET(@startRecord-1) ROWS
	FETCH NEXT @EndRecord ROWS ONLY;

	SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempPoTaxGidData) -- Set total count to Out paramete
END