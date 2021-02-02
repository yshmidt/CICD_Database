-- ============================================================================================================  
-- Date   : 11/22/2019  
-- Author  : Rajendra K 
-- Description : Used to Update data for inventory adjustment upload 
-- 05/07/2020 Rejandra K :  Change the join left to inner and added condition to update only CompanyName,part_sourc,partmfgr
-- 05/29/2020 Rejandra K :  Added outer apply to auto -populate the Part_No,Revision if not provided for consigned part
-- UpdateInvtFieldsRecords '20D0833F-6F8D-4587-9984-19E9E96AB39B'    
-- ============================================================================================================    
CREATE PROC UpdateInvtFieldsRecords  
 @ImportId UNIQUEIDENTIFIER  
 --@RowId UNIQUEIDENTIFIER =NULL  
AS  
BEGIN  
   
 SET NOCOUNT ON   
  DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName VARCHAR(MAX)
  DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,CssClass VARCHAR(MAX),Validation VARCHAR(MAX), CompanyName VARCHAR(MAX),
							  countQty VARCHAR(MAX),custpartno VARCHAR(MAX),custrev VARCHAR(MAX),ExpDate VARCHAR(MAX),INSTORE VARCHAR(MAX),location VARCHAR(MAX),Lotcode VARCHAR(MAX),
							  mfgr_pt_no VARCHAR(MAX) ,MTC VARCHAR(MAX),part_no VARCHAR(MAX),part_sourc VARCHAR(MAX),partmfgr VARCHAR(MAX),Ponum VARCHAR(MAX),
							  QtyPerPackage VARCHAR(MAX),Reference VARCHAR(MAX),revision VARCHAR(MAX),SERIALITEMS VARCHAR(MAX),warehouse VARCHAR(MAX))   

							   -- Insert statements for procedure here   
SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleDesc = 'MnxM_InventoryAdjustmentUpload' and FilePath = 'InventoryAdjustmentUpload'  
 
SELECT @FieldName = STUFF(    
      (    
		   SELECT  ',[' +  F.FIELDNAME + ']' FROM   
		   ImportFieldDefinitions F      
		   WHERE ModuleId = @ModuleId AND  F.SheetNo = 1
		   ORDER BY F.FIELDNAME   
		   FOR XML PATH('')    
      ),    
      1,1,'')  

 SELECT @SQL = N'    
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
		    WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''   
			AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')  
		    GROUP BY fkImportId,fd.RowId    
	   ) Sub    
   ON iaf.fkImportid=Sub.FkImportId and iaf.RowId=sub.RowId   
   WHERE iaf.fkImportId ='''+ CAST(@importId as CHAR(36))+'''     
  ) st    
   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')   
  ) as PVT'  

  --EXEC sp_executesql @SQL 
  INSERT INTO @ImportDetail EXEC sp_executesql @SQL  

 UPDATE iaf
 SET [Adjusted] = 
		CASE WHEN fd.FieldName = 'part_sourc' THEN  
			   CASE WHEN ISNULL(impt.custpartno,'') <>'' AND ISNULL(impt.custrev,'') <>'' AND impt.part_sourc = '' THEN 'CONSG' 
			        WHEN ISNULL(impt.custpartno,'') = '' AND ISNULL(impt.custrev,'') = '' AND impt.part_sourc = '' THEN InvtInt.PART_SOURC ELSE iaf.Adjusted END

			 WHEN fd.FieldName = 'CompanyName' THEN  
				   CASE WHEN ISNULL(impt.CompanyName,'') = '' AND ISNULL(impt.custpartno,'') <>'' AND ISNULL(impt.custrev,'') <>'' AND InvtCnt.PartCount = 1 THEN Invt.CUSTNAME 
				   		WHEN ISNULL(impt.CompanyName,'') = '' AND ISNULL(impt.custpartno,'') = '' AND ISNULL(impt.custrev,'') = '' AND impt.INSTORE IN ('y','yes','1','true') AND InvtSupCount.SupCnt = 1 THEN InvtSup.SUPNAME
				   ELSE iaf.Adjusted END

	         WHEN fd.FieldName = 'partmfgr' THEN   
				CASE WHEN (ISNULL(impt.partmfgr,'') = '' AND ManufactCount.Mcount IS NOT NULL AND ManufactCount.Mcount = 1 AND Manufact.PartMfgr IS NOT NULL) THEN Manufact.PartMfgr
					ELSE iaf.Adjusted END

	         WHEN fd.FieldName = 'part_no' THEN   -- 05/29/2020 Rejandra K :  Added outer apply to auto -populate the Part_No,Revision if not provided for consigned part
				CASE WHEN (ISNULL(impt.part_no,'') = '' AND CustCount.CustCnt IS NOT NULL AND CustCount.CustCnt = 1 AND (impt.part_sourc = 'CONSG' OR 
													(impt.CompanyName <>'' AND impt.custpartno <>''))
												AND CustPart.PART_NO IS NOT NULL) THEN CustPart.PART_NO
					ELSE iaf.Adjusted END

	         WHEN fd.FieldName = 'revision' THEN   
				CASE WHEN (ISNULL(impt.part_no,'') = '' AND CustCount.CustCnt IS NOT NULL AND CustCount.CustCnt = 1 AND (impt.part_sourc = 'CONSG' OR 
													(impt.CompanyName <>'' AND impt.custpartno <>''))
												AND CustPart.revision IS NOT NULL) THEN CustPart.revision
					ELSE iaf.Adjusted END

		ELSE iaf.Adjusted END

