-- ============================================================================================================  
-- Date   : 08/26/2019  
-- Author  : Rajendra K 
-- Description : Used for Validate Work order upload data  
-- 09/28/2019 Rajendra K : Update the date into @ImportDetail table 
-- 09/28/2019 Rajendra K : Changed some Validations
-- 10/01/2019 Rajendra K : Update the Adjusted and Originals 
-- 10/14/2019 Rajendra k : Changed Messages
-- 11/21/2019 Rajendra k : Changed Old PRICHEAD table, used new table priceheader,priceCustomer for customer validation
-- EXEC ValidateWorkOrderRecords  '4B680C27-196D-429A-A605-540B22870E6C'    
-- ============================================================================================================  
  
CREATE PROC ValidateWorkOrderRecords  
 @ImportId UNIQUEIDENTIFIER  
 --@RowId UNIQUEIDENTIFIER =NULL  
AS  
BEGIN  
   
 SET NOCOUNT ON    
 DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName VARCHAR(MAX),@headerErrs VARCHAR(MAX),@red VARCHAR(20)='i05red', @IsAutoWO BIT;
 DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX))      
  
 DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,WORowId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER, CssClass VARCHAR(100),Validation VARCHAR(100), bldqty VARCHAR(10),
							  Due_date VARCHAR(100),End_date VARCHAR(100), JobType VARCHAR(100),kitDefWarehouse VARCHAR(100),Line_no VARCHAR(100),OrderDate VARCHAR(100),
							  PRJNUMBER VARCHAR(100),PRJUNIQUE	VARCHAR(100),RoutingName VARCHAR(100),SONO VARCHAR(100),Start_date VARCHAR(100),wono VARCHAR(100),Wonote VARCHAR(100))	
							  
 DECLARE @AssemblyDetail TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),Validation VARCHAR(100),
							  assyDesc VARCHAR(100),assyNum VARCHAR(100),assypartclass VARCHAR(100),
							  assyparttype VARCHAR(100),assyRev VARCHAR(100),custno VARCHAR(100),UNIQ_KEY VARCHAR(10))   							  						  

SELECT @IsAutoWO = CASE WHEN w.settingId IS NOT NULL THEN  w.settingValue ELSE m.settingValue END FROM MnxSettingsManagement m
	LEFT JOIN wmSettingsManagement w on m.settingId = w.settingId
	WHERE settingName = 'AutoWONumber' AND settingDescription = 'AutoGenerateWO'

 -- Insert statements for procedure here    
 SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleDesc = 'MnxM_BOMtoKITUpload' and FilePath = 'BOMtoKITUpload'
 SELECT @FieldName = STUFF(    
      (    
       SELECT  ',[' +  F.FIELDNAME + ']' FROM   
       ImportFieldDefinitions F      
       WHERE ModuleId = @ModuleId  AND FieldName in ('bldqty','Due_date','End_date','JobType','kitDefWarehouse','Line_no','OrderDate','PRJNUMBER','PRJUNIQUE'
						,'RoutingName','SONO','Start_date','wono','Wonote')  
       ORDER BY F.FIELDNAME   
       FOR XML PATH('')    
      ),    
      1,1,'')     
  
 SELECT @SQL = N'    
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
				AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')     
			GROUP BY fkImportId,WORowId,AssemblyRowId 
	   ) Sub    
   ON ibf.fkImportid=Sub.FkImportId and ic.WORowId = sub.WORowId AND ic.FKAssemblyRowId = sub.AssemblyRowId 
   WHERE ibf.fkImportId = '''+ CAST(@importId as CHAR(36))+'''  
  ) st    
   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')   
  ) as PVT '  
   
 --Print @SQL  
 INSERT INTO @ImportDetail EXEC sp_executesql @SQL;
 INSERT INTO @AssemblyDetail EXEC GetAssemblyRecords @ImportId;    
