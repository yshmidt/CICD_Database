-- =============================================
-- Author:		David Sharp
-- Create date: 5/4/2012
-- Description:	pivots import items into an importBOM table
-- 10/30/13 DS added the ability to pull a single row
-- =============================================
CREATE FUNCTION [dbo].[fn_getImportBOMItems] (@importId uniqueidentifier, @rowId uniqueidentifier = null)
	RETURNS @iTable TABLE(	
		[importId] uniqueidentifier NOT NULL,
		[rowId] [uniqueidentifier] NOT NULL,
		[uniq_key] [varchar](10) NOT NULL,
		[itemno] [varchar](max)NOT NULL,
		[used] [varchar](max) NOT NULL,
		[partSource] [varchar](max) NOT NULL,
		[partClass] [varchar](max) NOT NULL,
		[partType] [varchar](max) NOT NULL,
		[qty] [varchar](max) NOT NULL,
		[custPartNo] [varchar](max) NOT NULL,
		[crev] [varchar](max) NOT NULL,
		[descript] [varchar](max) NOT NULL,
		[u_of_m] [varchar](max) NOT NULL,
		[warehouse] [varchar](max) NOT NULL,
		[standardCost] [varchar](max) NOT NULL,
		[workCenter] [varchar](max) NOT NULL,
		[partno] [varchar](max) NOT NULL,
		[rev] [varchar](max) NOT NULL,
		[bomNote] varchar(MAX) NOT NULL,
		[invNote] varchar(MAX) NOT NULL
	) AS
BEGIN

	-- Add the SELECT statement with parameter references here
	INSERT INTO @iTable
	SELECT importId,rowId,uniq_key, itemno, used, partSource,partClass,partType,qty,custPartNo,cRev,descript,u_of_m,warehouse,standardCost,workCenter,partno,rev,bomNote,invNote
		FROM
		(SELECT ibf.fkImportId AS importId,ibf.rowId,ibf.uniq_key,fd.fieldName,COALESCE(ibf.adjusted,'')adjusted
			FROM importBOMFieldDefinitions fd INNER JOIN importBOMFields ibf ON fd.fieldDefId = ibf.fkFieldDefId
			WHERE ibf.fkImportId = @importId AND 1=CASE WHEN ibf.rowId=@rowId THEN 1 ELSE 0 END )st
		PIVOT
		(
		MAX(adjusted)
		FOR fieldName IN 
		(itemno, used, partSource,partClass,partType,qty,custPartNo,cRev,descript,u_of_m,warehouse,standardCost,workCenter,partno,rev,bomNote,invNote)
		)AS pvt
	RETURN 
END