-- =============================================
-- Author:Satish B
-- Create date: 08/21/2017
-- Description : get Po Management detail grid data
-- Modified : Satish B : 10/30/2017 Satish B : Replace Inner join of INVENTOR and INVTMPNLINK and MFGRMASTER with Left Join
--          : 10/30/2017 : Satish B : Select poItems.PART_NO and poItems.REVISION for MRO part if part is MRO
--          : 10/30/2017 : Satish B : Select poItems.DESCRIPT for MRO part if part is MRO
--          : 11/07/2017 : Satish B : Cast COSTEACH into varchar
--          : 11/07/2017 : Satish B : Cast Extention into varchar
--          : 12/01/2017 : Satish B : Replace comma(,) with comma and space(, )
--          : 12/07/2017 : Satish B : Select poItems.UNIQMFGRHD,poItems.ORD_QTY
--          : 3/23/2018 : Satish B : Select PartMfgr and MfgrPtNo conditionally for MRO and Invt part
--			: 12/26/2018 : Satish B : Remove this from above substraction
--			:22/01/2018 : Satish B :Select Scheduled Quantity,Scheduled Balance,Next Schedule Date
--			:02/19/2019 : Satish B : Replace length VARCHAR(15) VARCHAR(30) 
--   :06/25/2019 : Nitesh B : Select package column from poitems  
-- 04/22/2020 Satyawan : removed Balance condition to get SCH_Date even if balance is zero 
-- exec GetpoManagementDetailGrid '000000000000053',1,5000,0
-- =============================================
CREATE PROCEDURE GetPoManagementDetailGrid
	@poNumber char(15) ='',
	@startRecord int ='',
    @endRecord int =10, 
	@outTotalNumberOfRecord int OUTPUT
 AS
 BEGIN
	 SET NOCOUNT ON	 
	 SELECT COUNT(poItems.ITEMNO) AS RowCnt -- Get total counts 
	 INTO #tempPoDetailGidData
     FROM POITEMS poItems
	 --10/30/2017 Satish B : Replace Inner join of INVENTOR and INVTMPNLINK and MFGRMASTER with Left Join
	 LEFT JOIN INVENTOR inventor ON inventor.UNIQ_KEY =poItems.UNIQ_KEY
	 INNER JOIN POMAIN pomain ON pomain.PONUM =poItems.PONUM
	 LEFT JOIN InvtMpNLink mpnLink ON mpnLink.uniqmfgrhd= poItems.UNIQMFGRHD
	 LEFT JOIN MfgrMaster partMaster ON partMaster.MfgrMasterId = mpnLink.MfgrMasterId
	 WHERE pomain.ponum=@poNumber

	 SELECT poItems.POITTYPE AS Type
		 ,CAST(dbo.fremoveLeadingZeros(poItems.ITEMNO) AS VARCHAR(MAX)) AS Item
		 --10/30/2017 : Satish B : Select poit.PART_NO and poit.REVISION for MRO part if part is MRO
		,ISNULL(RTRIM(inventor.PART_NO) + CASE WHEN inventor.REVISION IS NULL OR inventor.REVISION='' THEN '' ELSE '/' END + inventor.REVISION,
				RTRIM(poItems.PART_NO) + CASE WHEN poItems.REVISION IS NULL OR poItems.REVISION='' THEN '' ELSE '/' END + poItems.REVISION) AS PartRev
        --10/30/2017 : Satish B : Select poit.DESCRIPT for MRO part if part is MRO
		 ,ISNULL(RTRIM(inventor.PART_CLASS) + CASE WHEN inventor.PART_CLASS IS NULL OR inventor.PART_CLASS='' THEN '' ELSE '/' END + 
					 RTRIM(inventor.PART_TYPE) + CASE WHEN inventor.PART_TYPE IS NULL OR inventor.PART_TYPE='' THEN '' ELSE '/' END +
		--12/01/2017 : Satish B : Replace comma(,) with comma and space(, )
					 REPLACE(inventor.DESCRIPT,',',', '),REPLACE(poItems.DESCRIPT,',',', ')) AS Descript
        --3/23/2018 : Satish B : Select PartMfgr and MfgrPtNo conditionally for MRO and Invt part
        --,partMaster.partMfgr AS PartMfgr
		--,partMaster.mfgr_pt_no AS MfgrPtNo
		,RTRIM(ISNULL(partMaster.partMfgr,poItems.partMfgr)) AS PartMfgr
		,RTRIM(ISNULL(partMaster.mfgr_pt_no,poItems.mfgr_pt_no)) AS MfgrPtNo
		 
		 --11/07/2017 : Satish B : Cast COSTEACH into varchar
		 --02/19/2019 : Satish B : Replace length VARCHAR(15) VARCHAR(30) 
		 ,CAST(poItems.COSTEACH AS VARCHAR(30)) AS PriceEach
		 ,poItems.IS_TAX AS Taxable
		 ,poItems.LCANCEL AS Cancel
		 ,poItems.UNIQLNNO
		 ,inventor.UNIQ_KEY
		 ,((poItems.ORD_QTY - poItems.ACPT_QTY)) As BalQty
		 --12/26/2018 : Satish B : Remove this from above substraction
		 	 --,((poItems.ORD_QTY - poItems.ACPT_QTY)- ISNULL((SELECT SUM(receiverDetail.Qty_rec)
		   --        FROM receiverDetail WHERE receiverDetail.UNIQLNNO = poItems.UNIQLNNO and receiverDetail.isCompleted = 0),0)) As BalQty
		--11/07/2017 : Satish B : Cast Extention into varchar
		--02/19/2019 : Satish B : Replace length VARCHAR(15) VARCHAR(30) 
        ,CAST((((poItems.ORD_QTY - poItems.ACPT_QTY)- ISNULL((SELECT SUM(receiverDetail.Qty_rec)
		           FROM receiverDetail WHERE receiverDetail.UNIQLNNO = poItems.UNIQLNNO and receiverDetail.isCompleted = 0),0)) * poItems.COSTEACH) AS VARCHAR(30)) As Extention
	    --12/07/2017 : Satish B : Select poItems.UNIQMFGRHD,poItems.ORD_QTY
		,poItems.UNIQMFGRHD
		,poItems.ORD_QTY AS OrdQty
		 --22/01/2018 : Satish B :Select Scheduled Quantity,Scheduled Balance,Next Schedule Date
		,CAST((SELECT SUM(schd_qty) from POITSCHD where uniqlnno=poItems.UNIQLNNO) AS VARCHAR(15))AS schd_qty
		,CAST(((poItems.ORD_QTY - poItems.ACPT_QTY)- ISNULL((SELECT SUM(receiverDetail.Qty_rec)
		           FROM receiverDetail WHERE receiverDetail.UNIQLNNO = poItems.UNIQLNNO AND receiverDetail.isCompleted = 0),0)) AS DECIMAL(10,2)) As schd_bal
  --,(SELECT TOP 1 SCHD_DATE from POITSCHD where uniqlnno=poItems.UNIQLNNO AND BALANCE > 0) AS Next_Date   
  ,(SELECT TOP 1 SCHD_DATE from POITSCHD where uniqlnno=poItems.UNIQLNNO) AS Next_Date -- 04/22/2020 Satyawan : removed Balance condition to get SCH_Date even if balance is zero
  -- 06/25/2019 : Nitesh B : Select package column from poitems     
  ,poItems.Package  
	 FROM POITEMS poItems
	 --10/30/2017 Satish B : Replace Inner join of INVENTOR and INVTMPNLINK and MFGRMASTER with Left Join
		 LEFT JOIN INVENTOR inventor ON inventor.UNIQ_KEY =poItems.UNIQ_KEY
		 INNER JOIN POMAIN pomain ON pomain.PONUM =poItems.PONUM
		 LEFT JOIN InvtMpNLink mpnLink ON mpnLink.uniqmfgrhd= poItems.UNIQMFGRHD
		 LEFT JOIN MfgrMaster partMaster ON partMaster.MfgrMasterId = mpnLink.MfgrMasterId
	 WHERE pomain.ponum=@poNumber
	 ORDER BY poItems.ITEMNO
	 OFFSET(@startRecord-1) ROWS
	 FETCH NEXT @EndRecord ROWS ONLY;

	 SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempPoDetailGidData) -- Set total count to Out parameter 
END