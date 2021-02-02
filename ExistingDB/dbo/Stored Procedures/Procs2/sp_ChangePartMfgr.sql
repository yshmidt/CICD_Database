-- =============================================
-- Author:		Vicky Lu
-- Create date: 2012/09/27
-- Description: Change Partmfgr values in all tables (system utility)
-- 04/14/15 YS Location length is changed to varchar(256)
-- =============================================
CREATE PROCEDURE [dbo].[sp_ChangePartMfgr] @lcOldPartMfgr char(8) = ' ', @lcNewPartMfgr char(8) = ' ', @lcUserId char(8) = ' '
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

-- 12/05/12 VL changed @lcmattpControl from bit to char(1)
SET NOCOUNT ON;

DECLARE @ZNewOldMfg TABLE (Uniq_key char(10), PartMfgr char(8), Mfgr_pt_no char(30), UniqMfgrHd char(10), Is_Deleted bit, MatlType char(10))
DECLARE @ZOldNewDupl TABLE (nRecno int, Uniq_key char(10), Mfgr_pt_no char(30), N int)
-- 04/14/15 YS Location length is changed to varchar(256)
DECLARE @ZOldMfgr TABLE (UniqWh char(10), Location varchar(256), W_key char(10), UniqMfgrhd char(10), Qty_oh numeric(12,2), Reserved numeric(12,2), Uniq_key char(10))
DECLARE @ZNewMfgr TABLE (UniqWh char(10), Location varchar(256), W_key char(10), UniqMfgrhd char(10), Qty_oh numeric(12,2), Reserved numeric(12,2), Uniq_key char(10))
DECLARE @ZUpdLoc TABLE (nRecno int, OldW_key char(10), OldUniqMfgrhd char(10), OldQty_oh numeric(12,2), OldReserved numeric(12,2), Uniq_key char(10), UniqWh char(10),
						Location varchar(256), NewW_key char(10), NewUniqMfgrHd char(10))
				
DECLARE @ZUpdTable tTableFieldname

DECLARE @lnTableVarCnt int, @lnTotalCount int, @lnCnt int, @lcOldUniqMfgrHd char(10), @lcNewUniqMfgrHd char(10), @lcUniq_key char(10), 
		@lcMfgr_pt_no char(30), @lnTotalCount2 int, @lnCnt2 int, @lcLocOldW_key char(10), @lcLocNewW_key char(10), @lnLocQty_oh numeric(12,2),
		@lnLocReserved numeric(12,2), @lcMattpControl char(1), @lcUpdString varchar(1000)

SET @lnTotalCount = 0
SET @lnCnt = 0
SELECT @lcMattpControl = cMattpControl FROM InvtSetup
 
BEGIN TRANSACTION
BEGIN TRY;	

-- First get all invtmfhd records that have either old partmfgr or new partmfgr
INSERT @ZNewOldMfg (Uniq_key, Partmfgr, Mfgr_pt_no, UniqMfgrhd, Is_Deleted, MatlType)
	SELECT Uniq_key, Partmfgr, Mfgr_pt_no, Uniqmfgrhd, Is_deleted, MatlType 
		FROM InvtMfhd
		WHERE (Partmfgr = dbo.PADR(@lcOldPartMfgr,8,' ') 
		OR Partmfgr = dbo.PADR(@lcNewPartMfgr,8,' '))
		ORDER BY Uniq_key, Mfgr_pt_no, Partmfgr
	
-- now check if any duplicate combination of the Uniq_key+mfgr_pt_no+partmfgr, only need to check uniq_key and mfgr_pt_no because
-- change from old one to new one partmfgr will cause duplicates
INSERT @ZOldNewDupl (Uniq_key, Mfgr_pt_no, N)
	SELECT Uniq_key, Mfgr_pt_no, COUNT(*) AS N
		FROM @ZNewOldMfg ZnewoldMfg
		GROUP BY Uniq_key, Mfgr_pt_no
		HAVING COUNT(*) > 1

SET @lnTotalCount = @@ROWCOUNT;

-- Update nRecno
SET @lnTableVarCnt = 0
UPDATE @ZOldNewDupl SET @lnTableVarCnt = nRecno = @lnTableVarCnt + 1

