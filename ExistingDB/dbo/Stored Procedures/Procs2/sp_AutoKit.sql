-- =============================================
-- Author:		Vicky Lu
-- Create date: 2015/04/28
-- Description:	AutoKit for @gWono
---03/02/18 YS change size of the lotcode field to 25
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[sp_AutoKit] @gWono AS char(10) = ' ', @lcUserID AS char(8)
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
BEGIN TRANSACTION
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
DECLARE @KitReq TABLE (Dept_id char(4), Uniq_key char(10), BomParent char(10), Qty numeric(9,2), ShortQty numeric(9,2),
		Used_inKit char(1), Part_Sourc char(8), Part_no char(35), Revision char(8), Descript char(45), Part_class char(8), 
		Part_type char(8), U_of_meas char(4), Scrap numeric(6,2), SetupScrap numeric(4,0), CustPartNo char(35), SerialYes bit)
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
DECLARE @Zinvtresh TABLE (Dept_id char(4), Uniq_key char(10), BomParent char(10), Qty numeric(9,2), ShortQty numeric(9,2),
		Used_inkit char(1), Part_sourc char(8), Part_no char(35), Revision char(4), Descript char(45), Part_class char(8), 
		Part_type char(8), U_of_meas char(4), Scrap numeric(6,2), SetupScrap numeric(4,0), CustPartNo char(35), SerialYes bit, 
		ReqQty numeric(12,2), LotDetail bit, nrecno int)

-- 05/01/15 VL added BomCustno and replace with @BomCustno to left outer join to speed up
	---03/02/18 YS change size of the lotcode field to 25
DECLARE	@KitInvtView TABLE (QtyNotReserved numeric(12,2), LotQtyNotReserved numeric(12,2), QtyOh numeric(12,2), 
	LotQtyOh numeric(12,2), QtyReserved numeric(12,2), LotQtyReserved numeric(12,2), Uniq_key char(10), Partmfgr char(8), 
	InStore bit, UniqSupno char(10), Mfgr_pt_no char(30), Wh_gl_nbr char(13), UniqWh char(10), Location varchar(256), 
	W_key char(10), OrderPref INT, Lotcode nvarchar(25), Expdate smalldatetime, Ponum char(15), Reference char(12), 
	Warehouse char(6), UniqMfgrhd char(10), Bomparent char(10))
	---03/02/18 YS change size of the lotcode field to 25
DECLARE @KitAvailRep TABLE (Approved char(1), AvailQty Numeric(12,2), QtyOh Numeric(12,2), QtyReserved Numeric(12,2), ThisAlloc Numeric(12,2) DEFAULT 0.00,
	Uniq_key char(10), PartMfgr char(8), Mfgr_pt_no char(30), W_key char(10), Whno char(3), Location varchar(256), Warehouse char(6),
	cUniqKey char(10), Lotcode nvarchar(25), Expdate smalldatetime, Ponum char(15), Reference char(12), inStore bit, UniqSupno char(10), 
	OrderPref numeric(2), QtyNOTReserved numeric(12,2), AllocToProject Numeric(12,2) DEFAULT 0.00, UniqMfgrHd char(10), Bomparent char(10), BomCustno char(10))		
	---03/02/18 YS change size of the lotcode field to 25
DECLARE @ZInvtResD TABLE (Approved char(10), Warehouse char(6), Location char(17), Partmfgr char(8), Mfgr_pt_no char(30), Availqty numeric(12,2),
	QtyIssue numeric(12,2), LotCode nvarchar(25), Expdate smalldatetime, Reference char(15), W_key char(10), Qtyoh numeric(12,2), QtyReserved numeric(12,2),
	Uniq_key char(10), Ponum char(15), Wono char(10), DateTime smalldatetime, Saveinit char(8), Invtres_no char(10), ThisAlloc numeric(12,2), InStore bit,
	UniqSupno char(10), OrderPref numeric(2), AllocToProject numeric(12,2), UniqMfgrHd char(10), nrecno int)	

