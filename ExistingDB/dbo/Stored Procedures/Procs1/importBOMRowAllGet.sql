-- =============================================
-- Author:		David Sharp
-- Create date: 4/16/2012
-- Description:	gets all adjusted values for the selected import record
-- 05/16/13 YS need to manupulate the data before returning to mark record class (status) red when AVL is red for that record
-- 08/14/2018: Vijay G: class alises to CssClass. This class used to indicate Mfgr is invalid for specific row on work area grid.
-- =============================================
CREATE PROCEDURE [dbo].[importBOMRowAllGet] 
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--04/23/13 YS changes to [sp_getImportBOMItems] and @ImportId UD table type. Return CLass and validation from sp_getImportBOMItems
	-- per David front end do not use avlCnt and refCnt There fore no need in ##GlobalT or even table type @ImportId 
	-- just run exec exec [sp_getImportBOMItems] @ImportId
	
	--05/16/13 YS need to manupulate the data before returning to mark record class red when AVL is red for that record
	DECLARE @iTable importBOM
	DECLARE @tAvlAll tImportBomAvl
	INSERT INTO @iTable 
	exec [sp_getImportBOMItems] @ImportId
	INSERT INTO @tAvlAll exec ImportBomGetAvlToComplete @importId
	-- check for the class = 'i05red' in @tAvlAll, were @iTable class <>'i05red' and replace it with 'i05red'
	
	UPDATE @iTable SET class='i05red' WHERE class<>'i05red' AND rowId IN (SELECT rowId from @tAvlAll where class='i05red')
	-- 08/14/2018: Vijay G: class alises to CssClass. This class used to indicate Mfgr is invalid for specific row on work area grid.
	SELECT class as CssClass,* from @iTable order by CAST(itemno as INT)
	
	
	
 --   -- TODO BY YELENA
 --   -- 1. Add a column showing the count of mfgs in the AVL 

	--DECLARE @itemClass TABLE (rowId uniqueidentifier, class varchar(MAX), [validation] varchar(MAX))
	--DECLARE @iTable importBOM
	
	---- 11/18/12 YS changed the code to allow dynamic structure of the import fields
	----INSERT INTO @iTable
	----SELECT * FROM [dbo].[fn_getImportBOMItems] (@importId)
	---- code to produce dynamic structure
	--DECLARE @SQL as nvarchar(max),@Structure as varchar(max)
	---- build dynamic structure
	--SELECT @Structure =
	--STUFF(
	--(
 --    select  ',' +  F.FIELDNAME  + ' varchar(max) ' 
 --   from importBOMFieldDefinitions F  
 --   ORDER BY FIELDNAME 
 --   for xml path('')
	--),
	--1,1,'')
	---- now create global temp table
	--IF OBJECT_ID('TempDB..##GlobalT') IS NOT NULL
	--	DROP TABLE ##GlobalT;
	--SELECT @SQL = N'
	--create table ##GlobalT (importId uniqueidentifier,rowId uniqueidentifier,uniq_key char(10),'+@Structure+')'
	--exec sp_executesql @SQL		
	---- temp table ##GlobalT with the structure based on the importBOMFieldDefinitions is created 
	---- now insert return from the sp_getImportBOMItems into the global temp table
	--INSERT INTO ##GlobalT EXEC sp_getImportBOMItems @importId
	---- now use ##GlobalT in place of @iTable
	
	
	--INSERT INTO @itemClass
	--SELECT rowId,MAX(status) AS class, MIN(validation)
	--	FROM importBOMFields ibf
	--	WHERE ibf.fkImportId = @importId
	--	GROUP BY rowId
		
	--DECLARE @refCount TABLE(rowId uniqueidentifier,refCnt int)
	--INSERT INTO @refCount
	--SELECT fkRowId,COUNT(refdesg) FROM importBOMRefDesg WHERE fkImportId=@importId GROUP BY fkImportId,fkRowId
	
	--DECLARE @avlCount TABLE(rowId uniqueidentifier,avlCnt int)
	--INSERT INTO @avlCount
	--SELECT i.fkRowId,COUNT(i.adjusted) FROM importBOMAvl i INNER JOIN importBOMFieldDefinitions fd ON i.fkFieldDefId = fd.fieldDefId 
	--	WHERE i.fkImportId=@importId AND fd.fieldName='partMfg' GROUP BY i.fkImportId,i.fkRowId
	
	--SELECT i.*, t2.class, t2.validation,COALESCE(r.refCnt,0)refCnt,COALESCE(a.avlCnt,0)avlCnt
	--	FROM ##GlobalT i 
	--		INNER JOIN @itemClass t2 ON i.rowId = t2.rowId 
	--		LEFT OUTER JOIN @refCount r ON i.rowId=r.rowId
	--		LEFT OUTER JOIN @avlCount a ON i.rowId=a.rowId
	
END