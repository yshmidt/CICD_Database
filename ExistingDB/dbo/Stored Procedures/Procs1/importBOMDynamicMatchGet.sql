-- =============================================
-- Author:		David Sharp
-- Create date: 5/20/2013
-- Description:	gets a list of parts that match the dynamic criteria
-- =============================================
CREATE PROCEDURE [dbo].[importBOMDynamicMatchGet] 
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier,
	@partClass varchar(10)=null,@partClassOp varchar(MAX)='equals',@partClassType varchar(5) = 'AND',
	@partType varchar(10)=null,@partTypeOp varchar(MAX)='equals',@partTypeType varchar(5) = 'AND',
	@descript varchar(MAX)=null,@descriptOp varchar(MAX)='equals',@descriptType varchar(5) = 'AND',
	@mpn varchar(MAX)=null, @mpnOp varchar(MAX)='contains',@mpnType varchar(5) = 'AND'
		
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @conTable TABLE (field varchar(50),paramName varchar(50),fieldOperation varchar(50),fieldValue varchar(MAX),fieldType varchar(6))
	INSERT INTO @conTable (field,paramName,fieldOperation,fieldValue,fieldType)
	SELECT 'part_class','@partClass',@partClassOp,@partClass,@partClassType
	UNION ALL
	SELECT 'part_type','@partType',@partTypeOp,@partType,@partTypeType
	UNION ALL
	SELECT 'descript','@descript',@descriptOp,@descript,@descriptType
	UNION ALL
	SELECT 'mfgr_pt_no','@mpn',@mpnOp,@mpn,@mpnType


	DECLARE @tInventor tImportBomInventor, @tAvlAll tImportBomAvl 
	INSERT INTO @tAvlAll EXEC [dbo].ImportBomGetAvlToComplete @importId
	INSERT INTO @tInventor EXEC [dbo].[sp_getImportBOMItems] @importId,1,'Inventor' 
		
	DECLARE @SQL nvarchar(MAX) = 'SELECT DISTINCT rowId,Part_no,Revision,Descript,Part_class, Part_type, Dept_id '
		+'FROM (SELECT t.rowId,t.Part_no,t.Revision,t.Descript,t.Part_class,t.Part_type,t.Dept_id, a.Mfgr_pt_no,a.PartMfgr '
		+'FROM @tInventor t INNER JOIN @tAvlAll a ON a.rowId=t.rowId WHERE 1=1 '

	DECLARE @fieldName varchar(50),@paramName varchar(50),@ops varchar(MAX),@fValue varchar(MAX),@fType varchar(6)
	BEGIN    
		DECLARE fd_cursor CURSOR LOCAL FAST_FORWARD
		FOR
		SELECT * FROM @conTable
		OPEN		fd_cursor;
	END
	FETCH NEXT FROM fd_cursor INTO @fieldName,@paramName,@ops,@fValue,@fType

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @fType <>'' 
		BEGIN
			IF @fType <>'OR' SET @fType=' AND '
			ELSE SET @fType= ' OR '
			
			IF @ops = 'contains' SET @ops = @fType+@fieldName+' LIKE ''%''+ ' +@paramName+' + ''%'''
			ELSE IF @ops = 'starts' SET @ops = @fType+@fieldName+' LIKE ' +@paramName+' + ''%'''
			ELSE IF @ops = 'ends' SET @ops = @fType+@fieldName+' LIKE ''%'' + ' +@paramName
			ELSE IF @ops = 'not equals' SET @ops = @fType+@fieldName+' <> ' +@paramName
			ELSE SET @ops =	@fType+@fieldName+' = ' +@paramName
			
			SET @SQL = @SQL + @ops
		END

		FETCH NEXT FROM fd_cursor INTO @fieldName,@paramName,@ops,@fValue,@fType
	END
	 
	CLOSE fd_cursor
	DEALLOCATE fd_cursor

	SET @SQL = @SQL + ')a'
		
	EXEC sp_executesql @SQL, 
		N'@partClass varchar(MAX),@partType varchar(MAX),@descript varchar(MAX),@mpn varchar(MAX),@tInventor tImportBomInventor READONLY,@tAvlAll tImportBomAvl READONLY',
		@partClass,@partType,@descript,@mpn,@tInventor,@tAvlAll
END