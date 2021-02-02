-- =============================================                  
-- Author: David Sharp                  
-- Create date: 4/26/2012                  
-- Description: imports the XML file to SQL table                  
-- 06/03/13 YS modifications to fn_parseRefDesgString() function                  
-- 07/12/13 DS Grouped all RefDesg by row before parsing                  
-- 02/12/14 DS Removed Default AVL.  This should be moved to FullComplete                  
-- 02/19/14 DS skipped AVLs without a MFG                  
-- 03/09/15 DS added make_buy field                  
---12/06/17 YS make sure that qty is not saved with scientific notation                  
-- 6/19/2017 : Shripati : IsFlagged & IsSystemNote columns no longer in used                  
-- 02/24/18: Vijay G: Replaced the bomitem element name MFG by PARTMFG                  
-- 03/06/2018 : Vijay G : Passed the @NoteCategory parameter to MnxNotesAdd SP                  
-- 03/06/2018 : Vijay G : Add a Invt note and bom item note for assembly component                  
-- 11/14/2018 : Vijay G : Remove the Standard price customer '000000000~' and keep the field as empty                
-- 11/20/2018 : Vijay G Remove the hard coded assembly partclass(FGI) and partType(PC-ASY)          
-- 12/12/2018 : Vijay G Fix the Default warehouse Issue          
-- 12/27/2018 : Vijay G : Cust Name Not Populated First time          
-- 01/04/2018 : Vijay G : Fix the Issue the BOM Header become black if user not provided custno          
-- 01/17/2019 : Vijay G : Fix the Assembly is not getting Customer if it is already exists and user not providing custno from excel sheet          
-- 01/18/2019 : Vijay G : Fix the Issue the Part_Source of Assembly become CONSG Add AND CUSTNO =''          
-- 01/18/2019 : Vijay G : Add And Condition AND @eCustno<>''          
-- 01/21/2019 : Sachin B: Update the Customer if the BOM_Det Table Don't have component          
-- 01/24/2019 : Sachin B: Remove the Assemblies Default warehouse use logic          
-- 01/24/2019 : Sachin B: Use the BOM Comp Part Class Warehouse if Not then Use Default Warehouse and Also If Comp Part_Class and Warehouse both are Empty then also use Default Warehouse          
-- 01/30/2019 : Sachin B: Remove Logic From this SP Used the Same logic in importBOMVldtnCheckManExNumAll because when score is set the Part_Class are updated by system          
-- 01/30/2018 Sachin B Fix the Issue the Part Component Default Warehouse Selection Does Not Apply the Default Warehouse use on the Basis of Part_Class add Parameter fieldName          
-- 05/15/2019 : Vijay G : Added two row in importbomdefinition table to save data in table i have added two more parameter as sid or serial              
-- 05/15/2019 : Vijay G : modify sp for insert order preference value for manufacturer            
-- 05/15/2019 : Vijay G : modify sp for not insert cust no in importbomheader table when invalid cust no is in template          
-- 05/21/2019 : Vijay G : change parameter name as useid for @startedBy column  to insert userid value in this column of calling importbomheaderAdd sp           
-- 05/21/2019 Vijay G: Add PartNo in the DENSE_RANK() function          
-- 05/24/2019 : Vijay G : modify sp for remove blue color of standard cost field if part not exist           
 --01/16/2020 Vijay G Replace name of columns/variable sid with mtc         
 --04/07/2020 : Sachin B : Commented unwanted code of note                
 --08/24/2020 : Sachin B : If Material type is found then Match with the setup as present       
 --09/18/2020 : Sachin B : Add Part Master Note geeting populated from excel sheet 
 --01/05/2021 : Sachin B : Add the Location and Add New Entry in the ImportBOMFields Table   
