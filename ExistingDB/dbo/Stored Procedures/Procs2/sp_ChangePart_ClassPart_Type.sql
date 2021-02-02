-- =============================================
-- Author:		Vicky Lu
-- Create date: 2012/10/05
-- Description: Change Part_class and Part_type values in all tables (system utility)
-- =============================================
create PROCEDURE [dbo].[sp_ChangePart_ClassPart_Type] @lcOldPart_class char(8) = ' ', @lcNewPart_class char(8) = ' ', 
														@lcOldPart_Type char(8) = ' ', @lcNewPart_Type char(8) = ' ', 
														@llChangeSupplierCard bit

AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

SET NOCOUNT ON;

DECLARE @ZUpdTable TABLE (nrecno int identity, TableName nvarchar(128))
DECLARE @ZUpdTable2 TABLE (nrecno int identity, TableName nvarchar(128))
DECLARE @ZPhyDup TABLE (UNIQPIHEAD char(10), Part_class char(8), Uniqpihdtl char(10))
DECLARE @ZSupDup TABLE(Uniqsupno char(10), Part_class char(8), Unqsupclas char(10))

DECLARE @lnTotalNo int, @lnCount int, @lcTableName nvarchar(128), @lcFieldName nvarchar(128), @lcSQLString nvarchar(4000)

BEGIN TRANSACTION
BEGIN TRY;	

-- Change part_class and Part_type
;WITH ZPart_Class AS
(
SELECT O.Name AS TableName, C.Name AS FieldName 
	FROM sys.all_objects O, sys.all_columns C
	WHERE O.Object_id = C.Object_id
	AND (LTRIM(RTRIM(C.Name)) = 'part_class'
	OR CHARINDEX('part_class',c.name) > 0)
	AND Type = 'U'
	AND O.name<>'parttype'
),
ZPart_Type AS
(
SELECT O.Name AS TableName, C.Name AS FieldName 
	FROM sys.all_objects O, sys.all_columns C
	WHERE O.Object_id = C.Object_id
	AND (LTRIM(RTRIM(C.Name)) = 'part_type'
	OR CHARINDEX('part_type',c.name) > 0)
	AND Type = 'U'
	AND O.name<>'parttype'
)
INSERT @ZUpdTable
SELECT ZPart_class.Tablename
	FROM ZPart_Class, ZPart_Type
	WHERE ZPart_Class.TableName = ZPart_Type.TableName
	ORDER BY 1
	
SET @lnTotalNo = @@ROWCOUNT;
	
IF (@lnTotalNo>0)
BEGIN	
	SET @lnCount=0;
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @lcTableName = TableName	FROM @ZUpdTable WHERE nrecno = @lnCount
		IF (@@ROWCOUNT<>0)
		BEGIN
	
			SELECT @lcSQLString = 'UPDATE '+ LTRIM(RTRIM(@lcTableName)) + ' SET Part_Class = ''' + @lcNewPart_class +''', Part_Type = ''' + 
								@lcNewPart_Type + ''' WHERE Part_Class = ''' + @lcOldPart_Class + ''' AND Part_Type = ''' + @lcOldPart_Type + ''''
			EXECUTE sp_executesql @lcSQLString
		END
	END
END

-- Get only part_classt tables
-- Now have two tables have only part_class; supclass, phyhdtl, phyhdtl will just update, but supclass will based on user's choice
-- Change part class for supplier line card


;WITH ZPart_Class AS
(
SELECT O.Name AS TableName, C.Name AS FieldName 
	FROM sys.all_objects O, sys.all_columns C
	WHERE O.Object_id = C.Object_id
	AND (LTRIM(RTRIM(C.Name)) = 'part_class'
	OR CHARINDEX('part_class',c.name) > 0)
	AND Type = 'U'
	AND O.name<>'parttype'
),
ZPart_Type AS
(
SELECT O.Name AS TableName, C.Name AS FieldName 
	FROM sys.all_objects O, sys.all_columns C
	WHERE O.Object_id = C.Object_id
	AND (LTRIM(RTRIM(C.Name)) = 'part_type'
	OR CHARINDEX('part_type',c.name) > 0)
	AND Type = 'U'
	AND O.name<>'parttype'
)
INSERT @ZUpdTable2
SELECT ZPart_class.Tablename
	FROM ZPart_Class
	WHERE ZPart_Class.TableName NOT IN
		(SELECT TableName 
			FROM ZPart_Type)
	AND 1 = CASE WHEN @llChangeSupplierCard = 1 THEN 1 ELSE 
				CASE WHEN ZPart_class.TableName <> 'SUPCLASS' THEN 1 ELSE 0 END END
	ORDER BY 1

SET @lnTotalNo = @@ROWCOUNT;
	
IF (@lnTotalNo>0)
BEGIN	
	SET @lnCount=0;
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @lcTableName = TableName	FROM @ZUpdTable2 WHERE nrecno = @lnCount
		IF (@@ROWCOUNT<>0)
		BEGIN
	
			SELECT @lcSQLString = 'UPDATE '+ LTRIM(RTRIM(@lcTableName)) + ' SET Part_Class = ''' + @lcNewPart_class + 
								''' WHERE Part_Class = ''' + @lcOldPart_Class + ''''
			EXECUTE sp_executesql @lcSQLString
		END
	END
END

-- 10/10/12 VL found after update, in Phyhdtl and SupClass might created duplicate records
;WITH zPhy AS
	(SELECT Uniqpihead, Part_class, COUNT(*) AS N FROM Phyhdtl WHERE PART_CLASS <> '' GROUP BY Uniqpihead, PART_CLASS Having COUNT(*) > 1) -- duplicate
INSERT @ZPhyDup (UniqPiHead, Part_class, UniqPihdtl)
	SELECT UniqPiHead, Part_class, MAX(UniqPihdtl) AS UniqPihdtl 
		FROM Phyhdtl 
		WHERE Uniqpihead+Part_class IN 
			(SELECT Uniqpihead+Part_Class FROM zPhy) 
			GROUP BY Uniqpihead, Part_Class
DELETE FROM PHYHDTL WHERE UNIQPIHDTL IN (SELECT UNIQPIHDTL FROM @ZPhyDup)

;WITH zSup AS
	(SELECT Uniqsupno, Part_class, COUNT(*) AS N FROM Supclass GROUP BY Uniqsupno, PART_CLASS Having COUNT(*) > 1) -- duplicate
INSERT @ZSupDup (Uniqsupno, Part_class, Unqsupclas)
	SELECT Uniqsupno, Part_class, MAX(Unqsupclas) AS Unqsupclas 
		FROM Supclass 
		WHERE Uniqsupno+Part_class IN 
			(SELECT Uniqsupno+Part_Class FROM zSup) 
			GROUP BY Uniqsupno, Part_Class
DELETE FROM Supclass WHERE Unqsupclas IN (SELECT Unqsupclas FROM @ZSupDup)


		
END TRY

BEGIN CATCH
	RAISERROR('Error occurred in changing part classes and part types from current to new ones. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END	
