-- ============================================================================================================
-- Date			: 07/09/2019
-- Author		: Satyawan H
-- Description	: Import Work Order Upload and Validate imported data
-- 11/21/2019 Rajendra K : Changed Old PRICHEAD table, used new table priceheader,priceCustomer for customer validation
-- ============================================================================================================
-- EXEC ValidateWOUploadRecords @ImportId='8D43EACE-156A-4D41-B966-6C336A580231',@UserId = '49F80792-E15E-4B62-B720-21B360E3108A'

CREATE PROC ValidateWOUploadRecords 
	@ImportId UNIQUEIDENTIFIER,
	@RowId UNIQUEIDENTIFIER = null,
	@UserId UNIQUEIDENTIFIER = null
AS
BEGIN
	SET NOCOUNT ON  
	DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName varchar(max),@uniq_key VARCHAR(10),@orange VARCHAR(20)='i04orange',@sys VARCHAR(20)='01system',  
			@UDFSQL VARCHAR(MAX),@UFieldName NVARCHAR(max),@SFieldName nvarchar(max), @IsAutoWO BIT, @headerErrs VARCHAR(MAX)  

	DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX))      
	
	DECLARE @ImportDetail TABLE(importId UNIQUEIDENTIFIER,rowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),[Validation] VARCHAR(100), 
								BLDQTY VARCHAR(100),custName VARCHAR(100),CUSTNO VARCHAR(100),DUE_DATE VARCHAR(100), 
								End_date VARCHAR(100),JobType VARCHAR(100),Line_no VARCHAR(100),OPENCLOS VARCHAR(100),
								ORDERDATE VARCHAR(100),PART_NO VARCHAR(100),PRJNUMBER	VARCHAR(100),PRJUNIQUE VARCHAR(100),
								RELEDATE VARCHAR(100),Revision VARCHAR(100),RoutingName VARCHAR(100),SONO VARCHAR(100),
								[START_DATE] VARCHAR(100),UNIQ_KEY VARCHAR(100),Warehouse VARCHAR(100),WONO VARCHAR(100),WONOTE VARCHAR(100)) 

	-- Insert statements for procedure here  
	SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleName = 'WO Upload' and FilePath = 'WOUpload'
	SELECT @FieldName = STUFF(  
						(  
							SELECT  ',[' +  F.FIELDNAME + ']' FROM ImportFieldDefinitions F    
							WHERE ModuleId = @ModuleId 
							ORDER BY F.FIELDNAME 
							FOR XML PATH('')  
						),  
						1,1,'')   

	SELECT @SQL = N'  
		SELECT PVT.*
		FROM  
		(
			SELECT ibf.fkImportId AS importId,ibf.rowId,sub.class as CssClass,sub.Validation,fd.fieldName,adjusted'  
			+' FROM ImportFieldDefinitions fd    
			INNER JOIN ImportWOUploadFields ibf ON fd.FieldName = ibf.FieldName AND fd.ModuleId = ' + CAST(@ModuleId as varchar(10))
			+' INNER JOIN ImportWOUploadHeader h ON h.ImportId = ibf.FkImportId 
			INNER JOIN (
				SELECT fkImportId,rowid,MAX(status) as Class ,MIN(validation) as Validation  
				FROM ImportWOUploadFields WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''  
				AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')
				GROUP BY fkImportId,rowid) Sub  
			ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid  
			WHERE ibf.fkImportId ='''+ CAST(@importId as CHAR(36))+'''   
			) st  
		PIVOT (MAX(adjusted) FOR fieldName IN ('+ @FieldName +')) as PVT 
		LEFT JOIN CUSTOMER c ON c.CUSTNO = PVT.CUSTNO 
		ORDER BY [part_no],[revision]'
	
	INSERT INTO @ImportDetail EXEC sp_executesql @SQL   

	-- Populate Detail grid data with value trim, default OrderDate, DueDate and CustName, CustNo
	UPDATE impt 
		SET 
	
		WONO = CASE WHEN TRIM(impt.WONO) = '' THEN '' ELSE TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,impt.WONO),10)) END
		   ,CUSTNO = CASE WHEN TRIM(impt.Custno) <> '' THEN 
							TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,impt.CUSTNO),10)) 
						  WHEN TRIM(impt.custName) <> '' THEN
						  	ISNULL((select TOP 1 TRIM(CUSTNO) FROM CUSTOMER WHERE custName = TRIM(impt.custName)),'')
					 ELSE
						TRIM(impt.CUSTNO)
					 END 
		   ,CUSTNAME = CASE WHEN TRIM(impt.Custno) <> '' THEN 
								ISNULL((SELECT TOP 1 TRIM(CUSTNAME) FROM CUSTOMER WHERE CUSTNO = TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,impt.CUSTNO),10))),'')
							ELSE 
								TRIM(custName)
					   END
		   --,CUSTNAME = TRIM(custName)
		   ,ORDERDATE = CASE WHEN TRIM(ISNULL(ORDERDATE,'')) = '' THEN convert(varchar, GETDATE(), 23) ELSE convert(varchar, ORDERDATE, 23) END
		   ,DUE_DATE = CASE WHEN LTRIM(impt.DUE_DATE) = '' THEN
							CAST(
								CAST((
										DATEADD(DAY, Inv.PROD_LTIME, 
											CASE WHEN LTRIM(impt.ORDERDATE) = '' THEN 
													GETDATE() 
												 ELSE 
													CAST(impt.ORDERDATE AS VARCHAR(50)) 
											END)
									) As date) AS VARCHAR(50)
								)  
						ELSE 
							CAST(impt.DUE_DATE AS VARCHAR(50))  
						END
			,SONO = TRIM(ISNULL(SONO,''))
		FROM @ImportDetail impt 
		LEFT JOIN INVENTOR Inv ON ((impt.UNIQ_KEY <> '' AND impt.UNIQ_KEY = Inv.UNIQ_KEY ) OR (impt.UNIQ_KEY ='' AND 
									impt.PART_NO = inv.PART_NO AND TRIM(impt.Revision) = TRIM(inv.REVISION)))
		
	--select * from @ImportDetail
	SELECT @IsAutoWO = CASE WHEN w.settingId IS NOT NULL THEN  w.settingValue ELSE m.settingValue END FROM MnxSettingsManagement m
		LEFT JOIN wmSettingsManagement w on m.settingId = w.settingId
		WHERE settingName = 'AutoWONumber' AND settingDescription = 'AutoGenerateWO'

	-- Validate if error then update the message for field in WO
	UPDATE f
		SET [message] = 
	
		CASE  
			-- Part_sourc 
			WHEN f.FieldName = 'UNIQ_KEY' THEN 
				CASE WHEN impt.UNIQ_KEY = '' THEN ''
					 WHEN (ISNULL(impt.UNIQ_KEY,'') <> '' AND ISNULL(invtU.UNIQ_KEY,'') <> '')  THEN '' 
				ELSE  'Enter valid uniq key or Part number/Revision' END 
			
			-- PART_NO 
			WHEN f.FieldName = 'PART_NO' THEN 
				CASE WHEN RTRIM(invtP.PART_NO) = RTRIM(impt.PART_NO) THEN '' 
				ELSE  'Enter valid Part number/Revision.' END
							
			-- REVISION	
			WHEN f.FieldName = 'REVISION' THEN 
				CASE WHEN (impt.Revision ='') OR (invtP.REVISION = impt.Revision) THEN '' 
				ELSE  'Enter valid Part number/Revision' END
			
			-- JobType
			WHEN f.FieldName = 'JobType' THEN 
				CASE WHEN  (impt.JobType = JobTImpt.JobType) THEN '' 
				ELSE  'Enter valid Job Type' END
	
			-- WONO
			WHEN f.FieldName = 'WONO' THEN 
				CASE WHEN (@IsAutoWO = 0 AND TRIM(ISNULL(impt.WONO,'')) = '') THEN 'WONO is required.'
					 WHEN (@IsAutoWO = 0 AND NoAutoWOGen.WONO IS NOT NULL) THEN 'Entered WONO already exists.'
					 WHEN (@IsAutoWO = 0 AND DuplicateWO.TotalNo > 1) THEN 
					 '"' + CAST(impt.WONO as VARCHAR(10)) + '" is entered for ' + CAST(DuplicateWO.TotalNo as VARCHAR(10)) + ' WO''s in template.'
					 WHEN (invtP.[STATUS] = 'Inactive') THEN 'Entered part is not active.'
					 WHEN (invtP.PART_SOURC <> 'MAKE') THEN 'Entered part source is not MAKE.'
					 WHEN (invtP.make_buy <> 0) THEN 'Entered part make buy is not valid.'
				ELSE '' END 
			
			-- CUSTNO
			WHEN f.FieldName = 'CUSTNO' THEN 
				CASE WHEN (TRIM(ISNULL(impt.CUSTNO,'')) = '' AND ISNULL(impt.custName,'') = '') THEN ''
					 WHEN (TRIM(ISNULL(impt.CUSTNO,'')) <> '' AND (RIGHT('0000000000'+ CONVERT(VARCHAR,impt.CUSTNO),10)=CUSTOMER.CUSTNO)) THEN 
						-- Customer with Sales Order No. validation
						CASE WHEN (TRIM(ISNULL(impt.SONO,'')) <> '') AND (TRIM(CUSTOMER.CUSTNO) <> TRIM(SOdet.SOCUSTNO)) THEN 
							'Entered customer no. does not match with SONO.' 
						ELSE 
							-- Customer with BOM validation
							CASE WHEN bom_Det.totalCst > 0 AND bom_Det.CUSTNO <> CUSTOMER.CUSTNO THEN 'Customer Does not match with the BOM Customer.' 
								 ELSE 
									CASE WHEN TRIM(INVENTORBOM.BOMCUSTNO) = TRIM(impt.CUSTNO) THEN ''
										 WHEN PriceheadCnt.PhCount = 0 THEN ''
										 WHEN PriceheadCnt.PhCount > 0 AND Pricehead.CUSTNOCnt > 0 THEN ''
										 ELSE 'Provided Customer is Not Available in Price setup'
									END
							END
						END
				ELSE 'Entered Customer No. is not valid.' END
	
			-- CUSTNAME
			WHEN f.FieldName = 'CUSTNAME' THEN 
				CASE WHEN (ISNULL(TRIM(impt.CUSTNO),'') = '' AND ISNULL(impt.custName,'') = '') THEN ''
					 WHEN TRIM(impt.CUSTNO) = TRIM(CUSTOMER.CUSTNO) THEN ''
				ELSE 'Entered customer Name. is not valid.' END

			-- BLDQTY
			WHEN f.FieldName = 'BLDQTY' THEN 
				CASE WHEN (ISNUMERIC(impt.BLDQTY) = 1 AND impt.BLDQTY > 0) THEN ''
				ELSE 'Build quantity must be greater than zero.' END
			
			-- ORDERDATE
			WHEN f.FieldName = 'ORDERDATE' THEN 
    			CASE WHEN (LTRIM(impt.ORDERDATE) = LTRIM(impt.DUE_DATE)) THEN ''
    				 WHEN (impt.ORDERDATE <> '' AND (impt.ORDERDATE < impt.DUE_DATE)) THEN ''
    			ELSE 'Entered order date after than due date.' END
			
			-- DUE_DATE
			WHEN f.FieldName = 'DUE_DATE' THEN 
				CASE WHEN (LTRIM(impt.ORDERDATE) = LTRIM(impt.DUE_DATE)) THEN ''
					 WHEN (impt.ORDERDATE <> '' AND (impt.DUE_DATE > impt.ORDERDATE)) THEN ''
				ELSE 'Entered due date is before than ordered date' END

			-- START_DATE
			WHEN f.FieldName = 'START_DATE' THEN
				CASE WHEN (impt.[START_DATE] = '' OR impt.[START_DATE] IS NULL) THEN ''
						WHEN (ISDATE(impt.[START_DATE]) = 1) THEN --''
						CASE WHEN impt.[START_DATE] > impt.End_date THEN 'Start date is after end date'
						ELSE '' END
				ELSE 'Enter valid start date.' END
			-- END_DATE
			WHEN f.FieldName = 'END_DATE' THEN
				CASE WHEN (impt.[END_DATE] = '' OR impt.[END_DATE] IS NULL) THEN ''
					 WHEN (ISDATE(impt.[END_DATE]) = 1) THEN --''
					 CASE WHEN impt.[End_date] < impt.[START_DATE] THEN 'End date is before than start date'
					 ELSE '' END
				ELSE 'Enter valid end date.' END
			
			-- PRJUNIQUE
			WHEN f.FieldName = 'PRJUNIQUE' THEN
				CASE WHEN (impt.[PRJUNIQUE] = '') THEN ''
					 WHEN TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,ISNULL(PJCTM.CUSTNO,'')),10)) <> 
						  TRIM(ISNULL(RIGHT('0000000000'+ CONVERT(VARCHAR,ISNULL(impt.CUSTNO,'')),10),'')) THEN 'Project is not associated with the customer'
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
								 TRIM(ISNULL(RIGHT('0000000000'+ CONVERT(VARCHAR,ISNULL(impt.CUSTNO,'')),10),'')) THEN 
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
				ELSE 'Entered SONO and Line_no doesn''t match with Part.' END
			
			-- Warehouse
			WHEN f.FieldName = 'Warehouse' THEN
				CASE WHEN (ISNULL(impt.Warehouse,'')='' OR impt.Warehouse = '') THEN ''
					 WHEN (TRIM(impt.Warehouse) = TRIM(WH.WAREHOUSE)) THEN 
						CASE WHEN TRIM(impt.Warehouse) IN ('WIP', 'WO-WIP', 'MRB') THEN 'WIP, WO-WIP and MRB are not allowed.' ELSE '' END
				ELSE 'Enter valid warehouse.' END
			
			-- RoutingName
			WHEN f.FieldName = 'RoutingName' THEN
				CASE WHEN (ISNULL(impt.RoutingName,'')='' OR TRIM(impt.RoutingName)='') THEN '' 
					 WHEN ISNULL(Rout.TemplateName,'') <> '' AND ISNULL(Rout.TemplateType,'') <> '' THEN ''
				ELSE 
					'Job Type doesnot match with the template type or template type doesn''t exists.'
				END
			ELSE ''
		END
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

		ELSE Adjusted END

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

		ELSE Original END

		FROM ImportWOUploadFields f 
		JOIN ImportWOUploadHeader h ON  f.FkImportId =  h.ImportId
		JOIN importFieldDefinitions fd ON f.FieldName = fd.FieldName AND ModuleId = @ModuleId
		JOIN @ImportDetail impt on f.RowId = impt.RowId
		LEFT JOIN INVENTOR Inv ON ((impt.UNIQ_KEY <> '' AND impt.UNIQ_KEY = Inv.UNIQ_KEY ) OR (impt.UNIQ_KEY ='' AND 
								   impt.PART_NO = inv.PART_NO AND TRIM(impt.Revision) = TRIM(inv.REVISION)))
		OUTER APPLY (
			SELECT TOP 1 part1.UNIQ_KEY,CUSTPARTNO,part1.CUSTNO,REVISION,PART_NO,DESCRIPT,CUSTREV,PART_SOURC,make_buy,PROD_LTIME,[Status] 
			FROM INVENTOR part1 WHERE part1.UNIQ_KEY = inv.UNIQ_KEY
		) invtP
		OUTER APPLY (
			SELECT TOP 1 UNIQ_KEY,CUSTPARTNO,CUSTNO,REVISION,PART_NO,DESCRIPT,CUSTREV,PART_SOURC,make_buy,PROD_LTIME,[Status] FROM INVENTOR part 
			WHERE part.UNIQ_KEY =  inv.UNIQ_KEY
		) invtU
		OUTER APPLY (
			SELECT TOP 1 
				CASE WHEN JobType IN ('Standard','Priority 1','Priority 2','Rework','ReworkFirm','Firm Plann') THEN JobType ELSE '' END JobType
			from @ImportDetail imptdt 
			WHERE imptdt.rowId = impt.rowId
		) JobTImpt
		OUTER APPLY (
			SELECT TOP 1 WONO FROM WOENTRY WHERE TRIM(WONO) = RIGHT('0000000000'+ CONVERT(VARCHAR,impt.WONO),10) and @IsAutoWO = 0 
		) NoAutoWOGen
		OUTER APPLY (
			SELECT TOP 1 WONO, COUNT(WONO) TotalNo FROM @ImportDetail 
			WHERE TRIM(WONO) = RIGHT('0000000000'+ CONVERT(VARCHAR,impt.WONO),10)
			GROUP BY WONO
		) DuplicateWO
		OUTER APPLY (
			SELECT TOP 1 CUSTNO, custName from CUSTOMER C 
			WHERE CUSTNO = CASE WHEN impt.CUSTNO <> '' THEN RIGHT('0000000000'+ CONVERT(VARCHAR,impt.CUSTNO),10) ELSE C.CUSTNO END 
			AND C.CUSTNAME = CASE WHEN impt.CUSTNO <> '' THEN C.CUSTNAME
								  WHEN TRIM(impt.CUSTNAME) <> '' THEN  TRIM(impt.CUSTNAME) ELSE TRIM(C.CUSTNAME) END 
		) CUSTOMER
		OUTER APPLY (
			SELECT distinct count(custno) totalCst, CUSTNO FROM BOM_DET b 
				JOIN inventor i ON b.uniq_key=i.uniq_key 
				WHERE BOMPARENT = impt.UNIQ_KEY and PART_SOURC='CONSG' 
				GROUP BY custno
		) bom_Det
		OUTER APPLY (
			SELECT TOP 1 BOMCUSTNO FROM INVENTOR i WHERE I.UNIQ_KEY = TRIM(impt.UNIQ_KEY) 
		) INVENTORBOM
		OUTER APPLY (
			--SELECT COUNT(CATEGORY) PhCount FROM PricHead H WHERE uniq_key = impt.UNIQ_KEY
			SELECT COUNT(custno) PhCount -- 11/21/2019 Rajendra K : Changed Old PRICHEAD table, used new table priceheader,priceCustomer for customer validation
			FROM priceheader ph 
			INNER JOIN priceCustomer pc ON ph.uniqprhead = pc.uniqprhead
			WHERE uniq_key = impt.UNIQ_KEY
		) PriceheadCnt
		OUTER APPLY (
			--SELECT TOP 1 ISNULL(COUNT(CATEGORY),0) CUSTNOCnt FROM PricHead H 
			--WHERE uniq_key = impt.UNIQ_KEY AND (H.CATEGORY = impt.CUSTNO OR H.CATEGORY = '000000000~')
			SELECT TOP 1 ISNULL(COUNT(custno),0) CUSTNOCnt -- 11/21/2019 Rajendra K : Changed Old PRICHEAD table, used new table priceheader,priceCustomer for customer validation
			FROM priceheader ph
			INNER JOIN priceCustomer pc ON ph.uniqprhead = pc.uniqprhead
			WHERE uniq_key = impt.UNIQ_KEY AND (pc.custno = (RIGHT('0000000000'+ CONVERT(VARCHAR,impt.CUSTNO),10)) OR pc.custno = '000000000~')
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
										FROM SODETAIL WHERE UNIQ_KEY = invtP.UNIQ_KEY 
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
			AND UNIQ_KEY= invtP.UNIQ_KEY
		) Rout
		OUTER APPLY(
			SELECT TOP 1 UNIQWH,WAREHOUSE,IS_DELETED FROM WAREHOUS WHERE WAREHOUSE = impt.Warehouse and IS_DELETED = 0 
		) WH
		WHERE (NOT @rowId IS NULL AND f.RowId = @rowId) OR (@rowId IS NULL AND 1=1) 
	
	-- Check length of string entered by user in template
	BEGIN TRY -- inside begin try      
	  UPDATE f      
		SET [message]='Field will be truncated to ' + CAST(fd.fieldLength AS VARCHAR(50)) + ' characters.',[status]=@orange,[validation]=@sys      
		FROM ImportWOUploadFields f       
		INNER JOIN importFieldDefinitions fd ON f.FieldName =fd.FieldName AND fd.fieldLength>0 and ModuleId = @ModuleId       
		WHERE fkImportId= @ImportId 
		AND LEN(f.adjusted)>fd.fieldLength        
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
	 
	-- Insert WO Entry records for valid WOs only
	EXEC InsertWOEntryRecords @ImportId,@UserId
END