-- ====================================                      
CREATE PROCEDURE [dbo].[importBOMUploadXML]                
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
 DECLARE @ErrTable TABLE (ErrNumber int,ErrSeverity int,ErrProc varchar(MAX),ErrLine int,ErrMsg varchar(MAX))                  
 BEGIN TRY  -- outside begin try                  
    BEGIN TRANSACTION -- wrap transaction                  
  /* Declare import table variables */                  
  /**************************************/                  
                    
  /* Create two table variables.  1 - a unique list of parts to be loaded. 2 - all records passed by the xml */                  
  -- 05/15/2019 : Vijay G : Added two row in importbomdefinition table to save data in table i have added two more parameter as mtc or serial
  --01/05/2021 : Sachin B : Add the Location and Add New Entry in the ImportBOMFields Table                  
  DECLARE @partsTable TABLE (rowId uniqueidentifier DEFAULT NEWSEQUENTIALID() PRIMARY KEY,rowNum int, itemno varchar(MAX),used varchar(MAX),partSource varchar(MAX),make_buy varchar(MAX),                  
   qty varchar(MAX),custPartNo varchar(MAX),crev varchar(MAX),descript varchar(MAX),u_of_m varchar(MAX),partClass varchar(MAX),partType varchar(MAX),                  
   warehouse varchar(MAX),partNo varchar(MAX),rev varchar(MAX),workCenter varchar(MAX),standardCost varchar(MAX),bomNote varchar(MAX),invNote varchar(MAX),[mtc] varchar(MAX),              
   serial varchar(MAX),[location] VARCHAR(MAX))                      
                     
  DECLARE @tempTable TABLE (rowNum int,itemno varchar(MAX),used varchar(MAX),partSource varchar(MAX),make_buy varchar(MAX),                  
   qty varchar(MAX),custPartNo varchar(MAX),crev varchar(MAX),descript varchar(MAX),u_of_m varchar(MAX),partClass varchar(MAX),partType varchar(MAX),                  
   warehouse varchar(MAX),partNo varchar(MAX),rev varchar(MAX),workCenter varchar(MAX),standardCost varchar(MAX),bomNote varchar(MAX),invNote varchar(MAX),                  
   refDesg varchar(MAX),partMfg varchar(MAX),mpn varchar(MAX),matltype varchar(MAX), custno varchar(MAX),assynum varchar(MAX),assyrev varchar(MAX),assydesc varchar(MAX),              
   [mtc] varchar(MAX),serial varchar(MAX),preference varchar(MAX),[location] VARCHAR(MAX))                        
                     
  /* Set class and validation for easier update if we change methods later */                  
  DECLARE @skipped varchar(20)='i00skipped',@white varchar(20)='i00white',@fade varchar(20)='i02fade',@blue varchar(20)='i03blue',@orange varchar(20)='i04orange',                  
   @sys varchar(20)='00system',@none varchar(20)='00none'                  
  /* Parse BOM records and insert into table variable */         
 --01/16/2020 Vijay G Replace name of columns/variable sid with mtc                 
  INSERT INTO @tempTable(rowNum,itemno,used,partSource,make_buy,qty,custPartNo,crev,descript,u_of_m,partClass,partType,warehouse,partNo,rev,              
    workCenter,standardCost,bomNote,invNote,refDesg,partMfg,mpn,matltype,custno,assynum,assyrev,assydesc,[mtc],serial,preference,[location])                       
   SELECT DENSE_RANK() OVER(ORDER BY                   
     x.importBom.query('ITEMNO/text()').value('.','VARCHAR(MAX)')+                  
     x.importBom.query('DESCRIPT/text()').value('.', 'VARCHAR(MAX)')+          
  -- 05/21/2019 Vijay G: Add PartNo in the DENSE_RANK() function          
  x.importBom.query('PARTNO/text()').value('.', 'VARCHAR(MAX)'))rowNum,                    
     x.importBom.query('ITEMNO/text()').value('.','VARCHAR(MAX)') itemno,                  
     UPPER(x.importBom.query('USED/text()').value('.', 'VARCHAR(MAX)')) used,                  
     UPPER(x.importBom.query('PARTSOURCE/text()').value('.', 'VARCHAR(MAX)')) partSource,                  
     UPPER(x.importBom.query('MAKE_BUY/text()').value('.', 'VARCHAR(MAX)')) make_buy, /* 03/09/15 DS added make_buy field*/                  
     x.importBom.query('QTY/text()').value('.', 'VARCHAR(MAX)') qty,                  
     x.importBom.query('CUSTPARTNO/text()').value('.', 'VARCHAR(MAX)') custPartNo,                  
     x.importBom.query('CREV/text()').value('.', 'VARCHAR(MAX)')crev,                  
     x.importBom.query('DESCRIPT/text()').value('.', 'VARCHAR(MAX)')descript,                  
     UPPER(x.importBom.query('U_OF_M/text()').value('.', 'VARCHAR(MAX)'))u_of_m,                  
    UPPER(x.importBom.query('PARTCLASS/text()').value('.', 'VARCHAR(MAX)'))partClass,                  
     UPPER(x.importBom.query('PARTTYPE/text()').value('.', 'VARCHAR(MAX)'))partType,                  
     x.importBom.query('WAREHOUSE/text()').value('.', 'VARCHAR(MAX)')warehouse,                  
     x.importBom.query('PARTNO/text()').value('.', 'VARCHAR(MAX)')partNo,                  
     x.importBom.query('REV/text()').value('.', 'VARCHAR(MAX)')rev,                  
     UPPER(x.importBom.query('WORKCENTER/text()').value('.', 'VARCHAR(MAX)'))workCenter,                  
     x.importBom.query('STANDARDCOST/text()').value('.', 'VARCHAR(MAX)')standardCost,                  
     x.importBom.query('BOMNOTE/text()').value('.', 'VARCHAR(MAX)')bomNote,                  
     x.importBom.query('INVNOTE/text()').value('.', 'VARCHAR(MAX)')invNote,                  
     x.importBom.query('REFDESG/text()').value('.', 'VARCHAR(MAX)')refDesg,                  
     UPPER(x.importBom.query('PARTMFG/text()').value('.', 'VARCHAR(MAX)'))partmfg, -- 02/24/18: Vijay G: Replaced the bomitem element name MFG by PARTMFG                  
     x.importBom.query('MPN/text()').value('.', 'VARCHAR(MAX)')mpn,                  
     x.importBom.query('MATLTYPE/text()').value('.', 'VARCHAR(MAX)')matltype,                  
     x.importBom.query('CUSTNO/text()').value('.', 'VARCHAR(MAX)')custno,                  
     x.importBom.query('ASSYNUM/text()').value('.', 'VARCHAR(MAX)')assynum,                  
     x.importBom.query('ASSYREV/text()').value('.', 'VARCHAR(MAX)')assyrev,                  
     x.importBom.query('ASSYDESC/text()').value('.', 'VARCHAR(MAX)')assydesc,                
  x.importBom.query('MTC/text()').value('.', 'VARCHAR(MAX)')[mtc],                    
  x.importBom.query('SERIAL/text()').value('.', 'VARCHAR(MAX)')serial,              
  -- 05/15/2019 : Vijay G : modify sp for insert order preference value for manufacturer            
  x.importBom.query('PREFERENCE/text()').value('.','VARCHAR(MAX)')preference,    
  x.importBom.query('LOCATION/text()').value('.','VARCHAR(MAX)')location          
                   
    FROM @x.nodes('/Root/Row') AS X(importBom)                  
    OPTION (OPTIMIZE FOR(@x = NULL))            
           
 -- 12/12/2018 : Vijay G Fix the Default warehouse Issue          
 -- 01/24/2019 : Sachin B: Remove the Assemblies Default warehouse use logic          
 --DECLARE @defaultWarehouse CHAR(6) = (SELECT warehouse  FROM WAREHOUS WHERE [DEFAULT] =1)            
 --IF NOT EXISTS (SELECT warehouse  FROM WAREHOUS WHERE [DEFAULT] =1)           
 --BEGIN          
 --  SET @defaultWarehouse =''          
 --END            
              
  /* Create a unique list of parts filtering out duplicate rows for multiple AVLS and ref desg*/                  
  ---12/06/17 YS make sure that qty is not saved with scientific notation  
  --01/05/2021 : Sachin B : Add the Location and Add New Entry in the ImportBOMFields Table                
  INSERT INTO @partsTable(rowNum,itemno,used,partSource,make_buy,qty,custPartNo,crev,descript,u_of_m,partClass,partType,warehouse,partNo,rev,                  
    workCenter,standardCost,bomNote,invNote,              
  -- 05/15/2019 : Vijay G : Added two row in importbomdefinition table to save data in table i have added two more parameter as mtc or serial                
 [mtc],serial,location)                        
  SELECT rowNum,itemno,CASE WHEN used = 'TRUE' OR used = 'T' OR used = 'YES' OR used = 'Y' OR used = '1' THEN 'Y' ELSE used END used,partSource,                  
    CASE WHEN make_buy = 'TRUE' OR make_buy = 'T' OR make_buy = 'YES' OR make_buy = 'Y' OR make_buy = '1' THEN '1' ELSE '0' END make_buy,                  
    convert(varchar(max),convert(float(53),qty)),custPartNo,crev,descript,u_of_m,partClass,partType,          
 -- 12/12/2018 : Vijay G Fix the Default warehouse Issue          
 -- 01/24/2019 : Sachin B: Remove the Assemblies Default warehouse use logic          
 warehouse,          
 --CASE WHEN warehouse ='' THEN @defaultWarehouse          
 --ELSE warehouse END          
 partNo,rev,                  
    workCenter,standardCost,bomNote,invNote,            
 --05/15/2019 : Vijay G : Added two row in importbomdefinition table to save data in table i have added two more parameter as mtc or serial                
 CASE WHEN [mtc] is null OR [mtc] ='' THEN ISNULL(p.useIpkey,'0')              
 ELSE [mtc] END ,serial ,location                        
   FROM @tempTable t         LEFT JOIN PartClass p on p.part_class = t.partClass             
   GROUP BY rowNum,itemno,used,partSource,make_buy,qty,custPartNo,crev,descript,u_of_m,partClass,partType,warehouse,partNo,rev,                  
    workCenter,standardCost,bomNote,invNote,p.useIpkey,              
  -- 05/15/2019 : Vijay G : Added two row in importbomdefinition table to save data in table i have added two more parameter as mtc or serial                
 [mtc],serial,location                        
   ORDER BY Case                   
      When IsNumeric(itemno) = 1 then Right(Replicate('0',21) + itemno, 20)                  
      When IsNumeric(itemno) = 0 then Left(itemno + Replicate('',21), 20)                  
      Else itemno                  
     END                   
                    
  /* 07/02/13 DS Check to see if the assembly already has an active import and cancel if it does */                  
  -- 11/14/2018 : Vijay G : Remove the Standard price customer '000000000~' and keep the field as empty                
  DECLARE @assyNum varchar(max),@assyRev varchar(max),@assyDesc varchar(max),@custNo varchar(max),@existImportId uniqueidentifier,@existCount int              
            
    -- 12/27/2018 : Vijay G : Cust Name Not Populated First time          
    SELECT           
     @assyNum = assynum,          
  @assyRev = assyrev,          
  @assyDesc = assydesc,          
  @custNo=CASE WHEN custno = '' THEN '' ELSE RIGHT('0000000000'+custno,10)END           
 FROM @tempTable           
 -- 05/15/2019 : Vijay G : modify sp for not insert cust no in importbomheader table when invalid cust no is in template          
 IF NOT EXISTS(Select * FROM CUSTOMER WHERE CUSTNO =@custNo)          
 BEGIN          
    SET @custNo =''          
 UPDATE @tempTable SET custno =''          
 --UPDATE @partsTable SET custno =''          
 END          
            
 -- 01/04/2018 : Vijay G : Fix the Issue the BOM Header become black if user not provided custno          
 --WHERE custno<>''             
               
   SELECT @existImportId=importId,@existCount=COUNT(*)           
   FROM importBOMHeader          
   WHERE assyNum=@assyNum AND assyRev=@assyRev AND [status]<>'Loaded'           
   GROUP BY importId,startDate ORDER BY startDate                  
                    
  IF @existCount>0                  
   SELECT @existImportId AS existingId                  
  ELSE                  
  BEGIN                  
   /*                  
    BOM HEADER                  
    Get the assembly number it from the import xml file.                  
   */                   
   BEGIN TRY -- inside begin try                  
                      
    /* Match existing assembly record */                  
 -- 11/20/2018 : Vijay G Remove the hard coded assembly partclass(FGI) and partType(PC-ASY)          
    DECLARE @eUniq_key varchar(10)='',@partSource varchar(50)='MAKE',@partClass varchar(50)='',@partType varchar(50)='',@eCustno varchar(10),@msg varchar(MAX)=''                
    /* Find by matching internal part number - check by customer number is last because it has priority */                  
    SELECT           
     @eUniq_key=UNIQ_KEY           
 FROM INVENTOR           
 -- 01/18/2019 : Vijay G : Fix the Issue the Part_Source of Assembly become CONSG Add AND CUSTNO =''             
 WHERE rtrim(ltrim(PART_NO))=rtrim(ltrim(@assyNum))AND rtrim(ltrim(REVISION))=rtrim(ltrim(@assyRev))  AND CUSTNO =''                
              
 IF @eUniq_key<>''           
 BEGIN          
  SELECT            
   @partSource=PART_SOURC,          
   @assyDesc=DESCRIPT,          
   @partClass=PART_CLASS,          
   @partType=PART_TYPE,          
   @eCustno=BOMCUSTNO           
  FROM INVENTOR           
  WHERE UNIQ_KEY=@eUniq_key             
 END             
           
 -- 01/21/2019 : Sachin B: Update the Customer if the BOM_Det Table Don't have component          
    DECLARE @count INT = (SELECT COUNT(*) FROM BOM_DET WHERE BOMPARENT =@eUniq_key)            
              
 /* Find by matching customer part number - putting it last makes it the preference */                  
    SELECT @eUniq_key=INT_UNIQ FROM INVENTOR WHERE rtrim(ltrim(CUSTPARTNO))=rtrim(ltrim(@assyNum))AND rtrim(ltrim(CUSTREV))=rtrim(ltrim(@assyRev))                  
              
 IF @eUniq_key<>''           
 BEGIN          
  SELECT  @partSource=PART_SOURC,          
    @assyDesc=DESCRIPT,          
    @partClass=PART_CLASS,          
    @partType=PART_TYPE,          
    @eCustno=BOMCUSTNO           
  FROM INVENTOR           
