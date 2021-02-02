-- ============================================================================================================  
-- Date   : 12/30/2019  
-- Author  : Mahesh B	
-- Description : Used for Auto-Populate SODetails data
-- UpdateSODetailsData    '657732A5-A308-4C55-9EF3-31BF6A092B52'
-- ============================================================================================================  
  
CREATE PROC UpdateSODetailsData
 @ImportId UNIQUEIDENTIFIER  
AS  
BEGIN  
   
 SET NOCOUNT ON    
 DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName VARCHAR(MAX),@headerErrs VARCHAR(MAX)
 DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX))      

 DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,SODetailId UNIQUEIDENTIFIER,CssClass VARCHAR(100),Validation VARCHAR(100),
							 Attention_Name VARCHAR(200), FirstName VARCHAR(100), LastName VARCHAR(100),Line_No VARCHAR(100), Location VARCHAR(100), MFGR_Part_No VARCHAR(100),Part_MFGR VARCHAR(100), 
							 Part_No VARCHAR(100), Revision VARCHAR(100), Sodet_Desc VARCHAR(100),  Warehouse VARCHAR(100))

 -- Insert statements for procedure here   
SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleName = 'Sales' AND FilePath = 'salesPrice' AND Abbreviation='PL'  
 
SELECT @FieldName = STUFF(    
      (    
       SELECT  ',[' +  F.FIELDNAME + ']' FROM   
       ImportFieldDefinitions F      
       WHERE ModuleId = @ModuleId AND FieldName IN ('Attention_Name','Part_No','Revision','Line_No','Sodet_Desc','Part_MFGR','MFGR_Part_No','Warehouse','Location','FirstName','LastName')  
       ORDER BY F.FIELDNAME   
       FOR XML PATH('')    
      ),    
      1,1,'')  
	  
 SELECT @SQL = N'    
  SELECT PVT.*  
  FROM    
  (  
  SELECT so.fkImportId AS importId,ibf.RowId,sub.class AS CssClass,sub.Validation,fd.fieldName,ibf.Adjusted
	 FROM ImportFieldDefinitions fd      
     INNER JOIN ImportSODetailFields ibf ON fd.FieldDefId = ibf.FKFieldDefId 
	 INNER JOIN ImportSOMainFields so ON so.RowId=ibf.SOMainRowId
     INNER JOIN ImportSOUploadHeader h ON h.ImportId = so.FkImportId   
	 INNER JOIN   
	   (   
		SELECT so.fkImportId,so.RowId,MAX(fd.status) as Class ,MIN(fd.Message) AS Validation		
		FROM ImportSODetailFields fd  
			INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId  
			INNER JOIN ImportSOMainFields so ON so.RowId=fd.SOMainRowId
		WHERE so.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''   
			AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')  
		GROUP BY so.fkImportId,so.RowId
	   ) Sub    
   ON so.fkImportid=Sub.FkImportId AND ibf.SOMainRowId=sub.RowId   
   WHERE so.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''     
  ) st    
  PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')) AS PVT '      

 INSERT INTO @ImportDetail EXEC SP_EXECUTESQL @SQL   
  --select * from @ImportDetail
 --INSERT INTO @SOMainDetail EXEC Getsomaindata @importId   
 
 UPDATE a  
  SET [Adjusted] = 
  CASE 
	  WHEN ifd.FieldName = 'Part_MFGR' THEN   
	  		CASE WHEN impt.Part_MFGR = '' AND impt.MFGR_Part_No <> '' AND mfgrCnt.Mcount IS NOT NULL AND mfgrData.PartMfgr IS NOT NULL AND mfgrCnt.Mcount = 1 THEN mfgrData.PartMfgr
			     WHEN impt.Part_MFGR = '' AND impt.MFGR_Part_No = '' AND ManufactCount.Mfgrcount IS NOT NULL AND Manufact.PartMfgr IS NOT NULL AND ManufactCount.Mfgrcount = 1 THEN Manufact.PartMfgr 
				 ELSE a.Adjusted END

	  WHEN ifd.FieldName = 'MFGR_Part_No' THEN   
	  	  	CASE WHEN impt.Part_MFGR = '' AND impt.MFGR_Part_No = '' AND ManufactCount.Mfgrcount IS NOT NULL AND Manufact.mfgr_pt_no IS NOT NULL AND ManufactCount.Mfgrcount = 1 
				 THEN Manufact.mfgr_pt_no 
				 ELSE a.Adjusted END 

	  WHEN ifd.FieldName = 'Warehouse' THEN  
	  	  	 CASE WHEN impt.Part_MFGR = '' AND impt.MFGR_Part_No = '' AND impt.Warehouse = '' AND ManufactCount.Mfgrcount IS NOT NULL AND  manuWarehouse.WAREHOUSE IS NOT NULL AND ManufactCount.Mfgrcount = 1 
				  THEN manuWarehouse.WAREHOUSE 
				  ELSE a.Adjusted END  

	  WHEN ifd.FieldName = 'Location' THEN 
	  	  	 CASE WHEN impt.Part_MFGR = '' AND impt.MFGR_Part_No = '' AND impt.Warehouse = '' AND impt.Location = '' AND ManufactCount.Mfgrcount IS NOT NULL 
						AND manuWarehouse.LOCATION IS NOT NULL AND ManufactCount.Mfgrcount = 1 
				  THEN manuWarehouse.LOCATION
				  ELSE a.Adjusted END  

  ELSE a.Adjusted END