--SELECT * FROM @ImportDetail  
 -- 09/28/2019 Rajendra K : Update the date into @ImportDetail table 
 	-- Populate Detail grid data with value trim, default OrderDate, DueDate and CustName, CustNo
	UPDATE impt 
		SET 
			OrderDate = CASE WHEN TRIM(ISNULL(OrderDate,'')) = '' THEN convert(varchar, GETDATE(), 23) ELSE convert(varchar, OrderDate, 23) END
		   ,Due_date = CASE WHEN LTRIM(impt.Due_date) = '' THEN
							CAST(
								CAST((
										DATEADD(DAY, Inv.PROD_LTIME, 
											CASE WHEN LTRIM(impt.OrderDate) = '' THEN 
													GETDATE() 
												 ELSE 
													CAST(impt.OrderDate AS VARCHAR(50)) 
											END)
									) As date) AS VARCHAR(50)
								)  
						ELSE 
							CAST(impt.Due_date AS VARCHAR(50))  
						END
			,SONO = TRIM(ISNULL(SONO,''))
		FROM @ImportDetail impt 
		INNER JOIN @AssemblyDetail ad ON ad.AssemblyRowId = impt.AssemblyRowId
		LEFT JOIN INVENTOR Inv ON ((ad.UNIQ_KEY <> '' AND ad.UNIQ_KEY = Inv.UNIQ_KEY ) OR (ad.UNIQ_KEY ='' AND 
									ad.assyNum = inv.PART_NO AND TRIM(ad.assyRev) = TRIM(inv.REVISION)))

 UPDATE iw  
  SET [message] =  
  -- 09/28/2019 Rajendra K : Changed some Validations
    --select impt.partno, invt.PART_NO,
    CASE 
			WHEN f.FieldName = 'wono' THEN -- 10/14/2019 Rajendra k : Changed Messages
				CASE WHEN (@IsAutoWO = 0 AND TRIM(ISNULL(impt.WONO,'')) = '') THEN 'Please enter WONO.'
					 WHEN (@IsAutoWO = 0 AND NoAutoWOGen.WONO IS NOT NULL) THEN 'Entered WONO already exists.'
				ELSE '' END 

   			WHEN f.FieldName = 'JobType' THEN 
   				CASE WHEN  (impt.JobType = JobTImpt.JobType) THEN '' 
   				ELSE  'Enter valid Job Type' END

			WHEN f.FieldName = 'bldqty' THEN 
				CASE WHEN (ISNUMERIC(impt.bldqty) = 1 AND impt.bldqty > 0) THEN ''
				ELSE 'Build quantity must be greater than zero.' END

			-- ORDERDATE
			WHEN f.FieldName = 'OrderDate' THEN 
    			CASE WHEN (LTRIM(impt.OrderDate) = LTRIM(impt.Due_date)) THEN ''
    				 WHEN (impt.OrderDate <> '' AND (impt.OrderDate < impt.Due_date)) THEN ''
    			ELSE 'Entered order date after than due date.' END

			-- DUE_DATE
			WHEN f.FieldName = 'Due_date' THEN 
				CASE WHEN (LTRIM(impt.OrderDate) = LTRIM(impt.Due_date)) THEN ''
					 WHEN (impt.OrderDate <> '' AND (impt.Due_date > impt.OrderDate)) THEN ''
				ELSE 'Entered due date is before than ordered date' END

			-- START_DATE
			WHEN f.FieldName = 'Start_date' THEN
				CASE WHEN (impt.Start_date = '' OR impt.Start_date IS NULL) THEN ''
						WHEN (ISDATE(impt.Start_date) = 1) THEN --''
						CASE WHEN impt.Start_date > impt.End_date THEN 'Start date is after end date'
						ELSE '' END
				ELSE 'Enter valid start date.' END

			-- END_DATE
			WHEN f.FieldName = 'End_date' THEN
				CASE WHEN (impt.End_date = '' OR impt.End_date IS NULL) THEN ''
					 WHEN (ISDATE(impt.End_date) = 1) THEN --''
					 CASE WHEN impt.End_date < impt.Start_date THEN 'End date is before than start date'
					 ELSE '' END
				ELSE 'Enter valid end date.' END

			-- PRJUNIQUE
			WHEN f.FieldName = 'PRJUNIQUE' THEN
				CASE WHEN (impt.[PRJUNIQUE] = '') THEN ''
					 WHEN TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,ISNULL(PJCTM.CUSTNO,'')),10)) <> 
						  TRIM(ISNULL(RIGHT('0000000000'+ CONVERT(VARCHAR,ISNULL(ad.CUSTNO,'')),10),'')) THEN 'Project is not associated with the customer'
					 WHEN (impt.[PRJUNIQUE] = PJCTM.PRJUNIQUE) THEN --''
						CASE WHEN TRIM(PJCTM.PRJSTATUS) = 'Open' THEN '' ELSE 'Entered project is closed.' END
				ELSE 'Enter valid PRJUNIQUE.' END
			
			-- PRJNUMBER
			WHEN f.FieldName = 'PRJNUMBER' THEN
				CASE WHEN (impt.[PRJNUMBER] = '') THEN ''
					 WHEN (impt.[PRJUNIQUE] <> '') THEN ''
					 WHEN (RIGHT('0000000000'+ CONVERT(VARCHAR,impt.PRJNUMBER),10) = PJCTM.PRJNUMBER) THEN --'
						CASE WHEN TRIM(PJCTM.PRJSTATUS) = 'Open' THEN 
							CASE WHEN TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,ISNULL(PJCTM.CUSTNO,'')),10)) <> 
								 TRIM(ISNULL(RIGHT('0000000000'+ CONVERT(VARCHAR,ISNULL(Ad.CUSTNO,'')),10),'')) THEN 
								'Project is not associated with the customer' ELSE '' END
						 ELSE 'Entered project is closed.' END
				ELSE 'Enter valid PRJNUMBER.' END
			
			-- SONO
			WHEN f.FieldName = 'SONO' THEN 
				CASE WHEN (ISNULL(impt.SONO,'')='' OR LTRIM(impt.SONO) = '') THEN ''
					 WHEN (SUBSTRING(TRIM(impt.SONO), PATINDEX('%[^0]%',impt.SONO), 10) 
						= SUBSTRING(TRIM(SOdet.SONO), PATINDEX('%[^0]%',TRIM(SOdet.SONO)), 10)) THEN ''
				ELSE 'Enter valid SONO.' END
			
			-- Line_no
			WHEN f.FieldName = 'Line_no' THEN 
				CASE WHEN (ISNULL(impt.Line_no,'')='' OR TRIM(impt.Line_no) = '') THEN ''
					 WHEN (TRIM(impt.Line_no) <> '' AND TRIM(impt.SONO) = '') THEN 'SONO is required.' 
					 WHEN (TRIM(impt.Line_no) <> '' AND (TRIM(SUBSTRING(impt.Line_no, PATINDEX('%[^0]%',impt.Line_no), 7)) 
					 = TRIM(SUBSTRING(SOdet.Line_no, PATINDEX('%[^0]%',SOdet.Line_no), 7)))) THEN ''
				ELSE 'Entered SONO and Line_no does not match with Assembly No/Rev.' END
			
			-- Warehouse
			WHEN f.FieldName = 'kitDefWarehouse' THEN
				CASE WHEN (ISNULL(impt.kitDefWarehouse,'')='' OR impt.kitDefWarehouse = '') THEN ''
					 WHEN (TRIM(impt.kitDefWarehouse) = TRIM(WH.WAREHOUSE)) THEN 
						CASE WHEN TRIM(impt.kitDefWarehouse) IN ('WIP', 'WO-WIP', 'MRB') THEN 'WIP, WO-WIP and MRB are not allowed.' ELSE '' END
				ELSE 'Enter valid Warehouse Name.' END
			
			-- RoutingName
			WHEN f.FieldName = 'RoutingName' THEN
				CASE WHEN (ISNULL(impt.RoutingName,'')='' OR TRIM(impt.RoutingName)='') THEN '' 
					 WHEN ISNULL(Rout.TemplateName,'') <> '' AND ISNULL(Rout.TemplateType,'') <> '' THEN ''
				ELSE 
					'Job Type doesnot match with the template type or template type does not exists.'
				END  																				
   ELSE '' END 
 
 ,[status] = 
   CASE 
			WHEN f.FieldName = 'wono' THEN 
				CASE WHEN (@IsAutoWO = 0 AND TRIM(ISNULL(impt.WONO,'')) = '') THEN 'i05red'
					 WHEN (@IsAutoWO = 0 AND NoAutoWOGen.WONO IS NOT NULL) THEN 'i05red'
				ELSE '' END 

   			WHEN f.FieldName = 'JobType' THEN 
   				CASE WHEN  (impt.JobType = JobTImpt.JobType) THEN '' 
   				ELSE  'i05red' END

			WHEN f.FieldName = 'bldqty' THEN 
				CASE WHEN (ISNUMERIC(impt.bldqty) = 1 AND impt.bldqty > 0) THEN ''
				ELSE 'i05red' END

			-- ORDERDATE
			WHEN f.FieldName = 'OrderDate' THEN 
    			CASE WHEN (LTRIM(impt.OrderDate) = LTRIM(impt.Due_date)) THEN ''
    				 WHEN (impt.OrderDate <> '' AND (impt.OrderDate < impt.Due_date)) THEN ''
    			ELSE 'i05red' END

			-- DUE_DATE
			WHEN f.FieldName = 'Due_date' THEN 
				CASE WHEN (LTRIM(impt.OrderDate) = LTRIM(impt.Due_date)) THEN ''
					 WHEN (impt.OrderDate <> '' AND (impt.Due_date > impt.OrderDate)) THEN ''
				ELSE 'i05red' END

			-- START_DATE
			WHEN f.FieldName = 'Start_date' THEN
				CASE WHEN (impt.Start_date = '' OR impt.Start_date IS NULL) THEN ''
						WHEN (ISDATE(impt.Start_date) = 1) THEN --''
						CASE WHEN impt.Start_date > impt.End_date THEN 'i05red'
						ELSE '' END
				ELSE 'i05red.' END

			-- END_DATE
			WHEN f.FieldName = 'End_date' THEN
				CASE WHEN (impt.End_date = '' OR impt.End_date IS NULL) THEN ''
					 WHEN (ISDATE(impt.End_date) = 1) THEN --''
					 CASE WHEN impt.End_date < impt.Start_date THEN 'i05red'
					 ELSE '' END
				ELSE 'i05red' END

			-- PRJUNIQUE
			WHEN f.FieldName = 'PRJUNIQUE' THEN
				CASE WHEN (impt.[PRJUNIQUE] = '') THEN ''
					 WHEN TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,ISNULL(PJCTM.CUSTNO,'')),10)) <> 
						  TRIM(ISNULL(RIGHT('0000000000'+ CONVERT(VARCHAR,ISNULL(ad.CUSTNO,'')),10),'')) THEN 'i05red'
					 WHEN (impt.[PRJUNIQUE] = PJCTM.PRJUNIQUE) THEN --''
						CASE WHEN TRIM(PJCTM.PRJSTATUS) = 'Open' THEN '' ELSE 'i05red' END
				ELSE 'i05red' END
			
			-- PRJNUMBER
			WHEN f.FieldName = 'PRJNUMBER' THEN
				CASE WHEN (impt.[PRJNUMBER] = '') THEN ''
					 WHEN (impt.[PRJUNIQUE] <> '') THEN ''
					 WHEN (RIGHT('0000000000'+ CONVERT(VARCHAR,impt.PRJNUMBER),10) = PJCTM.PRJNUMBER) THEN --'
						CASE WHEN TRIM(PJCTM.PRJSTATUS) = 'Open' THEN 
							CASE WHEN TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,ISNULL(PJCTM.CUSTNO,'')),10)) <> 
								 TRIM(ISNULL(RIGHT('0000000000'+ CONVERT(VARCHAR,ISNULL(Ad.CUSTNO,'')),10),'')) THEN 
								'i05red' ELSE '' END
						 ELSE 'i05red' END
				ELSE 'i05red' END
			
			-- SONO
			WHEN f.FieldName = 'SONO' THEN 
				CASE WHEN (ISNULL(impt.SONO,'')='' OR LTRIM(impt.SONO) = '') THEN ''
					 WHEN (SUBSTRING(TRIM(impt.SONO), PATINDEX('%[^0]%',impt.SONO), 10) 
						= SUBSTRING(TRIM(SOdet.SONO), PATINDEX('%[^0]%',TRIM(SOdet.SONO)), 10)) THEN ''
				ELSE 'i05red' END
			
			-- Line_no
			WHEN f.FieldName = 'Line_no' THEN 
				CASE WHEN (ISNULL(impt.Line_no,'')='' OR TRIM(impt.Line_no) = '') THEN ''
					 WHEN (TRIM(impt.Line_no) <> '' AND TRIM(impt.SONO) = '') THEN 'SONO is required.' 
					 WHEN (TRIM(impt.Line_no) <> '' AND (TRIM(SUBSTRING(impt.Line_no, PATINDEX('%[^0]%',impt.Line_no), 7)) 
					 = TRIM(SUBSTRING(SOdet.Line_no, PATINDEX('%[^0]%',SOdet.Line_no), 7)))) THEN ''
				ELSE 'i05red' END
			
			-- Warehouse
			WHEN f.FieldName = 'kitDefWarehouse' THEN
				CASE WHEN (ISNULL(impt.kitDefWarehouse,'')='' OR impt.kitDefWarehouse = '') THEN ''
					 WHEN (TRIM(impt.kitDefWarehouse) = TRIM(WH.WAREHOUSE)) THEN 
						CASE WHEN TRIM(impt.kitDefWarehouse) IN ('WIP', 'WO-WIP', 'MRB') THEN 'i05red' ELSE '' END
				ELSE 'i05red' END
			
			-- RoutingName
			WHEN f.FieldName = 'RoutingName' THEN
				CASE WHEN (ISNULL(impt.RoutingName,'')='' OR TRIM(impt.RoutingName)='') THEN '' 
					 WHEN ISNULL(Rout.TemplateName,'') <> '' AND ISNULL(Rout.TemplateType,'') <> '' THEN ''
				ELSE 
					'i05red'
				END  									
   ELSE '' END 
   -- 10/01/2019 Rajendra K : Update the Adjusted and Originals 
  ,[Adjusted] = 
	CASE 
		WHEN f.FieldName = 'JobType' THEN 
			CASE WHEN (TRIM(ISNULL(impt.JobType,'')) = '') THEN 'Standard' ELSE  impt.JobType END
		
		WHEN f.FieldName = 'PRJUNIQUE' THEN	
			CASE WHEN impt.PRJNUMBER = '' AND impt.PRJUNIQUE = '' THEN ''
				 WHEN impt.PRJNUMBER <> '' AND impt.PRJUNIQUE = '' THEN 
					ISNULL(PJCTM.PRJUNIQUE,'')
			ELSE 
				ISNULL(impt.PRJUNIQUE,'') 
			END

		WHEN f.FieldName = 'PRJNUMBER' THEN	
			CASE WHEN impt.PRJNUMBER = '' AND impt.PRJUNIQUE = '' THEN ''
				 WHEN impt.PRJUNIQUE <> '' AND impt.PRJNUMBER = '' THEN 
					ISNULL(PJCTM.PRJNUMBER,'')
			ELSE 
				CASE WHEN ISNULL(PJCTM.PRJNUMBER,'')='' THEN 
					RIGHT('0000000000'+ CONVERT(VARCHAR,impt.PRJNUMBER),10) 
				ELSE PJCTM.PRJNUMBER END  
			END

		WHEN f.FieldName = 'LINE_NO' THEN 
			CASE WHEN impt.SONO <> '' AND impt.Line_no = '' THEN 
				ISNULL(SOdet.LINE_NO,'')
			ELSE 
				ISNULL(impt.Line_no,'')
			END

		ELSE iw.Adjusted END

	,[Original] = CASE 
		WHEN f.FieldName = 'JobType' THEN 
			CASE WHEN (TRIM(ISNULL(impt.JobType,'')) = '') THEN 'Standard' ELSE  impt.JobType END

		WHEN f.FieldName = 'PRJUNIQUE' THEN	
			CASE WHEN impt.PRJNUMBER = '' AND impt.PRJUNIQUE = '' THEN ''
				 WHEN impt.PRJNUMBER <> '' AND impt.PRJUNIQUE = '' THEN 
					ISNULL(PJCTM.PRJUNIQUE,'')
			ELSE 
				ISNULL(impt.PRJUNIQUE,'') 
			END

		WHEN f.FieldName = 'PRJNUMBER' THEN	
			CASE WHEN impt.PRJNUMBER = '' AND impt.PRJUNIQUE = '' THEN ''
				 WHEN impt.PRJUNIQUE <> '' AND impt.PRJNUMBER = '' THEN 
					ISNULL(PJCTM.PRJNUMBER,'')
			ELSE 
				CASE WHEN ISNULL(PJCTM.PRJNUMBER,'')='' THEN 
					RIGHT('0000000000'+ CONVERT(VARCHAR,impt.PRJNUMBER),10) 
				ELSE PJCTM.PRJNUMBER END  
			END

		WHEN f.FieldName = 'LINE_NO' THEN 
			CASE WHEN impt.SONO <> '' AND impt.Line_no = '' THEN 
				ISNULL(SOdet.LINE_NO,'')
			ELSE 
				ISNULL(impt.Line_no,'')
			END

		ELSE iw.Original END
   FROM ImportBOMToKitWorkOrder iw
	  INNER JOIN ImportBOMToKitAssemly a ON  a.AssemblyRowId = iw.FKAssemblyRowId	 
	  INNER JOIN ImportFieldDefinitions f  ON iw.FKFieldDefId =f.FieldDefId AND ModuleId = @ModuleId 
	  INNER JOIN ImportBOMToKitHeader h  ON a.FkImportId =h.ImportId  
	  LEFT JOIN @ImportDetail impt ON iw.WORowId = impt.WORowId 
	  INNER JOIN @AssemblyDetail Ad ON Ad.AssemblyRowId = impt.AssemblyRowId
	  OUTER APPLY 
	  (
			SELECT TOP 1 TRIM(PART_NO) PART_NO, TRIM(REVISION) REVISION, TRIM(DESCRIPT) DESCRIPT, TRIM(PART_CLASS) PART_CLASS,TRIM(PART_TYPE) PART_TYPE,UNIQ_KEY
			FROM INVENTOR 
			WHERE TRIM(PART_NO) =  TRIM(Ad.assyNum) AND TRIM(REVISION) =  TRIM(Ad.assyRev) AND PART_SOURC = 'MAKE'
	   ) invt  
	  OUTER APPLY (
			SELECT TOP 1 CASE WHEN JobType IN ('Standard','Priority 1','Priority 2','Rework','ReworkFirm','Firm Plann') THEN JobType ELSE '' END JobType
			from @ImportDetail imptdt 
			WHERE imptdt.WORowId = impt.WORowId
		) JobTImpt
		OUTER APPLY (
			--SELECT COUNT(CATEGORY) PhCount FROM PricHead H WHERE uniq_key = Ad.UNIQ_KEY
			SELECT COUNT(custno) PhCount -- 11/21/2019 Rajendra k : Changed Old PRICHEAD table, used new table priceheader,priceCustomer for customer validation
			FROM priceheader ph 
			INNER JOIN priceCustomer pc ON ph.uniqprhead = pc.uniqprhead
			WHERE uniq_key = Ad.UNIQ_KEY
		) PriceheadCnt
		OUTER APPLY (
			--SELECT TOP 1 ISNULL(COUNT(CATEGORY),0) CUSTNOCnt FROM PricHead H 
			--WHERE uniq_key = Ad.UNIQ_KEY AND (H.CATEGORY = Ad.CUSTNO OR H.CATEGORY = '000000000~')
		    SELECT TOP 1 ISNULL(COUNT(custno),0) CUSTNOCnt -- 11/21/2019 Rajendra k : Changed Old PRICHEAD table, used new table priceheader,priceCustomer for customer validation
			FROM priceheader ph
			INNER JOIN priceCustomer pc ON ph.uniqprhead = pc.uniqprhead
			WHERE uniq_key = invt.UNIQ_KEY AND (pc.custno = (RIGHT('0000000000'+ CONVERT(VARCHAR,Ad.CUSTNO),10)) OR pc.custno = '000000000~')
	    ) Pricehead
		OUTER APPLY (
			SELECT TOP 1 PRJUNIQUE, PRJNUMBER, PRJSTATUS, CUSTNO FROM PJCTMAIN PJCT
				WHERE PRJUNIQUE = CASE WHEN TRIM(impt.PRJUNIQUE) <> '' THEN TRIM(impt.PRJUNIQUE) ELSE TRIM(PJCT.PRJUNIQUE) END
				  AND PRJNUMBER = CASE WHEN TRIM(impt.PRJUNIQUE) <> '' THEN PJCT.PRJNUMBER 
									   WHEN TRIM(impt.PRJNUMBER) <> '' THEN 
											CASE WHEN ISNUMERIC(impt.PRJNUMBER)=1 THEN 
												RIGHT('0000000000'+ CONVERT(VARCHAR,impt.PRJNUMBER),10)
											ELSE 
												TRIM(PJCT.PRJNUMBER) END 
									   ELSE TRIM(PJCT.PRJNUMBER) END
		) PJCTM
		OUTER APPLY (
			SELECT TOP 1 SUBSTRING(SO.SONO, PATINDEX('%[^0]%',SO.SONO), 10) SONO, 
						 SUBSTRING(LINE_NO, PATINDEX('%[^0]%',LINE_NO), 7) LINE_NO, UNIQ_KEY, 
						 TRIM(SOM.CUSTNO) SOCUSTNO FROM SODETAIL SO 
						 JOIN SOMAIN SOM ON SOM.SONO = SO.SONO
				WHERE TRIM(SUBSTRING(SO.SONO, PATINDEX('%[^0]%',SO.SONO), 10)) = 
					CASE WHEN TRIM(impt.SONO) <> '' THEN 
						TRIM(SUBSTRING(impt.SONO, PATINDEX('%[^0]%',TRIM(impt.SONO)), 10)) 
					ELSE 
						TRIM(SUBSTRING(SO.SONO, PATINDEX('%[^0]%',SO.SONO), 10)) END
				AND SUBSTRING(LINE_NO, PATINDEX('%[^0]%',LINE_NO), 7) 
				=	CASE WHEN TRIM(impt.Line_no) <> '' THEN
								CASE WHEN RTRIM(LTRIM(impt.Line_no)) = '' THEN 
									(
										SELECT TOP 1 SUBSTRING(LINE_NO, PATINDEX('%[^0]%',LINE_NO), 7) 
										FROM SODETAIL WHERE UNIQ_KEY = Ad.UNIQ_KEY 
										AND balance > 0 
										AND SUBSTRING(SO.SONO, PATINDEX('%[^0]%',SO.SONO), 10) = SUBSTRING(impt.SONO, PATINDEX('%[^0]%',impt.SONO), 10) 
									) 
								WHEN RTRIM(LTRIM(impt.Line_no)) <> '' THEN
									SUBSTRING(impt.Line_no, PATINDEX('%[^0]%',impt.Line_no), 7)  
								END
						 ELSE SUBSTRING(SO.LINE_NO, PATINDEX('%[^0]%',SO.LINE_NO), 7) END
		) SOdet
		OUTER APPLY (
			SELECT Top 1 rt.TemplateName, rt.TemplateType 
			FROM routingProductSetup rp 
			INNER JOIN RoutingTemplate rt ON rp.TemplateID=rt.TemplateID
			WHERE TRIM(rt.TemplateName) = TRIM(impt.RoutingName) 
			AND TRIM(rt.TemplateType) = CASE WHEN TRIM(impt.JobType) LIKE 'Rework%' THEN 'Rework' ELSE 'Regular' END
			AND UNIQ_KEY= Ad.UNIQ_KEY
		) Rout
		OUTER APPLY(
			SELECT TOP 1 UNIQWH,WAREHOUSE,IS_DELETED FROM WAREHOUS WHERE WAREHOUSE = impt.kitDefWarehouse and IS_DELETED = 0 
		) WH
		OUTER APPLY 
		(
			select top 1 WONO from WOENTRY where TRIM(WONO) = RIGHT('0000000000'+ CONVERT(VARCHAR,impt.WONO),10) and @IsAutoWO = 0 
		) NoAutoWOGen

-- Check length of string entered by user in template
	BEGIN TRY -- inside begin try      
	  UPDATE iw      
		SET [message]='Field will be truncated to ' + CAST(f.fieldLength AS VARCHAR(50)) + ' characters.',[status]=@red 
		FROM ImportBOMToKitWorkOrder iw
		  INNER JOIN ImportBOMToKitAssemly a ON  a.AssemblyRowId = iw.FKAssemblyRowId	 
		  INNER JOIN ImportFieldDefinitions f  ON iw.FKFieldDefId =f.FieldDefId AND ModuleId = @ModuleId AND f.fieldLength > 0      
			WHERE fkImportId= @ImportId      
				AND LEN(iw.adjusted)>f.fieldLength        
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