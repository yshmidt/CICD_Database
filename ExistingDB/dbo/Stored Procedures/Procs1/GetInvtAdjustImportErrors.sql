
-- =====================================================================================  
-- Author		: Rajendra K
-- Date			: 12/06/2019
-- Description  : This SP is used for Get the inventory adjustment upload Error
-- EXEC GetInvtAdjustImportErrors '97F5ED20-7497-49CF-9DA4-8E2CAD8913B4'  
-- =====================================================================================  
CREATE PROC GetInvtAdjustImportErrors  
 @ImportId UNIQUEIDENTIFIER
 
 AS
BEGIN      
 SET NOCOUNT ON  

  DECLARE @SQL NVARCHAR(MAX),@SQLSer NVARCHAR(MAX),@ModuleId INT,@FieldName VARCHAR(MAX),@SerFieldName VARCHAR(MAX)
  DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER, CompanyName VARCHAR(MAX),
							  countQty VARCHAR(MAX),custpartno VARCHAR(MAX),custrev VARCHAR(MAX),ExpDate VARCHAR(MAX),INSTORE VARCHAR(MAX),location VARCHAR(MAX),Lotcode VARCHAR(MAX),
							  mfgr_pt_no VARCHAR(MAX) ,MTC VARCHAR(MAX),part_no VARCHAR(MAX),part_sourc VARCHAR(MAX),partmfgr VARCHAR(MAX),Ponum VARCHAR(MAX),
							  QtyPerPackage VARCHAR(MAX),Reference VARCHAR(MAX),revision VARCHAR(MAX),SERIALITEMS VARCHAR(MAX),warehouse VARCHAR(MAX))   

 DECLARE @SerImportDetail TABLE (importId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,SerialRowId UNIQUEIDENTIFIER,SERIALITEMS VARCHAR(MAX),Serialno VARCHAR(MAX))  

 SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleDesc = 'MnxM_InventoryAdjustmentUpload' and FilePath = 'InventoryAdjustmentUpload'  
 
 SELECT @FieldName = STUFF(    
       (    
 		   SELECT  ',[' +  F.FIELDNAME + ']' FROM   
 		   ImportFieldDefinitions F      
 		   WHERE ModuleId = @ModuleId AND F.SheetNo = 1
 		   ORDER BY F.FIELDNAME   
 		   FOR XML PATH('')    
       ),    
       1,1,'') 

   SELECT @SerFieldName = STUFF(    
      (    
       SELECT  ',[' +  F.FIELDNAME + ']' FROM   
       ImportFieldDefinitions F      
       WHERE ModuleId = @ModuleId  AND F.SheetNo = 2
       ORDER BY F.FIELDNAME   
       FOR XML PATH('')    
      ),    
      1,1,'')

   SELECT @SQL = N'    
   SELECT PVT.*  
   FROM    
   (   
 		SELECT DISTINCT fd.ImportId AS importId,ic.RowId,ibf.fieldName,ic.Adjusted 
 		FROM ImportInvtAdjustHeader fd  
 			INNER JOIN ImportInvtAdjustFields ic ON fd.ImportId = ic.FkImportId
 			INNER JOIN ImportFieldDefinitions ibf ON ic.FKFieldDefId = ibf.FieldDefId  
 		WHERE fkImportId =  '''+ CAST(@ImportId as CHAR(36))+'''
 			AND FieldName IN  ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+') 
   ) st    
    PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')   
   ) as PVT'  

   print @SQL
    INSERT INTO @ImportDetail EXEC sp_executesql @SQL  
	--SELECT * FROM @ImportDetail

    SELECT @SQLSer = N'    
	SELECT *
	 FROM    
	 (   
		SELECT DISTINCT fd.FkImportId AS importId,fd.RowId,ic.SerialRowId,ibf.fieldName,ic.Adjusted 
		FROM ImportInvtAdjustFields fd  
			INNER JOIN ImportInvtAdjustSerialFields ic ON fd.RowId = ic.FkRowId
			INNER JOIN ImportFieldDefinitions ibf ON ic.FKFieldDefId = ibf.FieldDefId  
		WHERE fkImportId =  '''+ CAST(@ImportId as CHAR(36))+'''
			AND FieldName IN ('+REPLACE(REPLACE(@SerFieldName,'[',''''),']','''')+') 
		) st    
	  PIVOT (MAX(Adjusted) FOR fieldName IN ('+ @SerFieldName +')     
	 ) as PVT'

    INSERT INTO @SerImportDetail EXEC sp_executesql @SQLSer  
	--SELECT * FROM @SerImportDetail

 ;WITH PartImportError AS
	(
	SELECT ibf.fkImportId AS ImportId,ibf.RowId AS RowId,part_no AS PartNumber,'Part' AS ErrorRelatedTo,fd.fieldName,ibf.Adjusted As Value,ibf.Message 
	FROM ImportFieldDefinitions fd      
		INNER JOIN ImportInvtAdjustFields ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId =  @ModuleId 
		INNER JOIN ImportInvtAdjustHeader h ON h.ImportId = ibf.FkImportId   
		INNER JOIN   
		(   
				SELECT fkImportId,RowId 
				FROM ImportInvtAdjustFields fd  
					INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId  
				WHERE fkImportId = CAST(@importId as CHAR(36))
					AND SheetNo = 1 AND ModuleId = @ModuleId 
					AND fd.Status = 'i05red'
				GROUP BY fkImportId,RowId 
				
		) Sub ON ibf.fkImportid=Sub.FkImportId and ibf.RowId=sub.RowId
		INNER JOIN @ImportDetail idt ON  ibf.fkImportid=idt.ImportId and ibf.RowId=idt.RowId 
	WHERE ibf.Status = 'i05red'
   )
   ,SerImportError AS(
	SELECT Sub.fkImportId AS ImportId,Sub.RowId AS RowId,id.part_no AS PartNumber,'Serial' AS ErrorRelatedTo,fd.fieldName,ic.Adjusted As Value,ic.Message 
	FROM ImportFieldDefinitions fd      
		INNER JOIN ImportInvtAdjustSerialFields ic ON fd.FieldDefId = ic.FKFieldDefId
	    INNER JOIN   
	    (   
			SELECT fkImportId,RowId,SerialRowId
			FROM ImportInvtAdjustFields fd  
				INNER JOIN ImportInvtAdjustSerialFields ic ON fd.RowId = ic.FkRowId
				INNER JOIN ImportFieldDefinitions ibf ON ic.FKFieldDefId = ibf.FieldDefId   
	   		WHERE fkImportId =  CAST(@importId as CHAR(36))   
	   			AND SheetNo = 2 AND ModuleId = @ModuleId 
	   			AND ic.Status = 'i05red'
			GROUP BY fkImportId,RowId,SerialRowId 
	   		
	    ) Sub ON ic.SerialRowId = sub.SerialRowId 
	    INNER JOIN @SerImportDetail idt ON  ic.SerialRowId=idt.SerialRowId
		INNER JOIN @ImportDetail id ON idt.RowId=id.RowId
   WHERE ic.Status = 'i05red'
)
,AllError AS(
   SELECT PartNumber,ErrorRelatedTo,fieldName,Value,Message FROM PartImportError
  UNION	 
   SELECT PartNumber,ErrorRelatedTo,fieldName,Value,Message FROM SerImportError
)

SELECT * FROM AllError ORDER BY PartNumber,ErrorRelatedTo  
END