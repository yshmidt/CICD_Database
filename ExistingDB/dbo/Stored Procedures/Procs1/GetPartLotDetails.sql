-- ============================================================================================================  
-- Date   : 09/04/2019  
-- Author  : Rajendra K 
-- Description : Used for Validate Manufacture uploaded data  
-- 10/03/2019 Rajendra k : Selected Distinct records
-- 10/03/2019 Rajendra k : Changed the join 
-- 10/04/2019 Rajendra k : Added Union to select lotted and manually parts And table manufactData
-- 10/15/2019 Rajendra k : Declared @Bom and @ConsgKey table for consign Avls
-- 10/15/2019 Rajendra k : Added CTE "ManufactList" to get Consign manufacturers and in join
-- 10/23/2019 Rajendra k : il.status ,il.Message Removed from selection
-- 10/23/2019 Rajendra k : il.status ,il.Message Removed from selection
-- 10/25/2019 Rajendra k : Changed the join Inner to right if lot details is empty
-- 11/02/2019 Rajendra k : Added Condition if partmfgr is empty
-- 11/04/2019 Rajendra k : Added WHERE Condition if partmfgr,mpn are empty
-- 12/05/2019 Rajendra k : Changed the data type of ManufactQty from numeric(4,0)  to numeric(12,2) 
-- 12/26/2019 Rajendra k  : Added MTCData table and used in join 
-- 12/26/2019 Rajendra k  : Added useipkey and serialyes in @MfgrDetails table	
-- GetPartLotDetails '3AC542DC-765E-4EBF-8CE9-C697BA8BF707' ,'0000001368'
-- ============================================================================================================    
CREATE PROC GetPartLotDetails  
 @ImportId UNIQUEIDENTIFIER,
 @woNo CHAR(10),
 @avlRowId UNIQUEIDENTIFIER = NULL  
AS  
BEGIN  
   
 SET NOCOUNT ON   
	DECLARE @CustNo CHAR(10) ;
	DECLARE @MfgrDetails TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId	UNIQUEIDENTIFIER,AvlRowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),
							Validation VARCHAR(100),partMfg	VARCHAR(100), mpn VARCHAR(100),Warehouse VARCHAR(100),Location VARCHAR(100),ResQty VARCHAR(100),UNIQ_KEY VARCHAR(100),
							partno	VARCHAR(100),rev VARCHAR(100),custPartNo VARCHAR(100),crev VARCHAR(100),IsLotted BIT,WorkCenter VARCHAR(100),useipkey BIT,SERIALYES BIT)    
							-- 12/26/2019 Rajendra k  : Added useipkey and serialyes in @MfgrDetails table	
	-- 10/15/2019 Rajendra k : Declared @Bom and @ConsgKey table for consign Avls
	DECLARE @Bom Table (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),Validation VARCHAR(100),assyDesc VARCHAR(100)
							 ,assyNum VARCHAR(100),assypartclass VARCHAR(100),assyparttype VARCHAR(100),assyRev VARCHAR(100),custno VARCHAR(100),UNIQ_KEY VARCHAR(10));  
	
	DECLARE @ConsgKey Table (Uniq_Key CHAR(10),CosignUniqKey CHAR(10))

   INSERT INTO @MfgrDetails EXEC GetManufactureUploadData @importId;
   INSERT INTO @Bom EXEC GetAssemblyRecords @importId	
   SELECT TOP 1 @CustNo= custno FROM @Bom

   INSERT INTO @ConsgKey (Uniq_Key,CosignUniqKey) 
   SELECT DISTINCT m.UNIQ_KEY, ISNULL(Consg.UNIQ_KEY,m.UNIQ_KEY) AS CosignUniqKey
   FROM @MfgrDetails m
   OUTER APPLY
   (
		SELECT TOP 1 UNIQ_KEY FROM INVENTOR WHERE INT_UNIQ = m.UNIQ_KEY AND CUSTNO = @CustNo
   ) AS Consg

 ;WITH  ManufactList AS( -- 10/15/2019 Rajendra k : Added CTE "ManufactList" to get Consign manufacturers and in join
      SELECT DISTINCT mf.MfgrMasterId,C.Uniq_Key,mf.mfgr_pt_no,mf.PartMfgr
	  FROM INVTMFGR im 
	     INNER JOIN InvtMPNLink m ON im.uniqmfgrhd = m.UNIQMFGRHD AND m.is_deleted = 0
	     INNER JOIN  MfgrMaster mf ON mf.MfgrMasterId = m.MfgrMasterId 
		 INNER JOIN @ConsgKey C ON im.UNIQ_KEY = C.CosignUniqKey
  )
	--SELECT * FROM @MfgrDetails
