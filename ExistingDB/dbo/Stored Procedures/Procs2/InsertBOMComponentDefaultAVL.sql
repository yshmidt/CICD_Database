-- =============================================
-- Author:Vijay G
-- Create date: 12/03/2018
-- Description:	Insert BOM Component Default AVL if Manufacture are not Provide from bom Imports
-- [InsertBOMComponentDefaultAVL] '3723A134-71E1-48DE-BDF2-26F89298CC31'   
-- =============================================
CREATE PROCEDURE [dbo].[InsertBOMComponentDefaultAVL] 
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier
AS
BEGIN
SET NOCOUNT ON;

DECLARE @iTable importBom

DECLARE @AvlDefaultData TABLE(
    id INT,
	rowid UNIQUEIDENTIFIER,
	PARTMFGR CHAR(8),
	MFGR_PT_NO CHAR(30),
	MATLTYPE CHAR(10)
)

DECLARE @rowid UNIQUEIDENTIFIER,@CustNo char(10)

Set @CustNo =(SELECT custNo FROM importBOMHeader WHERE importId =@importId)

IF(@CustNo ='000000000~')
BEGIN
    SET @CustNo =''
END
 
INSERT INTO @iTable  
EXEC [dbo].[sp_getImportBOMItems] @importId 

DECLARE defaultAvl_cursor CURSOR FOR
SELECT rowid FROM @iTable

OPEN defaultAvl_cursor;
FETCH NEXT FROM defaultAvl_cursor
INTO @rowid;

WHILE @@FETCH_STATUS = 0
BEGIN

	IF NOT EXISTS (SELECT * FROM @iTable t INNER JOIN importBOMAvl av ON t.rowid =av.fkRowId and t.rowid =@rowid)
	BEGIN
	        INSERT INTO @AvlDefaultData(id,rowid,MFGR_PT_NO,PARTMFGR,MATLTYPE) 
			SELECT Row_Number() Over ( Order By @rowid, mfMaster.MFGR_PT_NO,mfMaster.PARTMFGR,mfMaster.MATLTYPE ), @rowid, mfMaster.MFGR_PT_NO,mfMaster.PARTMFGR,mfMaster.MATLTYPE 
			FROM @iTable t 
			INNER JOIN INVENTOR i ON ( 
										 (
												 t.partNo =i.PART_NO AND t.rev = i.REVISION AND  i.CUSTNO = @CustNo  AND t.custPartNo = i.CUSTPARTNO 
												 AND  t.crev = i.CUSTREV 
										 )
									)
			INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY
			INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId
			WHERE t.rowid =@rowid 
			AND mpn.Is_deleted = 0 
			AND mfMaster.IS_DELETED=0 

			DECLARE @MAXID INT, @Counter INT

			SET @COUNTER = 1
			SELECT @MAXID = COUNT(*) FROM @AvlDefaultData

			WHILE (@COUNTER <= @MAXID)
			BEGIN
				 DECLARE @avlRowId UNIQUEIDENTIFIER =NEWID()

				INSERT INTO importBOMAvl(fkImportId,fkFieldDefId,fkRowId,adjusted,original,[load],[bom],avlRowId)
				SELECT @importId, (SELECT FieldDefId FROM importBOMFieldDefinitions WHERE fieldName ='partMfg'),rowid,PARTMFGR,PARTMFGR,CAST(0 as bit),CAST(1 AS BIT),@avlRowId
				FROM @AvlDefaultData
				WHERE id = @COUNTER

				INSERT INTO importBOMAvl(fkImportId,fkFieldDefId,fkRowId,adjusted,original,[load],[bom],avlRowId)
				SELECT @importId, (SELECT FieldDefId FROM importBOMFieldDefinitions WHERE fieldName ='mpn'),rowid,MFGR_PT_NO,MFGR_PT_NO,CAST(0 AS BIT),CAST(1 AS BIT),@avlRowId
				FROM @AvlDefaultData
				WHERE id = @COUNTER

				INSERT INTO importBOMAvl(fkImportId,fkFieldDefId,fkRowId,adjusted,original,[load],[bom],avlRowId)
				SELECT @importId, (SELECT FieldDefId FROM importBOMFieldDefinitions WHERE fieldName ='matlType'),rowid,MATLTYPE,MATLTYPE,CAST(0 AS BIT),CAST(1 AS BIT),@avlRowId
				FROM @AvlDefaultData
				WHERE id = @COUNTER

				SET @COUNTER = @COUNTER + 1
			END

			DELETE FROM @AvlDefaultData
	END
	FETCH NEXT FROM defaultAvl_cursor
	INTO @rowid;
END;	

CLOSE defaultAvl_cursor;
DEALLOCATE defaultAvl_cursor;

END