-- Start to go through all invtmfhd records that will have duplicate MPN, need to treat differently, need to update invtmfhd and Invtmfgr also all tables with those uniqmfgrhd, w_key
-- What will be done:
-- 1) get old and new invtmfgr, find Mfgr_pt_no+Location in old, but not in new invtmfgr record, will just change uniqmfgrhd to new one
-- 2) delete the old invtmfhd record
-- 3) now left the invtmfgr records that have same mfgr_pt_no+location with new invtmfgr records, will have to join old and new tables
--    then update all other tables (except invtmfgr) old w_key to new w_key, add old qty_oh to new ones, delete old invtmfgr table
-- 4) then update all tables uniqmfgrhd field from old one to new one

IF @lnTotalCount <> 0		
BEGIN
	WHILE @lnTotalCount> @lnCnt
	BEGIN
	SET @lnCnt = @lnCnt + 1	
	SELECT @lcUniq_key = Uniq_key, @lcMfgr_pt_no = Mfgr_pt_no FROM @ZOldNewDupl WHERE nRecno = @lnCnt;
	IF @@ROWCOUNT > 0
		BEGIN
			-- Old Uniqmfgrhd
			SELECT @lcOldUniqMfgrHd = ISNULL(UniqMfgrHd,SPACE(10))
				FROM @ZNewOldMfg
				WHERE Uniq_key = @lcUniq_key
				AND PartMfgr = @lcOldPartMfgr
				AND Mfgr_pt_no = @lcMfgr_pt_no

			-- New Uniqmfgrhd
			SELECT @lcNewUniqMfgrHd = ISNULL(UniqMfgrHd,SPACE(10))
				FROM @ZNewOldMfg
				WHERE Uniq_key = @lcUniq_key
				AND PartMfgr = @lcNewPartMfgr
				AND Mfgr_pt_no = @lcMfgr_pt_no
			
			DELETE FROM @ZOldMfgr
			DELETE FROM @ZNewMfgr
			
			-- Get all Invtmfgr for Old Uniqmfgrhd
			INSERT @ZOldMfgr
				SELECT UniqWh, Location, W_key, UniqMfgrhd, Qty_oh, Reserved, Uniq_key
					FROM INVTMFGR
					WHERE UNIQMFGRHD = @lcOldUniqMfgrHd
			
			-- Get all Invtmfgr for New Uniqmfgrhd
			INSERT @ZNewMfgr
				SELECT UniqWh, Location, W_key, UniqMfgrhd, Qty_oh, Reserved, Uniq_key
					FROM INVTMFGR
					WHERE UNIQMFGRHD = @lcNewUniqMfgrHd
			
			-- Now, get records (Location+UniqWh) that are in old, not in new, will just change invtmfgr.Uniqmfgrhd to new one and delete the old uniqmfgrhd record from invtmfhd
			-- find the location in the old uniqmfgrdh that are not exists for the new one
			--1)
			UPDATE INVTMFGR	
				SET UNIQMFGRHD = @lcNewUniqMfgrHd
				WHERE W_KEY IN 
					(SELECT W_KEY 
						FROM @ZOldMfgr
						WHERE UniqWh+Location NOT IN
							(SELECT UniqWh+Location 
								FROM @ZNewMfgr))
			
			UPDATE Invtmfhd SET IS_DELETED = 0 WHERE Uniqmfgrhd = @lcNewUniqMfgrHd 
			--2)	
			DELETE FROM Invtmfhd WHERE Uniqmfgrhd = @lcOldUniqMfgrHd 

			-- Now will move qty_oh from old one to new one and update w_key in other tables
			--3)
			INSERT @ZUpdLoc (OldW_key, OldUniqMfgrHd, OldQty_oh, OldReserved, Uniq_key, UniqWh, Location, NewW_key, NewUniqMfgrHd)
				SELECT ZOldMfgr.W_key AS oldW_key ,ZOldMfgr.Uniqmfgrhd AS OldUniqMfgrhd,
					ZOldMfgr.qty_oh AS Oldqty_oh, ZOldMfgr.Reserved AS Oldreserved, ZOldMfgr.Uniq_key,
					ZOldMfgr.UniqWh, ZOldMfgr.Location, ZNewMfgr.W_key AS NewW_key,
					ZNewMfgr.Uniqmfgrhd AS NewUniqMfgrhd
					FROM @ZOldMfgr ZOldMfgr, @ZNewMfgr ZNewmfgr 
					WHERE ZNewMfgr.UniqWh+ZNewMfgr.Location = ZOldMfgr.UniqWh+ZOldMfgr.Location

			SET @lnTotalCount2 = @@ROWCOUNT;

			-- Update nRecno
			SET @lnTableVarCnt = 0
			UPDATE @ZUpdLoc SET @lnTableVarCnt = nRecno = @lnTableVarCnt + 1

			IF @lnTotalCount2 <> 0		
			BEGIN
			
				--if any records found, need to replace all the tables, which have w_key field, 
				-- including overw_key and fromwkey and towkey also invtser.id_value
				DELETE FROM @ZUpdTable
				INSERT @ZUpdTable 
					SELECT O.Name AS TableName, C.Name AS FieldName 
						FROM sys.all_objects O, sys.all_columns C
						WHERE O.Object_id = C.Object_id
						AND (LTRIM(RTRIM(C.Name)) = 'w_key'
						OR LTRIM(RTRIM(C.Name)) = 'wkey'
						OR CHARINDEX('w_key',c.name) > 0 
						OR CHARINDEX('wkey',c.name) > 0 
						OR (O.name='invtser' AND c.name = 'id_value'))
						AND Type = 'U'
						AND O.name<>'invtmfgr'
						ORDER BY Tablename			
				
				-- start to update all w_key from old to new (each table that are in @ZUpdTable
				WHILE @lnTotalCount2> @lnCnt2
				BEGIN
				SET @lnCnt2 = @lnCnt2 + 1	
				SELECT @lcLocOldW_key = OldW_key, @lcLocNewW_key = NewW_key, @lnLocQty_oh = OldQty_oh, @lnLocReserved = OldReserved
					FROM @ZUpdLoc WHERE nRecno = @lnCnt;
				IF @@ROWCOUNT > 0
					BEGIN
					-- This sp will go through @ZUpdTable table all table and field to update from @lcLocOldW_key to @lcLocNewW_key
					SELECT @lcUpdString = 'W_key = '''+@lcLocOldW_key + ''''
					EXEC dbo.[sp_GlobalUpdateField] @ZUpdTable, @lcLocNewW_key, @lcUpdString
					-- Move qty_oh from old w_key to new one	
					UPDATE Invtmfgr
						SET QTY_OH = QTY_OH + @lnLocQty_oh,
							RESERVED = RESERVED + @lnLocReserved,
							IS_DELETED = 0 
						WHERE W_KEY = @lcLocNewW_key
					
					DELETE FROM INVTMFGR
						WHERE W_KEY = @lcLocOldW_key
				END	
				END
			END
			--4) now update all table old uniqmfgrhd to new one
			DELETE FROM @ZUpdTable
			INSERT @ZUpdTable
				SELECT O.Name AS TableName, C.Name AS FieldName 
					FROM sys.all_objects O, sys.all_columns C
					WHERE O.Object_id = C.Object_id
					AND (LTRIM(RTRIM(C.Name)) = 'uniqmfgrhd'
					OR CHARINDEX('uniqmfgrhd',c.name) > 0 )
					AND Type = 'U'
					AND O.name<>'invtmfgr'
					AND O.name<>'invtmfhd'
					ORDER BY Tablename
					
			IF @@ROWCOUNT > 0
				BEGIN
				-- This sp will go through @ZUpdTable table all table and field to update from old uniqmfgrhd to new uniqmfgrhd
				SELECT @lcUpdString = 'UniqMfgrhd = '''+@lcOldUniqMfgrHd + ''''
				EXEC dbo.[sp_GlobalUpdateField] @ZUpdTable, @lcNewUniqMfgrHd, @lcUpdString
			END
			
			-- Now will update MatlType if system setup set to auto
			IF @lcMattpControl = 'A'
			BEGIN
				EXEC dbo.sp_UpdOneInvMatlType @lcUniq_key, @lcUserId
			END
		END
	END
END

-- After deal with duplicate MPN, now can change partmfgr of all tables from old value to new ones
DELETE FROM @ZUpdTable
INSERT @ZUpdTable
	SELECT O.Name AS TableName, C.Name AS FieldName 
		FROM sys.all_objects O, sys.all_columns C
		WHERE O.Object_id = C.Object_id
		AND (LTRIM(RTRIM(C.Name)) = 'partmfgr'
		OR CHARINDEX('partmfgr',c.name) > 0 )
		AND Type = 'U'
		ORDER BY Tablename
IF @@ROWCOUNT > 0
	BEGIN
	-- This sp will go through @ZUpdTable table all table and field to update from old partmfgr to new ones
	SELECT @lcUpdString = 'Partmfgr = '''+@lcOldPartMfgr+''''
	EXEC dbo.[sp_GlobalUpdateField] @ZUpdTable, @lcNewPartMfgr, @lcUpdString
END		
			
END TRY

BEGIN CATCH
	RAISERROR('Error occurred in changing part manufacturer from current to new ones. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END	