-- =============================================
-- Author: David Sharp
-- Create date: 4/26/2012
-- Description: imports the XML file to SQL table
-- =============================================
CREATE PROCEDURE [dbo].[importBOMUploadXMLBase]
-- Add the parameters for the stored procedure here
@importId uniqueidentifier,
@userId uniqueidentifier,
@x xml
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here
	/* If import ID is not provided, create a new is */
	IF (@importId IS NULL) SET @importId = NEWID()
	/* Get user initials for the header */
	DECLARE @userInit varchar(5)
	SELECT @userInit = Initials FROM aspnet_Profile WHERE userId = @userId
	
	DECLARE @lRollback bit=0,@headerErrs varchar(MAX),@partErrs varchar(MAX),@refErrs varchar(MAX),@avlErrs varchar(MAX)
	BEGIN TRY  -- outside begin try
    BEGIN TRANSACTION -- wrap transaction
		/* Declare import table variables */
		/**************************************/
		------/* I used a temp table instead of a table variable specifically so I can use NEWSEQUENTIALID and force the items in order */
		------/**************************************/
		------CREATE TABLE #importBOMTemp (rowId uniqueidentifier DEFAULT NEWSEQUENTIALID() PRIMARY KEY,itemno varchar(MAX),used varchar(MAX),partSource varchar(MAX),
		------	qty varchar(MAX),custPartNo varchar(MAX),crev varchar(MAX),descript varchar(MAX),u_of_m varchar(MAX),partClass varchar(MAX),partType varchar(MAX),
		------	warehouse varchar(MAX),partNo varchar(MAX),rev varchar(MAX),workCenter varchar(MAX),standardCost varchar(MAX),bomNote varchar(MAX),invNote varchar(MAX),
		------	refDesg varchar(MAX),partMfg varchar(MAX),mpn varchar(MAX),matltype varchar(MAX),custno varchar(MAX),assynum varchar(MAX),assyrev varchar(MAX),
		------	assydesc varchar(MAX))
		/*The table variable is a temporary holder to allow for all xml records to be loaded (including AVL and ref Desg)*/
		DECLARE @holderTable TABLE (itemno varchar(MAX),used varchar(MAX),partSource varchar(MAX),
			qty varchar(MAX),custPartNo varchar(MAX),crev varchar(MAX),descript varchar(MAX),u_of_m varchar(MAX),partClass varchar(MAX),partType varchar(MAX),
			warehouse varchar(MAX),partNo varchar(MAX),rev varchar(MAX),workCenter varchar(MAX),standardCost varchar(MAX),bomNote varchar(MAX),invNote varchar(MAX),
			refDesg varchar(MAX),partMfg varchar(MAX),mpn varchar(MAX),matltype varchar(MAX),custno varchar(MAX),assynum varchar(MAX),assyrev varchar(MAX),assydesc varchar(MAX),
			rowNum int)
		DECLARE @tempTable TABLE (itemno varchar(MAX),used varchar(MAX),partSource varchar(MAX),
			qty varchar(MAX),custPartNo varchar(MAX),crev varchar(MAX),descript varchar(MAX),u_of_m varchar(MAX),partClass varchar(MAX),partType varchar(MAX),
			warehouse varchar(MAX),partNo varchar(MAX),rev varchar(MAX),workCenter varchar(MAX),standardCost varchar(MAX),bomNote varchar(MAX),invNote varchar(MAX),
			refDesg varchar(MAX),partMfg varchar(MAX),mpn varchar(MAX),matltype varchar(MAX),custno varchar(MAX),assynum varchar(MAX),assyrev varchar(MAX),assydesc varchar(MAX))
		/* Set class and validation for easier update if we change methods later */
		DECLARE @skipped varchar(20)='i00skipped',@white varchar(20)='i00white',@fade varchar(20)='i02fade',@blue varchar(20)='i03blue',@orange varchar(20)='i04orange',
			@sys varchar(20)='00system',@none varchar(20)='00none'
		/* Parse BOM records and insert into table variable */
		INSERT INTO @tempTable(itemno,used,partSource,qty,custPartNo,crev,descript,u_of_m,partClass,partType,warehouse,partNo,rev,
				workCenter,standardCost,bomNote,invNote,refDesg,partMfg,mpn,matltype,custno,assynum,assyrev,assydesc)
			SELECT x.importBom.query('itemno/text()').value('.','VARCHAR(MAX)') itemno,
					UPPER(x.importBom.query('used/text()').value('.', 'VARCHAR(MAX)')) used,
					UPPER(x.importBom.query('partSource/text()').value('.', 'VARCHAR(MAX)')) partSource,
					x.importBom.query('qty/text()').value('.', 'VARCHAR(MAX)') qty,
					x.importBom.query('custPartNo/text()').value('.', 'VARCHAR(MAX)') custPartNo,
					x.importBom.query('crev/text()').value('.', 'VARCHAR(MAX)')crev,
					x.importBom.query('descript/text()').value('.', 'VARCHAR(MAX)')descript,
					UPPER(x.importBom.query('u_of_m/text()').value('.', 'VARCHAR(MAX)'))u_of_m,
					UPPER(x.importBom.query('partClass/text()').value('.', 'VARCHAR(MAX)'))partClass,
					UPPER(x.importBom.query('partType/text()').value('.', 'VARCHAR(MAX)'))partType,
					x.importBom.query('warehouse/text()').value('.', 'VARCHAR(MAX)')warehouse,
					x.importBom.query('partNo/text()').value('.', 'VARCHAR(MAX)')partNo,
					x.importBom.query('rev/text()').value('.', 'VARCHAR(MAX)')rev,
					UPPER(x.importBom.query('workCenter/text()').value('.', 'VARCHAR(MAX)'))workCenter,
					x.importBom.query('standardCost/text()').value('.', 'VARCHAR(MAX)')standardCost,
					x.importBom.query('bomNote/text()').value('.', 'VARCHAR(MAX)')bomNote,
					x.importBom.query('invNote/text()').value('.', 'VARCHAR(MAX)')invNote,
					x.importBom.query('refDesg/text()').value('.', 'VARCHAR(MAX)')refDesg,
					UPPER(x.importBom.query('mfg/text()').value('.', 'VARCHAR(MAX)'))mfg,
					x.importBom.query('mpn/text()').value('.', 'VARCHAR(MAX)')mpn,
					x.importBom.query('matltype/text()').value('.', 'VARCHAR(MAX)')matltype,
					x.importBom.query('custno/text()').value('.', 'VARCHAR(MAX)')custno,
					x.importBom.query('assynum/text()').value('.', 'VARCHAR(MAX)')assynum,
					x.importBom.query('assyrev/text()').value('.', 'VARCHAR(MAX)')assyrev,
					x.importBom.query('assydesc/text()').value('.', 'VARCHAR(MAX)')assydesc
				FROM @x.nodes('/Root/Row') AS X(importBom)
				OPTION (OPTIMIZE FOR(@x = NULL))
		
		INSERT INTO @holderTable(rowNum,itemno,used,partSource,qty,custPartNo,crev,descript,u_of_m,partClass,partType,warehouse,partNo,rev,
				workCenter,standardCost,bomNote,invNote,refDesg,partMfg,mpn,matltype,custno,assynum,assyrev,assydesc)
		SELECT DENSE_RANK() OVER(ORDER BY CAST(itemno AS INT),descript) ,itemno,used,partSource,qty,custPartNo,crev,descript,u_of_m,partClass,partType,warehouse,partNo,rev,
				workCenter,standardCost,bomNote,invNote,refDesg,partMfg,mpn,matltype,custno,assynum,assyrev,assydesc
			FROM @tempTable
			ORDER BY itemno
		
		/* Create a unique list of parts filtering out duplicate rows for multiple AVLS and ref desg*/
		INSERT INTO importBOMTempParts (importId,itemno,used,partSource,qty,custPartNo,crev,descript,u_of_m,partClass,partType,warehouse,partNo,rev,
				workCenter,standardCost,bomNote,invNote,rowNum)
			SELECT DISTINCT @importId,itemno,used,partSource,qty,custPartNo,crev,descript,u_of_m,partClass,partType,warehouse,partNo,rev,
				workCenter,standardCost,bomNote,invNote,rowNum
				FROM @holderTable
				GROUP BY itemno,used,partSource,qty,custPartNo,crev,descript,u_of_m,partClass,partType,warehouse,partNo,rev,
				workCenter,standardCost,bomNote,invNote,rowNum
				ORDER BY rowNum
		/*Temp Header*/
		INSERT INTO importBOMTempHeader(importId,custno,assynum,assyrev,assydesc)
		SELECT DISTINCT @importId,custno,assynum,assyrev,assydesc FROM @holderTable
		
		/*AVL*/
		INSERT INTO importBOMTempAvl(importId,partMfg,mpn,matlType,rowId)
		SELECT DISTINCT @importId,h.partMfg,h.mpn,h.matlType,p.rowId
			FROM @holderTable h inner join importBOMTempParts p ON h.rowNum=p.rowNum AND p.importId=@importId
			WHERE h.partMfg<>''
			GROUP BY h.partMfg,h.mpn,h.matlType,p.rowId
		
		/*RefDesg*/
		INSERT INTO importBOMTempRefs(importId,refDesg,rowId)
		SELECT DISTINCT @importId,h.refDesg,p.rowId
			FROM @holderTable h inner join importBOMTempParts p ON h.rowNum=p.rowNum AND p.importId=@importId
			WHERE h.refDesg<>''
			GROUP BY h.refDesg,p.rowId
		
			
		----/*
		----	BOM HEADER
		----	Get the assembly number it from the import xml file.
		----*/	
		----BEGIN TRY -- inside begin try
		----	DECLARE @assyNum varchar(max),@assyRev varchar(max),@assyDesc varchar(max),@custNo varchar(max)
		----	SELECT @assyNum = assynum, @assyRev = assyrev, @assyDesc = assydesc,@custNo=CASE WHEN custno = '' THEN '000000000~' ELSE RIGHT('0000000000'+custno,10)END FROM #importBOMTemp
			
		----	/* Match existing assembly record */
		----	DECLARE @eUniq_key varchar(10)='',@partSource varchar(50)='MAKE',@partClass varchar(50)='FGI',@partType varchar(50)='ALL',@eCustno varchar(10),@msg varchar(MAX)=''
		----	/* Find by matching internal part number - check by customer number is last because it has priority */
		----	SELECT @eUniq_key=UNIQ_KEY FROM INVENTOR WHERE rtrim(ltrim(PART_NO))=rtrim(ltrim(@assyNum))AND rtrim(ltrim(REVISION))=rtrim(ltrim(@assyRev))
		----	IF @eUniq_key<>'' SELECT @partSource=PART_SOURC,@assyDesc=DESCRIPT,@partClass=PART_CLASS,@partType=PART_TYPE,@eCustno=BOMCUSTNO FROM INVENTOR WHERE UNIQ_KEY=@eUniq_key
		----	/* Find by matching customer part number - putting it last makes it the preference */
		----	SELECT @eUniq_key=INT_UNIQ FROM INVENTOR WHERE rtrim(ltrim(CUSTPARTNO))=rtrim(ltrim(@assyNum))AND rtrim(ltrim(CUSTREV))=rtrim(ltrim(@assyRev))
		----	IF @eUniq_key<>'' SELECT @partSource=PART_SOURC,@assyDesc=DESCRIPT,@partClass=PART_CLASS,@partType=PART_TYPE,@eCustno=BOMCUSTNO FROM INVENTOR WHERE UNIQ_KEY=@eUniq_key
		----	IF @custNo<>'' AND @custNo<>@eCustno
		----	BEGIN
		----		SET @custNo=@eCustno 
		----		SET @msg='Assembly and Rev exist under another customer.  Assigned customer was adjusted.'
		----	END
			
		----	EXEC importBOMHeaderAdd @importId,@userInit,@partSource,'NEW',NULL,'',@custNo,@assyNum,@assyRev,@assyDesc,@partClass,@partType,@eUniq_key,@msg
		----END TRY
		----BEGIN CATCH	
		----	SET @headerErrs = 'There are issues with the header information while trying to load ASSY: '+@assyNum+', REV: '+@assyRev+', DESC: '+@assyDesc
		----END CATCH
		
		
		----/*
		----	PART RECORDS
		----	Unpivot the temp table and insert into importBOMFields
		----*/
		----BEGIN TRY -- inside begin try
		----	INSERT INTO importBOMFields (fkImportId,fkFieldDefId,rowId,original,adjusted)
		----		SELECT @importId,fd.fieldDefId,u.rowId,u.adjusted,u.adjusted
		----			FROM(
		----				SELECT rowId,[itemno],[used],[partSource],[partClass],[partType],[qty],[custPartNo],[cRev],[descript],[u_of_m],[warehouse],
		----					[standardCost],[workCenter],[partno],[rev],[bomNote],[invNote]
		----					FROM #importBOMTemp)p
		----				UNPIVOT
		----				(adjusted FOR fieldName IN
		----					([itemno],[used],[partSource],[partClass],[partType],[qty],[custPartNo],[cRev],[descript],[u_of_m],[warehouse],[standardCost],[workCenter],[partno],[rev],[bomNote],[invNote])
		----					) AS u
		----				INNER JOIN importBOMFieldDefinitions fd ON fd.fieldName = u.fieldName
		----	/* Update import fields with the default value if none were provided */
		----	UPDATE i
		----		SET i.adjusted=fd.[default],i.[status]=@blue,i.[message]='Default Value',i.[validation]=@sys
		----		FROM importBOMFieldDefinitions fd INNER JOIN importBOMFields i ON i.fkFieldDefId=fd.fieldDefId WHERE i.adjusted='' AND fd.[default]<>'' AND i.fkImportId=@importId
		----END TRY
		----BEGIN CATCH	
		----	SET @partErrs = 'There are issues with loading part records.  No additional information available.  Please review the spreadsheet before trying again.'
		----END CATCH		
		
		----/*
		----	REF DESG
		----	This has to run via cursor because the function works on only 1 string at a time.
		----*/
		----BEGIN TRY -- inside begin try
		----	DECLARE @rowId uniqueidentifier,@refString varchar(max)
		----	BEGIN
		----		DECLARE rt_cursor CURSOR LOCAL FAST_FORWARD
		----		FOR
		----		SELECT it.rowId,ht.refDesg
		----			FROM #importBOMTemp it inner join @holderTable ht 
		----				ON it.itemno=ht.itemno AND it.partNo=ht.partNo AND it.rev=ht.rev AND it.custPartNo=ht.custPartNo AND it.crev=ht.crev AND it.descript=ht.descript
		----			WHERE ht.refDesg <>''
		----			GROUP BY it.rowId,ht.refDesg
		----		OPEN rt_cursor;
		----	END
		----	FETCH NEXT FROM rt_cursor INTO @rowId,@refString
		----	WHILE @@FETCH_STATUS = 0
		----	BEGIN
		----		BEGIN TRY 
		----			INSERT INTO importBOMRefDesg(fkImportId,fkRowId,refDesg)
		----			SELECT DISTINCT @importId,rowId,ref FROM dbo.fn_parseRefDesgString(@rowId,@refString,',','-')
		----			FETCH NEXT FROM rt_cursor INTO @rowId,@refString
		----		END TRY
		----		BEGIN CATCH	
		----			SET @refErrs = COALESCE(@refErrs+', ','')
		----		END CATCH	
		----	END
		----	CLOSE rt_cursor
		----	DEALLOCATE rt_cursor
		----	IF @refErrs<>'' SET @refErrs = 'There following refDesg values are creating issues with the import: ' + @refErrs 
		----END TRY
		----BEGIN CATCH	
		----	SET @refErrs = 'Unknown Error while importing refDesg.  Please review the values before proceeding.'
		----END CATCH	

		----/*
		----	AVL
		----*/
		----BEGIN TRY -- inside begin try
		----	INSERT INTO importBOMAvl(fkImportId,fkFieldDefId,fkRowId,avlRowId,adjusted,original,[load])
		----		SELECT @importId,fd.fieldDefId,u.rowId,u.iRowId,u.adjusted,u.adjusted,1
		----			FROM(
		----			SELECT it.rowId,ht.[partMfg],ht.[mpn],ht.[matlType],max(cast(ht.iRowId as varchar(50)))iRowId
		----				FROM #importBOMTemp it INNER JOIN @holderTable ht 
		----				ON it.itemno=ht.itemno AND it.partNo=ht.partNo AND it.rev=ht.rev AND it.custPartNo=ht.custPartNo AND it.crev=ht.crev AND it.descript=ht.descript
		----				GROUP BY it.rowId,it.rowId,ht.[partMfg],ht.[mpn],ht.[matlType]
		----			)p
		----			UNPIVOT
		----			(adjusted FOR fieldName IN
		----			([partMfg],[mpn],[matlType])
		----			) AS u
		----			INNER JOIN importBOMFieldDefinitions fd ON fd.fieldName = u.fieldName
			
		----	--SELECT * FROM importBOMAvl WHERE fkImportId=@importId
		----	/* Update import fields with the default value if none were provided */
		----	UPDATE i
		----		SET i.adjusted=fd.[default],i.[status]=@blue,i.[message]='Default Value',i.[validation]=@sys
		----		FROM importBOMFieldDefinitions fd INNER JOIN importBOMAvl i ON i.fkFieldDefId=fd.fieldDefId WHERE i.adjusted='' AND fd.[default]<>'' AND i.fkImportId=@importId

		----END TRY
		----BEGIN CATCH	
		----	SET @avlErrs = 'Unknown Error while importing AVL info.  Please review the values before proceeding.'
		----END CATCH	
				
	COMMIT
	--DROP TABLE #importBOMTemp
	
	END TRY
	BEGIN CATCH
		SET @lRollback=1
		SELECT 'Problems uploading file' AS uploadError
		ROLLBACK
		RETURN -1
	END CATCH	
END