DECLARE @UPM tUPM
DECLARE @UPMresult TABLE (UniqMfgrhd char(10), UNIQ_KEY char(10), MFGR_PT_NO char(30), Partmfgr char(8), lDisallowbuy bit)
	---03/02/18 YS change size of the lotcode field to 25
DECLARE @llKitAllowNonNettable bit, @BomCustno char(10), @PrjUnique char(10), @lnTotalNo int, @lnCount int, @ReqQty numeric(12,2), 
		@Wono char(10), @Dept_id char(10), @Uniq_key char(10), @Bomparent char(10),  @Qty numeric(12,2), @Kaseqnum char(10), @lnTableVarCnt int,
		@lnTotalNo2 int, @lnCount2 int, @LotDetail bit, @lnOffset int = 0, @ThisAlloc numeric(12,2), @AllocToProject numeric(12,2), @IssuedQty numeric(12,2) = 0,
		@chkQtyIssue numeric(12,2) = 0, @W_key char(10), @Lotcode nvarchar(25), @Expdate smalldatetime, @Ponum char(15), @Reference char(12), @UniqMfgrHd char(10),
		@chkShortQty numeric(12,2) = 0, @U_of_meas char(4), @AvailQty numeric(12,2), @lIsKitCreated bit

SELECT @llKitAllowNonNettable = lKitAllowNonNettable FROM KitDef
SELECT @BomCustno = BomCustno FROM INVENTOR WHERE Uniq_key = (SELECT UNIQ_KEY FROM WOENTRY WHERE WONO = @gWono)
SELECT @PrjUnique = PrjUnique FROM Woentry WHERE Wono = @gWono

-- Add to check if Kamain record already exist, can not run auto kit 
-- if Only first time
SELECT @lIsKitCreated = CASE WHEN EXISTS (SELECT 1 FROM KAMAIN WHERE WONO = @gWono) THEN 1 ELSE 0 END
IF @lIsKitCreated = 1
	BEGIN
	RAISERROR('KIT has been pulled.  Can not run auto-kit again.  This operation will be cancelled.',1,1)
	ROLLBACK TRANSACTION
	RETURN
END

-- Get BOM info for this kit
INSERT @KitReq EXEC [KitBomInfoView] @gWono;

-- Auto Kit header table, will use it to insert into kamain
SET @lnTableVarCnt = 0
INSERT @Zinvtresh SELECT ZKitReq.*, ZKitReq.ShortQty AS ReqQty, ISNULL(LotDetail,CAST(0 as bit)) as LotDetail, 0 AS nRecno
	FROM @KitReq ZKitReq LEFT OUTER JOIN PARTTYPE ON ZKitReq.Part_class = Parttype.PART_CLASS
	AND ZKitReq.Part_type = Parttype.Part_type

UPDATE @Zinvtresh SET @lnTableVarCnt = nRecno = @lnTableVarCnt + 1
SELECT @lnTotalNo = @lnTableVarCnt