, lotData As(	    -- 10/03/2019 Rajendra k : Changed the join 
	 SELECT importId,AssemblyRowId,CompRowId,AvlRowId,LotRowId,lot.*,DateCode,ExpDate,LotCode,PoNum,ResQty
	 FROM    
	 (   
		SELECT DISTINCT fd.FkImportId AS importId,fd.AssemblyRowId,ic.CompRowId,ia.AvlRowId,il.LotRowId,ibf.fieldName,il.Adjusted --,il.status ,il.Message
		FROM ImportBOMToKitAssemly fd  -- 10/23/2019 Rajendra k : il.status ,il.Message Removed from selection
			INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
			INNER JOIN ImportBOMToKitAvls ia ON ic.CompRowId = ia.FKCompRowId
			INNER JOIN ImportBOMToKitLot il ON ia.AvlRowId = il.FKAvlRowId
			INNER JOIN ImportFieldDefinitions ibf ON il.FKFieldDefId = ibf.FieldDefId  
		WHERE fkImportId = @ImportId
			AND FieldName IN ('DateCode','ExpDate','LotCode','PoNum','ResQty') 
		) st    
	  PIVOT (MAX(Adjusted) FOR fieldName IN ([DateCode],[ExpDate],[LotCode],[PoNum],[ResQty])  
	 ) as PVT
	 OUTER APPLY
	 (
			SELECT MAX(Status) CssClass,MIN(Message) Validation FROM ImportBOMToKitLot where  LotRowId = PVT.LotRowId GROUP BY LotRowId
	 ) AS lot
  )
, MTCData AS
  (-- 12/26/2019 Rajendra k  : Added MTCData table and used in join 
	 SELECT AssemblyRowId,CompRowId,AvlRowId,LotRowId,MTCRowId,MTC.*,ResQty,MTC
     FROM    
     (   
		SELECT DISTINCT fd.FkImportId AS importId,fd.AssemblyRowId,ic.CompRowId,ia.AvlRowId,il.LotRowId,mt.MTCRowId,mt.status ,mt.Message,ibf.fieldName,mt.Adjusted 
		FROM ImportBOMToKitAssemly fd  
			INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
			INNER JOIN ImportBOMToKitAvls ia ON ic.CompRowId = ia.FKCompRowId
			INNER JOIN ImportBOMToKitMTC mt ON mt.FKAvlRowId = ia.AvlRowId
			LEFT JOIN ImportBOMToKitLot il ON il.LotRowId = mt.FkLotRowId
			INNER JOIN ImportFieldDefinitions ibf ON mt.FKFieldDefId = ibf.FieldDefId  
		WHERE fkImportId = @ImportId
			AND FieldName IN ('ResQty','MTC') 
			AND mt.Status = ''
	) st    
    PIVOT (MAX(Adjusted) FOR fieldName IN ([ResQty],[MTC])  
	) as PVT
	OUTER APPLY
	(
		SELECT MAX(Status) CssClass,MIN(Message) Validation FROM ImportBOMToKitMTC where  MTCRowId = PVT.MTCRowId GROUP BY MTCRowId
    ) AS MTC
  )
  --select * from lotData
