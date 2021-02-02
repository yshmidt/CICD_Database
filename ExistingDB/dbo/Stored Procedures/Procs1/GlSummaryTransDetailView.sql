-- =============================================  
-- Author:  Nilesh Sa  
-- Create date: 08/19/2016  
-- Description: This SP used in the GLVIEW form for the detail tab.  
-- [GlSummaryTransDetailView] '1210000-00-30','7/1/2017 12:00:00 AM','7/31/2017 12:00:00 AM',1,150000,null,null  
-- 11/23/2017 Nilesh Sa : Optimized as it was taking longer to filter data added temp table GLSummaryDetailsData.  
-- 01/02/2018 Nilesh Sa : Fix the Sorting Reported By Debbie and add default short expression if short expression is null  
-- 01/09/2018 Nilesh Sa : Removed + 1 from @startRecord for issue skip one record  
-- 01/22/2018 Nilesh Sa: Added GLTRANSUNIQUE column in selection  
-- 01/25/2018 Nilesh Sa: Check RTRIM for gljehdr.JE_NO number and removed extra space from Reason  
-- 07/26/2018 Nilesh Sa:Fetch the result based on fiscal year and period
-- [GlSummaryTransDetailView] '1031000-00-00','2018',8,'1/1/2012 12:00:00 AM','1/31/2012 12:00:00 AM',150,300,'',''  
-- =============================================  
CREATE PROCEDURE [dbo].[GlSummaryTransDetailView]  
 -- Add the parameters for the stored procedure here  
	 @lcGlNbr AS VARCHAR(13) = ' '  
	 	-- 07/26/2018 Nilesh Sa:Fetch the result based on fiscal year and period
	,@fiscalYear AS CHAR(4) = null
	,@period AS NUMERIC(2,0) = null
	,@lcDateStart AS SMALLDATETIME= null  
	,@lcDateEnd AS SMALLDATETIME = null  
	,@startRecord INT = 1  
    ,@endRecord INT = 50   
    ,@sortExpression NVARCHAR(1000) = null  
    ,@filter NVARCHAR(1000) = null   
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets FROM  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 DECLARE @SQL NVARCHAR(MAX)  
  
 -- 01/02/2018 Nilesh Sa : Fix the Sorting Reported By Debbie and add default short expression if short expression is null  
 IF(@sortExpression = NULL OR @sortExpression = '')  
 BEGIN  
  SET @sortExpression = 'TRANS_DT desc'  
 END  
  
    -- Insert statements for procedure here  
 -- 11/23/2017 Nilesh Sa : Optimized as it was taking longer to filter data added temp table GLSummaryDetailsData.  