WHERE UNIQ_KEY=@eUniq_key            
 END           
             
 -- 01/18/2019 : Vijay G : Add And Condition AND @eCustno<>''                
    IF @custNo<>'' AND @eCustno<>'' AND @custNo<>@eCustno AND @count>0                 
    BEGIN                  
     SET @custNo=@eCustno                   
     SET @msg='Assembly and Rev exist under another customer.  Assigned customer was adjusted.'                  
    END            
           
 -- 01/17/2019 : Vijay G : Fix the Assembly is not getting Customer if it is already exists and user not providing custno from excel sheet          
 IF(@custNo ='' AND @eCustno<>'')           
 BEGIN          
   SET @custNo=@eCustno                
 END               
                     
   -- 05/21/2019 : Vijay G : change parameter name as useid for @startedBy column  to insert userid value in this column of calling importbomheaderAdd sp                 
    EXEC importBOMHeaderAdd @importId,@userId,@partSource,'NEW',NULL,NULL,@custNo,@assyNum,@assyRev,@assyDesc,@partClass,@partType,@eUniq_key,@msg                  
   END TRY                  
   BEGIN CATCH                   
    INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                  
    SELECT                  
     ERROR_NUMBER() AS ErrorNumber                  
     ,ERROR_SEVERITY() AS ErrorSeverity                  
     --,ERROR_STATE() AS ErrorState                  
     ,ERROR_PROCEDURE() AS ErrorProcedure                  
     ,ERROR_LINE() AS ErrorLine                  
     ,ERROR_MESSAGE() AS ErrorMessage;                  
    SET @headerErrs = 'There are issues with the header information while trying to load ASSY: '+@assyNum+', REV: '+@assyRev+', DESC: '+@assyDesc                  
   END CATCH            
  -- 01/30/2019 : Sachin B: Remove Logic From this SP Used the Same logic in importBOMVldtnCheckManExNumAll because when score is set the Part_Class are updated by system          
  ---- 01/24/2019 : Sachin B:Use the BOM Comp Part Class Warehouse if Not then Use Default Warehouse and Also If Comp Part_Class and Warehouse both are Empty then also use Default Warehouse           
  --DECLARE @PartRowId UNIQUEIDENTIFIER,@PartClassData NVARCHAR(8),@UniqWH CHAR(10)          
      
  --DECLARE PartsCurosr CURSOR LOCAL FAST_FORWARD                
  --FOR  SELECT rowid,partClass FROM @partsTable WHERE warehouse =''               
            
  --OPEN PartsCurosr;                
              
  --FETCH NEXT FROM PartsCurosr INTO @PartRowId,@PartClassData;                
                  
  --WHILE @@FETCH_STATUS = 0                
  --BEGIN                
  --  IF @PartClassData <>''                
  --BEGIN                    
  -- SET @UniqWH = (SELECT uniqwh FROM PartClass WHERE part_class =@PartClassData)          
  -- IF(@UniqWH IS NOT NULL AND @UniqWH<>'')          
  --  BEGIN          
  --   UPDATE @partsTable SET warehouse =(SELECT WAREHOUSE FROM WAREHOUS WHERE UNIQWH =@UniqWH)          
  --   WHERE rowId =@PartRowId          
  --  END          
  -- ELSE          
  --  BEGIN          
  --   UPDATE @partsTable SET warehouse =(SELECT WAREHOUSE FROM WAREHOUS WHERE [DEFAULT] =1)          
  --   WHERE rowId =@PartRowId          
  --  END          
             
  -- FETCH NEXT FROM PartsCurosr INTO @PartRowId,@PartClassData;                
  -- CONTINUE                
  --END          
  --  ELSE          
  --   BEGIN          
  --      UPDATE @partsTable SET warehouse =(SELECT WAREHOUSE FROM WAREHOUS WHERE [DEFAULT] =1)          
  --   WHERE rowId =@PartRowId          
          
  --   FETCH NEXT FROM PartsCurosr INTO @PartRowId,@PartClassData;            
  --   CONTINUE          
  --   END          
  --END          
  --CLOSE PartsCurosr;                
  --DEALLOCATE PartsCurosr;                
                     
   /*                  
    PART RECORDS                  
    Unpivot the temp table and insert into importBOMFields                  
   */                  
   BEGIN TRY -- inside begin try                  
    INSERT INTO importBOMFields (fkImportId,fkFieldDefId,rowId,original,adjusted)                  
     SELECT @importId,fd.fieldDefId,u.rowId,u.adjusted,u.adjusted                  
      FROM(                  
       SELECT [rowId],[itemno],[used],[partSource],[make_buy],[partClass],[partType],[qty],[custPartNo],[cRev],[descript],[u_of_m],[warehouse],                  
        [standardCost],[workCenter],[partno],[rev],[bomNote],[invNote] ,              
   -- 05/15/2019 : Vijay G : Added two row in importbomdefinition table to save data in table i have added two more parameter as mtc or serial                
  [mtc],serial,location                      
        FROM @partsTable)p                  
       UNPIVOT                  
       (adjusted FOR fieldName IN                  
        ([itemno],[used],[partSource],[make_buy],[partClass],[partType],[qty],[custPartNo],[cRev],[descript],[u_of_m],[warehouse],[standardCost],[workCenter],[partno],[rev],  
  [bomNote],[invNote],[mtc],[serial],[location])  --                      
        ) AS u                  
       INNER JOIN importBOMFieldDefinitions fd ON fd.fieldName = u.fieldName                  
    /* Update import fields with the default value if none were provided */               
