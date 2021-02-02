-- ============================================================================================================  
-- Date   : 11/25/2019  
-- Author  : Rajendra K 
-- Description : Used for Validate  data  
-- GetInvtAdjustValidData '36915831-FEE2-4B01-8FE1-4514A1FE8863' ,1 
-- ============================================================================================================    
CREATE PROC GetInvtAdjustValidData
 @ImportId UNIQUEIDENTIFIER,
 @IsSerial BIT = 0
AS  
BEGIN  
   
 SET NOCOUNT ON   
  DECLARE @ModuleId INT

  SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleDesc = 'MnxM_InventoryAdjustmentUpload' and FilePath = 'InventoryAdjustmentUpload'     

 ;WITH ImportDetail AS(
	SELECT PVT.*  
	 FROM    
	 (   
	 SELECT iaf.fkImportId AS importId,iaf.RowId,sub.class as CssClass,sub.Validation,fd.fieldName,adjusted 
	 FROM ImportFieldDefinitions fd      
	    INNER JOIN ImportInvtAdjustFields iaf ON fd.FieldDefId = iaf.FKFieldDefId 
	    INNER JOIN ImportInvtAdjustHeader h ON h.ImportId = iaf.FkImportId    
		 INNER JOIN   
		 (   
			    SELECT fkImportId,fd.RowId,MAX(status) as Class ,MIN(Message) as Validation		
			    FROM ImportInvtAdjustFields fd  
				INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId  
			    WHERE fkImportId =CAST(@importId as CHAR(36))
				AND SheetNo = 1 AND ModuleId = @ModuleId
			    GROUP BY fkImportId,fd.RowId  
				HAVING MAX(STATUS) <> 'i05red'  
		  ) Sub    
	  ON iaf.fkImportid=Sub.FkImportId and iaf.RowId=sub.RowId   
	  WHERE iaf.fkImportId =CAST(@importId as CHAR(36))
	 ) st    
	  PIVOT (MAX(adjusted) FOR fieldName IN ([CompanyName],[countQty],[custpartno],[custrev],[ExpDate],[INSTORE],[location],[Lotcode],
	  [mfgr_pt_no],[MTC],[part_no],[part_sourc],[partmfgr],[Ponum],[QtyPerPackage],[Reference],[revision],[SERIALITEMS],[warehouse])   
	 ) as PVT
  )
  
  SELECT impt.importId 
		,impt.RowId
		--,impt.CompanyName
		,impt.CssClass
		,impt.Validation
		,CAST(impt.countQty AS NUMERIC(9,2)) AS countQty
		,impt.part_sourc
		,impt.part_no
		,impt.revision
		,impt.partmfgr
		,impt.mfgr_pt_no
		,impt.warehouse
		,impt.location
		--,impt.custpartno
		--,impt.custrev
		,impt.Lotcode
		,(CASE WHEN (ISDATE(impt.ExpDate) = 1) AND p.LOTDETAIL = 1 THEN CAST(impt.ExpDate AS DATE) ELSE NULL END) AS ExpDate
		,impt.Reference
		,impt.Ponum
		,impt.MTC
		,CASE WHEN ISNULL(impt.QtyPerPackage,'') <> '' THEN CAST(impt.QtyPerPackage  AS NUMERIC(9,2)) ELSE  0 END AS QtyPerPackage
		,impt.SERIALITEMS
		,im.W_KEY
		,im.UNIQMFGRHD
		,I.UNIQ_KEY
		,ISNULL(IL.UNIQ_LOT,'') AS UNIQ_LOT
		,wa.UNIQWH
		,I.SERIALYES
		,I.useipkey
		--,CASE WHEN ISNULL(P.LOTDETAIL,CAST(0 AS BIT)) = 0 AND I.SERIALYES = 0 AND I.useipkey = 0 AND IM.QTY_OH IS NOT NULL THEN IM.QTY_OH - IM.Reserved
		--	  WHEN ISNULL(P.LOTDETAIL,CAST(0 AS BIT)) = 1 AND I.SERIALYES = 0 AND I.useipkey = 0 AND IL.LotQty IS NOT NULL THEN IL.LotQty - IL.LotResQty
		--	  WHEN ISNULL(P.LOTDETAIL,CAST(0 AS BIT)) = 0 AND I.SERIALYES = 0 AND I.useipkey = 1 AND IP.PkgBalance IS NOT NULL THEN IP.PkgBalance -IP.qtyAllocatedTotal
		--	  WHEN ISNULL(P.LOTDETAIL,CAST(0 AS BIT)) = 1 AND I.SERIALYES = 0 AND I.useipkey = 1 AND IP.PkgBalance IS NOT NULL THEN IP.PkgBalance - IP.qtyAllocatedTotal
		--	  WHEN ISNULL(P.LOTDETAIL,CAST(0 AS BIT)) = 0 AND I.SERIALYES = 1 AND I.useipkey = 0 AND IM.QTY_OH IS NOT NULL THEN IM.QTY_OH - IM.Reserved
		--	  WHEN ISNULL(P.LOTDETAIL,CAST(0 AS BIT)) = 1 AND I.SERIALYES = 1 AND I.useipkey = 1 THEN IM.QTY_OH - IM.Reserved
		--	  ELSE 0 END AS QTY_OH
		,CASE WHEN ISNULL(P.LOTDETAIL,CAST(0 AS BIT)) = 0 AND I.useipkey = 0 AND IM.QTY_OH IS NOT NULL THEN IM.QTY_OH - IM.Reserved
			  WHEN ISNULL(P.LOTDETAIL,CAST(0 AS BIT)) = 1 AND I.useipkey = 0 AND IL.LotQty IS NOT NULL THEN IL.LotQty - IL.LotResQty
			  WHEN I.useipkey = 1 AND IP.PkgBalance IS NOT NULL THEN IP.PkgBalance -IP.qtyAllocatedTotal
			  ELSE 0 END AS QTY_OH
        ,ISNULL(P.LOTDETAIL,CAST(0 AS BIT)) AS IsLotted    
		,CASE WHEN impt.INSTORE IN ('n','no','0','false') THEN CAST(0 AS BIT) 
		      WHEN ISNULL(impt.INSTORE,'') = '' THEN im.INSTORE
			  ELSE CAST(1 AS BIT) END AS INSTORE
		,CASE WHEN (im.INSTORE = 1 OR impt.INSTORE IN ('y','yes','1','true')) AND TRIM(impt.part_sourc) <> 'CONSG' THEN Sup.UNIQSUPNO 
			  WHEN TRIM(impt.part_sourc) = 'CONSG' THEN Cust.CUSTNO 
			  ELSE '' END AS SenderId
		,CASE WHEN (im.INSTORE = 1 OR impt.INSTORE IN ('y','yes','1','true')) AND TRIM(impt.part_sourc) <> 'CONSG' THEN 'S' 
			  WHEN TRIM(impt.part_sourc) = 'CONSG' THEN 'C'
			  ELSE '' END AS SenderType
  FROM ImportDetail impt
  INNER JOIN INVENTOR I ON I.PART_NO = impt.part_no AND I.REVISION = impt.revision  AND I.PART_SOURC = ISNULL(TRIM(impt.part_sourc),'')
  LEFT JOIN  PARTTYPE p ON p.PART_TYPE = I.PART_TYPE AND p.PART_CLASS = I.PART_CLASS  
  INNER JOIN INVTMFGR im ON I.UNIQ_KEY = im.UNIQ_KEY AND im.LOCATION = TRIM(impt.location) 
  INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = im.UNIQ_KEY AND im.UNIQMFGRHD = mpn.uniqmfgrhd AND im.IS_DELETED = 0			  
  INNER JOIN MfgrMaster mfM  ON mfM.MfgrMasterId = mpn.MfgrMasterId  AND mfM.IS_DELETED = 0  
  INNER JOIN WAREHOUS wa ON im.UNIQWH = wa.UNIQWH AND wa.WAREHOUSE = TRIM(impt.warehouse)
  LEFT JOIN INVTLOT IL ON IM.W_KEY = IL.W_KEY 
		AND TRIM(impt.Lotcode)= IL.LOTCODE 
		AND TRIM(impt.Reference)=   IL.REFERENCE 
		AND TRIM(impt.Ponum)= IL.PONUM 
        AND ISNULL(IL.ExpDate,'') = CASE WHEN p.LOTDETAIL = 1 THEN 
			                       CASE WHEN impt.ExpDate IS NOT NUll OR impt.ExpDate <>'' 
								        THEN CAST(impt.ExpDate AS DATETIME)
										 ELSE ISNULL(impt.ExpDate,'') END 
								   ELSE '' END
  LEFT JOIN IPKEY IP ON I.UNIQ_KEY = IP.UNIQ_KEY AND TRIM(impt.MTC) = IP.IPKEYUNIQUE
		AND IM.W_KEY = IP.W_KEY
		AND COALESCE(IL.LOTCODE,IP.LOTCODE)= IP.LOTCODE
		AND ISNULL(IL.REFERENCE,IP.REFERENCE)= IP.REFERENCE
		AND ISNULL(IL.PONUM,IP.PONUM)= IP.PONUM
		AND 1 =(CASE WHEN ISNULL(IL.LOTCODE,'')= '' THEN 1 
					 WHEN ISNULL(IL.LOTCODE,'')= '' AND ISNULL(IP.LOTCODE,'')= '' THEN 1
					 WHEN ISNULL(IL.EXPDATE,'') = ISNULL(IP.EXPDATE,'') THEN 1 ELSE 0 END)
  OUTER APPLY
  ( 
	  SELECT Custno FROM CUSTOMER WHERE custname = TRIM(impt.CompanyName)
  ) AS Cust
  OUTER APPLY
  ( 
	  SELECT UNIQSUPNO FROM SUPINFO WHERE SUPNAME = TRIM(impt.CompanyName)
  ) AS Sup
  WHERE mfM.mfgr_pt_no = TRIM(impt.mfgr_pt_no) AND mfM.PartMfgr = TRIM(impt.partmfgr)
  AND I.CUSTNO = CASE WHEN TRIM(impt.part_sourc) = 'CONSG' THEN Cust.CUSTNO ELSE '' END 
  AND I.CUSTPARTNO = CASE WHEN TRIM(impt.part_sourc) = 'CONSG' THEN impt.custpartno ELSE '' END 
  AND I.CUSTREV = CASE WHEN TRIM(impt.part_sourc) = 'CONSG' THEN impt.custrev ELSE '' END 
  AND (I.SERIALYES = @IsSerial OR (@IsSerial = 0 AND 1=1))
  AND im.INSTORE = CASE WHEN impt.INSTORE IN ('n','no','0','false') THEN CAST(0 AS BIT) 
		               WHEN ISNULL(impt.INSTORE,'') = '' THEN CAST(0 AS BIT)
			           ELSE CAST(1 AS BIT) END 
  AND im.UNIQSUPNO =  CASE WHEN TRIM(impt.INSTORE) IN ('1','true','yes','y') THEN Sup.UNIQSUPNO ELSE '' END
END