;WITH GLSummaryDetailsData AS  
(  
        SELECT GLTRANSHEADER.FY,GLTRANSHEADER.PERIOD ,GLTRANSHEADER.TRANS_NO,GltransHeader.TransactionType,GLTRANSHEADER.POST_DATE,GLTRANSHEADER.TRANS_DT,  
		  gltrans.GL_NBR,GlTransDetails.DEBIT, GlTransDetails.CREDIT, gltrans.SourceTable, gltrans.CIDENTIFIER,gltransdetails.cDrill  
		  ,gltrans.SourceSubTable,gltrans.cSubIdentifier,GlTransDetails.cSubDrill,GLTRANSHEADER.GLTRANSUNIQUE -- 01/22/2018 Nilesh Sa: Added GLTRANSUNIQUE column in selection  
		  FROM GLTRANSHEADER    
		  INNER JOIN gltrans ON gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique AND gltrans.GL_NBr = @lcGlNbr  
		  INNER JOIN GlTransDetails ON gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key      
        WHERE DATEDIFF(Day,GLTRANSHEADER.trans_dt,@lcDateStart)<=0   
		  AND DATEDIFF(Day,GLTRANSHEADER.TRANS_DT,@lcDateEnd)>=0  
			-- 07/26/2018 Nilesh Sa:Fetch the result based on fiscal year and period
		  AND GLTRANSHEADER.FY = @fiscalYear AND GLTRANSHEADER.Period = @period
)  
--select * FROM GLSummaryDetailsViews  
,GLSummaryDetailsView AS(   
  SELECT FY,PERIOD ,TRANS_NO,TransactionType,POST_DATE,TRANS_DT,  
  GL_NBR,DEBIT, CREDIT, SourceTable, CIDENTIFIER,cDrill  
  ,SourceSubTable,cSubIdentifier,cSubDrill,GLTRANSUNIQUE -- 01/22/2018 Nilesh Sa: Added GLTRANSUNIQUE column in selection  
  ,CASE   
   WHEN TransactionType = 'APPREPAY' THEN(SELECT CAST('AP Offset against Prepay: '+RTRIM(apmaster.ponum)  AS VARCHAR(100))   
    FROM apmaster  
    WHERE apmaster.UNIQAPHEAD = RTRIM(cSubDrill))  
   WHEN TransactionType = 'ARPREPAY' AND cSubIdentifier = 'UniqueAr' THEN   
    (SELECT distinct CAST(CASE WHEN Acctsrec.lPrepay=1 THEN  'AR Offset using Prepay: '+ RTRIM(ACCTSREC.invno)   
    ELSE 'AR Offset against Prepay: '+ RTRIM(ACCTSREC.invno) END  AS VARCHAR(100))  
    FROM AROFFSET,ACCTSREC   
    WHERE aroffset.CTRANSACTION = RTRIM(cdrill) AND acctsrec.uniquear = rtrim(csubdrill))  
   WHEN TransactionType = 'ARPREPAY' AND cSubIdentifier = 'CTRANSACTION' THEN (SELECT CAST(rtrim(SourceTable)+'.'+rtrim(CIDENTIFIER)+': '+rtrim(cDrill) AS VARCHAR(100)))  
   WHEN TransactionType = 'ARWO'  THEN (select CAST('Cust: '+rtrim(customer.custname)+'  Inv#: '+acctsrec.INVNO AS VARCHAR(100))   
    FROM AR_WO  
    INNER JOIN ACCTSREC ON AR_WO.UniqueAR = ACCTSREC.UNIQUEAR  
    INNER JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO  
    WHERE AR_WO.ARWOUNIQUE =RTRIM(CDRILL))   
   WHEN TransactionType = 'CHECKS' THEN (SELECT CAST('Check#: '+RTRIM(checkno)+'  Bank Acct# '+RTRIM(BANKS.BK_ACCT_NO)+'  Supp: '+rtrim(supinfo.supname) AS VARCHAR(100))   
    FROM APCHKMST  
    INNER JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO  
    INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ  
     WHERE apchkmst.APCHK_UNIQ =RTRIM(CDRILL))  
   WHEN TransactionType = 'CM'  THEN (select cast('Customer: ' +RTRIM(CustName)+', Credit Memo: '+ rtrim(cmemono) AS CHAR (80))  
    FROM cmmain   
    INNER JOIN Customer ON cmmain.CUSTNO = customer.CUSTNO WHERE cdrill = cmmain.cmunique)  
   WHEN TransactionType = 'CONFGVAR' THEN (SELECT CAST('WO#: '+Confgvar.wono+'  Date: '+ cast(cast(confgvar.DATETIME AS DATE)AS VARCHAR(10))+' Part/Rev: '+rtrim(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty Trns: '+ cast(CAST(qtytransf AS numeric(12,0))AS VARCHAR(12)) AS VARCHAR(100))   
    FROM CONFGVAR   
    INNER JOIN INVENTOR ON confgvar.UNIQ_KEY = inventor.UNIQ_KEY  
    WHERE Confgvar.UNIQCONF=RTRIM(CDRILL))  
   WHEN TransactionType = 'COSTADJ' THEN (SELECT CAST('PN/Rev: '+RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+ '  QtyOH: '+ rtrim(updtstd.QTY_OH)+'  Old: '+rtrim(updtstd.OLDMATLCST)+'  New: '+RTRIM(updtstd.newmatlcst) AS VARCHAR(80))  
    FROM UPDTSTD  
    INNER JOIN INVENTOR ON updtstd.UNIQ_KEY = inventor.UNIQ_KEY  
    WHERE updtstd.UNIQ_UPDT = RTRIM(cdrill))  
   WHEN TransactionType = 'DEP' THEN (select cast('Deposit Number: ' + rtrim(cDrill)+'  Bank Acct# '+RTRIM(deposits.bk_acct_no)  AS VARCHAR (100))   
    FROM DEPOSITS  
    WHERE deposits.DEP_NO = RTRIM(cdrill))  
   WHEN TransactionType = 'DM' THEN (SELECT CASE WHEN DMEMOS.DMTYPE = 1 THEN cast(rtrim(Dmemono)+'  Supp: '+rtrim(supname)+', '+CASE WHEN DMEMOS.PONUM = '' THEN '' ELSE '  PO#:'+RTRIM(DMEMOS.PONUM)END+ '  Against Inv' AS VARCHAR(100))   
    when dmemos.dmtype = 2 THEN cast (RTRIM(dmemono)+'  Supp: '+ rtrim(supname)+','+  CASE WHEN DMEMOS.PONUM = '' THEN '' ELSE '  PO#:'+RTRIM(DMEMOS.PONUM)END + '  Against Acct' AS VARCHAR(100)) end   
    FROM dmemos INNER JOIN SUPINFO ON DMEMOS.uniqsupno = supinfo.UNIQSUPNO    
    WHERE DMEMOS.UNIQDMHEAD  =RTRIM(CDRILL))  
   WHEN TransactionType = 'INVTCOSTS' THEN (select case when confgvar.wono = 'PORecon' THEN cast (rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'PO#: '+confgvar.ponum+'  Qty: '+cast(CAST(confgvar.QTYTRANSF AS numeric(12,0))AS VARCHAR(12)) AS VARCHAR(100))   
    else cast (rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'WO#: '+confgvar.wono+'  Qty: '+ cast(CAST(confgvar.QTYTRANSF AS numeric(12,0))AS VARCHAR(12)) AS VARCHAR (100))end   
    FROM confgvar LEFT OUTER JOIN INVENTOR ON confgvar.uniq_key = inventor.uniq_key  WHERE CONFGVAR.UNIQCONF = RTRIM(cDrill))   
   WHEN TransactionType = 'INVTISU' THEN (SELECT CAST ('PN/Rev: ' + RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+'Wh: '+RTRIM(warehous.WAREHOUSE)+'  Qty: '+RTRIM(INVT_ISU.QTYISU )+'  Cost: '+RTRIM(invt_ISU.stdcost) AS VARCHAR (100))  
    FROM Invt_ISU  
    INNER JOIN INVENTOR ON invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY  
    INNER JOIN INVTMFGR ON invt_ISU.W_KEY = invtmfgr.W_KEY  
    INNER JOIN WAREHOUS ON invtmfgr.UNIQWH = warehous.UNIQWH  
    WHERE invt_isu.INVTISU_NO = RTRIM(cdrill))  
   WHEN TransactionType = 'INVTREC' THEN (SELECT  CAST('PN/Rev: '+ RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+'Wh: '+RTRIM(warehous.WAREHOUSE)+'  Qty: '+RTRIM(invt_rec.qtyrec)+'  Cost: '+RTRIM(invt_rec.stdcost) AS VARCHAR (100))   
    FROM Invt_rec  
    INNER JOIN INVENTOR ON invt_rec.UNIQ_KEY = inventor.UNIQ_KEY  
    INNER JOIN INVTMFGR ON invt_rec.W_KEY = invtmfgr.W_KEY  
    INNER JOIN WAREHOUS ON invtmfgr.UNIQWH = warehous.UNIQWH  
    WHERE INVT_REC.INVTREC_NO = RTRIM(cdrill))  
--   04/15/2013 DRP: needed to look for INVTTRNS in SQL  
   --when gltransheader.TransactionType = 'INVTTRANS' THEN (SELECT CAST (RTRIM(INVTTRNS.REASON)+'  PN/Rev: ' + RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty: '+RTRIM(invtTRNS.QTYXFER)+'  Cost: '+RTRIM(INVTTRNS.stdcost) AS VARCHAR (100))  
   WHEN TransactionType = 'INVTTRNS' THEN (SELECT CAST (RTRIM(INVTTRNS.REASON)+'  PN/Rev: ' + RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty: '+RTRIM(invtTRNS.QTYXFER)+'  Cost: '+RTRIM(INVTTRNS.stdcost) AS VARCHAR (100))  
    FROM INVTTRNS  
    INNER JOIN INVENTOR ON INVTTRNS.UNIQ_KEY = INVENTOR.UNIQ_KEY  
    WHERE INVTTRNS.INVTXFER_N = RTRIM(cDrill))  
    --01/25/2018 Nilesh Sa: Check RTRIM for gljehdr.JE_NO number and removed extra space from Reason  
   WHEN TransactionType = 'JE' THEN (SELECT cast(rtrim(gljehdr.JETYPE)+' JE# '+RTRIM(CAST(gljehdr.JE_NO AS char (6)))+' Reason: '+RTRIM(GLJEHDR.REASON) AS VARCHAR (100))   
    FROM  GLJEHDR WHERE cDrill = gljehdr.UNIQJEHEAD)  
   WHEN TransactionType = 'MFGRVAR' THEN (SELECT CAST('WO#: '+RTRIM(MFGRVAR.WONO)+'  Date:'+cast(cast(mfgrvar.DATETIME AS DATE)AS VARCHAR(10))+'  Part/Rev: '+rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+' Desc: '+RTRIM(inventor.descript) AS VARCHAR(100))   
    FROM MFGRVAR,INVENTOR  
    WHERE MFGRVAR.UNIQMFGVAR=RTRIM(CDRILL)  
    AND inventor.UNIQ_KEY = mfgrvar.UNIQ_KEY)  
   WHEN TransactionType = 'NSF' THEN (select 'NSF: '+cast(RTRIM(cdrill) + ' for Dep#: ' + rtrim(ARRETCK.DEP_NO)+'  Receipt Advice: '+RTRIM(arretck.rec_advice)+'  Cust: '+RTRIM(custname)  AS VARCHAR(100))   
    FROM ARRETCK  
    INNER JOIN CUSTOMER ON arretck.CUSTNO = customer.CUSTNO WHERE cdrill = arretck.UNIQRETNO)   
   WHEN TransactionType = 'PURCH' THEN (SELECT CAST(' Inv#: '+rtrim(apmaster.invno)+'  PO#: '+rtrim(apmaster.ponum)+ '  Supp: '+RTRIM(Supname)  AS VARCHAR(100))   
    FROM Apmaster   
    INNER JOIN Supinfo ON apmaster.UNIQSUPNO = supinfo.UNIQSUPNO   
    WHERE apmaster.UNIQAPHEAD =RTRIM(CDRILL))    
   WHEN TransactionType = 'PURVAR' THEN (SELECT CAST('Recv#: '+rtrim(Sinvoice.receiverno)+'  '+'Inv#: '+rtrim(sinvoice.INVNO)+'  Part/Rev: '+RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision) AS VARCHAR(100))   
    FROM pur_var  
    INNER JOIN SINVDETL ON Pur_Var.sdet_UNIQ = sinvdetl.SDET_UNIQ  
    INNER JOIN SINVOICE ON sinvdetl.sinv_uniq = sinvoice.SINV_UNIQ  
    INNER JOIN POITEMS ON sinvdetl.UNIQLNNO = POITEMS.UNIQLNNO  
    INNER JOIN INVENTOR ON poitems.UNIQ_KEY = inventor.UNIQ_KEY  
    WHERE pur_var.VAR_KEY =RTRIM(cDrill))   
   WHEN TransactionType = 'ROUNDVAR' THEN (SELECT CAST('Rounding Variance for WO#: '+mfgrvar.WONO  AS VARCHAR(80)) FROM MFGRVAR  WHERE MFGRVAR.UNIQMFGVAR=RTRIM(CDRILL))  
   WHEN TransactionType = 'SALES' THEN (SELECT  CAST('Customer: '+RTRIM(CustName)+', Invoice: '+InvoiceNo AS VARCHAR(100))   
    FROM Plmain   
    INNER JOIN Customer ON Plmain.custno = customer.CUSTNO   
    WHERE plmain.PACKLISTNO =RTRIM(CDRILL))  
   WHEN TransactionType = 'SCRAP' THEN (SELECT CAST('WO#: '+SCRAPREL.wono+'  Date: '+ cast(cast(SCRAPREL.DATETIME AS DATE)AS VARCHAR(10))+'  Part/Rev: '+RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty: '+cast(CAST(scraprel.QTYTRANSF AS numeric
(12,0))AS VARCHAR(12))+'  Cost: '+cast(scraprel.stdcost AS VARCHAR(17)) AS VARCHAR(100))   
    FROM SCRAPREL,INVENTOR  
    WHERE ScrapRel.TRANS_NO=RTRIM(CDRILL)  
    AND inventor.UNIQ_KEY = scraprel.UNIQ_KEY)  
   WHEN TransactionType = 'UNRECREC' THEN (SELECT CAST('Recv# '+Porecloc.RECEIVERNO+'  '+'PO# '+RTRIM(poitems.ponum)+'  CO# '+RTRIM(pomain.conum)+'  Item# '+RTRIM(poitems.ITEMNO)+'  Supp:'+RTRIM(supinfo.supname)  AS VARCHAR(100))   
    FROM porecrelgl   
    INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ   
    INNER JOIN PORECDTL ON porecloc.FK_UNIQRECDTL = porecdtl.UNIQRECDTL  
    INNER JOIN POitems ON porecdtl.UNIQLNNO = poitems.uniqlnno  
    INNER JOIN POMAIN ON poitems.PONUM = pomain.ponum  
    INNER JOIN SUPINFO ON pomain.UNIQSUPNO = supinfo.UNIQSUPNO  
    WHERE PorecRelGl.UNIQRECREL =RTRIM(CDRILL))  
   ELSE CAST('Cannot Link back to source' AS VARCHAR(100))  
   END AS TransDescr  
   FROM GLSummaryDetailsData    
  )  
   SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP FROM GLSummaryDetailsView   
   -- 01/02/2018 Nilesh Sa : Fix the Sorting Reported By Debbie and add default short expression if short expression is null  
   IF @filter <> '' AND @sortExpression <> ''  
    BEGIN  
     SET @SQL=N'select  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount FROM #TEMP  t  WHERE '+@filter  
     +' ORDER BY '+ @SortExpression+''+ ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'   
     -- 01/09/2018 Nilesh Sa : Removed + 1 from @startRecord for issue skip one record  
     END  
   ELSE IF @filter = '' AND @sortExpression <> ''  
     BEGIN  
   SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount FROM #TEMP  t '  
   +' ORDER BY '+ @sortExpression+'' + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'  
   -- 01/09/2018 Nilesh Sa : Removed + 1 from @startRecord for issue skip one record  
  END  
   ELSE IF @filter <> '' AND @sortExpression = ''  
    BEGIN  
    SET @SQL=N'select  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount FROM #TEMP  t  WHERE  '+@filter+''   
    + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'  
    -- 01/09/2018 Nilesh Sa : Removed + 1 from @startRecord for issue skip one record  
    END  
   ELSE  
   BEGIN  
    SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount FROM #TEMP t'   
     + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord) + ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'  
     -- 01/09/2018 Nilesh Sa : Removed + 1 from @startRecord for issue skip one record  
      END  
  EXEC SP_EXECUTESQL @SQL  
END