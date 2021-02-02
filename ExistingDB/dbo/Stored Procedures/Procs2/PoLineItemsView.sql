-- =================================================    
-- Author:  Nitesh B    
-- Create date: <04/17/2016>    
-- Description: Return PO Line Items.. 1013002    
-- PoLineItemsView '000000000001903', @receiverNo='0001012994'    
-- PoLineItemsView '000000000792314', @receiverNo='0001013002','PT7XQNHSPS'  1012999    
--Shivshsnkar P :04/01/17 Used for display wether part is loted/not on grid    
--Shivshsnkar P :02/01/17 For getting all line items based on ponum OR Single line Item    
--Shivshankar P : 05/18/17  Added Two Table Join to get their columns    
--Shivshsnkar P :21/06/17 Get Wo shortage count    
-- Shivshankar P : 14/09/17 Display only LCANCEL =0 PO's and not status with 'EDITING' and 'CLOSED'    
-- Shivshankar P : 11/06/17 Display PART_NO ,DESCRIPT from POITEMS for 'MRO'    
-- Shivshankar P : 11/09/17 Check the the POITSCHD.REQUESTTP ='MRO'     
-- Shivshankar P : 02/20/17 Added WayBill Column and removed commented     
-- Nitesh B : 12/17/2018 remove received quantity from current receipt     
-- Nitesh B : 12/20/2018 Added Code to get the all receiving and inspection quantity pending    
-- Nitesh B : 01/16/2019 Remove INVENTOR.PART_CLASS , INVENTOR.PART_TYPE when POITSCHD.REQUESTTP ='MRO'    
-- Nitesh B : 01/31/2019 Added condition to get REVISION when POITSCHD.REQUESTTP ='MRO'    
-- Nitesh B : 06/28/2019 Added OUTER APPLY to get the Pending Receipt count    
-- Nitesh B : 07/15/2019 Added Default sorting by ItemNo     
-- Nitesh B : 08/30/2019 Display PART_NO, REV, DESCRIPT from POITEMS for 'Service'    
-- Nitesh B : 11/07/2019 Added Case to get QtyPerPackage     
-- Shivshankar P : 05/06/20 Display records with status 'EDITING' also for Accept Queue     
-- Shivshankar P : 05/18/20 We should only allow a PO with at status of OPEN to be received     
-- Shivshankar P : 07/21/20 Added condition in outer apply for MRO and Services and Change 'Service' to 'Services'    
-- Shivshankar P : 10/06/20 Added CASE for POITSCHD.BALANCE in outer apply for MRO and Services    
-- Sachin B : 11/20/20 Getting PUR_UOFM insted of U_OF_MEAS  
-- Sachin B : 11/25/20 Sachin B Revert his Changes of 11/20/20
-- =================================================    
CREATE PROCEDURE [dbo].[PoLineItemsView]     
 @poNumber char(15)=' ',    
 @uniqLnNo char(10)=' ',      
 @startRecord int = 1,    
    @endRecord int = 50,     
    @sortExpression nvarchar(1000) = null,    
    @filter nvarchar(1000) = null,    
 @receiverNo varchar(20) = ' '    
AS    
    
