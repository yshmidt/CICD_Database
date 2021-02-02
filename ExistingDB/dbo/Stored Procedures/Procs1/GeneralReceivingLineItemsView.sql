-- ==================================================================================================    
-- Author:  Nilesh S    
-- Create date: <02/12/2018>    
-- Description:  Used to General receiving    
-- exec [dbo].[GeneralReceivingLineItemsView] '_2520IV7JB','',0,'',0,50,'','' 
-- exec [dbo].[GeneralReceivingLineItemsView] '_2520IV7JB','',0,'G',0,50,'',''      
-- Nilesh Sa 2/26/2018 Check account from ReceivingDetails table     
-- Nilesh Sa 2/26/2018 Change failed qty based inspected qty and accepted qty    
-- Nilesh Sa 2/28/2018 Added  StatusToolTip data    
-- Nilesh Sa 3/1/2018 Added case for isinspReq = 1 and isinspCompleted = 0    
-- Nilesh Sa 2/28/2018 Added  Get inspected failed qty    
-- Nilesh Sa 3/7/2018 Modify the SP for edit mode : Display records only for received parts if wants then add result using Autocomplete from UI    
-- Nilesh sa 3/7/2018 Here get only received parts results    
-- Nilesh sa 3/7/2018 Combine result for received parts & searched parts from UI    
-- Rajendra K 06/14/2018 Added new parameter @isInStore to get records for InPlant Supplier    
-- Rajendra K 06/14/2018 : replaced 0 by parameter @isInStore in where condition for inStore comparision     
-- Rajendra K 06/26/2018 : Added new parameter @inspectionSource to get records for InPlant Supplier    
-- Rajendra K 07/05/2018 : Condition commented from join condition for Invtmgr table and moved to where condition    
-- Rajendra K 07/05/2018 : Added condition to get records by @inspectionSource type    
-- Rajendra K 07/10/2018  : Added custpartno in select list    
-- Mahesh B  11/26/2018 : Added the StatusToolTip
-- Nitesh B 1/25/2019 : Added condition @inspectionSource <> 'G', PART_SOURC <>'CONSG' to get records 
-- Nitesh B 1/25/2019 : Change condition @inspectionSource != 'C' to @inspectionSource <> 'C'
-- Nitesh B 3/15/2019 : Calculate SUM(FailedQty-Buyer_Accept) AS InspectionFailedQty  
-- Nitesh B 5/03/2019 : Remove condition "im.NETABLE = 1" to get non netable location records  
-- Nitesh B 5/10/2019 : Change the INNER JOIN to LEFT JOIN for InvtMfgr table  
-- Nitesh B 10/10/2019 : Added the OUTER JOIN to get CPN Mfgrs list for IPC
  -- ==================================================================================================    
CREATE PROCEDURE [dbo].[GeneralReceivingLineItemsView]       
 @uniqKey NVARCHAR(MAX)  =' ',    
 @receiverNo CHAR(10)='',    
 @isInStore  BIT = 0,    
 @inspectionSource CHAR(1)='',    
 @startRecord INT=1 ,    
    @endRecord INT=50,     
    @sortExpression nvarchar(1000) = null,    
    @filter nvarchar(1000) = null    
