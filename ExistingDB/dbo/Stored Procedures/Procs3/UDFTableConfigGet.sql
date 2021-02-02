-- =============================================
-- Author:		David Sharp
-- Create date: 8/13/2012
-- Description:	get udf table information
-- 11/12/14 Added role to the sections information
-- 7/17/2015 Anuj : Added isUdf check to make udf/udt table name based on section
--Sachin s 10-15-2015 CHARACTER_MAXIMUM_LENGTH value get the null value so replace from NUMERIC_PRECISION
-- 06/30/2016 Satish : Added '@section' to get section name from mnxUdfSection table
-- 06/30/2016 Satish : Added '@section' to create udf table based on 'section' from mnxUdfSection table
-- 06/30/2016 Satish : Added '@section' to create udt table based on 'section' from mnxUdfSection table
-- 9/30/2016 Raviraj :Join the udfmeta with udftable name to avoid duplicate entries with same name
-- 11/06/2017 Raviraj P : Added a new parameter @categoryName
-- 11/06/2017 Raviraj P :  Added custom CAPACategoryUDF condition
-- 10/04/2018 Shivshankarp : Added a new parameter @subSection 
-- 10/04/2018 Nitesh B : Replaced REPLACE(@categoryName,'-','_') by REPLACE(REPLACE(@categoryName,'-','_'),' ','_') for Category having '-'
-- 11/01/2018 Nitesh B : Added COLUMN m.NUMERIC_SCALE  in select list
-- 11/01/2018 Raviraj P : Changed sp for udf lot code search
-- 21/01/2019 Raviraj P : Get metaId column to update UDF setup 
-- 04/10/2020 Shivshankar P : Replaced um.dynamicSQL by REPLACE((um.dynamicSQL),'-','_') 
-- EXEC UDFTableConfigGet  @sectionName = 'INVENTOR,Lot code',  @isUdf = 1, @categoryName = 'Internal' , @subSection ='', @isSourceAvl = 1, @isFieldType = 1 
-- =============================================
CREATE PROCEDURE [dbo].[UDFTableConfigGet] 
	-- Add the parameters for the stored procedure here
	@sectionName varchar(200),
	@isUdf BIT = 1,
	@categoryName VARCHAR(100) = '' ,  -- 11/06/2017 Raviraj P : Added a new parameter @categoryName
	@subSection VARCHAR(100) ='', -- 10/04/2018 Shivshankarp : Added a new parameter @subSection 
    @isSourceAvl BIT = 0,  
    @isFieldType BIT = 0 -- 12/028/2018 Raviraj P : If UDF field show with class and type then set to 1  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @udfTableName VARCHAR(200),@SQL VARCHAR(MAX),@udfTableKeyName VARCHAR(200),@tableKey VARCHAR(50),@tableName VARCHAR(200),@section VARCHAR(200)
	
	-- 11/01/2018 Raviraj P : Changed sp for udf lot code search
	DECLARE @sectionTable table(id INT IDENTITY(1,1) PRIMARY KEY, sectionName varchar(200))
	DECLARE @TotalRecords INT, @Count INT = 1

    DECLARE @udfData table(UdfColumn varchar(200),ORDINAL_POSITION INT,COLUMN_NAME VARCHAR(256),COLUMN_DEFAULT NVARCHAR(MAX),IS_NULLABLE BIT, DATA_TYPE NVARCHAR(256),   
      CHARACTER_MAXIMUM_LENGTH INT, listString VARCHAR(MAX), dynamicSQL VARCHAR(MAX), NUMERIC_SCALE INT , ClassName VARCHAR(200),udfId UNIQUEIDENTIFIER)  
    DECLARE @roleTable table(tableKey VARCHAR(50), role VARCHAR(100))  
    
	INSERT INTO @sectionTable SELECT id FROM dbo.[fn_simpleVarcharlistToTable](@sectionName,',')

	SELECT  @TotalRecords  = COUNT(id) FROM @sectionTable

	WHILE (@Count <= @totalRecords)
	BEGIN
		SELECT @sectionName = sectionName FROM @sectionTable WHERE id = @Count
		SELECT @Count = @Count + 1
	

	SELECT @tableName=mainTable FROM MnxUdfSections WHERE section=@sectionName
	IF(@tableName IS NULL) SET @tableName=@sectionName
	-- 06/30/2016 Satish : Added '@section' to get section name from mnxUdfSection table
	SELECT @section=REPLACE(section,' ','_')FROM MnxUdfSections WHERE section=@sectionName

	SET @subSection = CASE WHEN @subSection = '' OR @subSection IS NULL THEN 'udf' +  @tableName ELSE @subSection END

	--7/17/2015 Anuj : Added isUdf check to make udf/udt table name based on section
	IF @isUdf = 1 AND (@subSection IS NOT NULL AND @subSection != '')  AND  (@categoryName IS NOT NULL AND @categoryName != '') -- 10/04/2018 Shivshankarp : Added a new parameter @subSection 
	-- 11/06/2017 Raviraj P :  Added custom CAPACategoryUDF condition
	BEGIN
	-- 10/04/2018 Nitesh B : Replaced REPLACE(@categoryName,'-','_') by REPLACE(REPLACE(@categoryName,'-','_'),' ','_') for Category having '-'
		SET @udfTableName =  @subSection +'_'+ REPLACE(REPLACE(@categoryName,'-','_'),' ','_')   --11/06/2017 Raviraj P : Set capa table name
	END
	ELSE IF @isUdf = 1
	BEGIN
		SET @udfTableName = 'udf'+@section  -- 06/30/2016 Satish : Added '@section' to create udf table based on 'section' from mnxUdfSection table
	END
	ELSE
	BEGIN
		SET @udfTableName = 'udt'+@section  -- 06/30/2016 Satish : Added '@section' to create udt table based on 'section' from mnxUdfSection table
	END
	SELECT @tableKey=COLUMN_NAME FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME=@tableName

	DECLARE @partClass table (tableName VARCHAR(MAX))
	DECLARE @tempPartClass table (tableName VARCHAR(MAX),Id VARCHAR(MAX))
	DECLARE @source varchar(max)
	
	IF(@isSourceAvl=1)
	BEGIN
	SELECT @source = Source FROM MnxUdfSections WHERE section=@sectionName 
	INSERT INTO @tempPartClass exec(@source)
	INSERT INTO @partClass SELECT (REPLACE(REPLACE(RTRIM(Id),'-','_'), ' ', '_')) FROM @tempPartClass
	END
	ELSE
	BEGIN
	 INSERT INTO @partClass SELECT @udfTableName
	END
	INSERT INTO @udfData
    SELECT  TABLE_NAME  + '_'+ m.COLUMN_NAME, m.ORDINAL_POSITION,m.COLUMN_NAME,m.COLUMN_DEFAULT,CASE WHEN m.IS_NULLABLE='NO' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END IS_NULLABLE,m.DATA_TYPE,  
	--m.CHARACTER_MAXIMUM_LENGTH,
	--Sachin s 10-15-2015 CHARACTER_MAXIMUM_LENGTH value get the null value so replace from NUMERIC_PRECISION
	CASE WHEN (m.CHARACTER_MAXIMUM_LENGTH IS NULL )
							 THEN  m.NUMERIC_PRECISION 
             ELSE m.CHARACTER_MAXIMUM_LENGTH 
             END  AS CHARACTER_MAXIMUM_LENGTH,
	
	um.listString,
	REPLACE((um.dynamicSQL),'-','_') -- 04/10/2020 Shivshankar P : Replaced um.dynamicSQL by REPLACE((um.dynamicSQL),'-','_') 
	,m.NUMERIC_SCALE -- 11/01/2018 Nitesh B : Added COLUMN m.NUMERIC_SCALE  in select list
 ,SUBSTRING(TABLE_NAME, CHARINDEX('_', TABLE_NAME)+1, LEN(TABLE_NAME) - CHARINDEX('_', TABLE_NAME)+1) AS ClassName,  
 um.metaId -- 21/01/2019 Raviraj P : Get metaId column to update UDF setup  
 --,count(case when m.COLUMN_NAME=um.udfField AND m.DATA_TYPE <> um.da then )  
 --,m.*  
 --row_number() over(partition by TABLE_NAME) as cnt  
 FROM INFORMATION_SCHEMA.COLUMNS m   
  LEFT OUTER JOIN UDFMeta um   
  ON m.COLUMN_NAME=um.udfField and um.udfTable = TABLE_NAME --in (SELECT tableName FROM @partClass) -- 9/30/2016 Raviraj :Join the udfmeta with udftable name to avoid duplicate entries with same name  
  WHERE TABLE_NAME in (SELECT  tableName FROM @partClass) ORDER BY M.ORDINAL_POSITION ASC  
	INSERT INTO @roleTable SELECT 'fk'+@tableKey, [role] FROM MnxUdfSections WHERE mainTable = @sectionName
	END--While end	
  
 IF(@isFieldType=0)  
 BEGIN  
  SELECT ORDINAL_POSITION,COLUMN_NAME,COLUMN_DEFAULT,IS_NULLABLE,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH,listString,dynamicSQL,NUMERIC_SCALE,UdfColumn,COLUMN_NAME as FieldTypeClass,udfId  
  FROM @udfData  
    END  
 ELSE  
 BEGIN  
  ;WITH tempData AS  
  (SELECT result.cont AS TotalCount,   
  CASE WHEN result.cont > 1 THEN COLUMN_NAME+ ' (Type: '+  
  CASE WHEN DATA_TYPE ='varchar' THEN 'string' ELSE DATA_TYPE END +')' ELSE COLUMN_NAME + ' (Class: ' + ClassName +'  Type: '+CASE WHEN DATA_TYPE ='varchar' THEN 'string' ELSE DATA_TYPE END + ')' END TypeAndClass,  
   *, rn = ROW_NUMBER() OVER (PARTITION BY udf.COLUMN_NAME,udf.DATA_TYPE,listString ORDER BY udf.COLUMN_NAME )   
   FROM @udfData udf  
   OUTER APPLY(SELECT COUNT(td.COLUMN_NAME) AS cont FROM @udfData  td WHERE COLUMN_NAME = udf.COLUMN_NAME  and DATA_TYPE = udf.DATA_TYPE    
   and ((ISNULL(udf.listString,'') ='' AND 1=1 ) OR  (ISNULL(td.listString,'') <>'' AND td.listString= udf.listString ))  
   GROUP BY COLUMN_NAME,DATA_TYPE) AS result  
  )  
    
  SELECT ORDINAL_POSITION,COLUMN_NAME,COLUMN_DEFAULT,IS_NULLABLE,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH,listString,dynamicSQL,NUMERIC_SCALE,UdfColumn,FieldTypeClass,udfId  
    FROM (SELECT  CASE WHEN outResult.typeClassCnt > 1  THEN COLUMN_NAME + ' (Class: ' + ClassName +'  Type: '+  
    CASE WHEN DATA_TYPE ='varchar' THEN 'string' ELSE DATA_TYPE END  + ')' ELSE TypeAndClass END FieldTypeClass,*   
    FROM tempData   
   OUTER APPLY(SELECT  COUNT(TypeAndClass) AS typeClassCnt FROM tempData y WHERE tempData.TypeAndClass = y.TypeAndClass and y.rn = 1) outResult  
  WHERE tempData.rn = 1   
  ) result  ORDER BY ORDINAL_POSITION  
 END  
	SELECT * FROM @roleTable
END