,[Original] = 
  CASE 
	  WHEN ifd.FieldName = 'Part_MFGR' THEN   
	  		CASE WHEN impt.Part_MFGR = '' AND impt.MFGR_Part_No <> '' AND mfgrCnt.Mcount IS NOT NULL AND mfgrData.PartMfgr IS NOT NULL AND mfgrCnt.Mcount = 1 THEN mfgrData.PartMfgr
			     WHEN impt.Part_MFGR = '' AND impt.MFGR_Part_No = '' AND ManufactCount.Mfgrcount IS NOT NULL AND Manufact.PartMfgr IS NOT NULL AND ManufactCount.Mfgrcount = 1 THEN Manufact.PartMfgr 
				 ELSE a.Original END

	  WHEN ifd.FieldName = 'MFGR_Part_No' THEN   
	  	  	CASE WHEN impt.Part_MFGR = '' AND impt.MFGR_Part_No = '' AND ManufactCount.Mfgrcount IS NOT NULL AND Manufact.mfgr_pt_no IS NOT NULL AND ManufactCount.Mfgrcount = 1 
				 THEN Manufact.mfgr_pt_no 
				 ELSE a.Original END 

	  WHEN ifd.FieldName = 'Warehouse' THEN  
	  	  	 CASE WHEN impt.Part_MFGR = '' AND impt.MFGR_Part_No = '' AND impt.Warehouse = '' AND ManufactCount.Mfgrcount IS NOT NULL AND  manuWarehouse.WAREHOUSE IS NOT NULL AND ManufactCount.Mfgrcount = 1 
				  THEN manuWarehouse.WAREHOUSE 
				  ELSE a.Original END  

	  WHEN ifd.FieldName = 'Location' THEN 
	  	  	 CASE WHEN impt.Part_MFGR = '' AND impt.MFGR_Part_No = '' AND impt.Warehouse = '' AND impt.Location = '' AND ManufactCount.Mfgrcount IS NOT NULL 
						AND manuWarehouse.LOCATION IS NOT NULL AND ManufactCount.Mfgrcount = 1 
				  THEN manuWarehouse.LOCATION
				  ELSE a.Original END  
  ELSE a.Original END
  FROM ImportSODetailFields a  
	 JOIN ImportFieldDefinitions ifd  ON a.FKFieldDefId = ifd.FieldDefId AND UploadType = 'SalesOrderUpload'
	 --JOIN ImportSOMainFields so ON so.RowId = a.SOMainRowId
	 --JOIN ImportSOUploadHeader h  ON so.FkImportId = h.ImportId  
	 JOIN @ImportDetail impt ON impt.importId = @ImportId
	 OUTER APPLY 
	 (
		SELECT TOP 1 UNIQ_KEY FROM INVENTOR WHERE TRIM(PART_NO) = TRIM(impt.Part_No) AND TRIM(REVISION) = TRIM(impt.Revision) AND PART_SOURC NOT IN ('Phantom','CONSG')
	 ) AS Invt
	 OUTER APPLY 
	 (
			SELECT COUNT(mster.mfgr_pt_no) AS Mcount,mster.mfgr_pt_no
			FROM INVENTOR I 
				INNER JOIN InvtMPNLink mp ON i.UNIQ_KEY = mp.uniq_key
				INNER JOIN MfgrMaster mster ON mp.MfgrMasterId  = mster.MfgrMasterId
		    WHERE mster.mfgr_pt_no = TRIM(impt.MFGR_Part_No) AND I.UNIQ_KEY =  Invt.UNIQ_KEY AND 
				  (ISNULL(impt.Part_MFGR,'') = '' OR impt.Part_MFGR IS NULL)
			GROUP BY mster.mfgr_pt_no
	  )AS mfgrCnt
	  OUTER APPLY 
	  (
			SELECT DISTINCT TOP 1 mster.mfgr_pt_no,mster.partmfgr
			FROM INVENTOR I 
				INNER JOIN InvtMPNLink mp ON i.UNIQ_KEY = mp.uniq_key
				INNER JOIN MfgrMaster mster ON mp.MfgrMasterId  = mster.MfgrMasterId
		    WHERE mster.mfgr_pt_no = TRIM(impt.MFGR_Part_No) AND I.UNIQ_KEY =  Invt.UNIQ_KEY AND 
				  (ISNULL(impt.Part_MFGR,'') = '' OR impt.Part_MFGR IS NULL)
	 )AS mfgrData
	 OUTER APPLY 
	 (
			SELECT COUNT(I.UNIQ_KEY) AS Mfgrcount
			FROM INVENTOR I 
				INNER JOIN InvtMPNLink mp ON i.UNIQ_KEY = mp.uniq_key
				INNER JOIN MfgrMaster mster ON mp.MfgrMasterId  = mster.MfgrMasterId
		    WHERE I.UNIQ_KEY  = invt.UNIQ_KEY
			group by I.UNIQ_KEY
	  )AS ManufactCount
	  OUTER APPLY 
	  (
			SELECT TOP 1 mster.PartMfgr,mster.mfgr_pt_no
			FROM INVENTOR I 
				INNER JOIN InvtMPNLink mp ON i.UNIQ_KEY = mp.uniq_key
				INNER JOIN MfgrMaster mster ON mp.MfgrMasterId  = mster.MfgrMasterId
		    WHERE I.UNIQ_KEY  = invt.UNIQ_KEY
	  )AS Manufact
	  OUTER APPLY
	  (
			SELECT DISTINCT TOP 1 WAREHOUSE,LOCATION
 			FROM INVTMFGR im
 				 INNER JOIN  InvtMPNLink mpn ON mpn.uniq_key = im.UNIQ_KEY AND im.UNIQMFGRHD = mpn.uniqmfgrhd AND im.IS_DELETED = 0
 				 INNER JOIN  MfgrMaster mfM  ON mfM.MfgrMasterId = mpn.MfgrMasterId  AND mfM.IS_DELETED = 0  
 				 INNER JOIN  WAREHOUS wa ON im.UNIQWH = wa.UNIQWH 
 			WHERE mfgr_pt_no = Manufact.mfgr_pt_no AND mfM.partmfgr = Manufact.PartMfgr AND im.UNIQ_KEY  = invt.UNIQ_KEY
	  )AS manuWarehouse
END