AS    
BEGIN    
 SET NOCOUNT ON;    
 DECLARE @SQLQuery nvarchar(max)    
  BEGIN    
  -- Nilesh Sa 3/7/2018 Modify the SP for edit mode : Display records only for received parts if wants then add result using Autocomplete from UI    
  -- Nilesh sa 3/7/2018 Here get only received parts results    
   ;WITH grReceivedLineItemsList AS(    
    SELECT DISTINCT ir.UNIQ_KEY AS UniqKey, ir.PART_NO AS PartNumber, ir.Revision AS Rev,SavedInvtMfgr.UNIQWH AS UniqWh,SavedInvtMfgr.LOCATION AS Location,    
        ISNULL(mfg.Partmfgr,'') AS Partmfgr,ISNULL(mfg.mfgr_pt_no,'') AS MfgrPtNo,    
        CONCAT(ir.Part_Class, ' / ', ir.Part_Type,' / ', ir.Descript) AS Descript ,ir.U_OF_MEAS AS UnitOfMeasure,    
        ir.ITAR,ir.SERIALYES AS SerialYes,ir.Useipkey as  UseIpKey,    
        PartType.LOTDETAIL AS LotDetail,    
        PartType.Autodt,    
        PartType.FGIEXPDAYS AS FgiExpDays,    
        invtlk.UNIQMFGRHD AS Uniqmfgrhd,    
        mfg.AutoLocation AS AutoLocation,    
        ISNULL(ReceivingDetails.Qty_rec,0) AS  QtyRec,    
        ISNULL(receiverHeader.reason,'') AS  ReceiveReason,    
        ISNULL(ReceivingDetails.QtyPerPackage,ISNULL(mfg.qtyPerPkg,ISNULL(ir.ORDMULT,0))) AS QtyPerPackages,    
        ISNULL(ReceivingDetails.GL_NBR,'') AS Account, -- Nilesh Sa 2/26/2018 -- Check account from ReceivingDetails table     
        ISNULL(InvtRec.INVTREC_NO,'') AS InvtRecNo,       
        ISNULL(ReceivingDetails.ReceiverDetId,'') AS ReceiverDetId,     
        ISNULL(InvtRec.inspectedQty - InvtRec.acceptedQty,0) AS FailedQty,    
    CASE    
     WHEN ((ir.CERT_REQ = 1  OR ir.INSP_REQ  = 1 OR ir.FIRSTARTICLE = 1))    
     THEN  -- Nilesh Sa 3/1/2018 Added case for isinspReq = 1 and isinspCompleted = 0    
        CASE     
       WHEN(ReceivingDetails.isinspReq = 1 AND ReceivingDetails.isinspCompleted  = 1) THEN 'Warehouse'     
       WHEN(ReceivingDetails.isinspReq = 1 AND ReceivingDetails.isinspCompleted  = 0) THEN 'Inspection'     
     ELSE 'Inspection' END    
  WHEN (ir.CERT_REQ = 0  AND ir.INSP_REQ  = 0 AND ir.FIRSTARTICLE = 0) THEN 'Warehouse' END AS Disposition    
      ,CASE     
     WHEN (ReceivingDetails.isinspReq = 1 AND ReceivingDetails.isinspCompleted  = 0) THEN 'receiving-status-yellow' --AS StatusColor,'In Inspection' AS StatusToolTip,'Inspection' AS Disposition    
     WHEN (ReceivingDetails.IsCompleted = 1) THEN 'receiving-status-green'    
     WHEN (ReceivingDetails.IsCompleted = 0) THEN 'receiving-status-red'    
     ELSE '' END AS StatusColor,  
  CASE    
       --Nilesh Sa 2/28/2018 Added  StatusToolTip data    
     WHEN (ReceivingDetails.isinspReq = 1 AND ReceivingDetails.isinspCompleted  = 0) THEN 'In Inspection'     
     WHEN (ReceivingDetails.IsCompleted = 1) THEN 'Completed'    -- Mahesh B  11/26/2018 : Added the StatusToolTip
     WHEN (ReceivingDetails.IsCompleted = 0 AND PartType.LOTDETAIL = 1) THEN 'Receipt Pending, please enter the Lotcode information'   
     WHEN (ReceivingDetails.IsCompleted = 0 AND ir.SERIALYES = 1) THEN 'Receipt Pending, please enter the serial number information'   
	 WHEN (ReceivingDetails.IsCompleted = 0 AND PartType.LOTDETAIL = 1 AND ir.SERIALYES = 1) THEN 'Receipt Pending, please enter the Lotcode and Serial no information'   
     WHEN (ReceivingDetails.IsCompleted = 0) THEN 'Receipt Pending'    
     ELSE '' END AS StatusToolTip  
     ,ReceivingDetails.GL_NBR,    
     Inspection.InspectionFailedQty As InspectionFailedQty  --Nilesh Sa 2/28/2018 Added  Get inspected failed qty    
     ,RTRIM(ir.CustPartNO) + (CASE WHEN ir.CUSTREV IS NULL OR ir.CUSTREV = '' THEN '' ELSE '/'+ ir.CUSTREV END) AS CustPartRev -- 07/10/2018 Rajendra K : Added custpartno in select list    
     FROM INVENTOR ir    
    INNER JOIN InvtMPNLink invtlk ON ir.UNIQ_KEY = invtlk.uniq_key AND invtlk.Is_deleted = 0    
    INNER JOIN Mfgrmaster mfg ON invtlk.mfgrmasterId =  mfg.MfgrMasterId AND mfg.is_deleted = 0    
    LEFT JOIN InvtMfgr im ON invtlk.UniqMfgrHd = im.UniqMfgrHd AND invtlk.Uniq_Key = im.Uniq_Key AND im.Is_Deleted = 0    
 -- Nitesh B 5/10/2019 : Change the INNER JOIN to LEFT JOIN for InvtMfgr table    
         -- AND im.InStore = @isInStore -- Rajendra K 06/14/2018 : replaced 0 by parameter @isInStore in where condition for inStore comparision    
         -- Rajendra K 07/05/2018 : Condition commented and moved to where condition    
        -- Nitesh B 5/03/2019 : Remove condition "im.NETABLE = 1" to get non netable location records  
                INNER JOIN receiverDetail ReceivingDetails on ir.UNIQ_KEY  = ReceivingDetails.Uniq_key     
           AND ReceivingDetails.Partmfgr = mfg.PartMfgr AND ReceivingDetails.mfgr_pt_no = mfg.mfgr_pt_no    
                INNER  JOIN receiverHeader ON ReceivingDetails.receiverHdrId = receiverHeader.receiverHdrId      
     AND receiverHeader.inspectionsource = @inspectionSource  -- Rajendra K 06/26/2018 : replaced 'G' by parameter @inspectionSource in where condition for inStore comparision    
     AND ReceivingDetails.UNIQ_KEY = ir.UNIQ_KEY AND receiverno = @receiverNo     
     AND ReceivingDetails.Partmfgr = mfg.PartMfgr AND ReceivingDetails.mfgr_pt_no = mfg.mfgr_pt_no    
    OUTER APPLY (SELECT part.LOTDETAIL,part.Autodt, part.Fgiexpdays     
            FROM PARTTYPE part WHERE part.PART_TYPE = ir.PART_TYPE  and part.PART_CLASS = ir.PART_CLASS) AS PartType     
    OUTER APPLY (SELECT SUM(FailedQty-Buyer_Accept) AS InspectionFailedQty FROM inspectionHeader WHERE receiverDetId =ReceivingDetails.receiverDetId) AS Inspection     -- Nitesh B 3/15/2019 : Calculate SUM(FailedQty-Buyer_Accept) AS InspectionFailedQty  
    OUTER APPLY (SELECT TOP 1 INVT_REC.GL_NBR,INVT_REC.W_KEY,INVT_REC.INVTREC_NO,INVT_REC.acceptedQty,INVT_REC.QTYREC,    
       INVT_REC.inspectedQty -- Nilesh Sa 2/26/2018 Change failed qty based inspected qty and accepted qty    
            FROM INVT_REC WHERE receiverdetId = ReceivingDetails.receiverDetId) AS InvtRec     
                OUTER APPLY(SELECT UNIQWH,LOCATION FROM InvtMfgr WHERE W_KEY = InvtRec.W_KEY ) AS SavedInvtMfgr  
	OUTER APPLY
	(
		SELECT im.UNIQMFGRHD  FROM INVENTOR ir    
			INNER JOIN InvtMPNLink invtlk ON ir.UNIQ_KEY = invtlk.uniq_key AND invtlk.Is_deleted = 0    
			INNER JOIN Mfgrmaster mfg ON invtlk.mfgrmasterId =  mfg.MfgrMasterId AND mfg.is_deleted = 0    
			INNER JOIN InvtMfgr im ON invtlk.UniqMfgrHd = im.UniqMfgrHd AND invtlk.Uniq_Key = im.Uniq_Key AND im.Is_Deleted = 0 
			WHERE ir.UNIQ_KEY IN (SELECT id FROM dbo.[fn_simpleVarcharlistToTable](@uniqKey,',')) 
	) AS InvtMfgr  -- Nitesh B 10/10/2019 : Added the OUTER JOIN to get CPN Mfgrs list for IPC
    WHERE ir.STATUS ='active'    
    -- 07/05/2018 Rajendra K : Added condition to get records by @inspectionSource type    
       AND ((@inspectionSource = 'S' AND (im.InStore = 1 OR PART_SOURC = 'BUY' OR (PART_SOURC = 'MAKE' AND MAKE_BUY = 1)))    
             OR ((@inspectionSource <> 'C' OR PART_SOURC ='CONSG'))) AND PART_SOURC <> 'PHANTOM' -- Nitesh B 1/25/2019 : Change condition @inspectionSource != 'C' to @inspectionSource <> 'C'  
	AND invtlk.UNIQMFGRHD = CASE WHEN @inspectionSource = 'C' THEN InvtMfgr.UNIQMFGRHD ELSE invtlk.UNIQMFGRHD END
   )    
   SELECT * INTO #TEMP1 FROM grReceivedLineItemsList     
    
   -- Here get all parts results along with received parts    
   ;WITH grLineItemsList AS(    
    SELECT DISTINCT ir.UNIQ_KEY AS UniqKey, ir.PART_NO AS PartNumber, ir.Revision AS Rev,SavedInvtMfgr.UNIQWH AS UniqWh,SavedInvtMfgr.LOCATION AS Location,    
        ISNULL(mfg.Partmfgr,'') AS Partmfgr,ISNULL(mfg.mfgr_pt_no,'') AS MfgrPtNo,    
        CONCAT(ir.Part_Class, ' / ', ir.Part_Type,' / ', ir.Descript) AS Descript ,ir.U_OF_MEAS AS UnitOfMeasure,    
        ir.ITAR,ir.SERIALYES AS SerialYes,ir.Useipkey as  UseIpKey,    
        PartType.LOTDETAIL AS LotDetail,    
        PartType.Autodt,    
        PartType.FGIEXPDAYS AS FgiExpDays,    
        invtlk.UNIQMFGRHD AS Uniqmfgrhd,    
        mfg.AutoLocation AS AutoLocation,    
        ISNULL(ReceivingDetails.Qty_rec,0) AS  QtyRec,    
        ISNULL(ReceivingDetails.reason,'') AS  ReceiveReason,    
        ISNULL(ReceivingDetails.QtyPerPackage,ISNULL(mfg.qtyPerPkg,ISNULL(ir.ORDMULT,0))) AS QtyPerPackages,    
        ISNULL(ReceivingDetails.GL_NBR,'') AS Account, -- Nilesh Sa 2/26/2018 -- Check account from ReceivingDetails table     
        ISNULL(InvtRec.INVTREC_NO,'') AS InvtRecNo,       
        ISNULL(ReceivingDetails.ReceiverDetId,'') AS ReceiverDetId,     
        ISNULL(InvtRec.inspectedQty - InvtRec.acceptedQty,0) AS FailedQty,    
    CASE    
     WHEN ((ir.CERT_REQ = 1  OR ir.INSP_REQ  = 1 OR ir.FIRSTARTICLE = 1))    
     THEN  -- Nilesh Sa 3/1/2018 Added case for isinspReq = 1 and isinspCompleted = 0    
        CASE     
       WHEN(ReceivingDetails.isinspReq = 1 AND ReceivingDetails.isinspCompleted  = 1) THEN 'Warehouse'     
       WHEN(ReceivingDetails.isinspReq = 1 AND ReceivingDetails.isinspCompleted  = 0) THEN 'Inspection'     
     ELSE 'Inspection' END    
     WHEN (ir.CERT_REQ = 0  AND ir.INSP_REQ  = 0 AND ir.FIRSTARTICLE = 0) THEN 'Warehouse' END AS Disposition    
      ,CASE     
     WHEN (ReceivingDetails.isinspReq = 1 AND ReceivingDetails.isinspCompleted  = 0) THEN 'receiving-status-yellow' --AS StatusColor,'In Inspection' AS StatusToolTip,'Inspection' AS Disposition    
     WHEN (ReceivingDetails.IsCompleted = 1) THEN 'receiving-status-green'    
     WHEN (ReceivingDetails.IsCompleted = 0) THEN 'receiving-status-red'    
     ELSE '' END AS StatusColor    
      ,CASE    
  
       --Nilesh Sa 2/28/2018 Added  StatusToolTip data    
     WHEN (ReceivingDetails.isinspReq = 1 AND ReceivingDetails.isinspCompleted  = 0) THEN 'In Inspection'     
     WHEN (ReceivingDetails.IsCompleted = 1) THEN 'Completed'  -- Mahesh B  11/26/2018 : Added the StatusToolTip
     WHEN (ReceivingDetails.IsCompleted = 0 AND PartType.LOTDETAIL = 1) THEN 'Receipt Pending, please enter the Lotcode information'   
     WHEN (ReceivingDetails.IsCompleted = 0 AND ir.SERIALYES = 1) THEN 'Receipt Pending, please enter the serial number information' 
     WHEN (ReceivingDetails.IsCompleted = 0 AND PartType.LOTDETAIL = 1 AND ir.SERIALYES = 1) THEN 'Receipt Pending, please enter the Lotcode and Serial no information'    
     WHEN (ReceivingDetails.IsCompleted = 0) THEN 'Receipt Pending'    
     ELSE '' END AS StatusToolTip,    
     ReceivingDetails.GL_NBR,    
     Inspection.InspectionFailedQty As InspectionFailedQty  --Nilesh Sa 2/28/2018 Added  Get inspected failed qty    
         ,RTRIM(ir.CustPartNO) + (CASE WHEN ir.CUSTREV IS NULL OR ir.CUSTREV = '' THEN '' ELSE '/'+ ir.CUSTREV END) AS CustPartRev -- 07/10/2018 Rajendra K : Added custpartno in select list    
    FROM INVENTOR ir    
    INNER JOIN InvtMPNLink invtlk ON ir.UNIQ_KEY = invtlk.uniq_key AND invtlk.Is_deleted =0    
    INNER JOIN Mfgrmaster mfg ON invtlk.mfgrmasterId =  mfg.MfgrMasterId AND mfg.is_deleted =0    
    LEFT JOIN InvtMfgr im ON invtlk.UniqMfgrHd = im.UniqMfgrHd AND invtlk.Uniq_Key = im.Uniq_Key AND im.Is_Deleted = 0   
 -- Nitesh B 5/10/2019 : Change the INNER JOIN to LEFT JOIN for InvtMfgr table     
         --AND im.InStore = @isInStore -- Rajendra K 06/26/2018 : replaced 'G' by parameter @inspectionSource in where condition for inStore comparision    
         -- Rajendra K 07/05/2018 : Condition commented and moved to where condition    
         -- Nitesh B 5/03/2019 : Remove condition "im.NETABLE = 1" to get non netable location records   
    OUTER APPLY(    
     SELECT receiverDetail.isCompleted,receiverDetail.isinspCompleted,receiverDetail.isinspReq,receiverDetail.receiverDetId,    
     receiverDetail.Qty_rec,receiverDetail.QtyPerPackage,receiverHeader.reason,receiverDetail.Partmfgr,receiverDetail.mfgr_pt_no,    
     receiverDetail.GL_NBR    
     FROM receiverDetail JOIN receiverHeader ON receiverDetail.receiverHdrId = receiverHeader.receiverHdrId      
     WHERE receiverHeader.inspectionsource = @inspectionSource AND receiverDetail.UNIQ_KEY = ir.UNIQ_KEY AND receiverno = @receiverNo     
     AND receiverDetail.Partmfgr = mfg.PartMfgr AND receiverDetail.mfgr_pt_no = mfg.mfgr_pt_no    
    ) AS ReceivingDetails    
    OUTER APPLY (SELECT part.LOTDETAIL,part.Autodt, part.Fgiexpdays     
            FROM PARTTYPE part WHERE part.PART_TYPE = ir.PART_TYPE  and part.PART_CLASS = ir.PART_CLASS) AS PartType     
    OUTER APPLY (SELECT SUM(FailedQty-Buyer_Accept) AS InspectionFailedQty FROM inspectionHeader WHERE receiverDetId =ReceivingDetails.receiverDetId) AS Inspection -- Nitesh N 3/15/2019 : Calculate SUM(FailedQty-Buyer_Accept) AS InspectionFailedQty      
    OUTER APPLY (SELECT TOP 1 INVT_REC.GL_NBR,INVT_REC.W_KEY,INVT_REC.INVTREC_NO,INVT_REC.acceptedQty,INVT_REC.QTYREC,    
       INVT_REC.inspectedQty -- Nilesh Sa 2/26/2018 Change failed qty based inspected qty and accepted qty    
            FROM INVT_REC WHERE receiverdetId = ReceivingDetails.receiverDetId) AS InvtRec     
                OUTER APPLY(SELECT UNIQWH,LOCATION FROM InvtMfgr WHERE W_KEY = InvtRec.W_KEY ) AS SavedInvtMfgr
    OUTER APPLY
	(
		SELECT im.UNIQMFGRHD  FROM INVENTOR ir    
			INNER JOIN InvtMPNLink invtlk ON ir.UNIQ_KEY = invtlk.uniq_key AND invtlk.Is_deleted = 0    
			INNER JOIN Mfgrmaster mfg ON invtlk.mfgrmasterId =  mfg.MfgrMasterId AND mfg.is_deleted = 0    
			INNER JOIN InvtMfgr im ON invtlk.UniqMfgrHd = im.UniqMfgrHd AND invtlk.Uniq_Key = im.Uniq_Key AND im.Is_Deleted = 0 
			WHERE ir.UNIQ_KEY IN (SELECT id FROM dbo.[fn_simpleVarcharlistToTable](@uniqKey,',')) 
	) AS InvtMfgr -- Nitesh B 10/10/2019 : Added the OUTER JOIN to get CPN Mfgrs list for IPC				    
    WHERE ir.STATUS ='active'     
     -- 07/05/2018 Rajendra K : Added condition to get records by @inspectionSource type    
    AND ((@inspectionSource = 'S' AND (im.InStore = 1 OR PART_SOURC = 'BUY' OR (PART_SOURC = 'MAKE' AND MAKE_BUY = 1)))    
       OR ((@inspectionSource <> 'G' OR PART_SOURC <>'CONSG'))) AND PART_SOURC <> 'PHANTOM' -- Nitesh B 1/25/2019 : Added condition @inspectionSource <> 'G', PART_SOURC <>'CONSG' to get records    
       AND ir.UNIQ_KEY IN (SELECT id FROM dbo.[fn_simpleVarcharlistToTable](@uniqKey,','))
	   AND invtlk.UNIQMFGRHD = CASE WHEN @inspectionSource = 'C' THEN InvtMfgr.UNIQMFGRHD ELSE invtlk.UNIQMFGRHD END     
   )    
   SELECT * INTO #TEMP2 FROM grLineItemsList UNION SELECT * FROM #TEMP1 --Nilesh sa 3/7/2018 Combine result for received parts & searched parts from UI    
   SELECT IDENTITY(INT,1,1) AS RowNumber,* INTO #TEMP FROM #TEMP2      
  END    
    
  IF @filter <> '' AND @sortExpression <> ''    
     BEGIN    
       SET @SQLQuery=N'SELECT  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE '+@filter    
        +' ORDER BY '+ @SortExpression+''+ ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'    
     END    
     ELSE IF @filter = '' AND @sortExpression <> ''    
     BEGIN    
     SET @SQLQuery=N'SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t '      
     +' ORDER BY '+ @sortExpression+'' + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'     
     END    
  ELSE IF @filter <> '' AND @sortExpression = ''    
     BEGIN    
        SET @SQLQuery=N'SELECT  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE  '+@filter+''     
        + ' ORDER BY PartNumber OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'     
     END    
      ELSE    
     BEGIN    
        SET @SQLQuery=N'SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t'    
         + ' ORDER BY PartNumber OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'    
     END    
 EXEC SP_EXECUTESQL @SQLQuery    
END