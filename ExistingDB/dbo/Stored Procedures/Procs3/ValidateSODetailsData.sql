-- ============================================================================================================    
-- Date   : 09/24/2019    
-- Author  : Mahesh B   
-- Description : Used for Validate SODetails data  
-- ValidateSODetailsData    '657732A5-A308-4C55-9EF3-31BF6A092B52'
-- ============================================================================================================    
    
CREATE PROC ValidateSODetailsData  
 @ImportId UNIQUEIDENTIFIER    
AS    
BEGIN    
     
 SET NOCOUNT ON      
 DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName VARCHAR(MAX),@headerErrs VARCHAR(MAX),@autoSONO BIT    
 DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX))        
    
 DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,SOMainRowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),Validation VARCHAR(100),  
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
   SELECT so.fkImportId AS importId,ibf.RowId,ibf.SOMainRowId,sub.class AS CssClass,sub.Validation,fd.fieldName,ibf.Adjusted  
  FROM ImportFieldDefinitions fd        
     INNER JOIN ImportSODetailFields ibf ON fd.FieldDefId = ibf.FKFieldDefId   
  INNER JOIN ImportSOMainFields so ON so.RowId=ibf.SOMainRowId  
     INNER JOIN ImportSOUploadHeader h ON h.ImportId = so.FkImportId     
  INNER JOIN     
    (     
  SELECT so.fkImportId,fd.RowId,MAX(fd.status) as Class ,MIN(fd.Message) AS Validation    
  FROM ImportSODetailFields fd    
   INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId    
   INNER JOIN ImportSOMainFields so ON so.RowId=fd.SOMainRowId  
  WHERE so.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''     
   AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')    
  GROUP BY so.fkImportId,fd.RowId  
    ) Sub      
   ON so.fkImportid=Sub.FkImportId AND ibf.RowId=sub.RowId     
   WHERE so.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''       
  ) st      
  PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')) AS PVT '    
   
 --print @SQL  
 INSERT INTO @ImportDetail EXEC SP_EXECUTESQL @SQL     
  --select * from @ImportDetail  
   
 UPDATE a    
  SET [Adjusted] =   
  CASE   
   WHEN ifd.FieldName = 'Part_MFGR' THEN     
     CASE WHEN impt.Part_MFGR = '' AND impt.MFGR_Part_No = '' AND ManufactCount.Mcount IS NOT NULL AND ManufactCount.Mcount = 1 THEN Manufact.PartMfgr   
     ELSE a.Original END  
  
   WHEN ifd.FieldName = 'MFGR_Part_No' THEN     
        CASE WHEN impt.Part_MFGR = '' AND impt.MFGR_Part_No = '' AND ManufactCount.Mcount IS NOT NULL AND ManufactCount.Mcount = 1 THEN Manufact.mfgr_pt_no   
     ELSE a.Original END   
  
  ELSE a.Adjusted END  
  
