-- ============================================================================================================    
-- Date   : 09/27/2019    
-- Author  : Mahesh B   
-- Description : Used for Get Validated SODetail data  
-- GetValidatedSODetailData   'F2CA3AE7-496B-47A3-AA65-89471A3316C5'  
-- ============================================================================================================    
CREATE PROC GetValidatedSODetailData    
 @ImportId UNIQUEIDENTIFIER  
AS    
BEGIN   
;WITH Data AS(        
  SELECT PVT.importId,PVT.RowId,PVT.SOMainRowId
  ,TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR, PVT.SONO),10)))) AS SONO  
  ,PVT.Attention_Name,PVT.Part_No,PVT.Revision  
  ,TRIM((TRIM(RIGHT('0000000'+ CONVERT(VARCHAR, PVT.Line_No),7))))  AS Line_No,PVT.Sodet_Desc,  
   PVT.Part_MFGR,PVT.MFGR_Part_No,PVT.Warehouse,PVT.Note,PVT.Location,PVT.FirstName,PVT.LastName  
  FROM      
  (  SELECT so.fkImportId AS importId,ibf.RowId,ibf.SOMainRowId,sub.class AS CssClass,sub.Validation,fd.fieldName,ibf.Adjusted  
  FROM ImportFieldDefinitions fd        
     INNER JOIN ImportSODetailFields ibf ON fd.FieldDefId = ibf.FKFieldDefId   
  INNER JOIN ImportSOMainFields so ON so.RowId=ibf.SOMainRowId  
     INNER JOIN ImportSOUploadHeader h ON h.ImportId = so.FkImportId     
  INNER JOIN     
    (     
   SELECT so.fkImportId,fd.RowId,fd.SOMainRowId,MAX(fd.status) AS Class ,MIN(fd.Message) AS Validation    
   FROM ImportSODetailFields fd    
    INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId    
    INNER JOIN ImportSOMainFields so ON so.RowId=fd.SOMainRowId  
   WHERE so.fkImportId =  @ImportId  
    AND FieldName IN ('SONO','Attention_Name','Part_No','Revision','Line_No','Sodet_Desc','Part_MFGR','MFGR_Part_No','Warehouse','Location','Note','FirstName','LastName')   
   GROUP BY so.fkImportId,fd.RowId    ,fd.SOMainRowId
   HAVING MAX(fd.STATUS) <> 'i05red'  
    ) Sub      
   ON so.fkImportid=Sub.FkImportId AND ibf.RowId=Sub.RowId  
   WHERE so.fkImportId =  @ImportId  
  ) st      
  PIVOT (MAX(adjusted) FOR fieldName IN (SONO,Attention_Name,Part_No,Revision,Line_No,Sodet_Desc,Part_MFGR,MFGR_Part_No,Warehouse,[Location],Note,FirstName,LastName)) AS PVT   
)  
SELECT d.*,i.UNIQ_KEY,i.U_OF_MEAS,im.W_KEY,im.UNIQWH,i.DESCRIPT AS [Description],
CASE WHEN attention.CID  IS NULL THEN '' ELSE attention.CID END AS CID
FROM Data d  
 INNER JOIN INVENTOR i ON d.Part_No = i.PART_NO AND d.Revision = i.REVISION  AND PART_SOURC NOT IN ('Phantom','CONSG')
 INNER JOIN  InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY      
 INNER JOIN  MfgrMaster mfM  ON mfM.MfgrMasterId = mpn.MfgrMasterId  AND mfM.IS_DELETED = 0    
 INNER JOIN  INVTMFGR im ON im.UNIQ_KEY =i.UNIQ_KEY AND im.UNIQMFGRHD = mpn.uniqmfgrhd AND  im.IS_DELETED = 0  
 INNER JOIN  WAREHOUS wa ON im.UNIQWH = wa.UNIQWH 
 --INNER JOIN  CCONTACT p ON p.FirstName=d.FirstName AND TRIM(p.LastName)=TRIM(d.LastName)  
  OUTER APPLY(  
      SELECT CID FROM CCONTACT c  
   WHERE (c.FIRSTNAME=CASE WHEN  d.FirstName<>'' AND d.LastName<>'' THEN  d.FirstName  
        WHEN  d.FirstName='' AND d.LastName<>''  THEN d.LastName  
        WHEN  d.FirstName<>'' THEN d.FirstName  
        ELSE '' END   
    OR C.LASTNAME = CASE WHEN  d.FirstName<>'' AND d.LastName<>'' THEN  d.LastName  
        WHEN  d.FirstName<>'' AND d.LastName=''  THEN d.FirstName  
        WHEN  d.LastName<>'' THEN d.LastName  
        ELSE '' END)   
   AND (c.FIRSTNAME= CASE WHEN  d.FirstName<>'' AND d.LastName<>'' THEN  d.FirstName ELSE c.FIRSTNAME END  AND  
     c.LASTNAME = CASE WHEN  d.FirstName<>'' AND d.LastName<>'' THEN  d.LastName ELSE c.LASTNAME END)  
   AND c.TYPE='C'
   -- SELECT CID FROM CCONTACT c
		 --WHERE (c.FIRSTNAME = d.FirstName OR C.LASTNAME =  d.LastName) AND c.CUSTNO = custno AND c.TYPE='C'  
  )attention  
WHERE mfM.PartMfgr = d.Part_MFGR AND mfM.mfgr_pt_no = d.MFGR_Part_No  AND wa.WAREHOUSE = d.Warehouse AND im.LOCATION = ''  
--AND (p.FIRSTNAME=d.FirstName OR p.LASTNAME=d.LastName) AND p.TYPE='S'  
  
END 