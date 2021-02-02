-- ============================================================================================================
-- Date			: 07/27/2019
-- Author		: Mahesh B
-- Description	: Used for Validate Part Class Type upload data
--- 01/18/21 YS changed validations of a buyer using group permissions
-- Added changes by MaheshB: 01-07-2020 Change the permissions from add/edit to Tools
-- ValidatePartClassTypeUploadRecords '6B060D9B-2E6E-4F7C-B316-C75DFC9E0A8D','38E32D69-E37C-45FC-94D4-41EE61113C68'
-- ============================================================================================================

CREATE PROC [dbo].[ValidatePartClassTypeUploadRecords]
	@ImportId UNIQUEIDENTIFIER,
	@RowId UNIQUEIDENTIFIER = NULL
AS
BEGIN
	
	SET NOCOUNT ON 
	DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName varchar(MAX),@partClass VARCHAR(10)
	
	DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER, FKImportTemplateId UNIQUEIDENTIFIER, rowId UNIQUEIDENTIFIER
								 ,CssClass VARCHAR(100),[Validation] VARCHAR(100),buyer VARCHAR(100)
								, classDescription NVARCHAR(MAX),part_class NVARCHAR(MAX))

	-- Insert statements for procedure here  
	SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleName = 'Part Master &  AML Control (PM)' and FilePath = 'PartMaster'
	SELECT @FieldName = STUFF(  
						(  
							SELECT  ',[' +  F.FIELDNAME + ']' FROM 
							ImportFieldDefinitions F    
							WHERE ModuleId = @ModuleId AND FieldName IN ('part_class','classDescription','UniqueKey','UniqWH','Buyer')
							ORDER BY F.FIELDNAME 
							FOR XML PATH('')  
						),  
						1,1,'')   

	SELECT @SQL = N'  
	SELECT PVT.*
		FROM  
		(   SELECT ibf.fkImportId AS importId,ibf.FKImportTemplateId,ibf.rowId, sub.class as CssClass,sub.Validation,fd.fieldName,adjusted'  
			+' FROM ImportFieldDefinitions fd    
			INNER JOIN importPartClassTypeFields ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId = ' + CAST(@ModuleId as varchar(10))+
		   'INNER JOIN importPartClassTypeInfo ti ON ti.ImportTemplateId = ibf.FKImportTemplateId   
		   INNER JOIN importPartClassTypeHeader h ON h.ImportId = ibf.FkImportId 
			INNER JOIN 
			(   SELECT fkImportId,rowid,MAX(status) as Class ,MIN(Message) as ValidatiON  
				FROM importPartClassTypeFields fd
				INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId
				WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''  
				AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')
				GROUP BY fkImportId,rowid
			) Sub  
			ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid  
			WHERE ibf.fkImportId ='''+ CAST(@importId as CHAR(36))+'''   
		) st  
			PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')
		) as PVT 
		ORDER BY [part_class]'
	
	--Print @SQL
	INSERT INTO @ImportDetail EXEC sp_executesql @SQL   
	--select * from @ImportDetail
	UPDATE f
		SET [message] = 
		CASE 
			WHEN ifd.FieldName = 'PART_CLASS' THEN
				    CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE WHEN (LEN(f.Adjusted)>8)
										THEN  'PART_CLASS length can not be greater than 8 charcters.' ELSE '' END
						ELSE 'PART_CLASS can not be empty.' END
			WHEN ifd.FieldName = 'CLASSDESCRIPTION' THEN
				    CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
									WHEN (LEN(f.Adjusted)>50)
										THEN'CLASSDESCRIPTION length can not be greater than 50 charcters.'
									ELSE '' END
						ELSE '' END
			WHEN ifd.FieldName = 'PART_TYPE' THEN
				    CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN 
								CASE WHEN (LEN(TRIM(f.Adjusted)) > 8)
										THEN 'PART_TYPE length can not be greater than 8 charcters.'
									    ELSE ''END
						ELSE '' END
			WHEN ifd.FieldName = 'PREFIX' THEN
				    CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
									WHEN (LEN(f.Adjusted)>20)
										THEN'PREFIX length can not be greater than 20 charcters.'
									ELSE '' END
						ELSE '' END
			WHEN ifd.FieldName = '[DESCRIPTION]' THEN
				    CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
									WHEN (LEN(f.Adjusted)>100)
										THEN'[DESCRIPTION] length can not be greater than 100 charcters.'
									ELSE '' END
						ELSE '' END
			WHEN ifd.FieldName = 'USEIPKEY' THEN
				   CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN'Entered the invalid data into USEIPKEY.Values can be ( Y OR N ,YES OR NO ,True or False ,1 OR 0)'
								ELSE '' END
							ELSE '' END
			WHEN ifd.FieldName = 'ALLOWAUTOKIT' THEN
				   CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN'Entered the invalid data into ALLOWAUTOKIT.Values can be ( Y OR N ,YES OR NO ,True or False ,1 OR 0)'
								ELSE '' END
							ELSE '' END
			WHEN  ifd.FieldName = 'U_OF_MEAS' THEN 
			  CASE
					WHEN TRIM(f.Adjusted) <> '' AND TRIM(f.Adjusted) IS NOT NULL
					  THEN CASE 
					         WHEN TRIM(f.Adjusted) NOT IN (SELECT LEFT(support.text,4) AS UOM FROM SUPPORT WHERE support.fieldname = 'U_OF_MEAS' )
								THEN 'U_OF_MEAS Provided in the Sheet does not Exists.'
							 --WHEN (TRIM(f.Adjusted) NOT IN (SELECT [FROM] FROM UNIT) OR TRIM(f.Adjusted) NOT IN (SELECT [TO] FROM UNIT))
								--THEN 'U_OF_MEAS Conversion Provided in the Sheet does not Exists. '
						     Else ''END
                       ELSE ''END
			 WHEN  ifd.FieldName = 'PUR_UOFM' THEN 
				   CASE
						WHEN TRIM(f.Adjusted) <> '' AND TRIM(f.Adjusted) IS NOT NULL
							THEN CASE 
									WHEN LEN(f.Adjusted)<5
										THEN CASE
											WHEN TRIM(f.Adjusted) NOT IN (SELECT LEFT(support.text,4) AS UOM FROM SUPPORT WHERE support.fieldname = 'U_OF_MEAS' ) -- It is same for U_OF_MEAS
												THEN 'PUR_UOFM Provided in the Sheet does not Exists.'
											--WHEN (TRIM(f.Adjusted) NOT IN (SELECT [FROM] FROM UNIT) OR TRIM(f.Adjusted) NOT IN (SELECT [TO] FROM UNIT))
											--	THEN 'PUR_UOFM Conversion Provided in the Sheet does not Exists.'
											ELSE ''END
										ELSE 'PUR_UOFM value can not be greater than 4 charcters.' END
						ELSE  '' END
			WHEN  ifd.FieldName = 'ORD_POLICY' THEN 
				   CASE 
						WHEN TRIM(f.Adjusted) <> '' AND TRIM(f.Adjusted) IS NOT NULL 
						 THEN CASE 
							WHEN LEN(f.Adjusted)<13
								THEN  CASE 
										WHEN TRIM(f.Adjusted) NOT IN ('Daily', 'Lot for Lot', 'Monthly', 'Quarterly', 'Semi-Monthly', 'Weekly')
						 					THEN 'ORD_POLICY is NULL or not from this (Lot for Lot, Daily, Weekly, Semi-Monthly, Monthly, Quarterly)' 
										ELSE'' END 
								ELSE'ORD_POLICY value entered is greater than 12 characters.'END
					ELSE  '' END
			WHEN  ifd.FieldName = 'CERT_TYPE' THEN 
				   CASE 
						WHEN TRIM(f.Adjusted) <> '' AND TRIM(f.Adjusted) IS NOT NULL 
						  THEN CASE 
								WHEN LEN(f.Adjusted)<13
									THEN	CASE 
										WHEN f.Adjusted NOT IN ('Receive', 'Ship', 'Both')
											THEN 'CERT_TYPE is NULL or not from this (Receive, Ship, Both)' 
										ELSE ''END
								ELSE 'CERT_TYPE value entered is greater than 13 characters.'END
					ELSE '' END
			WHEN ifd.FieldName = 'PACKAGE' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN LEN(f.Adjusted)<16
								THEN CASE 
									WHEN TRIM(f.Adjusted) NOT IN (SELECT LEFT(TEXT,15) AS package FROM Support WHERE Fieldname = 'PART_PKG')
										THEN f.Adjusted+' PACKAGE Provided in the Sheet does not Exists.'
									ELSE '' END
								ELSE 'PACKAGE value entered is greater than 16 characters.'END
					ELSE '' END
			WHEN ifd.FieldName = 'WAREHOUSE' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE WHEN TRIM(f.Adjusted) IN  ('WIP', 'WO-WIP', 'MRB') 
											THEN 'Unable to associate warehouse :'+TRIM(f.Adjusted) +' for a class'
								ELSE 
									CASE WHEN TRIM(f.Adjusted) NOT IN (SELECT UNIQWH FROM WAREHOUS WHERE UNIQWH = f.Adjusted)
											THEN  'WAREHOUSE Provided in the Sheet does not Exists.'
										ELSE'' END
								END
							ELSE '' END
			WHEN ifd.FieldName = 'MRC' THEN
				   CASE
					WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						THEN CASE 
							WHEN TRIM(f.Adjusted) NOT IN (SELECT CAST(TRIM(LTRIM(Text)) AS Char(15)) AS Mrc FROM Support WHERE Fieldname = 'MRC')
								THEN 'MRC Provided in the Sheet does not Exists.'
							ELSE '' END
						ELSE '' END
			WHEN ifd.FieldName = 'ABC' THEN
				   CASE
					WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						THEN CASE 
							WHEN  TRIM(f.Adjusted) NOT IN (SELECT ABC_TYPE FROM INVTABC)
								THEN 'ABC Provided in the Sheet does not Exists.'
								ELSE '' END
					ELSE '' END
			WHEN ifd.FieldName = 'INSP_REQ' THEN
				    CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN 'Entered the invalid data into INSP_REQ.Values can be ( Y OR N ,YES OR NO ,True or False ,1 OR 0)'
								ELSE '' END
						ELSE '' END
			WHEN ifd.FieldName = 'CERT_REQ' THEN
				    CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN 'Entered the invalid data into CERT_REQ.Values can be ( Y OR N ,YES OR NO ,True or False ,1 OR 0)'
								ELSE '' END
						ELSE '' END
			WHEN ifd.FieldName = 'REORDPOINT' THEN
				CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						THEN CASE WHEN (LEN(f.Adjusted)<7)
									THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
										THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(7,0))<0)
													THEN 'REORDPOINT can not be negative.' ELSE '' END
										ELSE 'REORDPOINT is not numeric value.' END    
								ELSE 'REORDPOINT length can not be greater than 6 digits.' END	
				ELSE ''END
			WHEN ifd.FieldName = 'MINORD' THEN
				    CASE
						WHEN (f.Adjusted<>'' AND f.Adjusted IS NOT NULL)
							THEN CASE WHEN (LEN(f.Adjusted)<8)
								THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
									THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(7,0))<0)
												THEN 'MINORD can not be negative.' ELSE '' END
										ELSE 'MINORD is not numeric value.' END    
						ELSE 'MINORD length can not be greater than 6 digits.' END
				ELSE ''END
			WHEN ifd.FieldName = 'ORDMULT' THEN
				    CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE WHEN (LEN(f.Adjusted)<8)
									THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
										THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(7,0))<0)
												THEN 'ORDMULT can not be negative.' ELSE '' END
										ELSE 'ORDMULT is not numeric value.' END   
						ELSE 'ORDMULT length can not be greater than 6 digits.' END
				ELSE ''END
			WHEN ifd.FieldName = 'REORDERQTY' THEN
				    CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE WHEN (LEN(f.Adjusted)<8)
									THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
										THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(7,0))<0)
												THEN 'REORDERQTY can not be negative.' ELSE '' END
										ELSE 'REORDERQTY is not numeric value.' END   
							ELSE 'REORDERQTY length can not be greater than 6 digits.' END
						ELSE '' END	
			WHEN ifd.FieldName = 'SCRAP' THEN
				    CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE WHEN (LEN(f.Adjusted)<8)
									THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
										THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(7,0))<0)
												THEN 'SCRAP can not be negative.' ELSE '' END
										ELSE 'SCRAP is not numeric value.' END   
							ELSE 'SCRAP length can not be greater than 6 digits.' END
						ELSE '' END	
			WHEN ifd.FieldName = 'SETUPSCRAP' THEN
				    CASE
					WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE WHEN (LEN(f.Adjusted)<8)
									THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
										THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(4,0))<0)
												THEN 'SETUPSCRAP can not be negative.' ELSE '' END
										ELSE 'SETUPSCRAP is not numeric value.' END   
							ELSE 'SETUPSCRAP length can not be greater than 4 digits.' END
						ELSE '' END
			WHEN ifd.FieldName = 'PUR_LTIME' THEN    
		       CASE    
				 WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)    
				  THEN CASE WHEN (LEN(f.Adjusted)<4)    
				     THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
						THEN CASE WHEN ( CONVERT(DECIMAL(3,0),f.Adjusted)  <0)   
								 THEN 'PUR_LTIME can not be negative.' ELSE '' END
				      ELSE 'PUR_LTIME is not numeric value.' END    
				 ELSE 'PUR_LTIME length can not be greater than 3 digits.'END    
		     ELSE '' END    
			WHEN ifd.FieldName = 'KIT_LTIME' THEN
			 CASE    
				 WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)    
				  THEN CASE WHEN (LEN(f.Adjusted)<4)    
				     THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
						THEN CASE WHEN ( CONVERT(DECIMAL(3,0),f.Adjusted)  <0)   
								 THEN 'KIT_LTIME can not be negative.' ELSE '' END
				      ELSE 'KIT_LTIME is not numeric value.' END    
				 ELSE 'KIT_LTIME length can not be greater than 3 digits.'END    
		     ELSE '' END    
			WHEN ifd.FieldName = 'PROD_LTIME' THEN
				 CASE    
				 WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)    
				  THEN CASE WHEN (LEN(f.Adjusted)<4)    
				     THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
						THEN CASE WHEN ( CONVERT(DECIMAL(3,0),f.Adjusted)  <0)   
								 THEN 'PROD_LTIME can not be negative.' ELSE '' END
				      ELSE 'PROD_LTIME is not numeric value.' END    
				 ELSE 'PROD_LTIME length can not be greater than 3 digits.'END    
		     ELSE '' END 
			WHEN ifd.FieldName = 'PULL_IN' THEN
			    CASE    
				 WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)    
				  THEN CASE WHEN (LEN(f.Adjusted)<4)    
				     THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
						THEN CASE WHEN ( CONVERT(DECIMAL(3,0),f.Adjusted)  <0)   
								 THEN 'PULL_IN can not be negative.' ELSE '' END
				      ELSE 'PULL_IN is not numeric value.' END    
				 ELSE 'PULL_IN length can not be greater than 3 digits.'END    
		     ELSE '' END 
			WHEN ifd.FieldName = 'PUSH_OUT' THEN
			   CASE    
				 WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)    
				  THEN CASE WHEN (LEN(f.Adjusted)<4)    
				     THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
						THEN CASE WHEN ( CONVERT(DECIMAL(3,0),f.Adjusted)  <0)   
								 THEN 'PUSH_OUT can not be negative.' ELSE '' END
				      ELSE 'PUSH_OUT is not numeric value.' END    
				 ELSE 'PUSH_OUT length can not be greater than 3 digits.'END    
		     ELSE '' END 
			WHEN ifd.FieldName = 'DAY' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						 THEN CASE WHEN (isnumeric(f.Adjusted)=1)
							THEN CASE WHEN LEN(f.Adjusted)<2
								THEN CASE WHEN (LEN(f.Adjusted)<2 AND (CAST(f.Adjusted AS NUMERIC(1,0))<1 OR CAST(f.Adjusted AS NUMERIC(1,0))>6))
									THEN 'In DAY you can enter only Mon-Sat values i.e. 1-6.' ELSE '' END
								ELSE 'DAY can not be greater than 1 digits.'END
							ELSE 'DAY / DAYOFMO / DAYOFMO2 has to be a numeric value.' END
						ELSE '' END
			WHEN ifd.FieldName = 'DAYOFMO' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						 THEN CASE  WHEN (isnumeric(f.Adjusted)=1)
						 THEN CASE WHEN LEN(f.Adjusted)<3
						 			THEN CASE WHEN (LEN(f.Adjusted)<3 AND (CAST(f.Adjusted AS NUMERIC(2,0))<1 OR CAST(f.Adjusted AS NUMERIC(2,0))>31))
						 				THEN 'DAYOFMO day of month can have value between 1 to 31 only.' ELSE ''END
								ELSE 'DAYOFMO can not be greater than 2 digits.'END
						 	ELSE 'DAY / DAYOFMO / DAYOFMO2 has to be a numeric value.'END
						ELSE '' END
			WHEN ifd.FieldName = 'DAYOFMO2' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						 THEN CASE  WHEN (isnumeric(f.Adjusted)=1)
						  THEN CASE WHEN LEN(f.Adjusted)<3
						 			THEN CASE WHEN (LEN(f.Adjusted)<3 AND (CAST(f.Adjusted AS NUMERIC(2,0))<1 OR CAST(f.Adjusted AS NUMERIC(2,0))>31))
						 				THEN 'DAYOFMO2 day of month can have value between 1 to 31 only.' ELSE ''END
								ELSE 'DAYOFMO2 can not be greater than 2 digits.'END
						 	ELSE 'DAY / DAYOFMO / DAYOFMO2 has to be a numeric value.'END
						ELSE '' END
			WHEN ifd.FieldName = 'TARGETPRICE' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						 THEN CASE WHEN (LEN(f.Adjusted)<14)
						 		THEN CASE WHEN (isnumeric(f.Adjusted)=1)	
						 			THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(13,5))<0)
						 				THEN 'TARGETPRICE can not be negative.'ELSE '' END
						 		ELSE 'TARGETPRICE is not numeric value.'END
						 	ELSE 'TARGETPRICE length can not be greater than 13 digits.'END
					ELSE '' END
			WHEN ifd.FieldName = 'Taxable' THEN
				    CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN 'Entered the invalid data into Taxable.Values can be ( Y OR N ,YES OR NO ,True or False ,1 OR 0)'
								ELSE '' END
						ELSE '' END
			WHEN ifd.FieldName = 'STDCOST' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
					 	THEN CASE WHEN (LEN(f.Adjusted)<14)
					 			THEN CASE WHEN (isnumeric(f.Adjusted)=1)	
					 			  THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(13,5))<0)
					 					THEN 'STDCOST can not be negative.' ELSE '' END
					 			ELSE 'STDCOST is not numeric value.'END
					 		ELSE 'STDCOST length can not be greater than 13 digits.'END
						ELSE '' END
			WHEN ifd.FieldName = 'MATL_COST' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						 THEN CASE 
						 	WHEN (LEN(f.Adjusted)<14)
						 		THEN CASE WHEN(isnumeric(f.Adjusted)=1) 
						 		   THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(13,5))<0)
						 				THEN 'MATL_COST can not be negative.' ELSE '' END
						 			ELSE 'MATL_COST is not numeric value.' END
						 	ELSE 'MATL_COST length can not be greater than 13 digits.'END
						ELSE '' END
		WHEN ifd.FieldName = 'LABORCOST' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						 THEN CASE WHEN (LEN(f.Adjusted)<14)
						 		THEN CASE WHEN(isnumeric(f.Adjusted)=1) 
						 			THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(13,5))<0)
						 				THEN 'LABORCOST can not be negative.' ELSE '' END
						 			ELSE 'LABORCOST is not numeric value.' END
						 ELSE 'LABORCOST length can not be greater than 13 digits.'END
					ELSE '' END
		WHEN ifd.FieldName = 'OTHER_COST' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						 THEN CASE WHEN (LEN(f.Adjusted)<14)
						 	THEN CASE WHEN(isnumeric(f.Adjusted)=1) 
						 		THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(13,5))<0)
						 				THEN 'OTHER_COST can not be negative.'ELSE '' END
						 		ELSE 'OTHER_COST is not numeric value.' END
						 ELSE 'OTHER_COST length can not be greater than 13 digits.'END
					ELSE '' END
		WHEN ifd.FieldName = 'OTHERCOST2' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						 THEN CASE WHEN (LEN(f.Adjusted)<14)
						 	THEN CASE WHEN(isnumeric(f.Adjusted)=1) 
						 		THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(13,5))<0)
						 				THEN 'OTHER_COST2 can not be negative.' ELSE '' END
						 		ELSE 'OTHER_COST2 is not numeric value.' END
						 ELSE 'OTHER_COST2 length can not be greater than 13 digits.'END
					ELSE '' END
		WHEN ifd.FieldName = 'OVERHEAD' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
								THEN CASE WHEN (LEN(f.Adjusted)<14)
									THEN CASE WHEN(isnumeric(f.Adjusted)=1) 
										THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(13,5))<0)
												THEN 'OVERHEAD can not be negative.' ELSE '' END
										ELSE 'OVERHEAD is not numeric value.' END
								ELSE 'OVERHEAD length can not be greater than 13 digits.'END
						ELSE '' END
		WHEN ifd.FieldName = 'AUTONUM' THEN
				    CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN 'Entered the invalid data into AUTONUM.Values can be ( Y OR N ,YES OR NO ,True or False ,1 OR 0)'
								ELSE '' END
						ELSE '' END
		WHEN ifd.FieldName = 'AUTOLOCATION' THEN
				    CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN 'Entered the invalid data into AUTOLOCATION.Values can be ( Y OR N ,YES OR NO ,True or False ,1 OR 0)'
								ELSE '' END
						ELSE '' END
		WHEN ifd.FieldName = 'LOTDETAIL' THEN
				   CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN 'Entered the invalid data into LOTDETAIL.Values can be ( Y OR N ,YES OR NO ,True or False ,1 OR 0)'
								ELSE '' END
							ELSE '' END
		WHEN ifd.FieldName = 'AUTODT' THEN
				   CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN 'Entered the invalid data into AUTODT.Values can be ( Y OR N ,YES OR NO ,True or False ,1 OR 0)'
								ELSE '' END
							ELSE '' END
		WHEN ifd.FieldName = 'FGIEXPDAYS' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						 THEN CASE WHEN (LEN(f.Adjusted)<5)
						 	THEN CASE WHEN(isnumeric(f.Adjusted)=1) 
						 		THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(4,0))<0)
						 					THEN 'FGIEXPDAYS can not be negative.'ELSE '' END
						 	ELSE 'FGIEXPDAYS is not numeric value.' END
						 ELSE 'FGIEXPDAYS length can not be greater than 4 digits.'END
						ELSE '' END
		WHEN ifd.FieldName = 'UseCustPFX' THEN
				   CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN 'Entered the invalid data into UseCustPFX.Values can be ( Y OR N ,YES OR NO ,True or False ,1 OR 0)'
								ELSE '' END
							ELSE '' END
		--WHEN ifd.FieldName = 'Buyer' THEN
		--		   CASE
		--				WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL AND TRIM(f.Adjusted)<>(SELECT CAST(CAST(0 AS BINARY) AS UNIQUEIDENTIFIER)))
		--					THEN CASE 
		--						WHEN Cast(TRIM(f.Adjusted) AS UNIQUEIDENTIFIER) NOT IN 
		--						(SELECT DISTINCT users.UserId FROM aspnet_Profile AS pro
		--							INNER JOIN aspnet_Users AS users ON pro.UserId=users.UserId
		--							LEFT JOIN aspmnx_groupUsers AS guser ON pro.UserId=guser.fkuserid
		--							LEFT JOIN aspmnx_GroupRoles AS groles ON guser.fkgroupid=groles.fkGroupId
		--							LEFT JOIN aspnet_Roles AS roles ON groles.fkRoleId=roles.RoleId
		--							WHERE (roles.ModuleId=@ModuleId AND roles.RoleName IN ('ADD', 'EDIT')) OR pro.ScmAdmin=1 OR pro.CompanyAdmin=1
		--						)
		--							THEN 'Buyer is invalid please check the rights ADD or EDIT OR Admin Rights.'
		--						ELSE '' END
		--					ELSE '' END
		
		-- Added changes by MaheshB: 01-07-2020 Change the permissions from add/edit to Tools
		WHEN ifd.FieldName = 'Buyer' THEN
				   CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL AND TRIM(f.Adjusted)<>(SELECT CAST(CAST(0 AS BINARY) AS UNIQUEIDENTIFIER)))
							THEN CASE 
								--- 01/18/21 YS change wherevalidation of a buyer
								WHEN  CAST(TRIM(f.Adjusted) AS UNIQUEIDENTIFIER) NOT IN (SELECT G.fkuserid FROM AspMnx_GroupUsers G 
								INNER JOIN AspMnx_GroupRoles r  on g.FkGroupId=r.fkGroupId 
								INNER JOIN aspnet_Roles aspneRoles on r.fkRoleId=aspneRoles.RoleId   
								WHERE aspneRoles.ModuleId = 25 and ifd.FieldName='Buyer' 
								AND ((aspneRoles.RoleName='Add' OR aspneRoles.RoleName='Edit')))
							THEN 'Invalid buyer.'
							ELSE '' END
						ELSE '' END
		   ELSE '' 
		END,

		[Status] = 
		CASE 
			
			WHEN ifd.FieldName = 'PART_CLASS' THEN
				    CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE WHEN (LEN(f.Adjusted)>8)
										THEN  'i05red' ELSE '' END
								ELSE 'i05red' END
			WHEN ifd.FieldName = 'CLASSDESCRIPTION' THEN
				    CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
									WHEN (LEN(f.Adjusted)>50)
										THEN'i05red'
									ELSE '' END
						ELSE '' END
			WHEN ifd.FieldName = 'PART_TYPE' THEN
				     CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN 
								CASE WHEN (LEN(TRIM(f.Adjusted)) > 8)
										THEN 'i05red'
									    ELSE ''END
						ELSE '' END
			WHEN ifd.FieldName = 'PREFIX' THEN
				    CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
									WHEN (LEN(f.Adjusted)>20)
										THEN'i05red'
									ELSE '' END
						ELSE '' END
			WHEN ifd.FieldName = '[DESCRIPTION]' THEN
				    CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
									WHEN (LEN(f.Adjusted)>100)
										THEN'i05red'
									ELSE '' END
						ELSE '' END
			WHEN ifd.FieldName = 'USEIPKEY' THEN
				   CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN'i05red'
								ELSE '' END
							ELSE '' END
			WHEN ifd.FieldName = 'ALLOWAUTOKIT' THEN
				   CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN'i05red'
								ELSE '' END
							ELSE '' END
			WHEN  ifd.FieldName = 'U_OF_MEAS' THEN 
				 CASE
					WHEN TRIM(f.Adjusted) <> '' AND TRIM(f.Adjusted) IS NOT NULL
					  THEN CASE 
					         WHEN TRIM(f.Adjusted) NOT IN (SELECT LEFT(support.text,4) AS UOM FROM SUPPORT WHERE support.fieldname = 'U_OF_MEAS' )
								THEN 'i05red'
							 --WHEN (TRIM(f.Adjusted) NOT IN (SELECT [FROM] FROM UNIT) OR TRIM(f.Adjusted) NOT IN (SELECT [TO] FROM UNIT))
								--THEN 'i05red'
						     Else ''END
                       ELSE ''END
			WHEN  ifd.FieldName = 'PUR_UOFM' THEN 
				    CASE
						WHEN TRIM(f.Adjusted) <> '' AND TRIM(f.Adjusted) IS NOT NULL
							THEN CASE 
									WHEN LEN(f.Adjusted)<5
										THEN CASE
											WHEN TRIM(f.Adjusted) NOT IN (SELECT LEFT(support.text,4) AS UOM FROM SUPPORT WHERE support.fieldname = 'U_OF_MEAS' ) -- It is same for U_OF_MEAS
												THEN 'i05red'
											--WHEN (TRIM(f.Adjusted) NOT IN (SELECT [FROM] FROM UNIT) OR TRIM(f.Adjusted) NOT IN (SELECT [TO] FROM UNIT))
											--	THEN 'i05red'
											ELSE ''END
										ELSE 'i05red' END
						ELSE  '' END
			WHEN  ifd.FieldName = 'ORD_POLICY' THEN 
				   CASE 
						WHEN TRIM(f.Adjusted) <> '' AND TRIM(f.Adjusted) IS NOT NULL 
						 THEN CASE 
							WHEN LEN(f.Adjusted)<13
								THEN  CASE 
										WHEN TRIM(f.Adjusted) NOT IN ('Daily', 'Lot for Lot', 'Monthly', 'Quarterly', 'Semi-Monthly', 'Weekly')
						 					THEN 'i05red' 
										ELSE'' END 
								ELSE'i05red'END
					ELSE'' END 
		    WHEN  ifd.FieldName = 'CERT_TYPE' THEN 
				    CASE 
						WHEN TRIM(f.Adjusted) <> '' AND TRIM(f.Adjusted) IS NOT NULL 
						  THEN CASE 
								WHEN LEN(f.Adjusted)<13
									THEN	CASE 
										WHEN f.Adjusted NOT IN ('Receive', 'Ship', 'Both')
											THEN 'i05red' 
										ELSE ''END
								ELSE 'i05red'END
					ELSE '' END
			WHEN ifd.FieldName = 'PACKAGE' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN LEN(f.Adjusted)<16
								THEN CASE 
									WHEN TRIM(f.Adjusted) NOT IN (SELECT LEFT(TEXT,15) AS package FROM Support WHERE Fieldname = 'PART_PKG')
										THEN 'i05red'
									ELSE '' END
								ELSE 'i05red'END
					ELSE '' END	
			WHEN ifd.FieldName = 'WAREHOUSE' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE WHEN TRIM(f.Adjusted) IN  ('WIP', 'WO-WIP', 'MRB') 
											THEN 'i05red'
								ELSE 
									CASE WHEN TRIM(f.Adjusted) NOT IN (SELECT UNIQWH FROM WAREHOUS WHERE UNIQWH = f.Adjusted)
											THEN 'i05red'
										ELSE'' END
								END
							ELSE '' END
			WHEN ifd.FieldName = 'MRC' THEN
				   CASE
					WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						THEN CASE 
							WHEN TRIM(f.Adjusted) NOT IN (SELECT CAST(TRIM(LTRIM(Text)) AS Char(15)) AS Mrc FROM Support WHERE Fieldname = 'MRC')
								THEN 'i05red'
							ELSE '' END
						ELSE '' END
			WHEN ifd.FieldName = 'ABC' THEN
				   CASE
					WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						THEN CASE 
							WHEN  TRIM(f.Adjusted) NOT IN (SELECT ABC_TYPE FROM INVTABC)
								THEN 'i05red'
								ELSE '' END
					ELSE '' END
			WHEN ifd.FieldName = 'INSP_REQ' THEN
				   CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN 'i05red'
								ELSE '' END
							ELSE '' END
			WHEN ifd.FieldName = 'CERT_REQ' THEN
				   CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN 'i05red'
								ELSE '' END
							ELSE '' END
			WHEN ifd.FieldName = 'MINORD' THEN
				    CASE
						WHEN (f.Adjusted<>'' AND f.Adjusted IS NOT NULL)
							THEN CASE WHEN (LEN(f.Adjusted)<7)
								THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
									THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(7,0))<0)
										THEN 'i05red' ELSE '' END
										ELSE 'i05red' END    
						ELSE 'i05red' END
					ELSE ''END
			WHEN ifd.FieldName = 'ORDMULT' THEN
				   CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE WHEN (LEN(f.Adjusted)<8)
									THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
									THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(7,0))<0)
												THEN 'i05red' ELSE '' END
										ELSE 'i05red' END   
						ELSE 'i05red' END
					ELSE ''END
			WHEN ifd.FieldName = 'REORDPOINT' THEN
				CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						THEN CASE WHEN (LEN(f.Adjusted)<7)
									THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
										THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(7,0))<0)
													THEN 'i05red' ELSE '' END
										ELSE 'i05red' END    
					ELSE 'i05red' END
				  ELSE ''END
			WHEN ifd.FieldName = 'REORDERQTY' THEN
				    CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE WHEN (LEN(f.Adjusted)<8)
									THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
									THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(7,0))<0)
												THEN 'i05red' ELSE '' END
										ELSE 'i05red' END   
						ELSE 'i05red' END
					ELSE ''END
			WHEN ifd.FieldName = 'SCRAP' THEN
				     CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE WHEN (LEN(f.Adjusted)<8)
									THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
									THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(7,0))<0)
												THEN 'i05red' ELSE '' END
										ELSE 'i05red' END   
						ELSE 'i05red' END
					ELSE ''END
			WHEN ifd.FieldName = 'SETUPSCRAP' THEN
				    CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE WHEN (LEN(f.Adjusted)<8)
									THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
									THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(7,0))<0)
												THEN 'i05red' ELSE '' END
										ELSE 'i05red' END   
						ELSE 'i05red' END
					ELSE ''END
			WHEN ifd.FieldName = 'PUR_LTIME' THEN    
		       CASE    
				 WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)    
				  THEN CASE WHEN (LEN(f.Adjusted)<4)    
				     THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
						THEN CASE WHEN ( CONVERT(DECIMAL(3,0),f.Adjusted)  <0)   
								 THEN 'i05red' ELSE '' END
				      ELSE 'i05red' END    
				 ELSE 'i05red'END    
		     ELSE '' END    
			WHEN ifd.FieldName = 'KIT_LTIME' THEN
			 CASE    
				 WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)    
				  THEN CASE WHEN (LEN(f.Adjusted)<4)    
				     THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
						THEN CASE WHEN ( CONVERT(DECIMAL(3,0),f.Adjusted)  <0)   
								 THEN 'i05red' ELSE '' END
				      ELSE 'i05red' END    
				 ELSE 'i05red'END    
		     ELSE '' END    
			WHEN ifd.FieldName = 'PROD_LTIME' THEN
				 CASE    
				 WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)    
				  THEN CASE WHEN (LEN(f.Adjusted)<4)    
				     THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
						THEN CASE WHEN ( CONVERT(DECIMAL(3,0),f.Adjusted)  <0)   
								 THEN 'i05red' ELSE '' END
				      ELSE 'i05red' END    
				 ELSE 'i05red'END    
		     ELSE '' END 
			WHEN ifd.FieldName = 'PULL_IN' THEN
			    CASE    
				 WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)    
				  THEN CASE WHEN (LEN(f.Adjusted)<4)    
				     THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
						THEN CASE WHEN ( CONVERT(DECIMAL(3,0),f.Adjusted)  <0)   
								 THEN 'i05red' ELSE '' END
				      ELSE 'i05red' END    
				 ELSE 'i05red'END    
		     ELSE '' END 
			WHEN ifd.FieldName = 'PUSH_OUT' THEN
			   CASE    
				 WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)    
				  THEN CASE WHEN (LEN(f.Adjusted)<4)    
				     THEN CASE WHEN (isnumeric(f.Adjusted)=1)   
						THEN CASE WHEN ( CONVERT(DECIMAL(3,0),f.Adjusted)  <0)   
								 THEN 'i05red' ELSE '' END
				      ELSE 'i05red' END    
				 ELSE 'i05red'END    
		     ELSE '' END 
			WHEN ifd.FieldName = 'DAY' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						 THEN CASE WHEN (isnumeric(f.Adjusted)=1)
							THEN CASE WHEN LEN(f.Adjusted)<2
								THEN CASE WHEN (LEN(f.Adjusted)<2 AND (CAST(f.Adjusted AS NUMERIC(1,0))<1 OR CAST(f.Adjusted AS NUMERIC(1,0))>6))
									THEN 'i05red' ELSE '' END
								ELSE 'i05red'END
							ELSE 'i05red' END
						ELSE '' END
			WHEN ifd.FieldName = 'DAYOFMO' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						 THEN CASE  WHEN (isnumeric(f.Adjusted)=1)
						 THEN CASE WHEN LEN(f.Adjusted)<3
						 			THEN CASE WHEN (LEN(f.Adjusted)<3 AND (CAST(f.Adjusted AS NUMERIC(2,0))<1 OR CAST(f.Adjusted AS NUMERIC(2,0))>31))
						 				THEN 'i05red' ELSE ''END
								ELSE 'i05red'END
						 	ELSE 'i05red'END
						ELSE '' END
			WHEN ifd.FieldName = 'DAYOFMO2' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						 THEN CASE  WHEN (isnumeric(f.Adjusted)=1)
						  THEN CASE WHEN LEN(f.Adjusted)<3
						 			THEN CASE WHEN (LEN(f.Adjusted)<3 AND (CAST(f.Adjusted AS NUMERIC(2,0))<1 OR CAST(f.Adjusted AS NUMERIC(2,0))>31))
						 				THEN 'i05red' ELSE ''END
								ELSE 'i05red'END
						 	ELSE 'i05red'END
						ELSE '' END
			WHEN ifd.FieldName = 'TARGETPRICE' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						 THEN CASE WHEN (LEN(f.Adjusted)<14)
						 		THEN CASE WHEN (isnumeric(f.Adjusted)=1)	
						 			THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(13,5))<0)
						 				THEN 'i05red'ELSE '' END
						 		ELSE 'i05red'END
						 	ELSE 'i05red'END
					ELSE '' END
			WHEN ifd.FieldName = 'Taxable' THEN
				    CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN 'i05red'
								ELSE '' END
						ELSE '' END
			WHEN ifd.FieldName = 'STDCOST' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
					 	THEN CASE WHEN (LEN(f.Adjusted)<14)
					 			THEN CASE WHEN (isnumeric(f.Adjusted)=1)	
					 			  THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(13,5))<0)
					 					THEN 'i05red' ELSE '' END
					 			ELSE 'i05red'END
					 		ELSE 'i05red'END
						ELSE '' END
			WHEN ifd.FieldName = 'MATL_COST' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						 THEN CASE 
						 	WHEN (LEN(f.Adjusted)<14)
						 		THEN CASE WHEN(isnumeric(f.Adjusted)=1) 
						 		   THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(13,5))<0)
						 				THEN 'i05red' ELSE '' END
						 			ELSE 'i05red' END
						 	ELSE 'i05red'END
					ELSE '' END
			WHEN ifd.FieldName = 'LABORCOST' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						 THEN CASE WHEN (LEN(f.Adjusted)<14)
						 		THEN CASE WHEN(isnumeric(f.Adjusted)=1) 
						 			THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(13,5))<0)
						 				THEN 'i05red' ELSE '' END
						 			ELSE 'i05red' END
						 ELSE 'i05red'END
					ELSE '' END
			WHEN ifd.FieldName = 'OTHER_COST' THEN
					   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							 THEN CASE WHEN (LEN(f.Adjusted)<14)
							 	THEN CASE WHEN(isnumeric(f.Adjusted)=1) 
							 		THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(13,5))<0)
							 				THEN 'i05red'ELSE '' END
							 		ELSE 'i05red' END
							 ELSE 'i05red'END
						ELSE '' END
			WHEN ifd.FieldName = 'OTHERCOST2' THEN
					   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							 THEN CASE WHEN (LEN(f.Adjusted)<14)
							 	THEN CASE WHEN(isnumeric(f.Adjusted)=1) 
							 		THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(13,5))<0)
							 				THEN 'i05red' ELSE '' END
							 		ELSE 'i05red' END
							 ELSE 'i05red'END
						ELSE '' END
			WHEN ifd.FieldName = 'OVERHEAD' THEN
					   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
									THEN CASE WHEN (LEN(f.Adjusted)<14)
										THEN CASE WHEN(isnumeric(f.Adjusted)=1) 
											THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(13,5))<0)
													THEN 'i05red' ELSE '' END
											ELSE 'i05red' END
									ELSE 'i05red'END
							ELSE '' END
			WHEN ifd.FieldName = 'AUTONUM' THEN
				    CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN 'i05red'
								ELSE '' END
						ELSE '' END
		WHEN ifd.FieldName = 'AUTOLOCATION' THEN
				    CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN 'i05red'
								ELSE '' END
						ELSE '' END
		WHEN ifd.FieldName = 'LOTDETAIL' THEN
				   CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN'i05red'
								ELSE '' END
							ELSE '' END
		WHEN ifd.FieldName = 'AUTODT' THEN
				   CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN'i05red'
								ELSE '' END
							ELSE '' END
		WHEN ifd.FieldName = 'FGIEXPDAYS' THEN
				   CASE WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
						 THEN CASE WHEN (LEN(f.Adjusted)<5)
						 	THEN CASE WHEN(isnumeric(f.Adjusted)=1) 
						 		THEN CASE WHEN (CAST(f.Adjusted AS NUMERIC(4,0))<0)
						 					THEN 'i05red'ELSE '' END
						 	ELSE 'i05red' END
						 ELSE 'i05red'END
					ELSE '' END
		WHEN ifd.FieldName = 'UseCustPFX' THEN
				   CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL)
							THEN CASE 
								WHEN  TRIM(f.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
									THEN'i05red'
								ELSE '' END
							ELSE '' END
		-- Added changes by MaheshB: 01-07-2020 Change the permissions from add/edit to Tools
		WHEN ifd.FieldName = 'Buyer' THEN
				   CASE
						WHEN (TRIM(f.Adjusted)<>'' AND TRIM(f.Adjusted) IS NOT NULL AND TRIM(f.Adjusted)<>(SELECT CAST(CAST(0 AS BINARY) AS UNIQUEIDENTIFIER)))
							THEN CASE 
								--- 01/18/21 YS change wherevalidation of a buyer
								WHEN  CAST(TRIM(f.Adjusted) AS UNIQUEIDENTIFIER) NOT IN (SELECT G.fkuserid FROM AspMnx_GroupUsers G 
								INNER JOIN AspMnx_GroupRoles r  on g.FkGroupId=r.fkGroupId 
								INNER JOIN aspnet_Roles aspneRoles on r.fkRoleId=aspneRoles.RoleId   
								WHERE aspneRoles.ModuleId = 25 and ifd.FieldName='Buyer' 
								AND ((aspneRoles.RoleName='Add' OR aspneRoles.RoleName='Edit')))
									THEN 'i05red'
								ELSE '' END
							ELSE '' END
	ELSE '' END	
	FROM importPartClassTypeFields f 
	JOIN ImportFieldDefinitions ifd  ON f.FKFieldDefId =ifd.FieldDefId AND ModuleId = @ModuleId
	JOIN importPartClassTypeInfo ai  ON f.FKImportTemplateId =ai.ImportTemplateId
	JOIN importPartClassTypeHeader h  ON f.FkImportId =h.ImportId
	LEFT JOIN @ImportDetail impt ON f.RowId = impt.RowId                   
	WHERE ((@RowId IS NULL OR f.RowId=@RowId) AND ifd.UploadType='PartClassTypeUpload')
END