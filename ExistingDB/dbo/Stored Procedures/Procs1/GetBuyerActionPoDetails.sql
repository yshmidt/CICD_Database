-- =============================================    
-- Author:Satish B    
-- Create date: 03/24/2017    
-- Description: Get Po Number Details in DMR Buyer Action Tab    
-- Modified :05/12/2017 Satish B : Select recHeader.receiverno and recDetail.uniqlnno    
--          :06/14/2017 Satish B : Select invtmfgr.W_KEY instade of L.W_KEY    
--          :06/14/2017 Satish B : Replace Invtmfgr and porecdtl join with Invtmfgr and poitem    
--          :07/24/2017 Satish B : Added new parameter @filterText    
--          :07/24/2017 Satish B : Implement filter search against PL Number,Part_No,mfgr_pt_no    
--          :08/16/2017 Satish B : Comment selection of only description and select class,type and description as Description    
--          :08/16/2017 Satish B : Select Distinct record    
--          :08/18/2017 Satish B : Select porecloc.LOC_UNIQ    
--          :09/12/2017 Satish B : Select ITAR    
--          :09/20/2017 : Satish B : Change the condition of checking the insHeader.FailedQty -insHeader.ReturnQty    
--          :02/23/2018 : Satish B : Change selection of UNIQMFGRHD conditionally and comment porecdtl.UNIQMFGRHD As UniqMfgrHd    
--          :05/2/2018 : Satish B : Modify the wrong condition to correct way i.e. If UNIQMFGRHD from PORECDTL table is null then select it from POITEM table    
--          :05/2/2018 : Satish B : Modify the where condition : Removed wrong closing bracket    
--          :05/7/2018 : Satish B : Modify the where condition : check IsInspReq and IsInspCompleted flag only when rejected at Inspection    
--          :05/15/2018 : Satish B : Select isCompleted from receiverDetail table    
--         :07/29/2019 : Shiv P : Add column to show the line item no    
--         :11/23/2020 : Rajendra k : Added condition REJQTY > 0  
-- GetBuyerActionPoDetails '000000000002121',''      
-- =============================================    
CREATE PROCEDURE GetBuyerActionPoDetails    
  @poNumber char(15)='',    
  -- Modified :07/24/2017 Satish B : Added new parameter @filterText    
  @filterText char(50)=''    
 AS    
 BEGIN    
  SET NOCOUNT ON    
  DECLARE @uniqMrbWh char(10)=' '    
  SELECT @uniqMrbWh = UniqWH     
    FROM WAREHOUS where  Warehouse='MRB'    
  -- Modified :08/16/2017 Satish B : Select Distinct record    
  SELECT  DISTINCT    
   insHeader.InspHeaderId    
  ,insHeader.BuyerAction    
  ,recHeader.RecPklNo    
  ,inventor.Part_No As PartNo    
  ,inventor.Revision    
  ,inventor.SERIALYES    
  ,inventor.useipkey    
  ,parttype.LOTDETAIL    
   --08/16/2017 Satish B : Comment selection of only description and select class,type and description as Description    
  --,inventor.Descript As Description    
  ,RTRIM(inventor.PART_CLASS) + CASE WHEN inventor.PART_CLASS IS NULL OR inventor.PART_CLASS='' THEN '' ELSE '/' END +     
     RTRIM(inventor.PART_TYPE) + CASE WHEN inventor.PART_TYPE IS NULL OR inventor.PART_TYPE='' THEN '' ELSE '/' END +    
     inventor.DESCRIPT AS Description    
  ,recDetail.PartMfgr    
  ,recDetail.mfgr_pt_no As MfgrPtNo    
  ,insHeader.RejectedAt    
  ,insHeader.FailedQty    
  ,(insHeader.FailedQty - insHeader.ReturnQty) As Rejected    
  ,insHeader.ReturnQty As ReturnedQty    
  ,(CASE WHEN insHeader.BuyerAction='Accept' THEN  insHeader.FailedQty - insHeader.ReturnQty ELSE NULL END) As Returned    
  ,(CASE WHEN insHeader.BuyerAction='Return' THEN NULL ELSE insHeader.BuyerAction  END) As Action    
  ,inventor.Uniq_Key As UniqKey    
  --02/23/2018 : Satish B : Change selection of UNIQMFGRHD conditionally and comment porecdtl.UNIQMFGRHD As UniqMfgrHd    
  --05/2/2018 : Satish B : Modify the wrong condition to correct way i.e. If UNIQMFGRHD from PORECDTL table is null then select it from POITEM table    
  , ISNULL(porecdtl.UNIQMFGRHD,poitem.UNIQMFGRHD) As UniqMfgrHd     
  --,porecdtl.UNIQMFGRHD As UniqMfgrHd    
  ,poitem.COSTEACH As CostEach    
  ,inventor.U_Of_Meas As UnitOfMeasure    
  ,inventor.Pur_Uofm As PurOfMeasure     
  ,inventor.StdCost     
  ,(CASE WHEN inventor.Pur_Uofm <>'' THEN inventor.Pur_Uofm ELSE inventor.U_Of_Meas  END) As Unit    
  ,L.UNIQ_LOT    
  ,L.LOTCODE    
  ,L.REFERENCE    
  ,L.EXPDATE    
  ,L.PONUM    
  ,l.LOTQTY     
     ,ipkey.IPKEYUNIQUE    
  --06/14/2017 Satish B : Select invtmfgr.W_KEY instade of L.W_KEY    
  ,invtmfgr.W_KEY    
  --,L.W_KEY    
  ,porecdtl.uniqrecdtl AS UniqRecDtl    
  ,porecloc.SDET_UNIQ    
  ,porecloc.SINV_UNIQ    
  --08/18/2017 Satish B : Select porecloc.LOC_UNIQ    
  ,porecloc.LOC_UNIQ    
  --05/12/2017 Satish B : Select recHeader.receiverno and recDetail.uniqlnno    
  ,recHeader.receiverno AS ReceiverNo    
  ,recDetail.uniqlnno As UniqlnNo    
  --09/12/2017 Satish B : Select ITAR    
  ,inventor.ITAR    
  --05/15/2018 : Satish B : Select isCompleted from receiverDetail table    
  ,recDetail.isCompleted AS IsCompleted,    
  --07/29/2019 : Shiv P : Add column to show the line item no    
  poitem.ItemNO     
  FROM inspectionHeader insHeader    
  INNER JOIN receiverDetail recDetail ON recDetail.receiverDetId=insHeader.receiverDetId    
  INNER JOIN receiverHeader recHeader ON recHeader.receiverHdrId=recDetail.receiverHdrId    
  INNER JOIN Inventor inventor ON  recDetail.Uniq_key=inventor.Uniq_Key    
  INNER JOIN PARTTYPE parttype ON  parttype.PART_CLASS=inventor.PART_CLASS AND parttype.PART_TYPE=inventor.PART_TYPE    
  INNER JOIN POITEMS poitem ON  recDetail.Uniq_key=poitem.UNIQ_KEY    
      
  LEFT JOIN porecdtl ON porecdtl.receiverdetId=recDetail.receiverDetId  --         :11/23/2020 : Rajendra k : Added condition REJQTY > 0  
  LEFT JOIN PORECLOC porecloc ON  porecloc.FK_UNIQRECDTL=porecdtl.uniqrecdtl  AND porecloc.REJQTY > 0  
  -- 06/14/2017 Satish B : Replace Invtmfgr and porecdtl join with Invtmfgr and poitem    
  --LEFT JOIN INVTMFGR invtmfgr ON porecdtl.uniqrecdtl=invtmfgr.UNIQMFGRHD     
  LEFT JOIN INVTMFGR invtmfgr ON poitem.UNIQ_KEY=invtmfgr.UNIQ_KEY AND invtmfgr.UNIQWH=@uniqMrbWh AND invtmfgr.INSTORE = 0 AND invtmfgr.LOCATION=insHeader.inspHeaderId     
  AND invtmfgr.uniqwh=@uniqMrbWh    
  --and porecdtl.uniqmfgrhd=invtmfgr.uniqmfgrhd    
  LEFT JOIN IPKEY ipkey ON ipkey.W_KEY=invtmfgr.W_KEY --and ipkey.UNIQMFGRHD=invtmfgr.UNIQMFGRHD    
      
  OUTER  APPLY    
  ( SELECT poreclot.LOT_UNIQ ,poreclot.lotcode,PORECLOT.expdate,poreclot.reference,poreclot.LOTQTY,invtlot.LOTQTY AS RejlotQty,invtlot.UNIQ_LOT,     
     invtlot.ponum,invtmfgr.W_KEY    
    FROM porecloc INNER JOIN poreclot ON porecloc.LOC_UNIQ=poreclot.loc_uniq    
   INNER JOIN INVTLOT invtlot ON poreclot.LOTCODE=invtlot.lotcode    
       AND poreclot.EXPDATE=invtlot.expdate    
       AND poreclot.REFERENCE=invtlot.reference    
   INNER JOIN invtmfgr ON invtlot.w_key=invtmfgr.w_key AND invtmfgr.uniqwh=@uniqMrbWh AND invtmfgr.INSTORE = 0 AND invtmfgr.LOCATION=insHeader.inspHeaderId    
    WHERE porecloc.FK_UNIQRECDTL=porecdtl.uniqrecdtl    
    AND invtlot.ponum=poitem.ponum    
  ) L    
        
  WHERE recHeader.PONUM=@poNumber AND    
   poitem.PONUM=@poNumber AND    
   --05/2/2018 : Satish B : Modify the where condition : Removed wrong closing bracket    
   ((insHeader.RejectedAt='Receiving') OR    
   --05/7/2018 : Satish B : Modify the where condition : check IsInspReq and IsInspCompleted flag only when rejected at Inspection    
   (insHeader.RejectedAt='Production') OR ((insHeader.RejectedAt='Inspection') AND    
   (recDetail.IsInspReq=1 AND recDetail.IsInspCompleted=1) OR (recDetail.IsInspReq=0 and recDetail.IsInspCompleted=0)))  AND    
   --((recDetail.IsInspReq=1 AND recDetail.IsInspCompleted=1) OR (recDetail.IsInspReq=0 and recDetail.IsInspCompleted=0)) AND    
    
   --09/20/2017 : Satish B : Change the condition of checking the insHeader.FailedQty -insHeader.ReturnQty    
   --(insHeader.FailedQty -insHeader.ReturnQty >0) AND    
    (insHeader.FailedQty -insHeader.ReturnQty -insHeader.Buyer_Accept >0) AND    
    -- Modified :07/24/2017 Satish B : Implement filter search against PL Number,Part_No,mfgr_pt_no    
   (@filterText IS NULL  OR @filterText = '' OR inventor.PART_NO LIKE '%' + RTRIM(@filterText) + '%' OR recHeader.RecPklNo LIKE '%' + RTRIM(@filterText) + '%'     
    OR recDetail.mfgr_pt_no LIKE '%' + RTRIM(@filterText) + '%')         
 END