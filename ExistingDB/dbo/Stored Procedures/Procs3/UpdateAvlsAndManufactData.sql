-- ============================================================================================================  
-- Date   : 10/21/2019  
-- Author  : Rajendra K 
-- Description : Used for update Manufacture and warehouse 
-- 11/28/2019 Rajendra k  : Changed and Added condition to Update value of Location field
-- 12/19/2019 Rajendra K : Added Block to Update Avls,warehouse,lot details  using MTC 
-- 12/19/2019 Rajendra K : Modified the conditions if part is MTC
-- 01/24/2020 Rajendra K : Added the condition if mpn is empty then skip autopopulation of partmfgr data
-- UpdateAvlsAndManufactData '91DBD9FA-139B-4F44-93BC-ED8828C20169'
-- ============================================================================================================    
CREATE PROC UpdateAvlsAndManufactData
 @ImportId UNIQUEIDENTIFIER
AS  
BEGIN  
   
 SET NOCOUNT ON 
  DECLARE @SQL NVARCHAR(MAX),@SQLQ NVARCHAR(MAX),@ModuleId INT,@FieldName VARCHAR(MAX),@WoFieldName VARCHAR(MAX),@Warehouse VARCHAR(6),@SQLLot NVARCHAR(MAX),@LotName VARCHAR(MAX),
			@MTCSQL NVARCHAR(MAX),@MTCFieldName NVARCHAR(MAX)

  DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER,AvlRowId UNIQUEIDENTIFIER,
							  CssClass VARCHAR(MAX),Validation VARCHAR(MAX),Location VARCHAR(MAX),mpn VARCHAR(MAX),partMfg VARCHAR(MAX),ResQty VARCHAR(MAX)
							  ,Warehouse VARCHAR(MAX))  
							  
 DECLARE @ComoponentsDetail TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER,CssClass VARCHAR(MAX),Validation VARCHAR(MAX),itemno NUMERIC
							,partSource  VARCHAR(MAX),partno  VARCHAR(MAX),rev  VARCHAR(MAX),custPartNo  VARCHAR(MAX),crev  VARCHAR(MAX),qty NUMERIC,bomNote  VARCHAR(MAX)
							,workCenter VARCHAR(MAX),used BIT,UNIQ_KEY VARCHAR(MAX),PART_CLASS VARCHAR(MAX),PART_TYPE VARCHAR(MAX),U_OF_MEAS VARCHAR(100),IsLotted BIT,useipkey BIT,SERIALYES BIT)     
 
 DECLARE @WODetail TABLE (importId UNIQUEIDENTIFIER,WORowId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER, CssClass VARCHAR(100),Validation VARCHAR(100), bldqty VARCHAR(10),
							  Due_date VARCHAR(100),End_date VARCHAR(100), JobType VARCHAR(100),kitDefWarehouse VARCHAR(100),Line_no VARCHAR(100),OrderDate VARCHAR(100),
							  PRJNUMBER VARCHAR(100),PRJUNIQUE	VARCHAR(100),RoutingName VARCHAR(100),SONO VARCHAR(100),Start_date VARCHAR(100),wono VARCHAR(100),Wonote VARCHAR(100))

 DECLARE @LotDetail TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER,AvlRowId UNIQUEIDENTIFIER,LotRowId UNIQUEIDENTIFIER,
							  CssClass VARCHAR(MAX),Validation VARCHAR(MAX),DateCode VARCHAR(MAX),ExpDate VARCHAR(MAX),LotCode VARCHAR(MAX),PoNum VARCHAR(MAX)
							  ,ResQty VARCHAR(MAX))

  DECLARE @MTCImportDetail TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER,AvlRowId UNIQUEIDENTIFIER,LotRowId UNIQUEIDENTIFIER 
							,MTCRowId UNIQUEIDENTIFIER,CssClass VARCHAR(MAX),Validation VARCHAR(MAX),MTC VARCHAR(MAX),ResQty VARCHAR(MAX))   

 -- Insert statements for procedure here 
SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleDesc = 'MnxM_BOMtoKITUpload' and FilePath = 'BOMtoKITUpload'   
SELECT @FieldName = STUFF(    
      (    
       SELECT  ',[' +  F.FIELDNAME + ']' FROM   
       ImportFieldDefinitions F      
       WHERE ModuleId = @ModuleId  AND FieldName in ('Location','mpn','partMfg','ResQty','Warehouse')  
       ORDER BY F.FIELDNAME   
       FOR XML PATH('')    
      ),    
      1,1,'')     