,[Original] =   
  CASE   
   WHEN ifd.FieldName = 'Part_MFGR' THEN     
     CASE WHEN impt.Part_MFGR = '' AND impt.MFGR_Part_No = '' AND ManufactCount.Mcount IS NOT NULL AND ManufactCount.Mcount = 1 THEN Manufact.PartMfgr   
     ELSE a.Adjusted END  
  
   WHEN ifd.FieldName = 'MFGR_Part_No' THEN     
        CASE WHEN impt.Part_MFGR = '' AND impt.MFGR_Part_No = '' AND ManufactCount.Mcount IS NOT NULL AND ManufactCount.Mcount = 1 THEN Manufact.mfgr_pt_no   
     ELSE a.Adjusted END   
  
  ELSE a.Original END  
  FROM ImportSODetailFields a    
  JOIN ImportFieldDefinitions ifd  ON a.FKFieldDefId = ifd.FieldDefId AND UploadType = 'SalesOrderUpload' --and ifd.FieldName='Attention_Name'  
  --JOIN ImportSOMainFields so ON so.RowId = a.SOMainRowId  
  --JOIN ImportSOUploadHeader h  ON so.FkImportId = h.ImportId    
  --JOIN @ImportDetail impt ON impt.importId = so.FkImportId  
  JOIN @ImportDetail impt ON  a.RowId = impt.RowId AND impt.importId = @ImportId 
  OUTER APPLY   
  (  
   SELECT COUNT(mster.mfgr_pt_no) AS Mcount,mster.mfgr_pt_no  
   FROM INVENTOR I   
    INNER JOIN InvtMPNLink mp ON i.UNIQ_KEY = mp.uniq_key  
    INNER JOIN MfgrMaster mster ON mp.MfgrMasterId  = mster.MfgrMasterId  
      WHERE mster.mfgr_pt_no = TRIM(impt.MFGR_Part_No) AND (TRIM(PART_NO) = TRIM(impt.Part_No) AND TRIM(REVISION) = TRIM(impt.Revision)) --AND TRIM(impt.cu) = TRIM(CUSTPARTNO))  
    AND (ISNULL(impt.Part_MFGR,'') = '' OR impt.Part_MFGR IS NULL)  
   GROUP BY mster.mfgr_pt_no  
   )AS ManufactCount  
   OUTER APPLY   
   (  
   SELECT DISTINCT TOP 1 mster.mfgr_pt_no,mster.partmfgr  
   FROM INVENTOR I   
    INNER JOIN InvtMPNLink mp ON i.UNIQ_KEY = mp.uniq_key  
    INNER JOIN MfgrMaster mster ON mp.MfgrMasterId  = mster.MfgrMasterId  
      WHERE mster.mfgr_pt_no = TRIM(impt.MFGR_Part_No) AND (TRIM(PART_NO) = TRIM(impt.Part_No) AND TRIM(REVISION) = TRIM(impt.Revision)) --AND TRIM(impt.cu) = TRIM(CUSTPARTNO))  
      AND (ISNULL(impt.Part_MFGR,'') = '' OR impt.Part_MFGR IS NULL)  
   )AS Manufact  

 UPDATE a    
 SET [Message] =    
 CASE  
  WHEN  ifd.FieldName = 'Part_No' THEN  
   CASE WHEN (ISNULL(a.Adjusted,'') = '') THEN 'Please enter Part No.'  
     ELSE   
     CASE WHEN (ISNULL(InvtPart.Part_No,'') = '')  THEN 'Please enter valid Part No.'  
     ELSE    
      CASE WHEN ((TRIM(a.Adjusted) <> '' OR TRIM(a.Adjusted) IS NOT NULL)  AND   
      TRIM(a.Adjusted) <> TRIM(InvtPart.PART_NO) AND TRIM(impt.Revision) <> TRIM(InvtPart.REVISION)) THEN 'Invalid Part No.'ELSE  '' END   
     END    
    END  
  WHEN  ifd.FieldName = 'Line_No' THEN     
   CASE WHEN  (ISNULL(a.Adjusted,'') = '')   
     THEN 'Please enter Line No.'   
     ELSE   
     CASE WHEN(NOT ISNULL(a.Message,'') = '') THEN a.Message ELSE '' END  
     END  
  
  WHEN ifd.FieldName='Revision' THEN  
   CASE WHEN (a.Adjusted != '' AND a.Adjusted IS NOT NULL)THEN  
    CASE WHEN (InvtPart.REVISION IS NULL) THEN 'Invalid Revision.' ELSE  '' END  
   ELSE '' END  
  
  WHEN ifd.FieldName='Part_MFGR' THEN  
   CASE WHEN ((ISNULL(a.Adjusted,'') = '')) THEN 'Please enter Part_MFGR.'  
    ELSE   
     CASE WHEN (TRIM(InvtPart.PART_SOURC) = 'BUY') THEN   
      CASE WHEN (ISNULL(invt.PartMfgr,'') = '')  THEN 'Please enter valid Part_MFGR.'  
       ELSE        
        CASE WHEN ((TRIM(a.Adjusted) <> TRIM(invt.partmfgr)) AND invt.delManufact = 1) THEN 'Please enter valid non-deleted manufacturer.'    
          WHEN ((TRIM(a.Adjusted) <> TRIM(invt.partmfgr)) OR  invt.partmfgr IS NULL) THEN 'Please enter valid Part MFGR.'  
        ELSE '' END  
       END  
      ELSE '' END  
    END  
    
  WHEN ifd.FieldName='MFGR_Part_No' THEN  
   CASE WHEN (ISNULL(a.Adjusted,'') = '') THEN ''  
    ELSE  
     CASE WHEN (TRIM(InvtPart.PART_SOURC) = 'BUY') THEN   
       CASE WHEN (ISNULL(invt.mfgr_pt_no,'') = '')  THEN 'Please enter valid MFGR_Part_No.'  
        ELSE    
            CASE WHEN ((TRIM(a.Adjusted) <> TRIM(invt.mfgr_pt_no)) AND invt.delManufact = 1) THEN 'Please enter valid non-deleted manufacturer.'   
              WHEN ((TRIM(a.Adjusted) <> TRIM(invt.mfgr_pt_no)) OR  invt.mfgr_pt_no IS NULL) THEN 'Please enter valid manufacturer part number.'  
         ELSE '' END  
           END  
      ELSE '' END  
   END  
  WHEN ifd.FieldName = 'WAREHOUSE' THEN  
   CASE WHEN (TRIM(a.Adjusted)='' OR a.Adjusted IS NULL) THEN 'Please enter warehouse.'  
     ELSE  
      CASE WHEN (TRIM(InvtPart.PART_SOURC) = 'BUY')  
       THEN   
        CASE WHEN (ISNULL(warehoue.WAREHOUSE,'')='') THEN 'Please enter valid WAREHOUSE.'  
      ELSE  
       CASE WHEN TRIM(a.Adjusted) IN  ('WIP', 'WO-WIP', 'MRB')   
         THEN 'Unable to associate warehouse :'+TRIM(a.Adjusted)  
         ELSE   
          CASE WHEN (TRIM(a.Adjusted) != TRIM(warehoue.WAREHOUSE))  
             THEN  'Invalid Warehouse. Please check the warehouse with the Part No.'  
            WHEN ((TRIM(a.Adjusted) <> warehoue.Warehouse) AND warehoue.delWare = 1)   
             THEN 'Please enter valid non-deleted Warehouse.'   
          ELSE'' END  
         END  
      END  
   ELSE ''END  
   END  
   
  WHEN ifd.FieldName = 'Location' THEN  
   CASE WHEN (TRIM(InvtPart.PART_SOURC) = 'BUY')  
     THEN  
       CASE WHEN (ISNULL(TRIM(impt.Location),'')='')   
        THEN ''  
        ELSE   
         CASE WHEN ((TRIM(impt.Location) <> warehoue.Location) AND invt.delLoc = 1) THEN 'Please enter valid non-deleted Location.'   
           WHEN ((TRIM(impt.Location) <> warehoue.Location) OR warehoue.Location IS NULL) THEN 'Please enter valid Location.'   
         ELSE ''END     
        END  
     ELSE ''END  
  --WHEN ifd.FieldName = 'FirstName' AND (impt.FirstName<>'' OR impt.LastName<>'') THEN  
  -- CASE WHEN (attention.attentionCount>2)  
  --   THEN 'Multiple Attention Names Found.'  
  --   ELSE   
  --    CASE WHEN (attention.attentionCount='')  
  --      THEN 'Attention Name Not Found. In combination of FirstName or LastName.'  
  --      ELSE ''END  
  --   END  
  
  --WHEN ifd.FieldName = 'LastName' AND (impt.FirstName<>'' OR impt.LastName<>'') THEN  
  -- CASE WHEN (attention.attentionCount>2)  
  --  THEN 'Multiple Attention Names Found.'  
  --  ELSE   
  --   CASE WHEN (attention.attentionCount='')  
  --     THEN 'Attention Name Not Found. In combination of FirstName or LastName.'  
  --     ELSE ''END  
  --  END  
  WHEN ifd.FieldName = 'Attention_Name' THEN  
   CASE WHEN (attention.attentionCount>2)  
     THEN 'Multiple Attention Names Found.'  
     ELSE   
      CASE WHEN (attention.attentionCount=0  AND (impt.FirstName<>'' OR impt.LastName<>''))  
        THEN 'Attention Name Not Found. In combination of FirstName or LastName.'  
        ELSE ''END  
     END  
