-- =====================================================================================  
-- Author		: Rajendra K
-- Date			: 09/06/2019
-- Description  : This SP is used for Get the BOM to KIT imports Error
-- 10/04/2019 Rajendra K : Changed All the joins
-- 10/04/2019 Rajendra K : Changed the joins in lot error selection
-- 12/16/2019 Rajendra K : Added mpn Column in error selection
-- 12/18/2019 Rajendra K : Added Block to get MTC errors
-- EXEC GetBomToKitImportErrors 'D64FE4B1-64E0-4E2C-BA51-7C28729056E1'  
-- =====================================================================================  
CREATE PROC GetBomToKitImportErrors  
 @ImportId UNIQUEIDENTIFIER
 
 AS
BEGIN      
 SET NOCOUNT ON  

  DECLARE @SQL NVARCHAR(MAX),@ModuleId INT, @CompSQL NVARCHAR(MAX), @AvlsSQL NVARCHAR(MAX), @LotSQL NVARCHAR(MAX), @WoSQL NVARCHAR(MAX), @RefDesgSQL NVARCHAR(MAX)
			,@MTCSQL NVARCHAR(MAX);
  DECLARE @FieldName NVARCHAR(MAX), @CompFieldName NVARCHAR(MAX), @AvlsFieldName NVARCHAR(MAX),@LotFieldName NVARCHAR(MAX),@WoFieldName NVARCHAR(MAX),
			@RefDesgFieldName NVARCHAR(MAX),@MTCFieldName NVARCHAR(MAX);

  DECLARE @ImportDetail TABLE (
  		importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,assyDesc VARCHAR(MAX),assyNum VARCHAR(MAX),
  		assypartclass VARCHAR(MAX),assyparttype VARCHAR(MAX),assyRev VARCHAR(MAX),custno VARCHAR(MAX)
  ) 
  
  DECLARE @CompImportDetail TABLE 
  (
  		importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER,bomNote VARCHAR(MAX),crev VARCHAR(MAX),custPartNo VARCHAR(MAX)
  		,itemno VARCHAR(MAX),partno VARCHAR(MAX),partSource VARCHAR(MAX),qty VARCHAR(MAX),rev VARCHAR(MAX) ,used VARCHAR(MAX),workCenter VARCHAR(MAX)
  )    
  
  DECLARE @AvlImportDetail TABLE 
  (
  		importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER,AvlRowId UNIQUEIDENTIFIER,
  		Location VARCHAR(MAX),mpn VARCHAR(MAX),partMfg VARCHAR(MAX),ResQty VARCHAR(MAX),Warehouse VARCHAR(MAX)
  ) 
  
  DECLARE @LotImportDetail TABLE 
  (
  		importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER,AvlRowId UNIQUEIDENTIFIER,LotRowId UNIQUEIDENTIFIER,
		DateCode VARCHAR(MAX),ExpDate VARCHAR(MAX),LotCode VARCHAR(MAX),PoNum VARCHAR(MAX),ResQty VARCHAR(MAX)
  ) 
  
  DECLARE @WOImportDetail TABLE 
  (
		importId UNIQUEIDENTIFIER,WORowId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,bldqty VARCHAR(MAX),Due_date VARCHAR(MAX),End_date VARCHAR(MAX),
		JobType VARCHAR(MAX),kitDefWarehouse VARCHAR(MAX),Line_no VARCHAR(MAX),OrderDate VARCHAR(MAX),PRJNUMBER VARCHAR(MAX),PRJUNIQUE	VARCHAR(MAX),
		RoutingName VARCHAR(MAX),SONO VARCHAR(MAX),Start_date VARCHAR(MAX),wono VARCHAR(MAX),Wonote VARCHAR(MAX)
   )	
	
  DECLARE @RefImportDetail TABLE 
  (	
		importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER,RefDesRowId UNIQUEIDENTIFIER, refdesg VARCHAR(MAX)
  ) 	    
  
  DECLARE @MTCImportDetail TABLE 
  (	
		importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER,AvlRowId UNIQUEIDENTIFIER,LotRowId UNIQUEIDENTIFIER 
		,MTCRowId UNIQUEIDENTIFIER,MTC VARCHAR(MAX),ResQty VARCHAR(MAX)
  )     
SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleDesc = 'MnxM_BOMtoKITUpload' and FilePath = 'BOMtoKITUpload'   

 SELECT @FieldName = STUFF(    
      (    
			SELECT  ',[' +  F.FIELDNAME + ']' FROM   
			ImportFieldDefinitions F      
			WHERE UploadType = 'BOMtoKITUpload' AND FieldName in ('custno','assyDesc','assyRev','assyNum','assypartclass','assyparttype')  
			ORDER BY F.FIELDNAME   
			FOR XML PATH('')    
      ),    
      1,1,'')  

 SELECT @CompFieldName = STUFF(    
      (    
			SELECT  ',[' +  F.FIELDNAME + ']' FROM   
			ImportFieldDefinitions F      
			WHERE ModuleId = @ModuleId  AND FieldName IN ('bomNote','crev','custPartNo','itemno','partno','partSource','qty','rev','used','workCenter')  
			ORDER BY F.FIELDNAME   
			FOR XML PATH('')    
      ),    
      1,1,'') 

 SELECT @AvlsFieldName = STUFF(    
      (    
       SELECT  ',[' +  F.FIELDNAME + ']' FROM   
       ImportFieldDefinitions F      
       WHERE ModuleId = @ModuleId  AND FieldName IN ('Location','mpn','partMfg','ResQty','Warehouse')  
       ORDER BY F.FIELDNAME   
       FOR XML PATH('')    
      ),    
      1,1,'')

 SELECT @LotFieldName = STUFF(    
      (    
       SELECT  ',[' +  F.FIELDNAME + ']' FROM   
       ImportFieldDefinitions F      
       WHERE ModuleId = @ModuleId  AND FieldName IN ('DateCode','ExpDate','LotCode','PoNum','ResQty')   
       ORDER BY F.FIELDNAME   
       FOR XML PATH('')    
      ),    
      1,1,'')  
	  
 SELECT @WoFieldName = STUFF(    
      (    
       SELECT  ',[' +  F.FIELDNAME + ']' FROM   
       ImportFieldDefinitions F      
       WHERE ModuleId = @ModuleId  AND FieldName IN ('bldqty','Due_date','End_date','JobType','kitDefWarehouse','Line_no','OrderDate','PRJNUMBER','PRJUNIQUE'
													,'RoutingName','SONO','Start_date','wono','Wonote')  
       ORDER BY F.FIELDNAME   
       FOR XML PATH('')    
      ),    
      1,1,'')  	    

 SELECT @RefDesgFieldName = STUFF(      
      (      
       SELECT  ',[' +  F.FIELDNAME + ']' FROM     
       ImportFieldDefinitions F        
       WHERE ModuleId = @ModuleId  AND FieldName IN ('refdesg')     
       ORDER BY F.FIELDNAME     
       FOR XML PATH('')      
      ),      
      1,1,'')

	  -- 12/18/2019 Rajendra K : Added Block to get MTC errors
 SELECT @MTCFieldName = STUFF(      
      (      
       SELECT  ',[' +  F.FIELDNAME + ']' FROM     
       ImportFieldDefinitions F        
       WHERE ModuleId = @ModuleId  AND FieldName IN ('ResQty','MTC')     
       ORDER BY F.FIELDNAME     
       FOR XML PATH('')      
      ),      
      1,1,'')
	-------------------------------------------------------  Assembly field information -----------------------------------------------------
	-- 10/04/2019 Rajendra K : Changed All the joins
	SELECT @SQL = N'    
	  SELECT PVT.*  
	  FROM    
	  (   
		 SELECT ibf.fkImportId AS importId,ibf.AssemblyRowId,fd.fieldName,adjusted
		 FROM ImportFieldDefinitions fd      
		 INNER JOIN ImportBOMToKitAssemly ibf ON fd.FieldDefId = ibf.FKFieldDefId 
		 INNER JOIN ImportBOMToKitHeader h ON h.ImportId = ibf.FkImportId  
		 INNER JOIN  
			(   
				SELECT fkImportId,AssemblyRowId
				FROM ImportBOMToKitAssemly fd  
					INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId  
				WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''   
					AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')  
				GROUP BY fkImportId,AssemblyRowId  
			) Sub    
		ON ibf.fkImportid=Sub.FkImportId and ibf.AssemblyRowId=sub.AssemblyRowId   
		WHERE ibf.fkImportId ='''+ CAST(@importId as CHAR(36))+'''      
	  ) st    
	   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')  
	  ) as PVT '
	
	--PRINT @SQL
	INSERT INTO @ImportDetail EXEC SP_EXECUTESQL @SQL 
	--SELECT * FROM @ImportDetail

  -------------------------------------------------------  Component field information -----------------------------------------------------
  -- 10/04/2019 Rajendra K : Changed All the joins
	SELECT @CompSQL = N'    
  SELECT PVT.*  
  FROM    
  (   
   SELECT Sub.fkImportId AS importId,Sub.AssemblyRowId,Sub.CompRowId,fd.fieldName,ic.Adjusted 
   FROM ImportFieldDefinitions fd      
	 INNER JOIN ImportBOMToKitComponents ic ON fd.FieldDefId = ic.FKFieldDefId
	 INNER JOIN   
	   (   
			SELECT fkImportId,CompRowId,AssemblyRowId		
			FROM ImportBOMToKitAssemly fd  
				INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
				INNER JOIN ImportFieldDefinitions ibf ON ic.FKFieldDefId = ibf.FieldDefId   
			WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''   
				AND FieldName IN ('+REPLACE(REPLACE(@CompFieldName,'[',''''),']','''')+')  
			GROUP BY fkImportId,CompRowId,AssemblyRowId
	   ) Sub    
   ON ic.CompRowId = sub.CompRowId    
   WHERE Sub.fkImportId ='''+ CAST(@importId as CHAR(36))+'''     
  ) st    
   PIVOT (MAX(Adjusted) FOR fieldName'+ ' IN ('+ @CompFieldName +')   
  ) as PVT 
  ORDER BY [itemno]'

	INSERT INTO @CompImportDetail EXEC SP_EXECUTESQL @CompSQL 

  -------------------------------------------------------  Avl field information -----------------------------------------------------
 -- 10/04/2019 Rajendra K : Changed All the joins
	 SELECT @AvlsSQL = N'    
	 SELECT PVT.*
	 FROM    
	 (   
		SELECT aa.fkImportId AS importId,aa.AssemblyRowId,c.CompRowId,ia.AvlRowId,fd.fieldName,ia.Adjusted 
		   FROM ImportFieldDefinitions fd 
			INNER JOIN ImportBOMToKitAvls ia ON fd.FieldDefId = ia.FKFieldDefId
			INNER JOIN ImportBOMToKitComponents c ON ia.FKCompRowId = c.CompRowId
			INNER JOIN ImportBOMToKitAssemly aa ON c.FKAssemblyRowId = aa.AssemblyRowId
		WHERE fkImportId =  '''+ CAST(@ImportId as CHAR(36))+'''
			AND FieldName IN ('+REPLACE(REPLACE(@AvlsFieldName,'[',''''),']','''')+')  
		) st    
	PIVOT (MAX(Adjusted) FOR fieldName IN ('+ @AvlsFieldName +')       
	) as PVT'

  	INSERT INTO @AvlImportDetail EXEC SP_EXECUTESQL @AvlsSQL 

 -- -------------------------------------------------------  Avl field information -----------------------------------------------------
 -- 10/04/2019 Rajendra K : Changed All the joins
  SELECT @LotSQL = N'    
	SELECT *
	 FROM    
	 (   
		SELECT DISTINCT fd.FkImportId AS importId,fd.AssemblyRowId,ic.CompRowId,ia.AvlRowId,il.LotRowId,ibf.fieldName,il.Adjusted 
		FROM ImportBOMToKitAssemly fd  
			INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
			INNER JOIN ImportBOMToKitAvls ia ON ic.CompRowId = ia.FKCompRowId
			INNER JOIN ImportBOMToKitLot il ON ia.AvlRowId = il.FKAvlRowId
			INNER JOIN ImportFieldDefinitions ibf ON il.FKFieldDefId = ibf.FieldDefId  
		WHERE fkImportId =  '''+ CAST(@ImportId as CHAR(36))+'''
			AND FieldName IN ('+REPLACE(REPLACE(@LotFieldName,'[',''''),']','''')+') 
		) st    
	  PIVOT (MAX(Adjusted) FOR fieldName IN ('+ @LotFieldName +')     
	 ) as PVT'

  INSERT INTO @LotImportDetail EXEC SP_EXECUTESQL @LotSQL 
  --print @LotSQL

-- -- ------------------------------------------------------- Work Order field information -----------------------------------------------------
-- 10/04/2019 Rajendra K : Changed All the joins
  SELECT @WoSQL = N'    
  SELECT PVT.*  
  FROM    
  (   
   SELECT ibf.fkImportId AS importId,ic.WORowId,ibf.AssemblyRowId,fd.fieldName,ic.Adjusted 
   FROM ImportFieldDefinitions fd      
	 INNER JOIN ImportBOMToKitWorkOrder ic ON fd.FieldDefId = ic.FKFieldDefId
     INNER JOIN ImportBOMToKitAssemly ibf ON ic.FKAssemblyRowId = ibf.AssemblyRowId
	 WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+''' 
				AND FieldName IN ('+REPLACE(REPLACE(@WoFieldName,'[',''''),']','''')+') 
	) st    
   PIVOT (MAX(adjusted) FOR fieldName IN ('+ @WoFieldName +')   
  ) as PVT' 
   
  INSERT INTO @WOImportDetail EXEC SP_EXECUTESQL @WoSQL 

-- -- ------------------------------------------------------- Reference Designator field information ------------------------------------------
-- 10/04/2019 Rajendra K : Changed All the joins
   SELECT @RefDesgSQL = N'      
  SELECT PVT.*    
  FROM      
  (     
   SELECT ibf.fkImportId AS importId,ibf.AssemblyRowId,ic.CompRowId,ia.RefDesRowId,fd.fieldName,ia.Adjusted   
   FROM ImportFieldDefinitions fd   
		INNER JOIN ImportBOMToKitRefDesg ia ON fd.FieldDefId = ia.FKFieldDefId       
		INNER JOIN ImportBOMToKitComponents ic ON ia.FKCompRowId = ic.CompRowId  
		INNER JOIN ImportBOMToKitAssemly ibf ON ic.FKAssemblyRowId = ibf.AssemblyRowId  
		INNER JOIN ImportBOMToKitHeader h ON h.ImportId = ibf.FkImportId  
					WHERE fkImportId ='''+ CAST(@ImportId as CHAR(36))+'''   
				 AND FieldName IN ('+REPLACE(REPLACE(@RefDesgFieldName,'[',''''),']','''')+')  
				   ) st      
      PIVOT (MAX(Adjusted) FOR fieldName IN ('+ @RefDesgFieldName +')) 
	  AS PVT' 

    INSERT INTO @RefImportDetail EXEC SP_EXECUTESQL @RefDesgSQL 

 -- -------------------------------------------------------  MCT field information -----------------------------------------------------
 -- 12/18/2019 Rajendra K : Added Block to get MTC errors
  SELECT @MTCSQL = N'    
	SELECT *
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
	 ) as PVT'

  INSERT INTO @MTCImportDetail EXEC SP_EXECUTESQL @MTCSQL 

 --SELECT * from @MTCImportDetail

;WITH assImportError AS(-- 12/16/2019 Rajendra K : Added mpn Column in error selection
	SELECT ibf.fkImportId AS ImportId,ibf.AssemblyRowId AS AssemblyRowId,assyNum AS AssemblyNumber,'' AS PartNumber,'' AS mpn,'Assembly' AS ErrorRelatedTo,fd.fieldName,ibf.Adjusted As Value
	,ibf.Message 
	FROM ImportFieldDefinitions fd      
		INNER JOIN ImportBOMToKitAssemly ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId =  @ModuleId 
		INNER JOIN ImportBOMToKitHeader h ON h.ImportId = ibf.FkImportId   
		INNER JOIN   
		(   
				SELECT fkImportId,AssemblyRowId 
				FROM ImportBOMToKitAssemly fd  
					INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId  
				WHERE fkImportId = @importId    
					AND FieldName IN ('custno','assyDesc','assyRev','assyNum','assypartclass','assyparttype')
					AND fd.Status = 'i05red'
				GROUP BY fkImportId,AssemblyRowId 
				
		) Sub ON ibf.fkImportid=Sub.FkImportId and ibf.AssemblyRowId=sub.AssemblyRowId
		INNER JOIN @ImportDetail idt ON  ibf.fkImportid=idt.ImportId and ibf.AssemblyRowId=idt.AssemblyRowId 
	WHERE ibf.Status = 'i05red'
)
,compImportError AS(
	SELECT ibf.fkImportId AS ImportId,ibf.AssemblyRowId AS AssemblyRowId,id.assyNum AS AssemblyNumber,partno AS PartNumber,'' AS mpn,'PartNumber' AS ErrorRelatedTo,
			fd.fieldName,ic.Adjusted As Value,ic.Message 
	FROM ImportFieldDefinitions fd      
		INNER JOIN ImportBOMToKitComponents ic ON fd.FieldDefId = ic.FKFieldDefId
	    INNER JOIN ImportBOMToKitAssemly ibf ON ic.FKAssemblyRowId = ibf.AssemblyRowId
	    INNER JOIN ImportBOMToKitHeader h ON h.ImportId = ibf.FkImportId   
	    INNER JOIN   
	    (   
			SELECT fkImportId,CompRowId,AssemblyRowId
			FROM ImportBOMToKitAssemly fd  
				INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
				INNER JOIN ImportFieldDefinitions ibf ON ic.FKFieldDefId = ibf.FieldDefId   
	   		WHERE fkImportId = @importId    
	   			AND FieldName IN ('bomNote','crev','custPartNo','itemno','partno','partSource','qty','rev','used','workCenter')
	   			AND ic.Status = 'i05red'
			GROUP BY fkImportId,AssemblyRowId,CompRowId 
	   		
	    ) Sub ON ibf.fkImportid=Sub.FkImportId AND ic.CompRowId = sub.CompRowId 
	    INNER JOIN @CompImportDetail idt ON  ibf.fkImportid=idt.ImportId and ic.CompRowId=idt.CompRowId
		INNER JOIN @ImportDetail id ON idt.AssemblyRowId=id.AssemblyRowId
   WHERE ic.Status = 'i05red'
)
,AvlImportError AS(
	SELECT ibf.fkImportId AS ImportId,ibf.AssemblyRowId AS AssemblyRowId,id.assyNum AS AssemblyNumber,comp.partno AS PartNumber,mpn AS mpn,'Manufactures' AS ErrorRelatedTo,fd.fieldName,ia.Adjusted As Value
			,ia.Message 
	FROM ImportFieldDefinitions fd      
		 INNER JOIN ImportBOMToKitAvls ia ON fd.FieldDefId = ia.FKFieldDefId     
		 INNER JOIN ImportBOMToKitComponents ic ON ia.FKCompRowId = ic.CompRowId
	     INNER JOIN ImportBOMToKitAssemly ibf ON ic.FKAssemblyRowId = ibf.AssemblyRowId
	    INNER JOIN   
	    (   
			SELECT fkImportId,AssemblyRowId,CompRowId,AvlRowId	
			FROM ImportBOMToKitAssemly fd  
				INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
				INNER JOIN ImportBOMToKitAvls ia ON ic.CompRowId = ia.FKCompRowId
				INNER JOIN ImportFieldDefinitions ibf ON ia.FKFieldDefId = ibf.FieldDefId     
	   		WHERE fkImportId = @importId    
	   			AND FieldName IN ('Location','mpn','partMfg','ResQty','Warehouse') 
	   			AND ia.Status = 'i05red'
			GROUP BY fkImportId,AssemblyRowId,CompRowId,AvlRowId 
	   		
	    ) Sub ON ibf.fkImportid=Sub.FkImportId and ia.FKCompRowId = sub.CompRowId AND ia.AvlRowId = sub.AvlRowId
	    INNER JOIN @AvlImportDetail idt ON ibf.fkImportid=idt.ImportId and ia.FKCompRowId=idt.CompRowId AND  ia.AvlRowId=idt.AvlRowId
		INNER JOIN @ImportDetail id ON idt.AssemblyRowId=id.AssemblyRowId
		OUTER APPLY
		(
			SELECT TOP 1 partno FROM @CompImportDetail where idt.CompRowId = CompRowId 
		)comp		
   WHERE ia.Status = 'i05red'
)
,LotImportError AS(
	SELECT Sub.fkImportId AS ImportId,Sub.AssemblyRowId AS AssemblyRowId,id.assyNum AS AssemblyNumber,comp.partno AS PartNumber,'' AS mpn,'Lot' AS ErrorRelatedTo,fd.fieldName,il.Adjusted As Value,il.Message 
	FROM ImportFieldDefinitions fd      
		INNER JOIN ImportBOMToKitLot il ON fd.FieldDefId = il.FKFieldDefId   -- 10/04/2019 Rajendra K : Changed the joins in lot error selection
		--INNER JOIN ImportBOMToKitAvls ia ON il.FKAvlRowId = ia.AvlRowId     
		--INNER JOIN ImportBOMToKitComponents ic ON ia.FKCompRowId = ic.CompRowId
		--INNER JOIN ImportBOMToKitAssemly ibf ON ic.FKAssemblyRowId = ibf.AssemblyRowId
		--INNER JOIN ImportBOMToKitHeader h ON h.ImportId = ibf.FkImportId  
	    INNER JOIN   
	    (   
			SELECT fkImportId,AssemblyRowId,CompRowId,AvlRowId,LotRowId		
			FROM ImportBOMToKitAssemly fd  
				INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
				INNER JOIN ImportBOMToKitAvls ia ON ic.CompRowId = ia.FKCompRowId
				INNER JOIN ImportBOMToKitLot il ON ia.AvlRowId = il.FKAvlRowId
				INNER JOIN ImportFieldDefinitions ibf ON il.FKFieldDefId = ibf.FieldDefId     
	   		WHERE fkImportId = @importId    
	   			AND FieldName IN ('DateCode','ExpDate','LotCode','PoNum','ResQty')   
	   			AND il.Status = 'i05red'
			GROUP BY fkImportId,AssemblyRowId,CompRowId,AvlRowId,LotRowId
	   		
	    ) Sub ON il.LotRowId = Sub.LotRowId 
		--ibf.fkImportid=Sub.FkImportId and ia.AvlRowId = sub.AvlRowId AND ia.FKCompRowId = sub.CompRowId
	    INNER JOIN @LotImportDetail idt ON il.LotRowId = idt.LotRowId
		INNER JOIN @ImportDetail id ON idt.AssemblyRowId=id.AssemblyRowId
		OUTER APPLY
		(
			SELECT TOP 1 partno FROM @CompImportDetail where idt.CompRowId = CompRowId 
		)comp
   WHERE il.Status = 'i05red'
)-- 12/18/2019 Rajendra K : Added Block to get MTC errors
,MTCImportError AS(
	SELECT Sub.fkImportId AS ImportId,Sub.AssemblyRowId AS AssemblyRowId,id.assyNum AS AssemblyNumber,comp.partno AS PartNumber,mfgr.mpn AS mpn,'MTC' AS ErrorRelatedTo,fd.fieldName,mt.Adjusted As Value,mt.Message 
	FROM ImportFieldDefinitions fd      
		INNER JOIN ImportBOMToKitMTC mt ON fd.FieldDefId = mt.FKFieldDefId  
	    INNER JOIN   
	    (   
			SELECT fkImportId,AssemblyRowId,CompRowId,AvlRowId,LotRowId,MTCRowId		
			FROM ImportBOMToKitAssemly fd  
				INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
				INNER JOIN ImportBOMToKitAvls ia ON ic.CompRowId = ia.FKCompRowId
				LEFT JOIN ImportBOMToKitLot il ON ia.AvlRowId = il.FKAvlRowId
				INNER JOIN ImportBOMToKitMTC mt ON mt.FkLotRowId = il.LotRowId OR mt.FKAvlRowId = ia.AvlRowId
				INNER JOIN ImportFieldDefinitions ibf ON mt.FKFieldDefId = ibf.FieldDefId     
	   		WHERE fkImportId = @importId    
	   			AND FieldName IN ('ResQty','MTC')   
	   			AND mt.Status = 'i05red'
			GROUP BY fkImportId,AssemblyRowId,CompRowId,AvlRowId,LotRowId,MTCRowId
	   		
	    ) Sub ON mt.MTCRowId = Sub.MTCRowId 
	    INNER JOIN @MTCImportDetail idt ON mt.MTCRowId = idt.MTCRowId
		INNER JOIN @ImportDetail id ON idt.AssemblyRowId=id.AssemblyRowId
		OUTER APPLY
		(
			SELECT TOP 1 partno FROM @CompImportDetail where idt.CompRowId = CompRowId 
		)comp
	    OUTER APPLY
		(
			SELECT TOP 1 mpn FROM @AvlImportDetail where idt.AvlRowId = AvlRowId 
		)mfgr
   WHERE mt.Status = 'i05red'
)
,woImportError AS(
	SELECT idt.importId AS ImportId,sub.AssemblyRowId AS AssemblyRowId,id.assyNum AS AssemblyNumber,'' AS PartNumber,'' AS mpn,'Work Order' AS ErrorRelatedTo,fd.fieldName,ic.Adjusted As Value
	,ic.Message 
	FROM ImportFieldDefinitions fd      
		INNER JOIN ImportBOMToKitWorkOrder ic ON fd.FieldDefId = ic.FKFieldDefId
		INNER JOIN   
		(   
				SELECT fkImportId,WORowId,AssemblyRowId	
				FROM ImportBOMToKitAssemly fd  
					INNER JOIN ImportBOMToKitWorkOrder ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
					INNER JOIN ImportFieldDefinitions ibf ON ic.FKFieldDefId = ibf.FieldDefId   
				WHERE fkImportId = @importId 
					AND FieldName IN ('bldqty','Due_date','End_date','JobType','kitDefWarehouse','Line_no','OrderDate','PRJNUMBER','PRJUNIQUE','RELEDATE',
										'RoutingName','SONO','Start_date','wono','Wonote') 
					AND ic.Status = 'i05red'
				GROUP BY fkImportId,AssemblyRowId,WORowId 
				
		) Sub ON ic.WORowId = sub.WORowId AND ic.FKAssemblyRowId = sub.AssemblyRowId 
		INNER JOIN @WOImportDetail idt ON ic.FKAssemblyRowId=idt.AssemblyRowId 
		INNER JOIN @ImportDetail id ON idt.AssemblyRowId=id.AssemblyRowId
	WHERE ic.Status = 'i05red' 
)
,refImportError AS(
	SELECT Sub.FkImportId AS ImportId,Sub.AssemblyRowId AS AssemblyRowId,id.assyNum AS AssemblyNumber,comp.partno AS PartNumber,'' AS mpn,'Reference Designator' AS ErrorRelatedTo,fd.fieldName,
			ic.Adjusted As Value,ic.Message 
	FROM ImportFieldDefinitions fd      
		INNER JOIN ImportBOMToKitRefDesg ic ON fd.FieldDefId = ic.FKFieldDefId
		INNER JOIN   
		(   
				SELECT fkImportId,AssemblyRowId,CompRowId,RefDesRowId
				FROM ImportBOMToKitAssemly fd    
					INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId  
					INNER JOIN ImportBOMToKitRefDesg ia ON ic.CompRowId = ia.FKCompRowId  
					INNER JOIN ImportFieldDefinitions ibf ON ia.FKFieldDefId = ibf.FieldDefId    
				WHERE fkImportId = @importId 
					AND FieldName IN ('refdesg')     
					AND ia.Status = 'i05red'
				GROUP BY fkImportId,AssemblyRowId,CompRowId,RefDesRowId
				
		) Sub ON ic.FKCompRowId = sub.CompRowId AND ic.RefDesRowId = sub.RefDesRowId 
		INNER JOIN @RefImportDetail idt ON ic.FKCompRowId=ic.FKCompRowId
		INNER JOIN @ImportDetail id ON idt.AssemblyRowId=id.AssemblyRowId
		OUTER APPLY
		(
			SELECT TOP 1 partno FROM @CompImportDetail where idt.CompRowId = CompRowId 
		)comp
	WHERE ic.Status = 'i05red'
)

,AllError AS(-- 12/16/2019 Rajendra K : Added mpn Column in error selection
   SELECT AssemblyNumber,PartNumber,mpn,ErrorRelatedTo,fieldName,Value,Message FROM assImportError
  UNION	 
   SELECT AssemblyNumber,PartNumber,mpn,ErrorRelatedTo,fieldName,Value,Message FROM compImportError
  UNION	  
   SELECT AssemblyNumber,PartNumber,mpn,ErrorRelatedTo,fieldName,Value,Message FROM AvlImportError
  UNION	  
   SELECT AssemblyNumber,PartNumber,mpn,ErrorRelatedTo,fieldName,Value,Message FROM LotImportError
  UNION	  
   SELECT AssemblyNumber,PartNumber,mpn,ErrorRelatedTo,fieldName,Value,Message FROM woImportError
  UNION	  
   SELECT AssemblyNumber,PartNumber,mpn,ErrorRelatedTo,fieldName,Value,Message FROM refImportError
 UNION -- 12/18/2019 Rajendra K : Added Block to get MTC errors
   SELECT AssemblyNumber,PartNumber,mpn,ErrorRelatedTo,fieldName,Value,Message FROM MTCImportError
)

SELECT * FROM AllError ORDER BY AssemblyNumber,PartNumber,ErrorRelatedTo
END