SELECT @WoFieldName = STUFF(    
      (    
       SELECT  ',[' +  F.FIELDNAME + ']' FROM   
       ImportFieldDefinitions F      
       WHERE ModuleId = @ModuleId  AND FieldName in ('bldqty','Due_date','End_date','JobType','kitDefWarehouse','Line_no','OrderDate','PRJNUMBER','PRJUNIQUE'
						,'RoutingName','SONO','Start_date','wono','Wonote')  
       ORDER BY F.FIELDNAME   
       FOR XML PATH('')    
      ),    
      1,1,'') 

 SELECT @LotName = STUFF(    
      (    
       SELECT  ',[' +  F.FIELDNAME + ']' FROM   
       ImportFieldDefinitions F      
       WHERE ModuleId = @ModuleId  AND FieldName IN ('DateCode','ExpDate','LotCode','PoNum','ResQty')   
       ORDER BY F.FIELDNAME   
       FOR XML PATH('')    
      ),    
      1,1,'')   

	  -- 12/19/2019 Rajendra K : Added Block to Update Avls,warehouse,lot details  using MTC 
 SELECT @MTCFieldName = STUFF(      
      (      
       SELECT  ',[' +  F.FIELDNAME + ']' FROM     
       ImportFieldDefinitions F        
       WHERE ModuleId = @ModuleId  AND FieldName IN ('MTC','ResQty')     
       ORDER BY F.FIELDNAME     
       FOR XML PATH('')      
      ),      
      1,1,'')

 SELECT @SQL = N'    
  SELECT importId,AssemblyRowId,CompRowId,AvlRowId,Avls.*,Location,mpn,partMfg,ResQty,Warehouse
  FROM    
  (   
	SELECT aa.fkImportId AS importId,aa.AssemblyRowId,c.CompRowId,ia.AvlRowId,ia.Status,ia.Message,fd.fieldName,ia.Adjusted 
	   FROM ImportFieldDefinitions fd 
		INNER JOIN ImportBOMToKitAvls ia ON fd.FieldDefId = ia.FKFieldDefId
		INNER JOIN ImportBOMToKitComponents c ON ia.FKCompRowId = c.CompRowId
		INNER JOIN ImportBOMToKitAssemly aa ON c.FKAssemblyRowId = aa.AssemblyRowId
	WHERE fkImportId = '''+ CAST(@ImportId as CHAR(36))+'''
		AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+') 
	) st    
   PIVOT (MAX(Adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')    
  ) as PVT
  OUTER APPLY
  (
		SELECT MAX(Status) CssClass,MIN(Message) Validation FROM ImportBOMToKitAvls where AvlRowId = PVT.AvlRowId GROUP BY AvlRowId
  ) AS Avls'  
  
  SELECT @SQLQ = N'    
  SELECT PVT.*  
  FROM    
  (   
   SELECT ibf.fkImportId AS importId,ic.WORowId,ibf.AssemblyRowId,sub.class as CssClass,sub.Validation,fd.fieldName,ic.Adjusted 
   FROM ImportFieldDefinitions fd      
	 INNER JOIN ImportBOMToKitWorkOrder ic ON fd.FieldDefId = ic.FKFieldDefId
     INNER JOIN ImportBOMToKitAssemly ibf ON ic.FKAssemblyRowId = ibf.AssemblyRowId
     INNER JOIN ImportBOMToKitHeader h ON h.ImportId = ibf.FkImportId     
	 INNER JOIN   
	   (   
			SELECT fkImportId,WORowId,AssemblyRowId,MAX(ic.status) as Class ,MIN(ic.Message) as Validation		
			FROM ImportBOMToKitAssemly fd  
				INNER JOIN ImportBOMToKitWorkOrder ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
				INNER JOIN ImportFieldDefinitions ibf ON ic.FKFieldDefId = ibf.FieldDefId   
			WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''    
				AND FieldName IN ('+REPLACE(REPLACE(@WoFieldName,'[',''''),']','''')+')     
			GROUP BY fkImportId,WORowId,AssemblyRowId 
	   ) Sub    
   ON ibf.fkImportid=Sub.FkImportId and ic.WORowId = sub.WORowId AND ic.FKAssemblyRowId = sub.AssemblyRowId 
   WHERE ibf.fkImportId = '''+ CAST(@importId as CHAR(36))+'''  
  ) st    
   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @WoFieldName +')   
  ) as PVT ' 

  SELECT @SQLLot = N'    
  SELECT importId,AssemblyRowId,CompRowId,AvlRowId,LotRowId,lot.*,DateCode,ExpDate,LotCode,PoNum,ResQty
  FROM    
  (   
	SELECT DISTINCT fd.FkImportId AS importId,fd.AssemblyRowId,ic.CompRowId,ia.AvlRowId,il.LotRowId,il.status ,il.Message,ibf.fieldName,il.Adjusted 
	FROM ImportBOMToKitAssemly fd  
		INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
		INNER JOIN ImportBOMToKitAvls ia ON ic.CompRowId = ia.FKCompRowId
		INNER JOIN ImportBOMToKitLot il ON ia.AvlRowId = il.FKAvlRowId
		INNER JOIN ImportFieldDefinitions ibf ON il.FKFieldDefId = ibf.FieldDefId  
	WHERE fkImportId = '''+ CAST(@ImportId as CHAR(36))+'''
		AND FieldName IN ('+REPLACE(REPLACE(@LotName,'[',''''),']','''')+') 
	) st    
   PIVOT (MAX(Adjusted) FOR fieldName'+ ' IN ('+ @LotName +')  
  ) as PVT
  OUTER APPLY
  (
		SELECT MAX(Status) CssClass,MIN(Message) Validation FROM ImportBOMToKitLot where  LotRowId = PVT.LotRowId GROUP BY LotRowId
  ) AS lot'

    SELECT @MTCSQL = N'    
	SELECT importId,AssemblyRowId,CompRowId,AvlRowId,LotRowId,MTCRowId,MTC.*,MTC,ResQty
	 FROM    
	 (   
		SELECT DISTINCT fd.FkImportId AS importId,fd.AssemblyRowId,ic.CompRowId,ia.AvlRowId,il.LotRowId,mt.MTCRowId,ibf.fieldName,mt.Adjusted 
		FROM ImportBOMToKitAssemly fd  
			INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
			INNER JOIN ImportBOMToKitAvls ia ON ic.CompRowId = ia.FKCompRowId
			INNER JOIN ImportBOMToKitMTC mt ON mt.FKAvlRowId = ia.AvlRowId
			LEFT JOIN ImportBOMToKitLot il ON il.LotRowId = mt.FkLotRowId
			INNER JOIN ImportFieldDefinitions ibf ON mt.FKFieldDefId = ibf.FieldDefId  
		WHERE fkImportId =  '''+ CAST(@ImportId as CHAR(36))+'''
			AND FieldName IN ('+REPLACE(REPLACE(@MTCFieldName,'[',''''),']','''')+') 
		) st    
	  PIVOT (MAX(Adjusted) FOR fieldName IN ('+ @MTCFieldName +')     
	 ) as PVT
	 OUTER APPLY
	 (
		SELECT MAX(Status) CssClass,MIN(Message) Validation FROM ImportBOMToKitMTC where  MTCRowId = PVT.MTCRowId GROUP BY MTCRowId
     ) AS MTC'

 --Print @@MTCSQL  
 INSERT INTO @ImportDetail EXEC sp_executesql @SQL
 INSERT INTO @ComoponentsDetail EXEC GetComponentsData @importId   
 INSERT INTO @WODetail EXEC sp_executesql @SQLQ;  
 INSERT INTO @LotDetail EXEC sp_executesql @SQLLot   
 INSERT INTO @MTCImportDetail EXEC SP_EXECUTESQL @MTCSQL 

 --select *from @MTCImportDetail
 IF EXISTS (SELECT kitDefWarehouse FROM @WODetail)
 BEGIN
	SELECT @Warehouse = w.WAREHOUSE  FROM @WODetail wo INNER JOIN warehous w ON TRIM(wo.kitDefWarehouse) = TRIM(w.WAREHOUSE)
 END

 UPDATE ia 
 SET [Adjusted] = 
  CASE -- 12/19/2019 Rajendra K : Modified the conditions if part is MTC
	  WHEN ifd.FieldName = 'partMfg' THEN   
			CASE WHEN (ISNULL(impt.partMfg,'') = '' AND Ipkey.PartMfgr IS NOT NULL AND c.useipkey = 1) THEN Ipkey.PartMfgr
				 WHEN (ISNULL(impt.partMfg,'') = '' AND mfgrCnt.Mfgrcount IS NOT NULL AND mfgrCnt.Mfgrcount = 1 AND mfgrData.PartMfgr IS NOT NULL AND ISNULL(impt.mpn,'') = '') THEN mfgrData.PartMfgr
				 WHEN (ISNULL(impt.partMfg,'') = '' AND ManufactCount.Mcount IS NOT NULL AND ManufactCount.Mcount = 1 AND Manufact.PartMfgr IS NOT NULL 
				 AND (ISNULL(impt.mpn,'') <> '')) THEN Manufact.PartMfgr-- 01/24/2020 Rajendra K : Added the condition if mpn is empty then skip autopopulation of partmfgr data
			ELSE ia.Adjusted END

	  WHEN ifd.FieldName = 'mpn' THEN    
			CASE WHEN (ISNULL(impt.mpn,'') = ''  AND Ipkey.mfgr_pt_no IS NOT NULL AND c.useipkey = 1) THEN Ipkey.mfgr_pt_no
			     WHEN (ISNULL(impt.partMfg,'') = '' AND ISNULL(impt.mpn,'') = '' AND  mfgrCnt.Mfgrcount IS NOT NULL AND mfgrCnt.Mfgrcount = 1 AND mfgrData.mfgr_pt_no IS NOT NULL) THEN mfgrData.mfgr_pt_no
				 WHEN (lotManufact.mfgr_pt_no IS NOT NULL AND ISNULL(impt.partMfg,'') <> '' AND ISNULL(impt.mpn,'') = '' AND c.IsLotted = 1 ) THEN lotManufact.mfgr_pt_no
			ELSE ia.Adjusted END

	  WHEN ifd.FieldName = 'Warehouse' THEN   
			CASE WHEN ISNULL(impt.Warehouse,'') = '' AND c.useipkey = 1 AND Ipkey.Warehouse IS NOT NULL THEN Ipkey.Warehouse
				 WHEN ISNULL(impt.Warehouse,'') = '' AND mfgrCnt.Mfgrcount IS NOT NULL AND mfgrCnt.Mfgrcount = 1 AND manuWarehouse.WAREHOUSE IS NOT NULL THEN manuWarehouse.WAREHOUSE
				 WHEN (ISNULL(impt.Warehouse,'') = '' AND warehouse.WAREHOUSE IS NOT NULL AND c.IsLotted = 1) THEN warehouse.WAREHOUSE
			ELSE 
				CASE WHEN ISNULL(impt.Warehouse,'') = '' AND ware.WAREHOUSE IS NOT NULL THEN ware.WAREHOUSE ELSE ia.Adjusted END 
			END

	  WHEN ifd.FieldName = 'Location' THEN   -- 11/28/2019 Rajendra k  : Changed and Added condition to Update value of Location field
			CASE WHEN ISNULL(impt.Location,'') = '' AND c.useipkey = 1 AND Ipkey.LOCATION IS NOT NULL THEN Ipkey.LOCATION
				 WHEN ISNULL(impt.Location,'') = '' AND mfgrCnt.Mfgrcount IS NOT NULL AND mfgrCnt.Mfgrcount = 1 AND manuWarehouse.LOCATION IS NOT NULL THEN manuWarehouse.LOCATION
				 WHEN (ISNULL(impt.Location,'') = '' AND warehouse.LOCATION IS NOT NULL AND c.IsLotted = 1 AND warehouse.WAREHOUSE = TRIM(impt.Warehouse)) THEN warehouse.LOCATION
				 WHEN (ISNULL(impt.Location,'') = '' AND warehouse.LOCATION IS NOT NULL AND c.IsLotted = 1 AND warehouse.WAREHOUSE <> TRIM(impt.Warehouse) AND TRIM(impt.Warehouse) = '') THEN warehouse.LOCATION
				 WHEN (ISNULL(impt.Location,'') = '' AND warehouse.LOCATION IS NOT NULL AND c.IsLotted = 1 AND warehouse.WAREHOUSE <> TRIM(impt.Warehouse) AND TRIM(impt.Warehouse) <> '') THEN ia.Adjusted 
			ELSE 
				CASE WHEN ISNULL(impt.Location,'') = '' AND ware.LOCATION IS NOT NULL THEN ware.LOCATION ELSE ia.Adjusted END 
			END

  ELSE ia.Adjusted END

,[Original] = 
  CASE 
	  WHEN ifd.FieldName = 'partMfg' THEN   
			CASE WHEN (ISNULL(impt.partMfg,'') = '' AND Ipkey.PartMfgr IS NOT NULL AND c.useipkey = 1) THEN Ipkey.PartMfgr
			     WHEN (ISNULL(impt.partMfg,'') = '' AND mfgrCnt.Mfgrcount IS NOT NULL AND mfgrCnt.Mfgrcount = 1 AND mfgrData.PartMfgr IS NOT NULL AND ISNULL(impt.mpn,'') = '') THEN mfgrData.PartMfgr				 
				 WHEN (ISNULL(impt.partMfg,'') = '' AND ManufactCount.Mcount IS NOT NULL AND ManufactCount.Mcount = 1 AND Manufact.PartMfgr IS NOT NULL
				 AND (ISNULL(impt.mpn,'') <> '')) THEN Manufact.PartMfgr-- 01/24/2020 Rajendra K : Added the condition if mpn is empty then skip autopopulation of partmfgr data
			ELSE  ia.Original END

	  WHEN ifd.FieldName = 'mpn' THEN  
		    CASE WHEN (ISNULL(impt.mpn,'') = ''  AND Ipkey.mfgr_pt_no IS NOT NULL AND c.useipkey = 1) THEN Ipkey.mfgr_pt_no
			     WHEN (ISNULL(impt.partMfg,'') = '' AND ISNULL(impt.mpn,'') = '' AND mfgrCnt.Mfgrcount IS NOT NULL AND mfgrCnt.Mfgrcount = 1 AND mfgrData.mfgr_pt_no IS NOT NULL) THEN mfgrData.mfgr_pt_no
			     WHEN (lotManufact.mfgr_pt_no IS NOT NULL AND ISNULL(impt.partMfg,'') <> '' AND ISNULL(impt.mpn,'') = '' AND c.IsLotted = 1 ) THEN lotManufact.mfgr_pt_no
			ELSE ia.Original END

	  WHEN ifd.FieldName = 'Warehouse' THEN   
			CASE WHEN ISNULL(impt.Warehouse,'') = '' AND c.useipkey = 1 AND Ipkey.Warehouse IS NOT NULL THEN Ipkey.Warehouse
				 WHEN ISNULL(impt.Warehouse,'') = '' AND mfgrCnt.Mfgrcount IS NOT NULL AND mfgrCnt.Mfgrcount = 1 AND manuWarehouse.WAREHOUSE IS NOT NULL THEN manuWarehouse.WAREHOUSE
				 WHEN (ISNULL(impt.Warehouse,'') = '' AND warehouse.WAREHOUSE IS NOT NULL AND c.IsLotted = 1) THEN warehouse.WAREHOUSE
			ELSE 
				CASE WHEN ISNULL(impt.Warehouse,'') = '' AND ware.WAREHOUSE IS NOT NULL THEN ware.WAREHOUSE ELSE ia.Original END 
			END

	  WHEN ifd.FieldName = 'Location' THEN   -- 11/28/2019 Rajendra k  : Changed and Added condition to Update value of Location field
			CASE WHEN ISNULL(impt.Location,'') = '' AND c.useipkey = 1 AND Ipkey.LOCATION IS NOT NULL THEN Ipkey.LOCATION
				 WHEN ISNULL(impt.Location,'') = '' AND mfgrCnt.Mfgrcount IS NOT NULL AND mfgrCnt.Mfgrcount = 1 AND manuWarehouse.LOCATION IS NOT NULL THEN manuWarehouse.LOCATION
				 WHEN (ISNULL(impt.Location,'') = '' AND warehouse.LOCATION IS NOT NULL AND c.IsLotted = 1 AND warehouse.WAREHOUSE = TRIM(impt.Warehouse)) THEN warehouse.LOCATION
				 WHEN (ISNULL(impt.Location,'') = '' AND warehouse.LOCATION IS NOT NULL AND c.IsLotted = 1 AND warehouse.WAREHOUSE <> TRIM(impt.Warehouse) AND TRIM(impt.Warehouse) = '') THEN warehouse.LOCATION
				 WHEN (ISNULL(impt.Location,'') = '' AND warehouse.LOCATION IS NOT NULL AND c.IsLotted = 1 AND warehouse.WAREHOUSE <> TRIM(impt.Warehouse) AND TRIM(impt.Warehouse) <> '') THEN ia.Original 
			ELSE 
				CASE WHEN ISNULL(impt.Location,'') = '' AND ware.LOCATION IS NOT NULL THEN ware.LOCATION ELSE ia.Original END 
			END

  ELSE ia.Original END
  --select Ipkey.*
  FROM ImportBOMToKitAvls ia 
	  INNER JOIN ImportFieldDefinitions ifd  ON ia.FKFieldDefId =ifd.FieldDefId AND ModuleId = @ModuleId
	  INNER JOIN @ImportDetail impt ON ia.AvlRowId = impt.AvlRowId
	  INNER JOIN @ComoponentsDetail c ON ia.FKCompRowId = c.CompRowId
	  LEFT JOIN @LotDetail l ON ia.AvlRowId = l.AvlRowId
	  LEFT JOIN @MTCImportDetail mt ON l.LotRowId= mt.LotRowId OR mt.AvlRowId = ia.AvlRowId
	  OUTER APPLY 
	  (
			SELECT COUNT(mster.mfgr_pt_no) AS Mcount,mster.mfgr_pt_no
			FROM INVENTOR I 
				INNER JOIN InvtMPNLink mp ON i.UNIQ_KEY = mp.uniq_key
				INNER JOIN MfgrMaster mster ON mp.MfgrMasterId  = mster.MfgrMasterId
		    WHERE mster.mfgr_pt_no = TRIM(impt.mpn) AND (I.UNIQ_KEY =  c.UNIQ_KEY OR  (TRIM(PART_NO) = TRIM(c.partno)   
				 AND TRIM(REVISION) = TRIM(c.rev) AND TRIM(c.custPartNo) = TRIM(CUSTPARTNO))) AND (ISNULL(impt.partMfg,'') = '' OR impt.partMfg IS NULL)
			GROUP BY mster.mfgr_pt_no
	  )AS ManufactCount
	  OUTER APPLY 
	  (
			SELECT DISTINCT TOP 1 mster.mfgr_pt_no,mster.partmfgr
			FROM INVENTOR I 
				INNER JOIN InvtMPNLink mp ON i.UNIQ_KEY = mp.uniq_key
				INNER JOIN MfgrMaster mster ON mp.MfgrMasterId  = mster.MfgrMasterId
			WHERE mster.mfgr_pt_no = TRIM(impt.mpn) AND (I.UNIQ_KEY =  c.UNIQ_KEY OR  (TRIM(PART_NO) = TRIM(c.partno)   
				 AND TRIM(REVISION) = TRIM(c.rev) AND TRIM(c.custPartNo) = TRIM(CUSTPARTNO))) AND (ISNULL(impt.partMfg,'') = '' OR impt.partMfg IS NULL)
	  )AS Manufact
	  OUTER APPLY
	  (
		SELECT TOP 1 mfgr_pt_no
 		FROM  INVTMFGR im
 			 INNER JOIN  InvtMPNLink mpn ON mpn.uniq_key = im.UNIQ_KEY AND im.UNIQMFGRHD = mpn.uniqmfgrhd AND im.IS_DELETED = 0 AND im.INSTORE = 0				  
 			 INNER JOIN  MfgrMaster mfM  ON mfM.MfgrMasterId = mpn.MfgrMasterId  AND mfM.IS_DELETED = 0  
 			 INNER JOIN  WAREHOUS wa ON im.UNIQWH = wa.UNIQWH 
			 INNER JOIN invtlot il on im.W_key = il.W_KEY
			 WHERE im.uniq_key = c.UNIQ_KEY 
				AND LOTCODE = l.LOTCODE 
				AND (CASE WHEN l.ExpDate IS NOT NUll OR l.ExpDate <>'' 
							THEN CAST(l.ExpDate AS DATETIME) 
							ELSE ISNULL(l.ExpDate,'') END = ISNULL(il.ExpDate,'') OR (1=1 AND (l.ExpDate = ''OR l.ExpDate IS NULL)))
				AND (ISNULL(l.DateCode,'') = IL.REFERENCE OR (1=1 AND (l.DateCode = '' OR l.DateCode IS NULL)))
				AND (ISNULL(l.PoNum,'') = IL.PONUM OR (1=1 AND (l.PoNum = ''OR l.PoNum IS NULL)))
				AND partmfgr = impt.partMfg
			Group by mfgr_pt_no
	  )AS lotManufact
	  OUTER APPLY
	  (
			SELECT DISTINCT TOP 1 WAREHOUSE,LOCATION
 			FROM INVTMFGR im
 				 INNER JOIN  InvtMPNLink mpn ON mpn.uniq_key = im.UNIQ_KEY AND im.UNIQMFGRHD = mpn.uniqmfgrhd AND im.IS_DELETED = 0
 				 INNER JOIN  MfgrMaster mfM  ON mfM.MfgrMasterId = mpn.MfgrMasterId  AND mfM.IS_DELETED = 0  
 				 INNER JOIN  WAREHOUS wa ON im.UNIQWH = wa.UNIQWH 
 			WHERE mfgr_pt_no = impt.mpn AND (mfM.partmfgr = impt.partMfg OR Manufact.partmfgr = impt.partMfg) AND wa.WAREHOUSE = @Warehouse
	  )AS ware
	  OUTER APPLY
	  (
		SELECT TOP 1 WAREHOUSE,LOCATION
 		FROM  INVTMFGR im
 			 INNER JOIN  InvtMPNLink mpn ON mpn.uniq_key = im.UNIQ_KEY AND im.UNIQMFGRHD = mpn.uniqmfgrhd AND im.IS_DELETED = 0 AND im.INSTORE = 0				  
 			 INNER JOIN  MfgrMaster mfM  ON mfM.MfgrMasterId = mpn.MfgrMasterId  AND mfM.IS_DELETED = 0  
 			 INNER JOIN  WAREHOUS wa ON im.UNIQWH = wa.UNIQWH 
			 LEFT JOIN invtlot il on im.W_key = il.W_KEY
			 WHERE im.uniq_key = c.UNIQ_KEY 
				AND LOTCODE = l.LOTCODE 
				AND (CASE WHEN l.ExpDate IS NOT NUll OR l.ExpDate <>'' 
							THEN CAST(l.ExpDate AS DATETIME) 
							ELSE ISNULL(l.ExpDate,'') END = ISNULL(il.ExpDate,'') OR (1=1 AND (l.ExpDate = ''OR l.ExpDate IS NULL)))
				AND (ISNULL(l.DateCode,'') = IL.REFERENCE OR (1=1 AND (l.DateCode = '' OR l.DateCode IS NULL)))
				AND (ISNULL(l.PoNum,'') = IL.PONUM OR (1=1 AND (l.PoNum = ''OR l.PoNum IS NULL)))
				AND (mfgr_pt_no = impt.mpn OR mfgr_pt_no = '' OR mfgr_pt_no = Manufact.mfgr_pt_no OR mfgr_pt_no = lotManufact.mfgr_pt_no)
				AND partmfgr = CASE WHEN  ISNULL(impt.partMfg,'') = '' OR impt.partMfg IS NULL THEN Manufact.PartMfgr ELSE impt.partMfg END
			Group by wa.WAREHOUSE,LOCATION
	  )AS warehouse
	  OUTER APPLY 
	  (
			SELECT COUNT(I.UNIQ_KEY) AS Mfgrcount
			FROM INVENTOR I 
				INNER JOIN InvtMPNLink mp ON i.UNIQ_KEY = mp.uniq_key
				INNER JOIN MfgrMaster mster ON mp.MfgrMasterId  = mster.MfgrMasterId
			WHERE I.UNIQ_KEY =  c.UNIQ_KEY 
			group by I.UNIQ_KEY
	  )mfgrCnt
	  OUTER APPLY 
	  (
			SELECT TOP 1 mster.PartMfgr,mster.mfgr_pt_no
			FROM INVENTOR I 
				INNER JOIN InvtMPNLink mp ON i.UNIQ_KEY = mp.uniq_key
				INNER JOIN MfgrMaster mster ON mp.MfgrMasterId  = mster.MfgrMasterId
			WHERE I.UNIQ_KEY = c.UNIQ_KEY 
			ORDER BY mp.orderpref
	  )mfgrData
	  OUTER APPLY
	  (
			SELECT DISTINCT TOP 1 WAREHOUSE,LOCATION
 			FROM INVTMFGR im
 				 INNER JOIN  InvtMPNLink mpn ON mpn.uniq_key = im.UNIQ_KEY AND im.UNIQMFGRHD = mpn.uniqmfgrhd AND im.IS_DELETED = 0
 				 INNER JOIN  MfgrMaster mfM  ON mfM.MfgrMasterId = mpn.MfgrMasterId  AND mfM.IS_DELETED = 0  
 				 INNER JOIN  WAREHOUS wa ON im.UNIQWH = wa.UNIQWH 
 			WHERE mfgr_pt_no = mfgrData.mfgr_pt_no AND mfM.partmfgr = mfgrData.PartMfgr AND im.UNIQ_KEY = c.UNIQ_KEY 
	  )AS manuWarehouse
	  OUTER APPLY
	  (
			SELECT im.UNIQ_KEY,im.UNIQMFGRHD,LOCATION,W.WAREHOUSE,mst.PartMfgr,mst.mfgr_pt_no,il.LOTCODE,il.EXPDATE,il.REFERENCE,il.PONUM
			FROM IPKEY ip 
			JOIN INVTMFGR im ON  ip.W_KEY = im.W_KEY AND ip.UNIQ_KEY = im.UNIQ_KEY
			JOIN InvtMPNLink mpn ON im.UNIQMFGRHD = mpn.uniqmfgrhd
			JOIN MfgrMaster mst ON mpn.MfgrMasterId = mst.MfgrMasterId
			JOIN WAREHOUS W ON W.UNIQWH = im.UNIQWH
			LEFT JOIN INVTLOT il ON il.W_KEY = ip.W_KEY
			WHERE IPKEYUNIQUE = TRIM(mt.MTC)
	  ) AS Ipkey


--Update the lot details using  MTC if lot details not entered in sheet and MTC is given
 UPDATE lt 
 SET [Adjusted] = 
  CASE WHEN c.IsLotted = 1 AND c.useipkey = 1 THEN 
	CASE WHEN ifd.FieldName = 'LotCode' THEN   
				CASE WHEN (ISNULL(l.LotCode,'') = '' AND Ipkey.LOTCODE IS NOT NULL) THEN Ipkey.LOTCODE
				ELSE  lt.Adjusted END	

		  WHEN ifd.FieldName = 'ExpDate' THEN   
				CASE WHEN (ISNULL(l.ExpDate,'') = '' AND Ipkey.EXPDATE IS NOT NULL) THEN CONVERT(VARCHAR(20),Ipkey.EXPDATE,120)
				ELSE  lt.Adjusted END	

		  WHEN ifd.FieldName = 'DateCode' THEN   
				CASE WHEN (ISNULL(l.DateCode,'') = '' AND Ipkey.REFERENCE IS NOT NULL) THEN Ipkey.REFERENCE
				ELSE  lt.Adjusted END	

		  WHEN ifd.FieldName = 'PoNum' THEN   
				CASE WHEN (ISNULL(l.PoNum,'') = '' AND Ipkey.PONUM IS NOT NULL) THEN Ipkey.PONUM
				ELSE  lt.Adjusted END	
	ELSE lt.Adjusted END	
  ELSE lt.Adjusted END	

 ,[Original] = 
  CASE WHEN c.IsLotted = 1 AND c.useipkey = 1 THEN 
	CASE WHEN ifd.FieldName = 'LotCode' THEN   
				CASE WHEN (ISNULL(l.LotCode,'') = '' AND Ipkey.LOTCODE IS NOT NULL) THEN Ipkey.LOTCODE
				ELSE  lt.Original END	

		  WHEN ifd.FieldName = 'ExpDate' THEN   
				CASE WHEN (ISNULL(l.ExpDate,'') = '' AND Ipkey.EXPDATE IS NOT NULL) THEN CONVERT(VARCHAR(20),Ipkey.EXPDATE,120)
				ELSE  lt.Original END	

		  WHEN ifd.FieldName = 'DateCode' THEN   
				CASE WHEN (ISNULL(l.DateCode,'') = '' AND Ipkey.REFERENCE IS NOT NULL) THEN Ipkey.REFERENCE
				ELSE  lt.Original END	

		  WHEN ifd.FieldName = 'PoNum' THEN   
				CASE WHEN (ISNULL(l.PoNum,'') = '' AND Ipkey.PONUM IS NOT NULL) THEN Ipkey.PONUM
				ELSE  lt.Original END	
	ELSE lt.Original END	
  ELSE lt.Original END	
 --select mt.MTC,Ipkey.*
  FROM ImportBOMToKitLot lt 
	  INNER JOIN ImportFieldDefinitions ifd  ON lt.FKFieldDefId =ifd.FieldDefId AND ModuleId = @ModuleId
	  INNER JOIN @ImportDetail impt ON lt.FKAvlRowId = impt.AvlRowId
	  INNER JOIN @ComoponentsDetail c ON impt.CompRowId = c.CompRowId
	  INNER JOIN @LotDetail l ON lt.LotRowId = l.LotRowId
	  LEFT JOIN @MTCImportDetail mt ON mt.LotRowId = lt.LotRowId
	  OUTER APPLY
	  (
			SELECT TOP 1 im.UNIQ_KEY,im.UNIQMFGRHD,LOCATION,W.WAREHOUSE,mst.PartMfgr,mst.mfgr_pt_no,il.LOTCODE,il.EXPDATE,il.REFERENCE,il.PONUM
			FROM IPKEY ip 
			JOIN INVTMFGR im ON  ip.W_KEY = im.W_KEY AND ip.UNIQ_KEY = im.UNIQ_KEY
			JOIN InvtMPNLink mpn ON im.UNIQMFGRHD = mpn.uniqmfgrhd
			JOIN MfgrMaster mst ON mpn.MfgrMasterId = mst.MfgrMasterId
			JOIN WAREHOUS W ON W.UNIQWH = im.UNIQWH
			LEFT JOIN INVTLOT il ON il.W_KEY = ip.W_KEY
				AND COALESCE(IL.LOTCODE,IP.LOTCODE)= IP.LOTCODE
	       		AND ISNULL(IL.REFERENCE,IP.REFERENCE)= IP.REFERENCE
	       		AND ISNULL(IL.PONUM,IP.PONUM)= IP.PONUM
	       		AND 1 =(CASE WHEN IL.LOTCODE IS NULL OR IL.LOTCODE= '' THEN 1 
	       					 WHEN IL.EXPDATE IS NULL OR IL.EXPDATE= '' AND IP.EXPDATE IS NULL OR IP.EXPDATE = '' THEN 1 
	       					 WHEN IL.EXPDATE = IP.EXPDATE THEN 1 ELSE 0 END)
			WHERE IPKEYUNIQUE = TRIM(mt.MTC)
	  ) AS Ipkey
END