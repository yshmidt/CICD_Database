-- =============================================
-- Author:		David Sharp
-- Create date: 4/16/2012
-- Description:	gets all adjusted values for the selected import record
-- 06/26/13 YS use new fnKeepAlphaNumeric() function that uses PATINDEX() to keep alpha-numeric charcaters only in place of fn_RemoveSpecialCharacters()
--10/13/14 YS removed invtmfhd table and replaced with 2 new tables	
-- 09/17/15 DS extend size for 'rev'
-- =============================================
CREATE PROCEDURE [dbo].[importBOMAvlAllGet] 
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @lock varchar(10)='i00lock'
	
	DECLARE @custno varchar(10),@uniq_key varchar(10)
	--05/21/13 YS check for NULL or standard price customer that is the same as no customer
	SELECT @custno = CASE WHEN Custno IS NULL or custno='000000000~' THEN ' ' ELSE Custno END FROM importBOMHeader WHERE importId = @importId
	--!!! Single uniq_key, this should create an error
	SELECT @uniq_key = uniq_key FROM importBOMFields WHERE fkImportId=@importId
	
    DECLARE @iTableA TABLE (rowId uniqueidentifier, avlRowId uniqueidentifier,uniqmfgrhd varchar(10),mfg varchar(MAX),mpn varchar(MAX),matlType varchar(MAX)) 
    DECLARE @iTableO TABLE (rowId uniqueidentifier, avlRowId uniqueidentifier,uniqmfgrhd varchar(10),mfg varchar(MAX),mpn varchar(MAX),matlType varchar(MAX)) 
	DECLARE @itemClass TABLE (avlRowId uniqueidentifier, bom bit, [load] bit, class varchar(MAX), [validation] varchar(MAX),uniqmfgrhd varchar(20))
	DECLARE @cAvl TABLE (int_uniq varchar(10),partno varchar(50),rev varchar(8),mpn varchar(50),mfg varchar(100),matlType varchar(20),uniqmfgrhd varchar(20),cust bit)
	
	-- Get the adjusted values pivoted
	INSERT INTO @iTableA
	SELECT rowId, avlRowId, uniqmfgrhd, partMfg, mpn, matlType
		FROM
		(SELECT iba.fkRowId AS rowId, iba.avlRowId,iba.uniqmfgrhd, fd.fieldName,iba.adjusted
			FROM importBOMFieldDefinitions fd inner join importBOMAvl iba ON fd.fieldDefId = iba.fkFieldDefId
			WHERE iba.fkImportId = @importId)st
		PIVOT
		(
		MAX(adjusted)
		FOR fieldName IN 
		(partMfg,mpn,matlType)
		)AS pvt
		
	-- Get the original values pivoted
	INSERT INTO @iTableO
	SELECT rowId, avlRowId, uniqmfgrhd, partMfg, mpn, matlType
		FROM
		(SELECT iba.fkRowId AS rowId,iba.avlRowId,iba.uniqmfgrhd, fd.fieldName,iba.original
			FROM importBOMFieldDefinitions fd inner join importBOMAvl iba ON fd.fieldDefId = iba.fkFieldDefId
			WHERE iba.fkImportId = @importId)st
		PIVOT
		(
		MAX(original)
		FOR fieldName IN 
		(partMfg,mpn,matlType)
		)AS pvt
	
	-- Get the avlRow class, type, bom etc.
	INSERT INTO @itemClass
	SELECT avlRowId AS rowId,MAX(CAST(bom AS int)),/*CASE WHEN NOT MAX(uniqmfgrhd)IS NULL THEN null /*WHEN MAX(uniqmfgrhd)<>'' THEN null*/ ELSE*/ MAX(CAST([load] AS INT)) /*END*/,MAX(status) AS class, MIN(validation),MIN(uniqmfgrhd)
		FROM importBOMAvl iba
		WHERE iba.fkImportId = @importId
		GROUP BY fkRowId,avlRowId
	
	-- Get a list of all AVLs tied to the selected internal partnumber and indicate if connected to the import customer AVL
	--10/13/14 YS removed invtmfhd table and replaced with 2 new tables
	INSERT INTO @cAvl(int_uniq,partno,rev,mfg,mpn,matlType,uniqmfgrhd,cust)	
	SELECT i.UNIQ_KEY,part_no,revision,m.PARTMFGR,m.MFGR_PT_NO,m.MATLTYPE,h.UNIQMFGRHD,ISNULL(z.cust,CAST(0 as bit))cust
		--10/13/14 YS removed invtmfhd table and replaced with 2 new tables
		--FROM	INVENTOR i INNER JOIN INVTMFHD h ON i.uniq_key = h.uniq_key 
		FROM	INVENTOR i INNER JOIN InvtMPNLink h ON i.uniq_key = h.uniq_key 
		INNER JOIN MfgrMaster M ON H.mfgrMasterId=M.MfgrMasterId
					LEFT OUTER JOIN 
					(SELECT CAST(1 as bit) AS cust,m.MFGR_PT_NO 
						--10/13/14 YS removed invtmfhd table and replaced with 2 new tables
						--FROM INVENTOR i INNER JOIN INVTMFHD h1 ON i.uniq_key = h1.uniq_key
						FROM INVENTOR i INNER JOIN InvtMPNLink h1 ON i.uniq_key = h1.uniq_key
						INNER JOIN MfgrMaster M ON H1.mfgrMasterId=m.MfgrMasterId
						WHERE  i.INT_UNIQ=@uniq_key AND i.CUSTNO = @custno and h1.IS_DELETED =0 ) Z ON z.MFGR_PT_NO=m.MFGR_PT_NO
		WHERE i.UNIQ_KEY=@uniq_key AND h.IS_DELETED=0
			

	-- Join the results
	--AVL added by import, does not exist
	-- 06/26/13 YS use new fnKeepAlphaNumeric() function that uses PATINDEX() to keep alpha-numeric charcaters only in place of fn_RemoveSpecialCharacters()
	SELECT CAST(a.avlRowId AS varchar(50))avlRowId,o.mfg oMfg,a.mfg,o.mpn oMpn,a.mpn,o.matlType oMatlType,a.matlType, t2.bom,t2.[load] AS [load],CAST(c.cust as bit)cust, t2.class, t2.[validation],c.uniqmfgrhd,'newAVL'	
	FROM @iTableA a 
		INNER JOIN @itemClass t2 ON a.avlRowId = t2.avlRowId 
		INNER JOIN @iTableO o ON a.avlRowId=o.avlRowId
		LEFT OUTER JOIN @cAvl c ON a.mfg=c.mfg AND 
			dbo.fnKeepAlphaNumeric(a.mpn)=dbo.fnKeepAlphaNumeric(c.mpn)
		WHERE c.mfg IS NULL
	UNION ALL
	--existing AVLs added to import row
	SELECT CAST(a.avlRowId AS varchar(50))avlRowId,o.mfg oMfg,a.mfg,o.mpn oMpn,a.mpn,o.matlType oMatlType,a.matlType, t2.bom, 
			null [load],isnull(c.cust,CAST(0 as bit))cust, @lock, t2.[validation],c.uniqmfgrhd,'exist & connected'
		FROM @iTableA a 
			INNER JOIN @itemClass t2 ON a.avlRowId = t2.avlRowId 
			INNER JOIN @iTableO o ON a.avlRowId=o.avlRowId
			INNER JOIN @cAvl c ON a.mfg=c.mfg AND 
				dbo.fnKeepAlphaNumeric(a.mpn)=dbo.fnKeepAlphaNumeric(c.mpn)
			WHERE NOT c.mfg IS NULL
	UNION ALL
	--existing AVL not added to import row
	SELECT NEWID(),'',c.mfg,'',c.mpn,'',c.matlType,isnull(c.cust,CAST(0 AS bit)),CAST(null AS bit),c.cust,'i00grey','01system',c.uniqmfgrhd,'exists not connected'
		FROM @cAvl c 
			LEFT OUTER JOIN @iTableA a ON c.mfg=a.mfg AND 
				dbo.fnKeepAlphaNumeric(c.mpn)=dbo.fnKeepAlphaNumeric(a.mpn)
		WHERE a.mfg IS NULL
	
	--SELECT CAST(a.avlRowId AS varchar(50))avlRowId,o.mfg oMfg,a.mfg,o.mpn oMpn,a.mpn,o.matlType oMatlType,a.matlType, t2.bom,t2.[load] AS [load],CAST(c.cust as bit)cust, t2.class, t2.[validation],c.uniqmfgrhd,'newAVL'	
	--FROM @iTableA a 
	--	INNER JOIN @itemClass t2 ON a.avlRowId = t2.avlRowId 
	--	INNER JOIN @iTableO o ON a.avlRowId=o.avlRowId
	--	LEFT OUTER JOIN @cAvl c ON a.mfg=c.mfg AND 
	--		REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(a.mpn)),' ','')=REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(c.mpn)),' ','')
	--	WHERE c.mfg IS NULL
	--UNION ALL
	----existing AVLs added to import row
	--SELECT CAST(a.avlRowId AS varchar(50))avlRowId,o.mfg oMfg,a.mfg,o.mpn oMpn,a.mpn,o.matlType oMatlType,a.matlType, t2.bom, 
	--		null [load],isnull(c.cust,CAST(0 as bit))cust, @lock, t2.[validation],c.uniqmfgrhd,'exist & connected'
	--	FROM @iTableA a 
	--		INNER JOIN @itemClass t2 ON a.avlRowId = t2.avlRowId 
	--		INNER JOIN @iTableO o ON a.avlRowId=o.avlRowId
	--		INNER JOIN @cAvl c ON a.mfg=c.mfg AND 
	--			REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(a.mpn)),' ','')=REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(c.mpn)),' ','')
	--		WHERE NOT c.mfg IS NULL
	--UNION ALL
	----existing AVL not added to import row
	--SELECT NEWID(),'',c.mfg,'',c.mpn,'',c.matlType,isnull(c.cust,CAST(0 AS bit)),CAST(null AS bit),c.cust,'i00grey','01system',c.uniqmfgrhd,'exists not connected'
	--	FROM @cAvl c 
	--		LEFT OUTER JOIN @iTableA a ON c.mfg=a.mfg AND 
	--			REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(c.mpn)),' ','')=REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(a.mpn)),' ','')
	--	WHERE a.mfg IS NULL



	--SELECT * FROM @itemClass
	--SELECT CAST(a.avlRowId AS varchar(50))avlRowId,o.mfg oMfg,a.mfg,o.mpn oMpn,a.mpn,o.matlType oMatlType,a.matlType, t2.bom,isnull(t2.[load],CAST(0 as bit))[load],CAST(c.cust as bit)cust, t2.class, t2.[validation],c.uniqmfgrhd	
	--FROM @iTableA a 
	--	INNER JOIN @itemClass t2 ON a.avlRowId = t2.avlRowId 
	--	INNER JOIN @iTableO o ON a.avlRowId=o.avlRowId
	--	LEFT OUTER JOIN @cAvl c ON a.mfg=c.mfg AND 
	--		REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(a.mpn)),' ','')=REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(c.mpn)),' ','')
	--	WHERE c.mfg IS NULL
	--SELECT CAST(a.avlRowId AS varchar(50))avlRowId,o.mfg oMfg,a.mfg,o.mpn oMpn,a.mpn,o.matlType oMatlType,a.matlType, t2.bom, 
	--		null [load],isnull(c.cust,CAST(0 as bit))cust, @lock, t2.[validation],c.uniqmfgrhd	
	--	FROM @iTableA a 
	--		INNER JOIN @itemClass t2 ON a.avlRowId = t2.avlRowId 
	--		INNER JOIN @iTableO o ON a.avlRowId=o.avlRowId
	--		INNER JOIN @cAvl c ON a.mfg=c.mfg AND 
	--			REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(a.mpn)),' ','')=REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(c.mpn)),' ','')
	--		WHERE NOT c.mfg IS NULL
	--SELECT NEWID(),'',c.mfg,'',c.mpn,'',c.matlType,isnull(c.cust,CAST(0 AS bit)),CAST(null AS bit),c.cust,'i00grey','01system',c.uniqmfgrhd
	--	FROM @cAvl c 
	--		LEFT OUTER JOIN @iTableA a ON c.mfg=a.mfg AND 
	--			REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(c.mpn)),' ','')=REPLACE(UPPER(dbo.fn_RemoveSpecialCharacters(a.mpn)),' ','')
	--	WHERE a.mfg IS NULL

END