-- Get available qty_oh
-- try to separate into two CTE cursors to speed up
;WITH ZInvtMF AS
(
SELECT DISTINCT I.qty_oh-I.reserved AS QtyNotReserved, I.qty_oh AS QtyOh, I.reserved AS QtyReserved, I.Uniq_key, M.Partmfgr, I.InStore, 
		I.UniqSupNo, M.Mfgr_pt_no, I.UniqWh, I.Location, I.W_key, L.OrderPref, L.UniqMfgrHd, I.NetAble, M.lDisallowKit, I.CountFlag
	FROM Invtmfgr I , InvtMPNLink L, MfgrMaster M
	WHERE L.UniqMfgrHd = I.UniqMfgrHd 
	AND L.mfgrMasterId=M.MfgrMasterId
	AND M.lDisallowKit = 0
	AND (@llKitAllowNonNettable = 1 
	OR (@llKitAllowNonNettable = 0 AND I.NetAble = 1))	
	AND I.CountFlag= SPACE(1)
	AND L.IS_DELETED = 0 
	AND M.IS_DELETED = 0
	AND I.Is_Deleted = 0
	AND I.Uniq_key IN (SELECT Uniq_key FROM @KitReq)
),
ZKitInvt AS
(
SELECT ZInvtMF.*, Warehous.Wh_gl_nbr, Warehous.Warehouse, KitReq.Bomparent
	FROM Warehous, @KitReq KitReq, ZInvtMF
	WHERE KitReq.Uniq_key = ZInvtMF.Uniq_key 
	AND ZInvtMF.UniqWh = Warehous.UniqWh
	AND Warehouse<>'MRB' AND Warehouse <> 'WIP' AND Warehouse <>'WO-WIP'
	AND Warehous.lNotAutoKit = 0
)
-- OLD CODE
--;WITH ZKitInvt AS
--(
--	SELECT DISTINCT Invtmfgr.qty_oh-Invtmfgr.reserved AS QtyNotReserved,
--		Invtmfgr.qty_oh AS QtyOh, Invtmfgr.reserved AS QtyReserved, Invtmfgr.Uniq_key,
--		Invtmfhd.Partmfgr, Invtmfgr.InStore, InvtMfgr.UniqSupNo,
--		Invtmfhd.Mfgr_pt_no, Warehous.Wh_gl_nbr, Invtmfgr.UniqWh,
--		Invtmfgr.Location, Invtmfgr.W_key, Invtmfhd.OrderPref, Warehous.Warehouse, 
--		Invtmfhd.UniqMfgrHd, Invtmfgr.NetAble, InvtMfhd.lDisallowKit, Invtmfgr.CountFlag, Bomparent
--	FROM Warehous, @KitReq KitReq, Invtmfgr, Invtmfhd
--	WHERE KitReq.Uniq_key = Invtmfgr.Uniq_key 
--	AND Invtmfgr.UniqWh = Warehous.UniqWh
--	AND Invtmfhd.UniqMfgrHd = Invtmfgr.UniqMfgrHd 
--	AND Invtmfhd.lDisallowKit = 0
--	AND 1 = (CASE WHEN @llKitAllowNonNettable = 1 THEN 1 ELSE Invtmfgr.NetAble END)
--	AND Warehouse<>'MRB' AND Warehouse <> 'WIP' AND Warehouse <>'WO-WIP'
--	AND Warehous.lNotAutoKit = 0
--	AND Invtmfgr.CountFlag= SPACE(1)
--	AND Invtmfhd.Is_deleted = 0
--	AND Invtmfgr.Is_Deleted = 0
--)

