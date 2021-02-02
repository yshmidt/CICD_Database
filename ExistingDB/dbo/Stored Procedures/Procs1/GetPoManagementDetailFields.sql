-- =============================================
-- Author:Satish B
-- Create date: 08/24/2017
-- Description : get Po Management detail fields
-- Modified : 10/05/2017 : Satish B : Select sum of poitschd.SCHD_QTY instade of selecting individual record
--          : 10/05/2017 : Satish B : Remove poitschd.SCHD_QTY from group by 
--          : 11/07/2017 : Satish B : Convert ORD_QTY from decimal to string for binding to UI with decimal places
--          : 11/07/2017 : Satish B : Convert S_ORD_QTY from decimal to string for binding to UI with decimal places
--          : 11/07/2017 : Satish B : Convert COSTEACH from decimal to string for binding to UI with decimal places
--          : 11/07/2017 : Satish B : Convert COSTEACHFC from decimal to string for binding to UI with decimal places
--          : 11/07/2017 : Satish B : Convert STDCOST from decimal to string for binding to UI with decimal places
--          : 11/07/2017 : Satish B : Convert TARGETPRICE from decimal to string for binding to UI with decimal places
--          : 11/08/2017 : Satish B : Check ISNULL. If null then return 0
--          : 11/08/2017 : Satish B : Change INNER join of INVENTOR to LEFT join
--          : 11/08/2017 : Satish B : Change INNER join of InvtMPNLink and MfgrMaster to LEFT join
--          : 11/14/2017 : Satish B : Change INNER join of POITSCHD to LEFT join
--          : 12/06/2017 : Satish B : Select PUR_UOFM from inventor and poitems conditionally
--          : 12/06/2017 : Satish B : Select U_OF_MEAS from inventor and poitems conditionally
--          : 12/06/2017 : Satish B : Added PUR_UOFM and U_OF_MEAS in group by 
--          : 12/20/2017 : Satish B : Convert costeach from purchase UOM to stock UOM
--          : 01/03/2018 : Satish B : Check Isnull for SCHD_QTY,Balance and UnScheduled
--          : 01/04/2018 : Satish B : Select TaxId
--          : 01/04/2018 : Satish B : Added join of POITEMSTAX table
--          : 01/04/2018 : Satish B : Select TAX_ID in gruop by clause
--			: 3/22/2018 : Satish B : Select top 1 RoHS value from #tempPoDetails because when multiple tax is applied then in tempPoDetails table we get multiple record only difference in taxid
--			: 10/16/2017 : Satish B : Select inventor.MATL_COST
--			: 10/16/2017 : Satish B : Select inventor.MATL_COST  in gruop by clause
-- exec GetPoManagementDetailFields 'T000000000TEMP5','DSL7Z6T20J'
-- =============================================
CREATE PROCEDURE GetPoManagementDetailFields
	@poNumber char(15) ='',
	@uniqLnNo char(10) =''
 AS
 BEGIN
	 SET NOCOUNT ON	 
	 DECLARE @roHsField char(10);
     SELECT poitem.UNIQ_KEY
	    --11/07/2017 : Satish B : Convert ORD_QTY from decimal to string for binding to UI with decimal places
	    ,CAST(poitem.ORD_QTY AS VARCHAR(12)) AS PURCHASE
	    --,poitem.ORD_QTY AS PURCHASE
		--12/06/2017 : Satish B : Select PUR_UOFM from inventor and poitems conditionally
		--,poitem.PUR_UOFM AS EACH
		,ISNULL(inventor.PUR_UOFM, poitem.PUR_UOFM) AS PUR_UOFM 
		--11/07/2017 : Satish B : Convert S_ORD_QTY from decimal to string for binding to UI with decimal places
		--,poitem.ORD_QTY AS STOCK
		,CAST(poitem.S_ORD_QTY AS VARCHAR(12)) AS STOCK
		,poitem.OVERAGE
		,fcused.Symbol AS TRANSL
		,poitem.PONUM
		--11/07/2017 : Satish B : Convert COSTEACH from decimal to string for binding to UI with decimal places
		,ISNULL(CAST(poitem.COSTEACH AS VARCHAR(22)),'') AS COSTEACH
		--,poitem.COSTEACH 
		--12/06/2017 : Satish B : Select U_OF_MEAS from inventor and poitems conditionally
		--,poitem.U_OF_MEAS 
		,ISNULL(inventor.U_OF_MEAS, poitem.U_OF_MEAS ) AS U_OF_MEAS 
		,poitem.IS_TAX 
		--11/07/2017 : Satish B : Convert COSTEACHFC from decimal to string for binding to UI with decimal places
		,ISNULL(CAST(poitem.COSTEACHFC  AS VARCHAR(22)),'') AS COSTEACHFC 
		--,poitem.COSTEACHFC 
		--11/07/2017 : Satish B : Convert STDCOST from decimal to string for binding to UI with decimal places
		,ISNULL(CAST(inventor.STDCOST AS VARCHAR(18)),'') AS STDCOST 
		--,inventor.STDCOST
		--11/07/2017 : Satish B : Convert TARGETPRICE from decimal to string for binding to UI with decimal places
		,ISNULL(CAST(inventor.TARGETPRICE AS VARCHAR(18)),'') AS TARGETPRICE 
		--,inventor.TARGETPRICE
		--11/08/2017 : Satish B : Check ISNULL. If null then return 0
		,ISNULL(inventor.PUR_LTIME,0) As PUR_LTIME
		,ISNULL(inventor.PUR_LUNIT,0) As PUR_LUNIT
		,ISNULL(inventor.MINORD	  ,0) As MINORD
		,ISNULL(inventor.ORDMULT  ,0) As ORDMULT
		,poitem.ISFIRM
		,poitem.FIRSTARTICLE
		,poitem.INSPEXCEPT
		,poitem.INSPEXCEPTION
		,CAST(poitem.INSPEXCNOTE AS NVARCHAR(MAX))  AS INSPEXCNOTE
		--10/05/2017 : Satish B : Select sum of poitschd.SCHD_QTY instade of selecting individual record
		--01/03/2018 : Satish B : Check Isnull for SCHD_QTY,Balance and UnScheduled
		,ISNULL(SUM(poitschd.SCHD_QTY),0) AS SCHD_QTY
		--,poitschd.SCHD_QTY
		,ISNULL(SUM(poitschd.BALANCE),0) AS Balance
		,ISNULL((poitem.ORD_QTY-SUM(poitschd.SCHD_QTY)),0) AS UnScheduled
		,fc.Symbol AS SYMBOL
	    ,mfgrMaster.MatlType AS RoHS
		--12/20/2017 : Satish B : Convert costeach from purchase UOM to stock UOM
		,cast(dbo.fn_convertPrice('Pur',poitem.COSTEACH ,poitem.PUR_UOFM ,poitem.U_OF_MEAS ) as numeric(13,5)) as CostEachSUM
		--01/04/2018 : Satish B : Select TaxId
		,ISNULL(pTax.TAX_ID,'') AS TaxId
		--10/16/2017 : Satish B : Select inventor.MATL_COST  
		,inventor.MATL_COST AS MaterialCost
		INTO #tempPoDetails
	FROM POITEMS poitem
	INNER JOIN POMAIN pomain ON pomain.PONUM=poitem.PONUM
	LEFT JOIN FcUsed fcused ON fcused.FcUsed_Uniq=pomain.FcUsed_uniq --Join with FcUsed_uniq
	LEFT JOIN FcUsed fc ON pomain.funcFcUsed_uniq = fc.FcUsed_Uniq --Join with funcFcUsed_uniq
	--11/08/2017 : Satish B : Change INNER join of INVENTOR to LEFT join
	LEFT JOIN INVENTOR inventor ON inventor.UNIQ_KEY=poitem.UNIQ_KEY
	--11/14/2017 : Satish B : Change INNER join of POITSCHD to LEFT join
	LEFT JOIN POITSCHD poitschd ON poitschd.UNIQLNNO=poitem.UNIQLNNO
	--11/08/2017 : Satish B : Change INNER join of InvtMPNLink and MfgrMaster to LEFT join
	LEFT JOIN InvtMPNLink mpn ON mpn.uniqmfgrhd=poitem.UNIQMFGRHD
	LEFT JOIN MfgrMaster mfgrMaster ON mfgrMaster.MfgrMasterId =mpn.MfgrMasterId
	--01/04/2018 : Satish B : Added join of POITEMSTAX table
	LEFT JOIN POITEMSTAX pTax ON pTax.UNIQLNNO =poitem.UNIQLNNO
	WHERE poitem.PONUM=@poNumber AND poitem.UNIQLNNO=@uniqLnNo
	GROUP BY  poitem.UNIQ_KEY
	    ,poitem.ORD_QTY
		,poitem.PUR_UOFM
		--,poitem.ORD_QTY
		,poitem.S_ORD_QTY
		,poitem.OVERAGE
		,fcused.Symbol
		,poitem.PONUM
		,poitem.COSTEACH 
		,poitem.U_OF_MEAS 
		,poitem.IS_TAX 
		,poitem.COSTEACHFC 
		,inventor.STDCOST
		,inventor.TARGETPRICE
		,inventor.PUR_LTIME
		,inventor.PUR_LUNIT
		,inventor.MINORD
		,inventor.ORDMULT
		,poitem.ISFIRM
		,poitem.FIRSTARTICLE
		,poitem.INSPEXCEPT
		,poitem.INSPEXCEPTION
		,CAST(poitem.INSPEXCNOTE AS NVARCHAR(MAX)) 
		--12/06/2017 : Satish B : Added PUR_UOFM and U_OF_MEAS in group by 
		,inventor.PUR_UOFM
		,inventor.U_OF_MEAS
		--10/05/2017 : Satish B : Remove poitschd.SCHD_QTY from group by 
		--,poitschd.SCHD_QTY
		,fc.Symbol
		,MfgrMaster.MatlType
		--01/04/2018 : Satish B : Select TAX_ID in gruop by clause
		,pTax.TAX_ID 
		--10/16/2017 : Satish B : Select inventor.MATL_COST  in gruop by clause
		,inventor.MATL_COST 
		--3/22/2018 : Satish B : Select top 1 RoHS value from #tempPoDetails because when multiple tax is applied then in tempPoDetails table we get multiple record only difference in taxid
	SET @roHsField =(SELECT top 1 RoHS FROM #tempPoDetails)
	IF(@roHsField='' OR @roHsField IS NULL)
	BEGIN
		UPDATE #tempPoDetails SET RoHS =  i.MATLTYPE  FROM  INVENTOR  I  INNER JOIN #tempPoDetails ON I.UNIQ_KEY = #tempPoDetails.UNIQ_KEY
	END

	SELECT * FROM #tempPoDetails;
END