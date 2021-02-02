-- =============================================
-- Author:		David Sharp
-- Create date: 8/30/2010
-- Description:	Compares two BoMs
-- 10/17/14 DS Started adding AVL and Ref Desg comparison
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- =============================================
CREATE PROCEDURE [dbo].[importBOMCompare] 
	-- Add the parameters for the stored procedure here
	@oUniq_key AS char(10), 
	@importId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Declare Temp Tables
	DECLARE @nBOM importBOM
	DECLARE @newBom TABLE(
		[UNIQ_KEY] char(10),
		[ITEM_NO] numeric(4, 0),
		[PART_SOURC] char(10),
		[PART_CLASS] char(8),
		[PART_TYPE] char(8),
		[DESCRIPT] char(45),
		[QTY] numeric(9, 2),
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
		[PART_NO] char(35),
		[REVISION] char(8),	
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
		[CUSTPARTNO] char(35),
		[CUSTREV] char(8),
		[DEPT_ID] char(4),	
		[ITEM_NOTE] text,
		[USED_INKIT] char(1),
		[U_OF_MEAS] char(4),						
		[STDCOST] numeric(13, 5)
	)
	DECLARE @nAVL TABLE(
		avlRowId uniqueidentifier,
		oMfg varchar(MAX),
		mfg varchar(MAX),
		oMpn varchar(MAX),
		mpn varchar(MAX),
		oMatlType varchar(MAX),
		matlType varchar(MAX),
		bom bit,
		[load] bit,
		[cust] bit,
		class varchar(500),
		[validation] varchar(200),
		uniqmfgrhd varchar(200),
		msg varchar(MAX)
	)
	DECLARE @newAVL TABLE(
		[UNIQ_KEY] char(10),
		uniqmfgrhd varchar(200),
		bom bit
	)
	DECLARE @newRefDesg TABLE(
		[UNIQ_KEY] char(10),
		refdesg varchar(200)
	)

	DECLARE	@oldBom TABLE(
		[BOMPARENT] char(10),
		[UNIQ_KEY] char(10),
		[ITEM_NO] numeric(4, 0),
		[PART_SOURC] char(10),
		[PART_CLASS] char(8),
		[PART_TYPE] char(8),
		[DESCRIPT] char(45),
		[QTY] numeric(9, 2),
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
		[PART_NO] char(35),
		[REVISION] char(8),
		--- 03/28/17 YS changed length of the part_no column from 25 to 35	
		[CUSTPARTNO] char(35),
		[CUSTREV] char(8),
		[DEPT_ID] char(4),	
		[ITEM_NOTE] text,
		[USED_INKIT] char(1),
		[U_OF_MEAS] char(4),						
		[STDCOST] numeric(13, 5),
		[TERM_DT] smalldatetime,
		[EFF_DT] smalldatetime	
	)
	
	INSERT INTO @nBOM
	exec [sp_getImportBOMItems] @importId

	INSERT @newBom([UNIQ_KEY],[ITEM_NO],[PART_NO],[REVISION],[DESCRIPT],[QTY],[CUSTPARTNO],[CUSTREV],[STDCOST])
		SELECT uniq_key,itemno,partno,rev,descript,qty,custPartNo,cRev,standardCost
			FROM @nBOM
		WHERE importId=@importId
	--SELECT uniq_key,ITEM_NO,PART_NO,REVISION,descript,qty,custPartNo,CUSTREV,STDCOST FROM @newBom

	INSERT INTO @nAVL
	exec importBOMAVLAllGet @importId

	INSERT INTO @newAVL
	SELECT i.uniq_key,a.uniqmfgrhd,a.bom 
		FROM @nAVL a 
			INNER JOIN (SELECT DISTINCT fkRowId,avlRowId FROM importBOMAvl) ia ON ia.avlRowId = a.avlRowId
			INNER JOIN @nBOM AS i on ia.fkRowId = i.rowId


	INSERT @oldBom([BOMPARENT],[UNIQ_KEY],[ITEM_NO],[PART_NO],[REVISION],[DESCRIPT],[QTY],[CUSTPARTNO],[CUSTREV],[STDCOST])
	SELECT bd.BOMPARENT,bd.UNIQ_KEY, bd.ITEM_NO,i.PART_NO,i.REVISION,i.DESCRIPT,bd.QTY,i2.CUSTPARTNO,i2.CUSTREV,i.STDCOST FROM BOM_DET bd 
		INNER JOIN INVENTOR i ON i.UNIQ_KEY=bd.UNIQ_KEY 
		LEFT OUTER JOIN INVENTOR i2 ON i.UNIQ_KEY = i2.INT_UNIQ
		WHERE bd.BOMPARENT = @oUniq_key

	SELECT UNIQ_KEY, ITEM_NO, MIN(part_no) ViewPartNo, revision, MIN(Qty) Qty, USED_INKIT,
			CASE WHEN MIN(Source) = 'B' THEN 'REMOVED'
				WHEN MAX(Source) = 'A' THEN 'ADDED'
				WHEN MIN(Qty) = MAX(Qty) THEN 'SAME'
				ELSE 'QTY CHANGE' END Result
			--,CASE WHEN MIN(Source) = 'B' THEN @oUniq_key
			--	ELSE @nUniq_key END BOMPARENT
	FROM (
			SELECT	UNIQ_KEY, ITEM_NO, PART_NO, REVISION, QTY, USED_INKIT, 'A' AS Source 
			FROM	@newBom
			
			UNION ALL 
			
			SELECT	UNIQ_KEY, ITEM_NO, PART_NO, REVISION, QTY, USED_INKIT, 'B' AS Source
			FROM	@oldBom
			WHERE	(EFF_DT IS NULL OR EFF_DT <= GETDATE()) AND (TERM_DT IS NULL OR TERM_DT >= GETDATE())
		) U
	GROUP BY UNIQ_KEY, ITEM_NO, REVISION, USED_INKIT
	ORDER BY ITEM_NO
	
END