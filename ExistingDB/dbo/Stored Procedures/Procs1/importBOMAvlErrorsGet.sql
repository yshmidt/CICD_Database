-- =============================================
-- Author:		David Sharp
-- Create date: 4/16/2012
-- Description:	get current errors for selected importId
-- =============================================
CREATE PROCEDURE [dbo].[importBOMAvlErrorsGet] 
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier,@rowId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	---- Get a list of all AVLs tied to the selected internal partnumber and indicate if connected to the import customer AVL
	--DECLARE @custno varchar(10),@uniq_key varchar(10)
	--SELECT @custno = custno FROM importBOMHeader WHERE importId = @importId
	--SELECT @uniq_key = uniq_key FROM importBOMFields WHERE fkImportId=@importId AND rowId=@rowId
	--DECLARE @cAvl TABLE (int_uniq varchar(10),mfg varchar(100),mpn varchar(100),matlType varchar(100))
	
	--INSERT INTO @cAvl(int_uniq,mfg,mpn,matlType)	
	--SELECT i.UNIQ_KEY,PARTMFGR,h.MFGR_PT_NO,h.MATLTYPE
	--	FROM	INVENTOR i INNER JOIN INVTMFHD h ON i.uniq_key = h.uniq_key 
	--				LEFT OUTER JOIN 
	--				(SELECT CAST(1 as bit) AS cust,h1.MFGR_PT_NO FROM INVENTOR i INNER JOIN INVTMFHD h1 ON i.uniq_key = h1.uniq_key
	--					WHERE  i.INT_UNIQ=@uniq_key AND i.CUSTNO = @custno and IS_DELETED <> 1 ) Z ON z.MFGR_PT_NO=h.MFGR_PT_NO
	--	WHERE i.UNIQ_KEY=@uniq_key AND IS_DELETED<>1
		
	
    -- Insert statements for procedure here
	SELECT i.avlRowId,fd.fieldName,i.[message] AS title, i.[status] AS class 
		FROM importBOMFieldDefinitions fd inner join importBOMAvl i ON fd.fieldDefId = i.fkFieldDefId
		WHERE (i.fkImportId = @importId) AND (i.fkRowId = @rowId) AND (i.[status] <> 'i00skipped') --AND(i.[status] <> 'i00white')
	--UNION ALL
	--SELECT rowId,fieldName,[title],class
	--	FROM(
	--	SELECT NEWID()AS rowId,mfg,mpn,matlType,'i00lock' AS class,'existing AVL' AS [title]
	--	FROM @cAvl)p
	--UNPIVOT
	--	(adjusted FOR fieldName IN 
	--		(mfg,mpn,matlType)
	--) AS u 	

END