DECLARE @SQL nvarchar(max);    
DECLARE @out int    
BEGIN    
    
 ;WITH PoLineItemsList AS(    
  SELECT DISTINCT POITEMS.ITEMNO As ItemNo,POMAIN.PONUM As PONum ,    
                  CASE WHEN (POITSCHD.REQUESTTP ='MRO' OR POITSCHD.REQUESTTP ='Services') THEN POITEMS.PART_NO ELSE INVENTOR.PART_NO END As PartNo,  -- Shivshankar P : 11/06/17 Display PART_NO ,DESCRIPT from POITEMS for 'MRO'    
        -- Nitesh B : 08/30/2019 Display PART_NO, REV, DESCRIPT from POITEMS for 'Service'    
        -- Shivshankar P : 07/21/20 Added condition in outer apply for MRO and Services and Change 'Service' to 'Services'    
        CASE WHEN (POITSCHD.REQUESTTP ='MRO' OR POITSCHD.REQUESTTP ='Services') THEN POITEMS.REVISION ELSE INVENTOR.REVISION END As Rev, -- Nitesh B : 01/31/2019 Added condition to get REVISION when POITSCHD.REQUESTTP ='MRO'     
        INVENTOR.PART_CLASS AS PartClass,    
        CASE WHEN receiverDetail.mfgr_pt_no <> NULL THEN receiverDetail.mfgr_pt_no ELSE POITEMS.MFGR_PT_NO END AS SavedMPN,    
        CASE WHEN receiverDetail.Partmfgr <> NULL THEN receiverDetail.Partmfgr ELSE POITEMS.PARTMFGR END AS SavedMfgr,    
        CASE WHEN receiverDetail.mfgr_pt_no <> NULL THEN receiverDetail.mfgr_pt_no ELSE POITEMS.MFGR_PT_NO END AS MfgrPtNo,    
        CASE WHEN receiverDetail.Partmfgr <> NULL THEN receiverDetail.Partmfgr ELSE POITEMS.PARTMFGR END AS PartMfgr,    
      CASE WHEN POITSCHD.REQUESTTP ='MRO'  THEN 1 ELSE 0  END AS RequestTPMRO,  -- Shivshankar P : 11/09/17 Check the the POITSCHD.REQUESTTP ='MRO'    
                POITSCHD.Requestor, -- Shivshankar P : 11/09/17 Check the the POITSCHD.REQUESTTP ='MRO'    
          -- Nitesh B : 08/30/2019 Display PART_NO, REV, DESCRIPT from POITEMS for 'Service'    
      CASE WHEN (POITSCHD.REQUESTTP ='MRO' OR POITSCHD.REQUESTTP ='Services') THEN POITEMS.DESCRIPT  -- Nitesh B : 01/16/2019 Remove INVENTOR.PART_CLASS , INVENTOR.PART_TYPE when POITSCHD.REQUESTTP ='MRO'    
           ELSE INVENTOR.PART_CLASS +'/' + INVENTOR.PART_TYPE  +'/' + INVENTOR.DESCRIPT END As Descript, --Shivshsnkar P :04/01/17 Merged 3 columns in one column    
        -- Sachin B : 11/25/20 Sachin B Revert his Changes of 11/20/20
		INVENTOR.U_OF_MEAS As UnitOfMeasure,POITEMS.PACKAGE As Package,POITEMS.POITTYPE as POItType,    
        Poitems.overage As Overage,POITEMS.UNIQMFGRHD As Uniqmfgrhd,    
        SUPNAME SupName,Inventor.Uniq_key as UniqKey,POITEMS.UNIQLNNO as UniqLnNo,    
        POITEMS.ORD_QTY as PoQty,    
    
     CASE WHEN Shortage.WoShortageCnt IS NOT NULL THEN 1 ELSE 0 END as WoShortageCnt,    
       POITEMS.ACPT_QTY,POITEMS.RECV_QTY,    
       CASE    
        WHEN (INVENTOR.CERT_REQ = 1  OR INVENTOR.INSP_REQ  = 1 OR POITEMS.FIRSTARTICLE = 1)    
        THEN 'Yes'    
        WHEN (INVENTOR.CERT_REQ = 0  AND INVENTOR.INSP_REQ  = 0 AND POITEMS.FIRSTARTICLE = 0)    
        THEN 'No'    
       END AS InspectionReq,    
     INVENTOR.useipkey As UseIpKey,INVENTOR.SERIALYES As SerialYes,INVENTOR.ORDMULT as OrdMult,INVENTOR.PUR_UOFM As PUnitOfMeasure,    
     INVENTOR.ITAR, --,PARTTYPE.LotDetail, --Shivshsnkar P :02/01/17 Added Column    
     MfgrMast.Autolocation,    
           -- Nitesh B : 11/07/2019 Added Case to get QtyPerPackage     
           CASE WHEN receiverDetail.QtyPerPackage > 0 THEN receiverDetail.QtyPerPackage ELSE CASE WHEN MfgrMast.qtyPerPkg > 0 THEN MfgrMast.qtyPerPkg ELSE INVENTOR.ORDMULT END END AS QtyPerPackage,      
     PartTyP.LOTDETAIL,PartTyP.Autodt,PartTyP.Fgiexpdays,MfgrMast.MfgrMasterId,receiverDetail.ReceiverDetId,     
     ISNULL(receiverDetail.IsCompleted,0) AS IsCompleted,    
     ISNULL(IsInspCompleted,0) AS IsInspCompleted, ISNULL(IsInspCompleted,0) AS InspCompleted, recPklNo AS PorecPl,ReceiverNo,receiverDetail.Qty_rec AS QtyRec ,    
     CASE WHEN receivingFailQty.RejectedQty IS NOT NULL  THEN  receivingFailQty.RejectedQty ELSE 0 END AS RejectedQty,    
    
     CASE WHEN inspectionFailQty.RejectedQtyAtInspection IS NOT NULL  THEN  inspectionFailQty.RejectedQtyAtInspection ELSE 0 END AS RejectedQtyAtInspection,    
    
        CASE WHEN porecdt.POAcceptedQty IS NULL THEN  (ISNULL(receiverDetail.Qty_rec,0) -    
                 (ISNULL(receivingFailQty.RejectedQty,0) + ISNULL(inspectionFailQty.RejectedQtyAtInspection,0)))     
                 ELSE ISNULL(porecdt.POAcceptedQty,0)  END AS POAcceptedQty,    
     CASE WHEN  porecdt.POReceivedQty IS NOT NULL THEN ISNULL(porecdt.POReceivedQty,0) ELSE ISNULL(receiverDetail.Qty_rec,0) END AS POReceivedQty,    
     CASE WHEN  porecdt.POFailedQty IS NOT NULL THEN ISNULL(porecdt.POFailedQty,0) ELSE     
                 (ISNULL(receivingFailQty.RejectedQty,0) +  (ISNULL(inspectionFailQty.RejectedQtyAtInspection,0) -ISNULL(inspectionFailQty.Buyer_Accept,0)))    
             END AS POFailedQty, ISNULL(inspectionFailQty.Buyer_Accept,0) AS BuyerAccept,    
    
        porecdt.Uniqwh,porecdt.Location,LTRIM(RTRIM( porecdt.SinvUniq)) AS SinvUniq    
       ,porecdt.UniqDetNo,porecdt.UniqRecDtl,porecdt.LocUniq    
       ,(POITEMS.ORD_QTY * Poitems.overage) /100 AS OverageQty,    
       POITEMS.ACPT_QTY AS AcceptedSoFar,    
       (ISNULL(POITEMS.ACPT_QTY,0) + ISNULL(recDetail.QtyRec,0)) As ReceivedSoFar ,ISNULL(receiverDetail.QtyPerPackage,0) AS PoRecLocIpKeyQty,    
       (ISNULL(POITEMS.ORD_QTY,0) - (ISNULL(POITEMS.ACPT_QTY,0))) As Balance, -- ISNULL(recDetail.QtyRec,0)     
       -- Nitesh B : 12/17/2018 remove received quantity from current receipt      
       ISNULL(IsInspReq,0) AS IsInspReq    
           
       ,WayBill   -- Shivshankar P : 02/20/17 Added WayBill Column and removed commented     
       ,ISNULL(RecQtyDetail.Qty_rec,0) AS QtyInReceiving ,ISNULL(InspQtyDetail.Qty_rec,0) AS QtyInInspection,      
       ---- Nitesh B : 12/20/2018 Added Code to get the all receiving and inspection quantity pending    
       CASE WHEN PendingReceipt.PendingReceiptCnt IS NOT NULL THEN 1 ELSE 0 END as PendingReceiptCnt    
       -- Nitesh B : 06/28/2019 Added OUTER APPLY to get the Pending Receipt count    
       -- Shivshankar P : 05/06/20 Display records with status 'EDITING' also for Accept Queue     
       -- Shivshankar P : 05/18/20 We should only allow a PO with at status of OPEN to be received    
        FROM POMAIN     
     INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM  AND (POSTATUS ='OPEN' OR POSTATUS = CASE WHEN @receiverNo = ' ' THEN 'OPEN' ELSE 'CLOSED' END     
     OR POSTATUS = CASE WHEN @receiverNo = ' ' THEN 'OPEN' ELSE 'EDITING' END) AND POITEMS.LCANCEL =0    
     LEFT JOIN INVENTOR ON POITEMS.UNIQ_KEY = INVENTOR.UNIQ_KEY    
     LEFT JOIN SUPINFO ON POMAIN.UNIQSUPNO = SUPINFO.UNIQSUPNO    
     LEFT JOIN receiverHeader on POMAIN.PONUM = receiverHeader.ponum  AND receiverHeader.receiverno = @receiverNo    
     LEFT JOIN receiverDetail on receiverHeader.receiverHdrId = receiverDetail.receiverHdrId     
                                AND receiverDetail.uniqlnno =POITEMS.UNIQLNNO    
    
                    OUTER APPLY(SELECT SUM(receiverDetail.Qty_rec ) AS Qty_rec    
         FROM receiverHeader     
         JOIN receiverDetail ON receiverHeader.receiverHdrId = receiverDetail.receiverHdrId    
         WHERE (((isinspreq=1 AND isinspCompleted = 1) OR (isinspreq=0 AND isinspCompleted = 0)) AND isCompleted = 0)     
         AND receiverHeader.ponum = POMAIN.PONUM AND receiverDetail.uniqlnno = POITEMS.UNIQLNNO AND POMAIN.PONUM = @poNumber    
        ) AS RecQtyDetail -- Nitesh B : 12/20/2018 Added Code to get the all receiving and inspection quantity pending         
     OUTER APPLY(    
         SELECT SUM(receiverDetail.Qty_rec ) AS Qty_rec    
         FROM receiverHeader     
         JOIN receiverDetail ON receiverHeader.receiverHdrId = receiverDetail.receiverHdrId    
         WHERE isCompleted = 0 AND isinspReq = 1 AND isinspCompleted = 0     
         AND receiverHeader.ponum = POMAIN.PONUM AND receiverDetail.uniqlnno = POITEMS.UNIQLNNO AND POMAIN.PONUM = @poNumber    
        ) AS InspQtyDetail -- Nitesh B : 12/20/2018 Added Code to get the all receiving and inspection quantity pending    
    
     OUTER APPLY(SELECT  TOP 1 dbo.porecdtl.AcceptedQty AS POAcceptedQty,porecdtl.ReceivedQty AS POReceivedQty,porecdtl.FailedQty AS POFailedQty,    
                             PORECLOC.Uniqwh,PORECLOC.Location,PORECLOC.Sinv_uniq AS SinvUniq,PORECLOC.UniqDetNo,    
                    PORECLOC.Fk_UniqRecDtl AS UniqRecDtl,PORECLOC.Loc_Uniq AS LocUniq    
        FROM dbo.porecdtl JOIN dbo.PORECLOC ON receiverHeader.receiverno = PORECLOC.receiverno    
                                   AND dbo.PORECLOC.FK_UNIQRECDTL= porecdtl.uniqrecdtl     
                 WHERE  porecdtl.receiverdetId = receiverDetail.receiverDetId AND porecdtl.UniqlnNo =receiverDetail.uniqlnno     
            AND porecdtl.porecpkno = receiverHeader.recPklNo) porecdt    
    
     OUTER APPLY ((SELECT SUM(receiverDetail.Qty_rec) AS QtyRec from receiverDetail     
                   WHERE receiverDetail.UNIQLNNO = POITEMS.UNIQLNNO and receiverDetail.isCompleted = 0)) recDetail    
                         
     OUTER APPLY (SELECT  SUM(FailedQty) RejectedQty    
        from inspectionHeader insp     
        where insp.receiverDetId = receiverDetail.receiverDetId AND RejectedAt ='Receiving') receivingFailQty    
    
     OUTER APPLY (SELECT  SUM(FailedQty) RejectedQtyAtInspection ,SUM(Buyer_Accept) Buyer_Accept    
        from inspectionHeader insp     
        where insp.receiverDetId = receiverDetail.receiverDetId AND RejectedAt ='Inspection') inspectionFailQty    
    
     --Shivshankar P : 05/18/17   Added Two Table Join to get their columns    
     OUTER APPLY (SELECT mast.Autolocation,mast.qtyPerPkg,MfgrMasterId from MfgrMaster mast where mast.PartMfgr = POITEMS.PARTMFGR      
                        AND mast.mfgr_pt_no = POITEMS.MFGR_PT_NO) MfgrMast    
     OUTER APPLY (SELECT part.LOTDETAIL,part.Autodt, part.Fgiexpdays from PARTTYPE part where part.PART_TYPE = INVENTOR.PART_TYPE      
                         AND part.PART_CLASS = INVENTOR.PART_CLASS) PartTyP    
     OUTER APPLY (SELECT  1 AS WoShortageCnt    
                             FROM kamain INNER JOIN woentry ON  Kamain.wono = Woentry.wono      
                                                    AND Kamain.shortqty >  0.00 AND  Kamain.ignorekit =0     
                                     AND  Woentry.openclos NOT IN ('Closed','Cancel')      
                   --AND  Woentry.balance <>  0    
                                  AND Kamain.uniq_key = POITEMS.UNIQ_KEY    
    
         ) Shortage  --Shivshsnkar P :21/06/17 Get Wo shortage count    
     -- Shivshankar P : 07/21/20 Added condition in outer apply for MRO and Services and Change 'Service' to 'Services'    
     -- Shivshankar P : 10/06/20 Added CASE for POITSCHD.BALANCE in outer apply for MRO and Services    
     OUTER APPLY ((SELECT TOP 1 REQUESTTP, REQUESTOR  from POITSCHD     
           WHERE POITSCHD.UNIQLNNO = POITEMS.UNIQLNNO AND (POITSCHD.REQUESTTP ='MRO' OR POITSCHD.REQUESTTP ='Services')    
        AND POITSCHD.BALANCE >= CASE WHEN @receiverNo = ' ' THEN 1 ELSE POITSCHD.BALANCE END)) POITSCHD   -- Shivshankar P : 11/06/17 Display PART_NO ,DESCRIPT from POITEMS for 'MRO'    
        -- Nitesh B : 06/28/2019 Added OUTER APPLY to get the Pending Receipt count      
     OUTER APPLY ( SELECT 1 AS PendingReceiptCnt    
         FROM receiverHeader     
         JOIN receiverDetail ON receiverHeader.receiverHdrId = receiverDetail.receiverHdrId    
         WHERE  ((isinspreq=1 AND isinspCompleted = 1) OR (isinspreq=0 AND isinspCompleted = 0)) AND isCompleted = 0     
         AND receiverHeader.ponum = @poNumber AND receiverDetail.uniqlnno = POITEMS.UNIQLNNO    
         UNION    
         SELECT 1 AS PendingReceiptCnt    
         FROM receiverHeader     
         JOIN receiverDetail ON receiverHeader.receiverHdrId = receiverDetail.receiverHdrId    
         WHERE isCompleted = 0 AND isinspReq = 1 AND isinspCompleted = 0     
         AND receiverHeader.ponum = @poNumber AND receiverDetail.uniqlnno = POITEMS.UNIQLNNO) PendingReceipt             
     WHERE (--  AND -- Shivshankar P : 14/09/17 Display only LCANCEL =0 PO's and not status with 'EDITING' and 'CLOSED'    
        ((@poNumber = ' ' AND POITEMS.UNIQLNNO = @uniqLnNo) OR (@uniqLnNo =' ' AND  POMAIN.PONUM = @poNumber ) )))  --Shivshsnkar P :02/01/17 For getting all line items based on ponum OR Single line Item    
    
    
    SELECT identity(int,1,1) as RowNumber,*INTO #TEMP from PoLineItemsList ORDER BY CAST(ItemNo AS int) ASC -- Nitesh B : 07/15/2019 Added Default sorting by ItemNo     
      
  IF @filter <> '' AND @sortExpression <> ''    
    BEGIN    
     SET @SQL=N'select  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE '+@filter+' and    
     RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+' ORDER BY '+ @SortExpression+''    
     END    
    ELSE IF @filter = '' AND @sortExpression <> ''    
    BEGIN    
   SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE     
   RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+' ORDER BY '+ @sortExpression+''    
   END    
    ELSE IF @filter <> '' AND @sortExpression = ''    
    BEGIN    
     SET @SQL=N'select  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE  '+@filter+' and    
     RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+''    
     END    
     ELSE    
    BEGIN    
     SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE     
     RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+''    
   END    
  exec sp_executesql @SQL    
  END     