,[Original] = 
		CASE WHEN fd.FieldName = 'part_sourc' THEN  
			   CASE WHEN ISNULL(impt.custpartno,'') <>'' AND ISNULL(impt.custrev,'') <>'' AND impt.part_sourc = '' THEN 'CONSG' 
			        WHEN ISNULL(impt.custpartno,'') = '' AND ISNULL(impt.custrev,'') = '' AND impt.part_sourc = '' THEN InvtInt.PART_SOURC ELSE iaf.Original END

			 WHEN fd.FieldName = 'CompanyName' THEN  
				   CASE WHEN ISNULL(impt.CompanyName,'') = '' AND ISNULL(impt.custpartno,'') <>'' AND ISNULL(impt.custrev,'') <>'' AND InvtCnt.PartCount = 1 THEN Invt.CUSTNAME 
						WHEN ISNULL(impt.CompanyName,'') = '' AND ISNULL(impt.custpartno,'') = '' AND ISNULL(impt.custrev,'') = '' AND impt.INSTORE IN ('y','yes','1','true') AND InvtSupCount.SupCnt = 1 THEN InvtSup.SUPNAME
						ELSE iaf.Original END

	         WHEN fd.FieldName = 'partmfgr' THEN   
				CASE WHEN (ISNULL(impt.partmfgr,'') = '' AND ManufactCount.Mcount IS NOT NULL AND ManufactCount.Mcount = 1 AND Manufact.PartMfgr IS NOT NULL) THEN Manufact.PartMfgr
					ELSE iaf.Original END

	         WHEN fd.FieldName = 'part_no' THEN   -- 05/29/2020 Rejandra K :  Added outer apply to auto -populate the Part_No,Revision if not provided for consigned part
				CASE WHEN (ISNULL(impt.part_no,'') = '' AND CustCount.CustCnt IS NOT NULL AND CustCount.CustCnt = 1 AND (impt.part_sourc = 'CONSG' OR 
													(impt.CompanyName <>'' AND impt.custpartno <>''))
												AND CustPart.PART_NO IS NOT NULL) THEN CustPart.PART_NO
					ELSE iaf.Original END

	         WHEN fd.FieldName = 'revision' THEN   
				CASE WHEN (ISNULL(impt.part_no,'') = '' AND CustCount.CustCnt IS NOT NULL AND CustCount.CustCnt = 1 AND (impt.part_sourc = 'CONSG' OR 
													(impt.CompanyName <>'' AND impt.custpartno <>''))
												AND CustPart.revision IS NOT NULL) THEN CustPart.revision
					ELSE iaf.Original END

		ELSE iaf.Original END

  FROM ImportFieldDefinitions fd      
  INNER JOIN ImportInvtAdjustFields iaf ON fd.FieldDefId = iaf.FKFieldDefId AND UploadType = 'InventoryAdjustmentUpload' 
  INNER JOIN @ImportDetail impt on iaf.RowId = impt.RowId -- 05/07/2020 Rejandra K :  Change the join left to inner and added condition to update only CompanyName,part_sourc,partmfgr
  OUTER APPLY
  (
	    SELECT COUNT(UNIQ_KEY) AS PartCount
		FROM INVENTOR 
		WHERE PART_NO = impt.part_no AND REVISION = impt.revision  AND PART_SOURC = 'CONSG'
		AND CUSTPARTNO = ISNULL(TRIM(impt.custpartno),'')
		AND CUSTREV = ISNULL(TRIM(impt.custrev),'')
  ) AS InvtCnt 
  OUTER APPLY
  (
	    SELECT TOP 1 UNIQ_KEY,PART_NO,I.CUSTNO,CUSTPARTNO,CUSTREV,REVISION,CUSTNAME 
		FROM INVENTOR i JOIN CUSTOMER c ON i.CUSTNO = C.CUSTNO
		WHERE PART_NO = impt.part_no AND REVISION = impt.revision  AND PART_SOURC = 'CONSG'
		AND CUSTPARTNO = ISNULL(TRIM(impt.custpartno),'')
		AND CUSTREV = ISNULL(TRIM(impt.custrev),'')
  ) AS Invt
  OUTER APPLY
  (
	    SELECT TOP 1 UNIQ_KEY,PART_NO,CUSTNO,CUSTPARTNO,CUSTREV,REVISION,CUSTNAME,PART_SOURC 
		FROM INVENTOR 
		WHERE PART_NO = impt.part_no AND REVISION = impt.revision AND CUSTNO = ''
  ) AS InvtInt  
  OUTER APPLY
  ( 
  SELECT Custno FROM CUSTOMER WHERE custname = CASE WHEN ISNULL(impt.CompanyName,'') = '' AND ISNULL(impt.custpartno,'') <>'' 
															AND ISNULL(impt.custrev,'') <>'' AND InvtCnt.PartCount = 1   
						THEN Invt.CUSTNAME ELSE TRIM(impt.CompanyName) END
  ) AS Cust
  OUTER APPLY 
  (
	SELECT COUNT(mster.mfgr_pt_no) AS Mcount,mster.mfgr_pt_no
	FROM INVENTOR I 
		INNER JOIN InvtMPNLink mp ON i.UNIQ_KEY = mp.uniq_key
		INNER JOIN MfgrMaster mster ON mp.MfgrMasterId  = mster.MfgrMasterId
	   WHERE mster.mfgr_pt_no = TRIM(impt.mfgr_pt_no) AND PART_NO = impt.part_no AND REVISION = impt.revision  
	   -- AND PART_SOURC = CASE WHEN ISNULL(impt.custpartno,'') <>'' AND ISNULL(impt.custrev,'') <>'' THEN 'CONSG'  ELSE ISNULL(TRIM(impt.part_sourc),'') END
		AND CUSTNO = CASE WHEN (TRIM(impt.part_sourc) = 'CONSG' OR (ISNULL(impt.custpartno,'') <>'' AND ISNULL(impt.custrev,'') <>'')) 
						  THEN Cust.CUSTNO ELSE '' END 
		AND CUSTPARTNO = CASE WHEN (TRIM(impt.part_sourc) = 'CONSG' OR (ISNULL(impt.custpartno,'') <>'' AND ISNULL(impt.custrev,'') <>''))
						      THEN impt.custpartno ELSE '' END 
		AND CUSTREV = CASE WHEN (TRIM(impt.part_sourc) = 'CONSG' OR (ISNULL(impt.custpartno,'') <>'' AND ISNULL(impt.custrev,'') <>'')) 
						   THEN impt.custrev ELSE '' END 
	GROUP BY mster.mfgr_pt_no
 )AS ManufactCount
 OUTER APPLY 
 (
	SELECT DISTINCT TOP 1 mster.mfgr_pt_no,mster.partmfgr
	FROM INVENTOR I 
		INNER JOIN InvtMPNLink mp ON i.UNIQ_KEY = mp.uniq_key
		INNER JOIN MfgrMaster mster ON mp.MfgrMasterId  = mster.MfgrMasterId
	WHERE mster.mfgr_pt_no = TRIM(impt.mfgr_pt_no) AND PART_NO = impt.part_no AND REVISION = impt.revision 
	  --  AND PART_SOURC = CASE WHEN ISNULL(impt.custpartno,'') <>'' AND ISNULL(impt.custrev,'') <>'' THEN 'CONSG'  ELSE ISNULL(TRIM(impt.part_sourc),'') END
		AND CUSTNO = CASE WHEN (TRIM(impt.part_sourc) = 'CONSG' OR (ISNULL(impt.custpartno,'') <>'' AND ISNULL(impt.custrev,'') <>'')) 
					      THEN Cust.CUSTNO ELSE '' END 
		AND CUSTPARTNO =  CASE WHEN (TRIM(impt.part_sourc) = 'CONSG' OR (ISNULL(impt.custpartno,'') <>'' AND ISNULL(impt.custrev,'') <>'')) 
							   THEN impt.custpartno ELSE '' END 
		AND CUSTREV =  CASE WHEN (TRIM(impt.part_sourc) = 'CONSG' OR (ISNULL(impt.custpartno,'') <>'' AND ISNULL(impt.custrev,'') <>'')) 
		                    THEN impt.custrev ELSE '' END 
  )AS Manufact
  OUTER APPLY
  (
		SELECT COUNT(im.UNIQ_KEY) SupCnt
		FROM INVTMFGR im 
		INNER JOIN INVENTOR i ON i.UNIQ_KEY = im.UNIQ_KEY 
		WHERE PART_NO = impt.part_no AND REVISION = impt.revision AND INSTORE = 1
  ) AS InvtSupCount
  OUTER APPLY
  (
		SELECT SUPNAME
		FROM INVTMFGR im 
		INNER JOIN INVENTOR i ON i.UNIQ_KEY = im.UNIQ_KEY
		INNER JOIN SUPINFO sp ON sp.UNIQSUPNO = im.uniqsupno
		WHERE PART_NO = impt.part_no AND REVISION = impt.revision AND INSTORE = 1
  ) AS InvtSup
  OUTER APPLY-- 05/29/2020 Rejandra K :  Added outer apply to auto -populate the Part_No,Revision if not provided for consigned part
  (
			SELECT COUNT(i.CUSTNO) AS CustCnt FROM INVENTOR i
			JOIN CUSTOMER c ON c.CUSTNO = i.CUSTNO
			WHERE c.CUSTNAME = impt.CompanyName AND CUSTPARTNO = impt.custpartno AND CUSTREV = impt.custrev group by i.CUSTNO,CUSTPARTNO,CUSTREV
  )AS CustCount
  OUTER APPLY
  (
			SELECT TOP 1 PART_NO,REVISION FROM INVENTOR i
			JOIN CUSTOMER c ON c.CUSTNO = i.CUSTNO
			WHERE c.CUSTNAME = impt.CompanyName AND  CUSTPARTNO = impt.custpartno AND CUSTREV = impt.custrev
  )AS CustPart
  WHERE iaf.FkImportId = @importId
  -- 05/07/2020 Rejandra K :  Change the join left to inner and added condition to update only CompanyName,part_sourc,partmfgr
  AND FieldName in ('partmfgr','CompanyName','part_sourc','part_no','revision')
END