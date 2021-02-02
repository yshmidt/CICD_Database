create PROCEDURE [dbo].[sp_GlobalUpdateWarehouse] @ltUniqMfgrHdWhnoUniqWh tUniqMfgrHdWhnoUniqWh READONLY

AS

-- @ltUniqMfgrHdWhnoUniqWh: The Uniqmfgrhd records that should be filter out when updating WH records
-- @lcOldWhno: Old Whno
-- @lcNewWhno: Newd Whno
-- @lcOldUniqWh: Old UniqWh
-- @lcNewUniqWh: New UniqWh

BEGIN

SET NOCOUNT ON;

BEGIN TRANSACTION
BEGIN TRY;	

DECLARE @ZFilterOutTable TABLE (nrecno int identity, UniqMfgrhd char(10), W_key char(10))
DECLARE @ZWhTable TABLE (nrecno int identity, TableName nvarchar(128), FieldName nvarchar(128))
DECLARE @lnTotalNo int, @lnCount int, @lcSQLString nvarchar(max)='', @lcSQLDupTableString nvarchar(max)='', @lcUniqMfgrhd char(10),
		@lcW_key char(10), @lnTotalNo2 int, @lnCount2 int, @llRun bit, @lcTableName nvarchar(128), @lcFieldname nvarchar(128),
		@lcOldWhno char(3), @lcNewWhno char(3), @lcOldUniqWh char(10), @lcNewUniqWh char(10)

-- Get the records that uniqmfgrhd and w_key should be filtered out
INSERT @ZFilterOutTable (UniqMfgrhd, W_key) 
	SELECT tUniqMfgrHdWhnoUniqWh.UniqMfgrhd, W_key 
	FROM @ltUniqMfgrHdWhnoUniqWh tUniqMfgrHdWhnoUniqWh, Invtmfgr 
	WHERE tUniqMfgrHdWhnoUniqWh.UniqMfgrhd = Invtmfgr.UNIQMFGRHD
	

-- Start to create @lcSQLDupTableString that will declare the table and insert record that will be used later in update tables
SET @lnTotalNo = @@ROWCOUNT;

IF (@lnTotalNo>0)
BEGIN	
	SET @lnCount=0;
	SELECT @lcSQLDupTableString=N'DECLARE @ZFilterDupTable TABLE (UniqMfgrHd char(10), W_key char(10))
							INSERT INTO @ZFilterDupTable (UniqMfgrHd, W_key) VALUES'

	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @lcUniqMfgrhd = UniqMfgrHd, @lcW_key = W_key
			FROM @ZFilterOutTable WHERE nrecno = @lnCount
		IF (@@ROWCOUNT<>0)
		BEGIN
			SELECT @lcSQLDupTableString=@lcSQLDupTableString + 
					'('''+@lcUniqMfgrhd+''','''+@lcW_key+''')' + CASE WHEN @lnCount = @lnTotalNo  THEN '' ELSE ',' END
		END
	END
	--SELECT @lcSQLDupTableString=@lcSQLDupTableString + ' SELECT * FROM Invtmfhd WHERE Uniqmfgrhd IN (SELECT Uniqmfgrhd from @ZFilterDupTable)'

END

-- Get values for @lcOldWhno, @lcNewWhno, @lcOldUniqWh, @lcNewUniqWh 
SELECT TOP 1 @lcOldWhno = OldWhno, @lcNewWhno = NewWhno, @lcOldUniqWh = OldUniqWh, @lcNewUniqWh = NewUniqWh
	FROM @ltUniqMfgrHdWhnoUniqWh ltUniqMfgrHdWhnoUniqWh ORDER BY UniqMfgrHd
		 
-- Now start to scan through @ZWhTable that contains all the tables name which have uniqwh and whno			 
INSERT @ZWhTable (TableName, FieldName)
SELECT O.Name AS TableName, C.Name AS FieldName 
	FROM sys.all_objects O, sys.all_columns C
	WHERE O.Object_id = C.Object_id
	AND (LTRIM(RTRIM(C.Name)) = 'whno'
	OR LTRIM(RTRIM(C.Name)) = 'uniqwh')
	AND (LTRIM(RTRIM(O.Name)) <> 'WAREHOUS'
	AND LTRIM(RTRIM(O.Name)) <> 'UPDTSTD')
	AND Type = 'U'
	ORDER BY Tablename

SET @lnTotalNo2 = @@ROWCOUNT;
	
IF (@lnTotalNo2>0)
BEGIN	
	SET @lnCount2=0;
	WHILE @lnTotalNo2>@lnCount2
	BEGIN	
		SET @lnCount2=@lnCount2+1;
		SELECT @lcTableName = TableName, @lcFieldName = FieldName
			FROM @ZWhTable WHERE nrecno = @lnCount2
		IF (@@ROWCOUNT<>0)
		BEGIN
			SET @lcSQLString = ''
			SET @llRun = 0
			SELECT @lcSQLString = @lcSQLDupTableString + ' UPDATE '+ LTRIM(RTRIM(@lcTableName)) + ' SET ' + LTRIM(RTRIM(@lcFieldName)) + ' = '''
							+ CASE WHEN UPPER(LTRIM(RTRIM(@lcFieldName))) = 'WHNO' THEN @lcNewWhno ELSE @lcNewUniqWh END + ''''
							+ ' WHERE ' + LTRIM(RTRIM(@lcFieldName)) + ' = '''
							+ CASE WHEN UPPER(LTRIM(RTRIM(@lcFieldName))) = 'WHNO' THEN @lcOldWhno ELSE @lcOldUniqWh END + ''''
							+ ' AND '

			IF UPPER(@lcTableName) = 'PHYHDTL'
			BEGIN
				SELECT @lcSQLString = @lcSQLString + 'UNIQPIHEAD NOT IN (SELECT Uniqpihead FROM Phyinvt, @ZFilterDupTable  ZFilterDupTable ' 
													+ 'WHERE Phyinvt.W_key = ZFilterDupTable.W_key)'	
				SET @llRun = 1
			END
			
			IF UPPER(@lcTableName) = 'POITSCHD'
			BEGIN
				SELECT @lcSQLString = @lcSQLString + 'UniqLnno NOT IN (SELECT UniqLnno FROM Poitems, @ZFilterDupTable  ZFilterDupTable ' 
													+ 'WHERE Poitems.UniqMfgrHd = ZFilterDupTable.UniqMfgrHd)'	
				SET @llRun = 1
			END
			
			IF UPPER(@lcTableName) = 'PORECLOC'
			BEGIN
				SELECT @lcSQLString = @lcSQLString + 'FK_UNIQRECDTL NOT IN (SELECT UniqRecDtl FROM Porecdtl, @ZFilterDupTable  ZFilterDupTable '
													+ 'WHERE Porecdtl.Uniqmfgrhd = ZFilterDupTable.UniqmfgrHd)'				
				SET @llRun = 1
			END

			IF UPPER(@lcTableName) = 'POSTORE'
			BEGIN
				SELECT @lcSQLString = @lcSQLString + 'UniqMfgrHd NOT IN (SELECT UniqMfgrhd FROM @ZFilterDupTable  ZFilterDupTable) '
				SET @llRun = 1
			END

			IF @llRun = 0
			BEGIN
				SELECT @lcSQLString = @lcSQLString + 'W_key NOT IN (SELECT W_key FROM @ZFilterDupTable)'
				SET @llRun = 1					
			END
			
			EXECUTE sp_executesql @lcSQLString

		END
	END
END
			
END TRY

BEGIN CATCH
	RAISERROR('Error occurred in globally updating values. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END		