ELSE   
 CASE WHEN(NOT ISNULL(a.Message,'') = '') THEN a.Message ELSE '' END  
END   
    
 ,[Status] =     
 CASE         
  WHEN  ifd.FieldName = 'Part_No' THEN  
   CASE WHEN (ISNULL(a.Adjusted,'') = '') THEN 'i05red'  
     ELSE   
     CASE WHEN (ISNULL(InvtPart.Part_No,'') = '')  THEN 'i05red'  
     ELSE    
      CASE WHEN ((TRIM(a.Adjusted) <> '' OR TRIM(a.Adjusted) IS NOT NULL)  AND   
      TRIM(a.Adjusted) <> TRIM(InvtPart.PART_NO) AND TRIM(impt.Revision) <> TRIM(InvtPart.REVISION)) THEN 'i05red'ELSE  '' END   
     END    
    END  
  
  WHEN  ifd.FieldName = 'Line_No' THEN     
   CASE WHEN  (ISNULL(a.Adjusted,'') = '')  
     THEN 'i05red'   
     ELSE    
     CASE WHEN(NOT ISNULL(a.Status,'') = '') THEN a.Status ELSE '' END  
     END    
  
  WHEN ifd.FieldName='Revision' THEN  
   CASE WHEN (a.Adjusted != '' AND a.Adjusted IS NOT NULL)THEN  
    CASE WHEN (InvtPart.REVISION IS NULL) THEN 'i05red' ELSE  '' END  
   ELSE '' END  
  
  WHEN ifd.FieldName='Part_MFGR' THEN  
   CASE WHEN ((ISNULL(a.Adjusted,'') = '')) THEN 'i05red'  
    ELSE   
     CASE WHEN (TRIM(InvtPart.PART_SOURC) = 'BUY') THEN   
      CASE WHEN (ISNULL(invt.PartMfgr,'') = '')  THEN 'i05red'  
       ELSE        
        CASE WHEN ((TRIM(impt.Part_MFGR) <> invt.partmfgr) AND invt.delManufact = 1) THEN 'i05red'    
          WHEN ((TRIM(impt.Part_MFGR) <> invt.partmfgr) OR  invt.partmfgr IS NULL) THEN 'i05red'  
        ELSE '' END  
       END  
      ELSE '' END  
    END  
  
  WHEN ifd.FieldName='MFGR_Part_No' THEN  
   CASE WHEN (ISNULL(a.Adjusted,'') = '') THEN ''  
    ELSE  
     CASE WHEN (TRIM(InvtPart.PART_SOURC) = 'BUY') THEN   
      CASE WHEN (ISNULL(invt.mfgr_pt_no,'') = '')  THEN 'i05red'  
        ELSE    
            CASE WHEN ((TRIM(a.Adjusted) <> invt.mfgr_pt_no) AND invt.delManufact = 1) THEN 'i05red'  
           WHEN ((TRIM(a.Adjusted) <> invt.mfgr_pt_no) OR  invt.mfgr_pt_no IS NULL) THEN 'i05red'  
         ELSE '' END  
           END  
      ELSE '' END  
    END  
  
  WHEN ifd.FieldName = 'WAREHOUSE' THEN  
   CASE WHEN (TRIM(a.Adjusted)='' OR a.Adjusted IS NULL) THEN 'i05red'  
     ELSE  
      CASE WHEN (TRIM(InvtPart.PART_SOURC) = 'BUY')  
       THEN   
        CASE WHEN (ISNULL(warehoue.WAREHOUSE,'')='') THEN 'i05red'  
      ELSE  
       CASE WHEN TRIM(a.Adjusted) IN  ('WIP', 'WO-WIP', 'MRB')   
         THEN 'i05red'  
         ELSE   
          CASE WHEN (TRIM(a.Adjusted) != TRIM(warehoue.WAREHOUSE))  
             THEN  'i05red'  
            WHEN ((TRIM(a.Adjusted) <> warehoue.Warehouse) AND warehoue.delWare = 1)   
             THEN 'i05red'   
          ELSE'' END  
         END  
      END  
   ELSE ''END  
  END  
   
  WHEN ifd.FieldName = 'Location' THEN  
   CASE WHEN (TRIM(InvtPart.PART_SOURC) = 'BUY')  
     THEN  
       CASE WHEN (ISNULL(TRIM(impt.Location),'')='')   
        THEN ''  
        ELSE   
         CASE WHEN ((TRIM(impt.Location) <> warehoue.LOCATION) AND invt.delLoc = 1) THEN 'i05red'  
           WHEN ((TRIM(impt.Location) <> warehoue.Location) OR warehoue.Location IS NULL) THEN 'i05red'  
         ELSE ''END     
        END  
     ELSE ''END  
  --WHEN ifd.FieldName = 'FirstName' AND (impt.FirstName<>'' OR impt.LastName<>'') THEN  
  -- CASE WHEN (attention.attentionCount>2)  
  --   THEN 'i05red'  
  --   ELSE   
  --    CASE WHEN (attention.attentionCount=0)  
  --      THEN 'i05red'  
  --      ELSE ''END  
  --   END  
  
  --WHEN ifd.FieldName = 'LastName' AND (impt.FirstName<>'' OR impt.LastName<>'') THEN  
  -- CASE WHEN (attention.attentionCount>2)  
  --   THEN 'i05red'  
  --   ELSE   
  --    CASE WHEN (attention.attentionCount=0)  
  --      THEN 'i05red'  
  --      ELSE ''END  
  --   END  
   WHEN ifd.FieldName = 'Attention_Name' THEN  
   CASE WHEN (attention.attentionCount>2)  
     THEN 'i05red'  
     ELSE   
      CASE WHEN (attention.attentionCount = 0  AND (impt.FirstName<>'' OR impt.LastName<>''))  
        THEN 'i05red'  
        ELSE ''END  
     END  