--	  -- 10/03/2019 Rajendra k : Selected Distinct records
,manufactData AS (
  SELECT DISTINCT 
		ISNULL(PVT.importId,mfgr.importId) AS importId
		,ISNULL(PVT.AssemblyRowId,mfgr.AssemblyRowId) AS AssemblyRowId
		,ISNULL(PVT.CompRowId,mfgr.CompRowId) AS CompRowId
		,ISNULL(PVT.AvlRowId,mfgr.AvlRowId) AS AvlRowId
		,ISNULL(PVT.LotRowId,null) AS LotRowId
		,CASE WHEN mfgr.useipkey = 1 THEN ISNULL(mt.CssClass,'')  ELSE ISNULL(ISNULL(PVT.CssClass,mfgr.CssClass),'') END AS CssClass
		,ISNULL(PVT.Validation,mfgr.Validation) AS Validation
		,ISNULL(PVT.LotCode,'') AS LotCode
		,(CASE WHEN (ISDATE(PVT.ExpDate) = 1) AND mfgr.IsLotted = 1 THEN CAST(PVT.ExpDate AS DATE) ELSE NULL END) AS ExpDate
		,PVT.DateCode
		,PVT.PoNum
		,ISNULL(PVT.ResQty,mfgr.ResQty) AS ResQty
		,mfgr.partno
		,mfgr.rev
		,mfgr.custPartNo
		,mfgr.crev
		,mfgr.partMfg
		,mfgr.mpn
		,CAST(ISNULL(mfgr.ResQty,0)AS NUMERIC(12,2)) AS ManufactQty-- 12/05/2019 Rajendra k : Changed the data type of ManufactQty from numeric(4,0)  to numeric(12,2) 
		,mfgr.Location
		,mfgr.Warehouse
		,mfgr.IsLotted
		,ISNULL(mfgr.UNIQ_KEY,'') AS UNIQ_KEY
		,WorkCenter
		,mt.MTC
 FROM lotData PVT
	  RIGHT JOIN @MfgrDetails mfgr ON PVT.AvlRowId = mfgr.AvlRowId 	-- 10/24/2019 Rajendra k : Changed the join Inner to right if lot details is empty
	  LEFT JOIN MTCData mt ON mt.LotRowId = PVT.LotRowId-- 12/26/2019 Rajendra k  : Added MTCData table and used in join 
	WHERE mfgr.IsLotted = 1

UNION -- 10/04/2019 Rajendra k : Added Union to select lotted and manually parts And table manufactData
  
  SELECT DISTINCT 
		 importId
		, mfgr.AssemblyRowId
		, mfgr.CompRowId
		, mfgr.AvlRowId
		,null AS LotRowId
		,CASE WHEN mfgr.useipkey = 1 THEN ISNULL(mt.CssClass,'') ELSE ISNULL(mfgr.CssClass,'') END AS CssClass
		, mfgr.Validation
		,'' AS LotCode
		, NULL  AS ExpDate
		,'' AS DateCode
		,'' AS PoNum
		,mfgr.ResQty
		,mfgr.partno
		,mfgr.rev
		,mfgr.custPartNo
		,mfgr.crev
		,mfgr.partMfg
		,mfgr.mpn
		,CAST(ISNULL(mfgr.ResQty,0)AS NUMERIC(12,2)) AS ManufactQty-- 12/05/2019 Rajendra k : Changed the data type of ManufactQty from numeric(4,0)  to numeric(12,2) 
		,mfgr.Location
		,mfgr.Warehouse
		,mfgr.IsLotted
		,ISNULL(mfgr.UNIQ_KEY,'') AS UNIQ_KEY
		,WorkCenter
		,mt.MTC
 FROM  @MfgrDetails mfgr 
 	  LEFT JOIN MTCData mt ON mt.AvlRowId = mfgr.AvlRowId-- 12/26/2019 Rajendra k  : Added MTCData table and used in join 
	WHERE mfgr.IsLotted = 0
	)

	--SELECT * from manufactData
	-- 10/04/2019 Rajendra k : Added Union to select lotted and manually parts And table manufactData
 SELECT ISNULL(partmfgr.UNIQMFGRHD,'') AS UNIQMFGRHD
 	,ISNULL(partmfgr.W_KEY,'') AS W_KEY
 	,ISNULL(partmfgr.UNIQWH,'') AS UNIQWH
 	,ISNULL(kamain.KASEQNUM,'') AS KASEQNUM,tt.* 
 FROM manufactData tt -- 10/15/2019 Rajendra k : Added CTE "ManufactList" to get Consign manufacturers and in join
   LEFT JOIN ManufactList ml on (tt.mpn = ml.mfgr_pt_no) AND (tt.partMfg = ml.PartMfgr ) AND tt.UNIQ_KEY = ml.Uniq_Key
   OUTER APPLY
   (
 		SELECT im.UNIQMFGRHD,im.UNIQ_KEY,im.W_KEY,PartMfgr,mfgr_pt_no,WAREHOUSE,LOCATION,wa.UNIQWH 
 		FROM  INVTMFGR im
 			 INNER JOIN  InvtMPNLink mpn ON mpn.uniq_key = im.UNIQ_KEY AND im.UNIQMFGRHD = mpn.uniqmfgrhd AND im.IS_DELETED = 0 AND im.INSTORE = 0				  
 			 INNER JOIN  MfgrMaster mfM  ON mfM.MfgrMasterId = mpn.MfgrMasterId  AND mfM.IS_DELETED = 0  
 			 INNER JOIN  WAREHOUS wa ON im.UNIQWH = wa.UNIQWH 
 		WHERE mfM.PartMfgr = tt.partMfg AND im.UNIQ_KEY = tt.UNIQ_KEY AND mfM.mfgr_pt_no = tt.mpn AND im.LOCATION = tt.Location AND wa.WAREHOUSE = tt.Warehouse
    )partmfgr
    OUTER APPLY
    (
 		SELECT KASEQNUM FROM KAMAIN WHERE WONO = @woNo AND UNIQ_KEY = tt.UNIQ_KEY AND DEPT_ID = tt.WorkCenter
    )kamain
	WHERE tt.partMfg  = CASE -- 11/04/2019 Rajendra k : Added WHERE Condition if partmfgr,mpn are empty
                          WHEN trim(tt.mpn)='' and trim(tt.partMfg)='' 
                               THEN ''
                          ELSE ml.PartMfgr
                     END 
   AND tt.mpn = CASE 
                          WHEN trim(tt.mpn)='' and trim(tt.partMfg)='' 
                               THEN ''
                          ELSE ml.mfgr_pt_no 
                     END 
 END