-- 05/24/2019 : Vijay G : modify sp for remove blue color of standard cost field if part not exist              
    UPDATE i               
     SET i.adjusted=fd.[default],i.[status]=@blue,i.[message]='Default Value',i.[validation]=@sys                  
     FROM importBOMFieldDefinitions fd           
  INNER JOIN importBOMFields i ON i.fkFieldDefId=fd.fieldDefId           
  -- 01/30/2018 Sachin B Fix the Issue the Part Component Default Warehouse Selection Does Not Apply the Default Warehouse use on the Basis of Part_Class add Parameter fieldName          
  WHERE i.adjusted='' AND fd.[default]<>'' AND i.fkImportId=@importId AND fd.fieldName<>'warehouse' AND fd.fieldName<>'standardCost'          
-- 05/24/2019 : Vijay G : modify sp for remove blue color of standard cost field if part not exist                    
    UPDATE i                  
     SET i.adjusted=0,i.[status]=@blue,i.[message]='Must have a value',i.[validation]=@sys                  
     FROM importBOMFieldDefinitions fd INNER JOIN importBOMFields i ON i.fkFieldDefId=fd.fieldDefId          
   WHERE fd.dataType='numeric' AND i.fkImportId=@importId AND i.adjusted=''  and fd.fieldName<>'standardCost'             
                      
   END TRY                  
   BEGIN CATCH                   
    INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                  
    SELECT                  
     ERROR_NUMBER() AS ErrorNumber                  
     ,ERROR_SEVERITY() AS ErrorSeverity                  
     --,ERROR_STATE() AS ErrorState                  
     ,ERROR_PROCEDURE() AS ErrorProcedure                  
     ,ERROR_LINE() AS ErrorLine                  
     ,ERROR_MESSAGE() AS ErrorMessage;                  
    SET @partErrs = 'There are issues with loading part records. No additional information available.  Please review the spreadsheet before trying again.'                  
   END CATCH                     
                       
   /*                  
    REF DESG                  
    This has to run via cursor because the function works on only 1 string at a time.                  
   */                  
   BEGIN TRY -- inside begin try                  
    DECLARE @rowId uniqueidentifier,@refString varchar(max)                  
    BEGIN                  
     DECLARE rt_cursor CURSOR LOCAL FAST_FORWARD                  
     FOR                  
     SELECT p1.rowId,STUFF((SELECT DISTINCT  ', ' + t.refDesg                  
       FROM @partsTable p inner join @tempTable t ON p.rowNum=t.rowNum                  
       WHERE p.rowId=p1.rowId                  
       FOR XML PATH ('')),1,1,'') AS refs                  
      FROM @partsTable p1 inner join @tempTable t1 ON p1.rowNum=t1.rowNum                  
      WHERE STUFF((SELECT DISTINCT  ', ' + t.refDesg                  
       FROM @partsTable p inner join @tempTable t ON p.rowNum=t.rowNum                  
       WHERE p.rowId=p1.rowId                  
       FOR XML PATH ('')),1,1,'')<>''                  
      GROUP BY p1.rowId                  
     -- 07/12/13 DS removed to allow for grouping RefDesg                  
     --SELECT p.rowId,t.refDesg                  
     -- FROM @partsTable p inner join @tempTable t                   
     --  ON p.rowNum=t.rowNum                  
     -- WHERE t.refDesg <>''                  
     -- GROUP BY p.rowId,t.refDesg                  
     OPEN rt_cursor;                  
    END                  
    FETCH NEXT FROM rt_cursor INTO @rowId,@refString                  
    WHILE @@FETCH_STATUS = 0                  
    BEGIN                  
     BEGIN TRY                   
      --INSERT INTO importBOMRefDesg(fkImportId,fkRowId,refDesg)                  
      --SELECT DISTINCT @importId,rowId,ref FROM dbo.fn_parseRefDesgString(@rowId,@refString,',','-')                  
      --06/03/13 YS populate RefOrd column with nSeq column from fn_parseRefDesgString                  
      INSERT INTO importBOMRefDesg(fkImportId,fkRowId,refDesg,RefOrd)                  
      SELECT DISTINCT @importId,rowId,ref,nSeq FROM dbo.fn_parseRefDesgString(@rowId,@refString,',','-')                  
                        
      FETCH NEXT FROM rt_cursor INTO @rowId,@refString                  
     END TRY                  
     BEGIN CATCH                   
      INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                  
      SELECT                  
       ERROR_NUMBER() AS ErrorNumber                  
       ,ERROR_SEVERITY() AS ErrorSeverity                  
       --,ERROR_STATE() AS ErrorState                  
       ,ERROR_PROCEDURE() AS ErrorProcedure                  
       ,ERROR_LINE() AS ErrorLine                  
       ,ERROR_MESSAGE() AS ErrorMessage;                  
      FETCH NEXT FROM rt_cursor INTO @rowId,@refString                  
     END CATCH                   
    END                  
    CLOSE rt_cursor                  
    DEALLOCATE rt_cursor                  
    IF @refErrs<>'' SET @refErrs = 'There following refDesg values are creating issues with the import: ' + @refErrs                   
   END TRY                  
   BEGIN CATCH                   
    INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                  
    SELECT                  
     ERROR_NUMBER() AS ErrorNumber                  
     ,ERROR_SEVERITY() AS ErrorSeverity                  
     --,ERROR_STATE() AS ErrorState                  
     ,ERROR_PROCEDURE() AS ErrorProcedure                  
     ,ERROR_LINE() AS ErrorLine                  
     ,ERROR_MESSAGE() AS ErrorMessage;                  
    SET @refErrs = 'Unknown Error while importing refDesg.  Please review the values before proceeding.'                  
   END CATCH                   
                  
   /*                  
    AVL                  
   */                  
   BEGIN TRY -- inside begin try                  
     INSERT INTO importBOMAvl(fkImportId,fkFieldDefId,fkRowId,adjusted,original,[load],[bom],avlRowId)                  
     SELECT @importId,fd.fieldDefId,u.rowId,u.adjusted,u.adjusted,1,1,avlRowId                  
     FROM            
  (                      
    SELECT p.rowId,t.[partMfg],t.[mpn],t.[matlType],t.[preference],newid()avlRowId                      
    FROM @partsTable p             
    INNER JOIN @tempTable t ON p.rowNum=t.rowNum                      
       WHERE [partMfg]<>''                  
    GROUP BY p.rowId,t.[partMfg],t.[mpn],t.[matlType],t.[preference]                    
     )p                  
     UNPIVOT  (adjusted FOR fieldName IN ([partMfg],[mpn],[matlType],[preference])) AS u                  
     INNER JOIN importBOMFieldDefinitions fd ON fd.fieldName = u.fieldName      
      
  DECLARE @avlFieldDefId UNIQUEIDENTIFIER = (SELECT fieldDefId FROM importBOMFieldDefinitions WHERE fieldName ='matlType')    
    
  --08/24/2020 : Sachin B : If Material type is found then Match with the setup as present    
  --Update the AVLMATLTYPE from AVLMATLTP same as setup    
  UPDATE impAvl    
  SET  impAvl.adjusted = avlMat.AVLMATLTYPE ,impAvl.original = avlMat.AVLMATLTYPE    
  FROM importBOMAvl impAvl     
  INNER JOIN AVLMATLTP avlMat  ON  impAvl.original = avlMat.AVLMATLTYPE     
  WHERE  impAvl.fkImportId = @importId AND impAvl.fkFieldDefId = @avlFieldDefId    
                      
    /* Update import fields with the default value if none were provided */                  
    /* 02/12/14 DS Removed adding the default value.  We will add the default at the end of the process IF they have not provided one by then. */                  
    --UPDATE i                  
    -- SET i.adjusted=fd.[default],i.[status]=@blue,i.[message]='Default Value',i.[validation]=@sys                  
    -- FROM importBOMFieldDefinitions fd INNER JOIN importBOMAvl i ON i.fkFieldDefId=fd.fieldDefId WHERE i.adjusted='' AND fd.[default]<>'' AND i.fkImportId=@importId                  
                  
   END TRY                  
   BEGIN CATCH                   
    INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                  
    SELECT                  
     ERROR_NUMBER() AS ErrorNumber                  
     ,ERROR_SEVERITY() AS ErrorSeverity                  
     --,ERROR_STATE() AS ErrorState                  
     ,ERROR_PROCEDURE() AS ErrorProcedure                  
     ,ERROR_LINE() AS ErrorLine                  
     ,ERROR_MESSAGE() AS ErrorMessage;                  
    SET @avlErrs = 'Unknown Error while importing AVL info.  Please review the values before proceeding.'                  
   END CATCH                   
                     
   DECLARE @errCnt int = 0                  
   SELECT @errCnt=COUNT(*) FROM @ErrTable                   
   IF @errCnt>0                  
   BEGIN                  
    SELECT * FROM @ErrTable                  
    ROLLBACK                  
    RETURN -1                    
   END                  
                     
   /* Add a note for the creation of the import */      
   DECLARE @noteId uniqueidentifier = newid()                  
   DECLARE @tempwmNote tWmNotes                  
   INSERT INTO @tempwmNote                  
            SELECT NULL AS NoteId,'' AS Description,NULL AS fkCreatedUserID, NULL AS ReminderDate, '' AS RecordId, '' AS RecordType, 0 AS NoteCategory,NULL AS ImagePath, NULL as OldNoteId FROM @tempwmNote                  
   EXEC MnxNotesAdd @tempwmNote, @NoteId=@noteId,@Description='New Import Started',@CreatedUserId=@userId,@ReminderDate=null,@RecordId=@importId,                  
    @RecordType='importBOMHeader',@NoteCategory=2 -- 03/06/2018 : Vijay G : Passed the @NoteCategory parameter to MnxNotesAdd SP                  
                      
                     
    /*03/06/2018 : Vijay G : Add a Invt note and bom item note for assembly component*/                  
    /*Add a inventor note for assembly component*/        
   --04/07/2020 : Sachin B : Commented unwanted code of note       
   --09/18/2020 : Sachin B : Add Part Master Note geeting populated from excel sheet            
   DECLARE  @tempwmNotes tWmNotes                  
   INSERT INTO @tempwmNotes (NoteId,Description,fkCreatedUserID,ReminderDate,RecordId,RecordType,NoteCategory,ImagePath)                  
   SELECT NEWID() AS NoteId, adjusted AS Description,@userId as CreatedUserID, null AS ReminderDate,                  
      rowId as RecordId,'importBOMPMNote' AS RecordType, 2 AS NoteCategory,NULL AS ImagePath     
   FROM importbomfields WHERE fkImportId=@importId AND fkFieldDefId='0103F212-D99A-E111-B197-1016C92052BC'                  
      AND adjusted <> ''                  
   IF EXISTS (SELECT 1 FROM @tempwmNotes)                  
   BEGIN                  
    EXEC MnxNotesAdd @tempwmNotes,NULL,NULL,NULL,NULL,NULL,NULL,NULL                  
   END                      
                     
    /*Add a bom item note for assembly component*/                  
   DECLARE  @tempbomWmNotes tWmNotes                  
   INSERT INTO @tempbomWmNotes (NoteId,Description,fkCreatedUserID,ReminderDate,RecordId,RecordType,NoteCategory,ImagePath)                  
   SELECT NEWID() AS NoteId, adjusted AS Description,@userId as CreatedUserID, null AS ReminderDate,                  
      rowId as RecordId,'importBOMItemNote' AS RecordType, 2 AS NoteCategory,NULL AS ImagePath     
   FROM importbomfields WHERE fkImportId=@importId AND fkFieldDefId='97DA0609-D99A-E111-B197-1016C92052BC'                  
      AND adjusted <> ''                  
   IF EXISTS (SELECT 1 FROM @tempbomWmNotes)                  
   BEGIN                  
    EXEC MnxNotesAdd @tempbomWmNotes,NULL,NULL,NULL,NULL,NULL,NULL,NULL                   
   END                     
  END                  
                    
  COMMIT                  
 END TRY                  
 BEGIN CATCH                  
  SET @lRollback=1                  
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                  
  SELECT                  
   ERROR_NUMBER() AS ErrorNumber                  
   ,ERROR_SEVERITY() AS ErrorSeverity                  
   --,ERROR_STATE() AS ErrorState                  
   ,ERROR_PROCEDURE() AS ErrorProcedure                  
   ,ERROR_LINE() AS ErrorLine                  
   ,ERROR_MESSAGE() AS ErrorMessage;                  
                     
  ROLLBACK                  
  BEGIN TRY                  
   INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg)                  
   SELECT DISTINCT @importId,ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg FROM @ErrTable                  
  END TRY                  
  BEGIN CATCH                  
   SELECT                  
   ERROR_NUMBER() AS ErrorNumber                  
   ,ERROR_SEVERITY() AS ErrorSeverity                  
   --,ERROR_STATE() AS ErrorState                  
   ,ERROR_PROCEDURE() AS ErrorProcedure                  
   ,ERROR_LINE() AS ErrorLine                  
   ,ERROR_MESSAGE() AS ErrorMessage;                  
  END CATCH        
  SELECT * FROM @ErrTable                  
  SELECT 'Problems uploading file' AS uploadError                  
  RETURN -1                  
 END CATCH                   
END