ELSE   
 CASE WHEN(NOT ISNULL(a.Status,'') = '') THEN a.Status ELSE '' END  
END   
--SELECT invt.*,InvtPart.*,impt.*,custno.CUST_NO,attention.*  
  FROM ImportSODetailFields a    
  JOIN ImportFieldDefinitions ifd  ON a.FKFieldDefId = ifd.FieldDefId AND UploadType = 'SalesOrderUpload' --and ifd.FieldName='Attention_Name'  
  --JOIN ImportSOMainFields so ON so.RowId = a.SOMainRowId  
  --JOIN ImportSOUploadHeader h  ON so.FkImportId = h.ImportId    
  JOIN @ImportDetail impt ON  a.RowId = impt.RowId AND impt.importId = @ImportId
    
  OUTER APPLY(  
        SELECT COUNT(*) attentionCount FROM CCONTACT c  
   WHERE (c.FIRSTNAME=CASE WHEN  impt.FirstName<>'' AND impt.LastName<>'' THEN  impt.FirstName  
        WHEN  impt.FirstName='' AND impt.LastName<>''  THEN impt.LastName  
        WHEN  impt.FirstName<>'' THEN impt.FirstName  
        ELSE '' END   
    OR C.LASTNAME = CASE WHEN  impt.FirstName<>'' AND impt.LastName<>'' THEN  impt.LastName  
        WHEN  impt.FirstName<>'' AND impt.LastName=''  THEN impt.FirstName  
        WHEN  impt.LastName<>'' THEN impt.LastName  
        ELSE '' END)   
   AND (c.FIRSTNAME= CASE WHEN  impt.FirstName<>'' AND impt.LastName<>'' THEN  impt.FirstName ELSE c.FIRSTNAME END  AND  
     c.LASTNAME = CASE WHEN  impt.FirstName<>'' AND impt.LastName<>'' THEN  impt.LastName ELSE c.LASTNAME END)  
   AND c.TYPE='C'  
   --   SELECT COUNT(*) attentionCount FROM CCONTACT c  
   --WHERE (c.FIRSTNAME = impt.FirstName OR C.LASTNAME =  impt.LastName) AND c.CUSTNO = custno AND c.TYPE='C'  
  )attention   
  OUTER APPLY   
  (  
  SELECT TOP 1 UNIQ_KEY,Part_No,REVISION,PART_SOURC FROM INVENTOR WHERE TRIM(PART_NO) = TRIM(impt.Part_No) AND TRIM(REVISION) = TRIM(impt.Revision) AND PART_SOURC NOT IN ('Phantom','CONSG')  
  ) AS InvtPart    OUTER APPLY  
  (  
   SELECt TOP 1   
   mster.PartMfgr,mster.mfgr_pt_no,mp.is_deleted AS delManufact,im.IS_DELETED AS delLoc,im.UNIQMFGRHD  
   FROM INVENTOR I   
    JOIN InvtMPNLink mp ON i.UNIQ_KEY = mp.uniq_key  
    JOIN MfgrMaster mster ON mp.MfgrMasterId  = mster.MfgrMasterId  
    JOIN INVTMFGR im ON i.UNIQ_KEY = im.UNIQ_KEY and mp.uniqmfgrhd =im.UNIQMFGRHD  
   WHERE mster.PartMfgr = TRIM(impt.Part_MFGR) AND mster.mfgr_pt_no = TRIM(impt.MFGR_Part_No) AND  i.UNIQ_KEY = InvtPart.UNIQ_KEY   
  )invt  
  OUTER APPLY  
  (  
  SELECt TOP 1 im.LOCATION,w.WAREHOUSE,w.IS_DELETED AS delWare,im.IS_DELETED AS delLoc  
  FROM INVENTOR I   
   JOIN InvtMPNLink mp ON i.UNIQ_KEY = mp.uniq_key  
   JOIN MfgrMaster mster ON mp.MfgrMasterId  = mster.MfgrMasterId  
   JOIN INVTMFGR im ON i.UNIQ_KEY = im.UNIQ_KEY and mp.uniqmfgrhd =im.UNIQMFGRHD  
   JOIN WAREHOUS w ON im.UNIQWH = w.UNIQWH  
  WHERE invt.UNIQMFGRHD = im.UNIQMFGRHD AND InvtPart.UNIQ_KEY = i.UNIQ_KEY  
    AND (w.WAREHOUSE IS NULL OR w.WAREHOUSE = TRIM(impt.Warehouse)) AND (im.LOCATION = TRIM(impt.Location)) AND im.IS_DELETED = 0  
  )warehoue  
  
  OUTER APPLY(  
  SELECT sm.Adjusted AS CUST_NO FROM ImportSOMainFields sm   
  JOIN ImportFieldDefinitions fd ON fd.FieldDefId=sm.FKFieldDefId  
  WHERE sm.RowId= impt.SOMainRowId AND fd.FieldName='CUSTNO'  
  )custno  
   
-- Check length of string entered by user in template  
 BEGIN TRY -- inside begin try        
   UPDATE a        
  SET a.[message]='Field will be truncated to ' + CAST(f.fieldLength AS VARCHAR(50)) + ' characters.',[status]='i05red'   
  FROM ImportSODetailFields a     
    INNER JOIN ImportFieldDefinitions f  ON a.FKFieldDefId =f.FieldDefId AND ModuleId = @ModuleId AND f.fieldLength > 0        
    INNER JOIN ImportSOMainFields so ON so.RowId=a.SOMainRowId
  WHERE so.fkImportId = @ImportId AND LEN(a.adjusted)>f.fieldLength          
  END TRY        
  BEGIN CATCH         
   INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)        
   SELECT        
    ERROR_NUMBER() AS ErrorNumber        
    ,ERROR_SEVERITY() AS ErrorSeverity        
    ,ERROR_PROCEDURE() AS ErrorProcedure        
    ,ERROR_LINE() AS ErrorLine        
    ,ERROR_MESSAGE() AS ErrorMessage;        
   SET @headerErrs = 'There are issues in the fields to be truncated.'        
  END CATCH       
END  