-------------------------
-- available qty OH to issue
INSERT INTO @KitAvailRep (QtyOh, QtyReserved, Uniq_key, PartMfgr, Mfgr_pt_no, W_key, Location, Warehouse, Lotcode, Expdate, Ponum, Reference, inStore, 
		UniqSupno, OrderPref, QtyNOTReserved, UniqMfgrHd, Bomparent, BomCustno)
	SELECT	CASE WHEN (Invtlot.Lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN ZK.QtyOh ELSE Invtlot.lotqty END AS QtyOh, 
			CASE WHEN (Invtlot.Lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN ZK.QtyReserved ELSE Invtlot.Lotresqty END AS QtyReserved, 
			Uniq_key, Partmfgr, Mfgr_pt_no, ZK.W_key, Location, Warehouse, Lotcode, Expdate, Ponum, Reference, instore, UniqSupno, OrderPref, 
			CASE WHEN (Invtlot.Lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN QtyNotReserved ELSE Invtlot.Lotqty-Invtlot.Lotresqty END AS QtyNotReserved, 
			Uniqmfgrhd, Bomparent, @BomCustno AS BomCustno 
		FROM ZKitInvt ZK LEFT OUTER JOIN Invtlot
		ON ZK.W_key = Invtlot.W_key

--  Update cUniqkey for consigned uniq_key, will use to check antiavl
UPDATE @KitAvailRep SET cUniqKey = ISNULL(Inventor.Uniq_key, KitAvailRep.Uniq_key) 
	FROM @KitAvailRep KitAvailRep LEFT OUTER JOIN Inventor 
	ON KitAvailRep.Uniq_key = Inventor.Int_uniq
	AND KitAvailRep.BomCustno = Inventor.Custno 

-- Check UPM		
-- get all the UPM used in KitAvailRep
INSERT INTO @UPM (Uniq_key, Mfgr_pt_no, Partmfgr) 
	SELECT cUniqkey AS Uniq_key, Mfgr_pt_no, Partmfgr 
	FROM @KitAvailRep 
-- Get only exsit in InvtMPNLink and MfgrMaster
INSERT @UPMResult EXEC sp_GetUPM @UPM
-- Delete from @KitAvailRep if can not find in @UPMResult
DELETE FROM @KitAvailRep WHERE cUniqkey+Mfgr_pt_no+Partmfgr NOT IN (SELECT Uniq_key+Mfgr_pt_no+Partmfgr FROM @UPMResult)

-- Check Anti AVL
;WITH ZAntiavl AS
(
SELECT A.BomParent,A.Uniq_key,A.PartMfgr,A.Mfgr_pt_no,A.UNIQANTI  
	FROM ANTIAVL A, @KitAvailRep K
	WHERE A.BomParent=K.Bomparent
	AND A.Uniq_key = K.cUniqkey
	AND A.Partmfgr = K.Partmfgr
	AND A.Mfgr_pt_no = K.Mfgr_pt_no
)
-- Delete from @KitAvalRep if can find antiavl records
DELETE FROM @KitAvailRep WHERE BomParent+cUniqkey+PartMfgr+Mfgr_pt_no IN (SELECT BomParent+Uniq_key+PartMfgr+Mfgr_pt_no FROM ZAntiAvl)

-- Now will update available qty + WO allocation qty
;WITH WoAllocatedView AS
(
SELECT W_key, Uniq_key, Lotcode, Expdate, ISNULL(SUM(Qtyalloc),0) AS qtyalloc,Reference, Ponum
	FROM Invt_res
	WHERE wono = @gWono
	GROUP BY Uniq_key, W_key, Lotcode, Expdate, Reference, Ponum
)
-- Update @KitAvailRep.AvailQty and ThisAlloc 
-- Update WO allocation Qty for this WO
UPDATE @KitAvailRep 
	SET AvailQty = K.QtyNotReserved + ISNULL(W.QtyAlloc,0),
		ThisAlloc = CASE WHEN W.Qtyalloc IS NOT NULL THEN W.QtyAlloc ELSE ThisAlloc END
	FROM @KitAvailRep K	LEFT JOIN WoAllocatedView W ON W.W_key = K.W_key
	AND ISNULL(W.Lotcode,1) = ISNULL(K.Lotcode,1) 
	AND ISNULL(W.Expdate,1) = ISNULL(K.Expdate,1) 
	AND ISNULL(W.Reference,1) = ISNULL(K.Reference,1) 
	AND ISNULL(W.Ponum,1) = ISNULL(K.Ponum,1) 

-- If Wono is linked to project, will check project allocation and update KitAvailRep.AvailQty and ThisAlloc
IF @PrjUnique <> ''
BEGIN
	; WITH PjAllocatedView AS
	(
	SELECT W_key, Uniq_key, ISNULL(SUM(Qtyalloc),0) AS Qtyalloc, Lotcode, Expdate, Reference, Ponum, Fk_prjunique
		FROM Invt_res
		WHERE Fk_prjunique = @PrjUnique
		AND Invt_res.wono = SPACE(10)
		GROUP BY Uniq_key, W_key, Lotcode, Expdate, Reference, Ponum, Fk_prjunique
	)
	-- Update @KitAvailRep.AvailQty and ThisAlloc 
	-- Update PJ allocation Qty for this PJ
	UPDATE @KitAvailRep 
		SET AvailQty = K.QtyNotReserved + ThisAlloc + ISNULL(P.QtyAlloc,0),
			AllocToProject = CASE WHEN P.Qtyalloc IS NOT NULL THEN P.QtyAlloc ELSE AllocToProject END
		FROM @KitAvailRep K
		LEFT JOIN PjAllocatedView P ON P.W_key = K.W_key
		AND ISNULL(P.Lotcode,1) = ISNULL(K.Lotcode,1) 
		AND ISNULL(P.Expdate,1) = ISNULL(K.Expdate,1) 
		AND ISNULL(P.Reference,1) = ISNULL(K.Reference,1) 
		AND ISNULL(P.Ponum,1) = ISNULL(K.Ponum,1) 
END


-- Now will go through @Zinvtresh and insert Kamain
-- Reccount of @Zinvtresh
IF (@lnTotalNo>0)
BEGIN
	SET @lnCount=0;
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @ReqQty = ReqQty, @Dept_id = Dept_id, @Uniq_key = Uniq_key, @Bomparent = Bomparent,  @Qty = Qty, @LotDetail = Lotdetail, @U_of_meas = U_of_meas
			FROM @Zinvtresh WHERE nrecno = @lnCount	
		IF (@@ROWCOUNT<>0)
		BEGIN
			IF @ReqQty = 0
				BEGIN
				CONTINUE
			END

			-- Save to Kamain
			SELECT @Kaseqnum = dbo.fn_GenerateUniqueNumber()
			INSERT INTO Kamain (Wono,Dept_id,Uniq_key,Initials,EntryDate,KaseqNum, Bomparent,ShortQty,Qty,SourceDev)
				VALUES (@gWono, @Dept_id, @Uniq_key, @lcUserID, GETDATE(), @Kaseqnum, @BomParent, @ReqQty, @Qty, 'I')

			-- Insert Kadetail
			INSERT INTO Kadetail (Kaseqnum, ShReason, ShortQty, ShQualify, ShortBal, AuditDate, AuditBy, UniqueRec, Wono)
				VALUES (@Kaseqnum, 'KIT MODULE', @ReqQty, 'ADD', @ReqQty, GETDATE(), @lcUserId, dbo.fn_GenerateUniqueNumber(), @gWono)


			-- First round, will go through allocation, 
			-- if no lot, pick up from WO alloc, PJ alloc, then order pref, 
			-- if part is lot coded, pick up from WO alloc, PJ alloc, Order pref, then expdate
			--------------------------------------------------
			DELETE FROM @ZInvtResD WHERE 1 = 1 
			SET @lnTableVarCnt = 0
			SET @lnOffset = 0

			BEGIN
			IF @Lotdetail = 0
				BEGIN
				INSERT @ZinvtresD (Approved, AvailQty, QtyOh, QtyReserved, ThisAlloc, Uniq_key, PartMfgr, Mfgr_pt_no, W_key, Location, Warehouse,
					Lotcode, Expdate, Ponum, Reference, inStore, UniqSupno, OrderPref, AllocToProject, UniqMfgrHd)		
				SELECT Approved, AvailQty, QtyOh, QtyReserved, ThisAlloc, Uniq_key, PartMfgr, Mfgr_pt_no, W_key, Location, Warehouse,
							---03/02/18 YS change size of the lotcode field to 25
						ISNULL(Lotcode,SPACE(25)) AS LotCode, Expdate, ISNULL(Ponum,SPACE(15)) AS Ponum, ISNULL(Reference,SPACE(15)) AS Reference, 
						inStore, UniqSupno, OrderPref, AllocToProject, UniqMfgrHd
					FROM @KitAvailRep
					WHERE Uniq_key = @Uniq_key 
					ORDER BY 100000000000-ThisAlloc,100000000000-AllocToProject, Orderpref
				END
			ELSE
				BEGIN
				INSERT @ZinvtresD (Approved, AvailQty, QtyOh, QtyReserved, ThisAlloc, Uniq_key, PartMfgr, Mfgr_pt_no, W_key, Location, Warehouse,
					Lotcode, Expdate, Ponum, Reference, inStore, UniqSupno, OrderPref, AllocToProject, UniqMfgrHd)		
				SELECT Approved, AvailQty, QtyOh, QtyReserved, ThisAlloc, Uniq_key, PartMfgr, Mfgr_pt_no, W_key, Location, Warehouse,
						ISNULL(Lotcode,SPACE(25)) AS LotCode, Expdate, ISNULL(Ponum,SPACE(15)) AS Ponum, ISNULL(Reference,SPACE(15)) AS Reference, 
						inStore, UniqSupno, OrderPref, AllocToProject, UniqMfgrHd
					FROM @KitAvailRep
					WHERE Uniq_key = @Uniq_key 
					ORDER BY 100000000000-ThisAlloc,100000000000-AllocToProject, Orderpref, ExpDate
				END
			END -- end of @lotdetail = 0

			UPDATE @ZinvtresD SET @lnTableVarCnt = nRecno = @lnTableVarCnt + 1
			
			-- Now will go through @ZinvtresD to decide to issue from which location
			SET @lnTotalNo2 = @lnTableVarCnt;
			IF (@lnTotalNo2>0)
			BEGIN
				SET @lnCount2=0;
				WHILE @lnTotalNo2>@lnCount2
				BEGIN	
					SET @lnCount2=@lnCount2+1;
					SELECT @ThisAlloc = ThisAlloc, @AllocToProject = AllocToProject, @W_key = W_key, @Lotcode = Lotcode, @Expdate = Expdate,
							@Reference = Reference, @Ponum = Ponum, @UniqMfgrHd = UniqMfgrHd
						FROM @ZinvtresD WHERE nrecno = @lnCount2
					IF (@@ROWCOUNT<>0)
					BEGIN
						IF @ThisAlloc=0.00 AND @AllocToProject=0.00
							BEGIN
							--no allocations because it's sorted from large qty to small, if already 0, no need to check the rest
							--exit from the first round
							BREAK
						END
						SET @lnOffset = @lnOffset + 1

						-- if this record is enough to issue whole qty, otherwise, just WO alloc+PJ alloc
						SET @IssuedQty = CASE WHEN @ReqQty <= @ThisAlloc + @AllocToProject THEN @ReqQty ELSE @ThisAlloc + @AllocToProject END 
						SET @ReqQty = @ReqQty - @IssuedQty

						UPDATE @ZinvtresD 
							SET QtyIssue = QtyIssue + @IssuedQty,
								AvailQty = AvailQty - @IssuedQty
							WHERE nrecno = @lnCount2
						
						SELECT @chkQtyIssue = QtyIssue FROM @ZinvtresD WHERE nrecno = @lnCount2
						IF @chkQtyIssue = 0
							BEGIN
								CONTINUE
						END

						-- Update Kamain, insert Kalocate and invt_isu
						-------------------------------------------------------------
						-- Update Kamain
						UPDATE Kamain 
							SET Act_qty = Act_qty + @IssuedQty,
								ShortQty = ShortQty - @IssuedQty
							WHERE Kaseqnum = @Kaseqnum

						-- Insert Kalocate
						INSERT INTO Kalocate (UniqKalocate, Kaseqnum, W_key, Pick_qty, Lotcode, Expdate, Reference, Ponum, Uniqmfgrhd, Wono)
							VALUES (dbo.fn_GenerateUniqueNumber(), @Kaseqnum, @W_key, @IssuedQty, @Lotcode, @Expdate, @Reference, @Ponum, @UniqMfgrHd, @gWono)

						-- Insert KalocIpkey

						SELECT @chkShortQty = ShortQty FROM Kamain WHERE Kaseqnum = @Kaseqnum
						-- Insert Kadetail
						INSERT INTO Kadetail (Kaseqnum, ShReason, ShortQty, ShQualify, ShortBal, AuditDate, AuditBy, UniqueRec, Wono)
							VALUES (@Kaseqnum, 'KIT MODULE/Issu', -@IssuedQty, 'EDT', @chkShortQty, DATEADD(ss,@lnOffset,GETDATE()), @lcUserId, dbo.fn_GenerateUniqueNumber(), @gWono)

						-- Insert Invt_isu
						-- Didn't update stdcost, should be updated by invt_isu trigger, will nned to save Fk_userid later  
						IF @IssuedQty > 0
							BEGIN
							INSERT INTO Invt_isu (W_key,Uniq_key,IssuedTo,QtyIsu,Date,U_of_meas,Gl_nbr, Invtisu_no, Wono, LotCode,Expdate,Reference,Ponum,Saveinit,UniqMfgrHd, cModId,SourceDev)
							VALUES (@W_key, @Uniq_key, '(WO:'+@gWono,@IssuedQty,GETDATE(),@U_of_meas, dbo.fn_GetWIPGl(), dbo.fn_GenerateUniqueNumber(), @gWono, @Lotcode, @Expdate, @Reference, @Ponum,
									@lcUserID, @UniqMfgrHd, 'K','I')
						END

						IF @ReqQty = 0
							BEGIN
							BREAK
						END
          			END -- IF (@@ROWCOUNT<>0) @ZinvtresD WHERE nrecno = @lnCount2
				END -- WHILE @lnTotalNo2>@lnCount2
			END -- (@lnTotalNo2>0) @ZinvtresD


			-- 2nd round, will go through by reference, 
			-- if no lot, order pref, 
			-- if part is lot coded, Order pref, then expdate
			--------------------------------------------------
			DELETE FROM @ZInvtResD WHERE 1 = 1 
			SET @lnTableVarCnt = 0
			--SET @lnOffset = 0

			BEGIN
			IF @Lotdetail = 0
				BEGIN
					---03/02/18 YS change size of the lotcode field to 25
				INSERT @ZinvtresD (Approved, AvailQty, QtyOh, QtyReserved, ThisAlloc, Uniq_key, PartMfgr, Mfgr_pt_no, W_key, Location, Warehouse,
					Lotcode, Expdate, Ponum, Reference, inStore, UniqSupno, OrderPref, AllocToProject, UniqMfgrHd)		
				SELECT Approved, AvailQty, QtyOh, QtyReserved, ThisAlloc, Uniq_key, PartMfgr, Mfgr_pt_no, W_key, Location, Warehouse,
						ISNULL(Lotcode,SPACE(25)) AS LotCode, Expdate, ISNULL(Ponum,SPACE(15)) AS Ponum, ISNULL(Reference,SPACE(15)) AS Reference, 
						inStore, UniqSupno, OrderPref, AllocToProject, UniqMfgrHd
					FROM @KitAvailRep
					WHERE Uniq_key = @Uniq_key 
					AND AvailQty > 0
					ORDER BY 100000000000-ThisAlloc,100000000000-AllocToProject, Orderpref
				END
			ELSE
				BEGIN
				INSERT @ZinvtresD (Approved, AvailQty, QtyOh, QtyReserved, ThisAlloc, Uniq_key, PartMfgr, Mfgr_pt_no, W_key, Location, Warehouse,
					Lotcode, Expdate, Ponum, Reference, inStore, UniqSupno, OrderPref, AllocToProject, UniqMfgrHd)		
				SELECT Approved, AvailQty, QtyOh, QtyReserved, ThisAlloc, Uniq_key, PartMfgr, Mfgr_pt_no, W_key, Location, Warehouse,
						ISNULL(Lotcode,SPACE(25)) AS LotCode, Expdate, ISNULL(Ponum,SPACE(15)) AS Ponum, ISNULL(Reference,SPACE(15)) AS Reference, 
						inStore, UniqSupno, OrderPref, AllocToProject, UniqMfgrHd
					FROM @KitAvailRep
					WHERE Uniq_key = @Uniq_key 
					AND AvailQty > 0
					ORDER BY 100000000000-ThisAlloc,100000000000-AllocToProject, Orderpref, ExpDate
				END
			END -- end of @lotdetail = 0

			UPDATE @ZinvtresD SET @lnTableVarCnt = nRecno = @lnTableVarCnt + 1
			
			-- Now will go through @ZinvtresD to decide to issue from which location
			SET @lnTotalNo2 = @lnTableVarCnt;
			IF (@lnTotalNo2>0)
			BEGIN
				SET @lnCount2=0;
				WHILE @lnTotalNo2>@lnCount2
				BEGIN	
					SET @lnCount2=@lnCount2+1;
					SELECT @AvailQty = Availqty, @W_key = W_key, @Lotcode = Lotcode, @Expdate = Expdate,
							@Reference = Reference, @Ponum = Ponum, @UniqMfgrHd = UniqMfgrHd
						FROM @ZinvtresD WHERE nrecno = @lnCount2
					IF (@@ROWCOUNT<>0)
					BEGIN
						SET @lnOffset = @lnOffset + 1

						-- if this record is enough to issue whole qty, otherwise, just WO alloc+PJ alloc
						SET @IssuedQty = CASE WHEN @ReqQty <= @AvailQty THEN @ReqQty ELSE @AvailQty END 
						SET @ReqQty = @ReqQty - @IssuedQty
						
						UPDATE @ZinvtresD 
							SET QtyIssue = QtyIssue + @IssuedQty,
								AvailQty = AvailQty - @IssuedQty
							WHERE nrecno = @lnCount2
						
						SELECT @chkQtyIssue = QtyIssue FROM @ZinvtresD WHERE nrecno = @lnCount2
						IF @chkQtyIssue = 0
							BEGIN
								CONTINUE
						END

						-- Update Kamain, insert Kalocate and invt_isu
						-------------------------------------------------------------
						-- Update Kamain
						UPDATE Kamain 
							SET Act_qty = Act_qty + @IssuedQty,
								ShortQty = ShortQty - @IssuedQty
							WHERE Kaseqnum = @Kaseqnum

						-- Insert Kalocate
						INSERT INTO Kalocate (UniqKalocate, Kaseqnum, W_key, Pick_qty, Lotcode, Expdate, Reference, Ponum, Uniqmfgrhd, Wono)
							VALUES (dbo.fn_GenerateUniqueNumber(), @Kaseqnum, @W_key, @IssuedQty, @Lotcode, @Expdate, @Reference, @Ponum, @UniqMfgrHd, @gWono)

						-- Insert KalocIpkey

						SELECT @chkShortQty = ShortQty FROM Kamain WHERE Kaseqnum = @Kaseqnum
						-- Insert Kadetail

						INSERT INTO Kadetail (Kaseqnum, ShReason, ShortQty, ShQualify, ShortBal, AuditDate, AuditBy, UniqueRec, Wono)
							VALUES (@Kaseqnum, 'KIT MODULE/Issu', -@IssuedQty, 'EDT', @chkShortQty, DATEADD(ss,@lnOffset*30,GETDATE()), @lcUserId, dbo.fn_GenerateUniqueNumber(), @gWono)

						-- Insert Invt_isu
						-- Didn't update stdcost, should be updated by invt_isu trigger, will nned to save Fk_userid later  
						IF @IssuedQty > 0
							BEGIN
							INSERT INTO Invt_isu (W_key,Uniq_key,IssuedTo,QtyIsu,Date,U_of_meas,Gl_nbr, Invtisu_no, Wono, LotCode,Expdate,Reference,Ponum,Saveinit,UniqMfgrHd, cModId,SourceDev)
							VALUES (@W_key, @Uniq_key, '(WO:'+@gWono,@IssuedQty,GETDATE(),@U_of_meas, dbo.fn_GetWIPGl(), dbo.fn_GenerateUniqueNumber(), @gWono, @Lotcode, @Expdate, @Reference, @Ponum,
									@lcUserID, @UniqMfgrHd, 'K','I')
						END

						IF @ReqQty = 0
							BEGIN
							BREAK
						END
          			END -- IF (@@ROWCOUNT<>0) @ZinvtresD WHERE nrecno = @lnCount2
				END -- WHILE @lnTotalNo2>@lnCount2
			END -- (@lnTotalNo2>0) @ZinvtresD
		END
	END -- End of WHILE @lnTotalNo>@lnCount
END -- End of @lnTotalNo>0

-- Don't need to run, Kamain insert trigger will update
---- Update WOentry for kit status
--UPDATE Woentry
--	SET Kitstatus = 'KIT PROCSS',
--        KitLstChDT = GETDATE(),
--		Start_date = GETDATE(),
--		KitStartInit = @lcUserId,
--        KitLstChInit = @lcUserId
--	WHERE Wono = @gWono

---- Update WO checklist
--EXEC sp_UpdOneWOChkLst @gWono, 'KIT IN PROCESS', @lcUserid


IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END	