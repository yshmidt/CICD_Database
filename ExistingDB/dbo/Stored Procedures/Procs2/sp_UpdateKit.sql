-- =============================================
-- Author:		Vicky Lu
-- Create date: 2015/05/20/
-- Description:	Update Kit, if the part is removed or issue more than needed, those qty will be returned (default) or over-issued.
-- Modification:
--	08/27/15	VL	changed @@AllBomDetView.qty from numeric(9,2) to numeric(12,2)
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[sp_UpdateKit] @gWono AS char(10) = ' ', @lcUserID AS char(8), @ReturnToInventory AS bit = 1
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
BEGIN TRANSACTION

DECLARE @AllBomDetView TABLE (Dept_id char(4), Uniq_key char(10), BomParent char(10), Qty Numeric(12,2),	U_of_meas char(4), Scrap Numeric(6,2), 
								SetupScrap Numeric(4,0), ReqQty Numeric(12,2), nRecno int identity, nSequence int)
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
DECLARE @KitMainView TABLE (DispPart_no char(35), Req_Qty numeric(12,2), Phantom char(1), DispRevision char(8),
	Part_class char(8), Part_type char(8), Kaseqnum char(10), Entrydate smalldatetime, Initials char(8), 
	Rej_qty numeric(12,2), Rej_date smalldatetime, Rej_reson char(10), Kitclosed bit, Act_qty numeric(12,2), 
	Uniq_key char(10), Dept_id char(4), Dept_name char(25), Wono char(10), Scrap numeric(6,2), Setupscrap numeric(4,0), 
	Bomparent char(10), Shortqty numeric(12,2), Lineshort bit, Part_sourc char(10), Qty numeric(12,2), 
	Descript char(45), Inv_note text, U_of_meas char(4), Pur_uofm char(4), Ref_des char(15), Part_no char(35), 
	Custpartno char(35), Ignorekit bit, Phant_make bit, Revision char(8), Serialyes bit, Matltype char(10),	CustRev char(8), nRecno int identity, 
	nSequence int)

DECLARE @Kalocate TABLE (UniqKalocate char(10), Kaseqnum char(10), W_key char(10), Pick_qty numeric(12,2), Lotcode char(15), Expdate smalldatetime,
						Reference char(12), Ponum char(15), Overissqty numeric(12,2), Overw_key char(10), Uniqmfgrhd char(10), nRecno int)

DECLARE @KalocIpkey TABLE (UniqKalocIpkey char(10), UniqKalocate char(10), Fk_IpkeyUnique char(10), nPick_qty numeric(12,2), nOverIssQty numeric(12,2), 
						OverIpkeyUnique char(10), nRecno int)
DECLARE @KitNewItem TABLE (Wono char(10), Dept_id char(4), Uniq_key char(10), Initials char(8), EntryDate smalldatetime, KaseqNum char(10), 
						Bomparent char(10), ShortQty numeric(12,2), Qty numeric(12,2)) 
DECLARE @GetOriginalW_key TABLE (OrigWkey char(10), lFromWoWip bit)
DECLARE @WoUniq_key char(10), @WoBldQqty numeric(7,0), @WoDue_date smalldatetime, @KitIgnoreScrap bit, @WoPrjUnique char(10), @chkWono char(10),
		@chkPrjunique char(10), @lnTotalNo int, @lnCount int, @LineShort bit, @KitBomparent char(10), @KitUniq_key char(10), @KitDept_id char(10),
		@KitnSequence int, @Kaseqnum char(10), @KitReq_Qty numeric(12,2), @BomReqQty numeric(12,2), @lFoundinBom bit, @KitAct_qty numeric(12,2), 
		@KitShortQty numeric(12,2),	@CountFlag char(1), @lnTableVarCnt int, @lnTotalNoKalocate int, @lnCountKalocate int, @Uniqkalocate char(10), 
		@W_key char(10), @Pick_qty numeric(12,2), @Lotcode char(15), @Expdate smalldatetime, @Reference char(12), @Ponum char(15), @OverissQty numeric(12,2), 
		@Overw_key char(10), @UniqMfgrhd char(10), @Instore bit, @lUseW_key char(10), @KitU_of_meas char(4), @WipGlNbr char(13), @StdCost numeric(13,5), 
		@UniqSupno char(10), @UniqWh char(10), @lUseW_key2 char(10), @UseIpkey bit, @lnTotalNoKalocIpkey int, @lnCountKalocipkey int, @UniqKalocIpkey char(10), 
		@Fk_IpkeyUnique char(10), @nPick_qty numeric(12,2), @nOverIssQty numeric(12,2), @OverIpkeyUnique char(10), @Invtisu_no char(10), @Invtxfer_n char(10), 
		@OrigWkey char(10),	@lFromWoWip bit, @lDelta numeric(12,2), @lcW_key char(10), @lcOverW_key char(10), @IssueThisTime numeric(12,2), 
		@lDelta2 numeric(12,2), @IssueThisTime2 numeric(12,2), @NeedNewKalocateRec bit, @GetUniqKalocate char(10), @NewTransferIpkey char(10),
		@GetNewIpkey numeric(10), @DeltaIssue numeric(12,2), @IssueThisTime3 numeric(12,2), @lDelta3 numeric(12,2), @IssueThisTime4 numeric(12,2)

SELECT @WoUniq_key = Uniq_key, @WoBldQqty = BldQty, @WoDue_date = Due_date, @WoPrjUnique = PrjUnique FROM Woentry WHERE Wono = @gWono
SELECT @KitIgnoreScrap = lKitIgnoreScrap FROM KitDef
SELECT @WipGlNbr = dbo.fn_GetWIPGl()

-- New BOM info
INSERT INTO @AllBomDetView (Dept_id, Uniq_key, Bomparent,Qty,U_of_meas,Scrap,setupscrap,ReqQty)
	SELECT Dept_id, Uniq_key, Bomparent,Qty,U_of_meas,Scrap,setupscrap,ReqQty 
	FROM dbo.fn_phantomSubSelect( @WoUniq_key, @WoBldQqty, 'T', @WoDue_date, 'F', 'T', 'F', @KitIgnoreScrap, 0, 0)
-- Update nSequence, if the BOM has duplicate bomparent, uniq_key, dept_id, the nSequence will increase for each set, will be used to update @KitmainView
UPDATE @AllBomDetView
	SET nSequence = S.Rank FROM (SELECT Bomparent, Uniq_key, Dept_id, row_number() 
		OVER (PARTITION BY Bomparent, Uniq_key, Dept_id ORDER BY Bomparent, Uniq_key, Dept_id) AS RANK, nRecno FROM @AllBomDetView) S
	INNER JOIN @AllBomDetView A ON S.nRecno = A.nRecno
	
-- Current Kit records
INSERT @KitMainView (DispPart_no, Req_Qty, Phantom, DispRevision, Part_class, Part_type, Kaseqnum, Entrydate, Initials, Rej_qty, Rej_date, 
	Rej_reson, Kitclosed, Act_qty, Uniq_key, Dept_id, Dept_name, Wono, Scrap, Setupscrap, Bomparent, Shortqty, Lineshort, Part_sourc, Qty, 
	Descript, Inv_note, U_of_meas, Pur_uofm, Ref_des, Part_no, Custpartno, Ignorekit, Phant_make, Revision, Serialyes, Matltype, CustRev)
	EXEC [KitMainView] @gWono
SET @lnTotalNo = @@ROWCOUNT

UPDATE @KitMainView
	SET nSequence = S.Rank FROM (SELECT Bomparent, Uniq_key, Dept_id, row_number() 
		OVER (PARTITION BY Bomparent, Uniq_key, Dept_id ORDER BY Bomparent, Uniq_key, Dept_id) AS RANK, nRecno FROM @KitMainView) S
	INNER JOIN @KitMainView K ON S.nRecno = K.nRecno

-- Check if qty in WO-WIP location is allocated by other WO/PJ
;WITH ZHasOverIssNeedReturn AS 
(
SELECT Uniq_key 
	FROM @KitMainView 
	WHERE ShortQty < 0
	AND LineShort = 0
	AND Uniq_key NOT IN (SELECT Uniq_key FROM @AllBomDetView) -- Item is removed, need to return pick qty and overissued qty
UNION ALL 
	SELECT K.Uniq_key
		FROM @KitMainView K, @AllBomDetView A
		WHERE K.BomParent = A.BomParent 
		AND K.Uniq_key = A.Uniq_key 
		AND K.Dept_id = A.Dept_id 
		AND ShortQty < 0 
		AND LineShort = 0
		AND K.Req_Qty < A.ReqQty -- Req_qty increase, has to move overissued to regular qty
)-- If any other WO/PRJ allocated from this work order WO-WIP location.  Can not continue if found, user has to un-allocate manually, to update Kit	
SELECT @chkWono = Wono, @chkPrjUnique = Fk_Prjunique
	FROM Invt_res, Invtmfgr
	WHERE Invt_res.W_key = Invtmfgr.W_key
	AND Invtmfgr.Location = 'WO' + @gWono
	AND Invt_res.WONO <> @gWono 
	AND Invt_res.Fk_Prjunique <> @WoPrjUnique 
	AND Invtres_no NOT IN 
		(SELECT Refinvtres
			FROM Invt_res)
	AND qtyAlloc > 0
	AND Invt_res.Uniq_key IN 
		(SELECT Uniq_key FROM ZHasOverIssNeedReturn)

IF @@ROWCOUNT>0
	BEGIN
	RAISERROR('Some parts in WO-WIP location are allocated by other work orders/projects.  The Kit Update process can not continue to update.  This operation will be cancelled.',1,1)
	ROLLBACK TRANSACTION
	RETURN
END

-- 
-- Now need to go through @KitmainView to check with @AllBomDetView
IF (@lnTotalNo>0)
BEGIN
	SET @lnCount=0;
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @KitBomparent = Bomparent, @KitUniq_key = Uniq_key, @KitDept_id = Dept_id, @KitnSequence = nSequence, @LineShort = LineShort, 
			@Kaseqnum = Kaseqnum, @KitReq_qty = Req_qty, @KitAct_qty = Act_qty, @KitU_of_meas = U_of_meas, @KitShortQty = ShortQty
			FROM @KitMainView WHERE nrecno = @lnCount	
		IF (@@ROWCOUNT<>0)
		BEGIN
			-- (1). Check if it's line shortage, if yes, go next one
			IF @LineShort = 1
				BEGIN
				CONTINUE
			END

			-- Get StdCost
			SELECT @StdCost = StdCost, @UseIpkey = UseIPkey FROM Inventor WHERE Uniq_key = @KitUniq_key
			-- Get fields from @AllBomDetView to compare with fields of @KitMainView
			SELECT @BomReqQty = ReqQty 
				FROM @AllBomDetView 
				WHERE Bomparent = @KitBomparent 
				AND Uniq_key = @KitUniq_key 
				AND Dept_id = @KitDept_id 
				AND nSequence = @KitnSequence

			SET @lFoundinBom = CASE WHEN @@ROWCOUNT > 0 THEN 1 ELSE 0 END
			
			-- (2). If not in BOM @lFoundinBom = 0 and Act_Qty=0, just remove all records for this @Kaseqnum
			IF @lFoundinBOM = 0 AND @KitAct_qty = 0
				BEGIN
				DELETE FROM Kamain WHERE Kaseqnum = @Kaseqnum
				DELETE FROM Kadetail WHERE Kaseqnum = @Kaseqnum
				DELETE FROM KalocIpkey WHERE UniqKalocate IN (SELECT UniqKalocate FROM Kalocate WHERE Kaseqnum = @Kaseqnum)
				DELETE FROM Kalocser WHERE UniqKalocate IN (SELECT UniqKalocate FROM Kalocate WHERE Kaseqnum = @Kaseqnum)
				DELETE FROM Kalocate WHERE Kaseqnum = @Kaseqnum
			END

			-- (3). If not in BOM @lFoundinBom = 0 and Act_Qty>0, has picked qty, need to based on @ReturnToInventory to return all back to inventory,
			--		or issued to WO
			IF @lFoundinBOM = 0 AND @KitAct_qty > 0
				BEGIN
				SELECT @CountFlag = CountFlag 
					FROM Invtmfgr 
					WHERE W_key IN (SELECT W_key FROM Kalocate WHERE Kaseqnum = @Kaseqnum)
					AND CountFlag<>''
					AND Is_deleted = 0

				IF @CountFlag<>''	-- Found cycle count/physical inventory record
					BEGIN
					RAISERROR('Location for this part number is in use by Cycle Count or Physical Inventory modules.  The Kit Update process can not continue to update.  This operation will be cancelled.',1,1)
					ROLLBACK TRANSACTION
					RETURN
				END

				-- Go through Kalocate, Kalocipkey to issue/transfer based on if @ReturnToInventory = 1 or 0
				SET @lnTableVarCnt = 0
				DELETE FROM @Kalocate WHERE 1=1
				INSERT INTO @Kalocate (UniqKalocate, Kaseqnum, W_key, Pick_qty, Lotcode, Expdate, Reference, Ponum, Overissqty, Overw_key, Uniqmfgrhd)
					SELECT UniqKalocate, Kaseqnum, W_key, Pick_qty, Lotcode, Expdate, Reference, Ponum, Overissqty, Overw_key, Uniqmfgrhd
						FROM Kalocate 
						WHERE Kaseqnum = @Kaseqnum
						AND Pick_qty - Overissqty > 0 
				UPDATE @Kalocate SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
				SET @lnTotalNoKalocate = @@ROWCOUNT

				-- Scan through Kalocate records for this @Kaseqnum to issue back and transfer back
				IF (@lnTotalNoKalocate>0)
				BEGIN
					SET @lnCountKalocate=0;
					WHILE @lnTotalNoKalocate>@lnCountKalocate
					BEGIN	
						SET @lnCountKalocate=@lnCountKalocate+1;
						SELECT @UniqKalocate = UniqKalocate, @W_key = w_key, @Pick_qty = Pick_qty, @Lotcode = Lotcode, @Expdate = Expdate,
								@Reference = Reference, @Ponum = Ponum, @OverissQty = OverissQty, @Overw_key = Overw_key, @UniqMfgrhd = UniqMfgrhd
							FROM @Kalocate WHERE nRecno = @lnCountKalocate

						IF @@ROWCOUNT > 0	-- If find Kalocate record
							BEGIN
							IF @ReturnToInventory = 1	
							-- Need to put issued qty back to inventory and over-issued qty back too.  
							-- When creating negative issued records, need to make sure it's not returning to in-store location, 
							-- when transfer over-issued qty back to inventory, just from WO-WIP location to original w_key
								BEGIN
								-- Check if the @w_key is an instore location, need to return to non-instore location, also get several fields to be checked later
								SELECT @Instore = Instore, @UniqSupno = UniqSupno, @Uniqwh = UniqWh 
									FROM Invtmfgr 
									WHERE W_key = @W_key

								SET @lUseW_key = @W_key
								IF @Instore = 1
									BEGIN
									EXEC sp_GetNotInstoreLocation4Mfgrhd @UniqMfgrhd, @lUsew_key OUTPUT
								END

								-- Put issued qty back to inventory by issuing negative qty 
								IF @Pick_qty-@OverissQty<>0
									BEGIN
									SET @Invtisu_no = dbo.fn_GenerateUniqueNumber()
									INSERT INTO Invt_isu (W_key,Uniq_key,IssuedTo,QtyIsu,U_of_meas, Wono,Gl_nbr,LotCode,Expdate,Reference, 
										Saveinit,Ponum,TransRef,UniqMfgrHD, Date, Invtisu_no, cModid, SourceDev) 
									VALUES (@lUseW_key,@KitUniq_key,'(WO:'+@gWono,-(@Pick_qty-@OverissQty),@KitU_of_meas, @gWono,@WipGlNbr, 
										@LotCode, @Expdate, @Reference,	@lcUserID, @Ponum, CASE WHEN @Instore = 1 THEN 'Un-issue in-store' ELSE '' END, 
										@UniqMfgrHd, GETDATE(), @Invtisu_no, 'U', 'I')
								END

								-- Transfer over-issued qty back to original w_key
								IF @OverIssQty<> 0
									BEGIN
									SET @Invtxfer_n = dbo.fn_GenerateUniqueNumber()
									INSERT INTO Invttrns (Uniq_key,QTYXFER,REASON,FromWkey,ToWkey, LotCode, ExpDate,Reference,Ponum,UniqMfgrHd, Invtxfer_n, 
										Date, StdCost, cModId, Wono, Kaseqnum, SaveInit, sourceDev) 
									VALUES (@KitUniq_key, @OverIssQty, 'Clear KIT Over Issue', @Overw_key,@W_key, @LotCode, @ExpDate, @Reference, @Ponum, 
										@UniqMfgrHD, @Invtxfer_n, GETDATE(), @StdCost, 'U', @gWono, @Kaseqnum, @lcUserId, 'I')
								END

								IF @UseIpkey = 1	-- Need to Update issueIpkey and iTransferIpkey
									BEGIN
									SET @lnTableVarCnt = 0
									DELETE FROM @KalocIpkey WHERE 1=1

									INSERT INTO @KalocIpkey (UniqKalocIpkey, UniqKalocate, Fk_IpkeyUnique, nPick_qty, nOverIssQty, OverIpkeyUnique)
										SELECT UniqKalocIpkey, UniqKalocate, Fk_IpkeyUnique, nPick_qty, nOverIssQty, OverIpkeyUnique
											FROM KalocIpkey
											WHERE UniqKalocate = @UniqKalocate
											AND nPick_qty > 0 

									UPDATE @KalocIpkey SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
									SET @lnTotalNoKalocIpkey = @@ROWCOUNT

									-- Scan through KalocIpkey records for this @Uniqkalocate to issue back and transfer back
									IF (@lnTotalNoKalocIpkey>0)
									BEGIN
										SET @lnCountKalocIpkey=0;
										WHILE @lnTotalNoKalocIpkey>@lnCountKalocIpkey
										BEGIN	
											SET @lnCountKalocIpkey=@lnCountKalocIpkey+1;
											SELECT @UniqKalocIpkey = UniqKalocIpkey, @Fk_IpkeyUnique = Fk_IpkeyUnique, 
													@nPick_qty = nPick_qty, @nOverIssQty = nOverIssQty, @OverIpkeyUnique = OverIpkeyUnique
												FROM @KalocIpkey WHERE nRecno = @lnCountKalocIPkey

											IF @@ROWCOUNT > 0
												BEGIN
													IF @Pick_qty-@OverissQty<>0 AND @nPick_qty-@nOverIssQty<>0
														BEGIN
														INSERT INTO IssueIpkey (IssueIpkeyUnique, Invtisu_no, QtyIssued, IpkeyUnique) 
															VALUES (dbo.fn_GenerateUniqueNumber(), @Invtisu_no, -(@nPick_qty-@nOverIssQty), @Fk_IpkeyUnique)
													END

													IF @OverIssQty<> 0 AND @nOverIssQty<>0
														BEGIN
														INSERT INTO iTransferIpkey (iXferIPkeyUnique, Invtxfer_n, QtyTransfer, FromIpkeyUnique, ToIpkeyunique)
															VALUES (dbo.fn_GenerateUniqueNumber(), @Invtxfer_n, @nOverIssQty, @OverIpkeyUnique, @OverIpkeyUnique)	-- use same ipkeyuniq so it still use the same ipkey
													END
											END
										END -- WHILE @lnTotalNoKalocIpkey>@lnCountKalocIpkey
									END -- (@lnTotalNoKalocIpkey>0)

								END -- @UseIpkey = 1

							END -- @ReturnToInventory = 1
							
							IF @ReturnToInventory = 0	
							-- Need to issue over-issued qty to this wono, 
							-- 1.Need to check if the 'from' w_key is WO-WIP location or not, if yes, need to transfer to origianl w_key first
							-- 2.Issed over-issued qty to this wono
								BEGIN

								-- Check if the Overw_key is WO-WIP and get original w_key if it is
								INSERT @GetOriginalW_key EXEC sp_GetOriginalW_key @Overw_key
								SELECT @OrigWkey = OrigWkey, @lFromWoWip = lFromWoWip FROM @GetOriginalW_key
								IF @lFromWoWip = 1 AND @OrigWkey = ''
									BEGIN
									RAISERROR('Can not find WO-WIP location.  The Kit Update process can not continue to update.  This operation will be cancelled.',1,1)
									ROLLBACK TRANSACTION
									RETURN
								END

								IF @lFromWoWip = 1
									BEGIN
									IF @OverIssQty<> 0
										BEGIN
										-- Transfer from WO-WIP to original w_key
										SET @Invtxfer_n = dbo.fn_GenerateUniqueNumber()
										INSERT INTO Invttrns (Uniq_key,QTYXFER,REASON,FromWkey,ToWkey, LotCode, ExpDate,Reference,Ponum,UniqMfgrHd, Invtxfer_n, 
											Date, StdCost, cModId, Wono, Kaseqnum, SaveInit, sourceDev) 
										VALUES (@KitUniq_key, @OverIssQty, 'Kit Transfer from wo-wip', @Overw_key,@OrigWkey, @LotCode, @ExpDate, @Reference, @Ponum, 
											@UniqMfgrHD, @Invtxfer_n, GETDATE(), @StdCost, 'U', @gWono, @Kaseqnum, @lcUserId, 'I')
									
										-- Issue from original w_key
										SET @Invtisu_no = dbo.fn_GenerateUniqueNumber()
										INSERT INTO Invt_isu (W_key,Uniq_key,IssuedTo,QtyIsu,U_of_meas, Wono,Gl_nbr,LotCode,Expdate,Reference, 
											Saveinit,Ponum,UniqMfgrHD, Date, Invtisu_no, cModid, SourceDev) 
										VALUES (@OrigWkey,@KitUniq_key,'(WO:'+@gWono,@OverIssQty,@KitU_of_meas, @gWono,@WipGlNbr, 
											@LotCode, @Expdate, @Reference,	@lcUserID, @Ponum, @UniqMfgrHd, GETDATE(), @Invtisu_no, 'U', 'I')

										IF @UseIpkey = 1	-- Need to Update issueIpkey and iTransferIpkey
											BEGIN
											SET @lnTableVarCnt = 0
											DELETE FROM @KalocIpkey WHERE 1=1

											INSERT INTO @KalocIpkey (UniqKalocIpkey, UniqKalocate, Fk_IpkeyUnique, nPick_qty, nOverIssQty, OverIpkeyUnique)
												SELECT UniqKalocIpkey, UniqKalocate, Fk_IpkeyUnique, nPick_qty, nOverIssQty, OverIpkeyUnique
													FROM KalocIpkey
													WHERE UniqKalocate = @UniqKalocate
													AND nOverIssQty > 0 

											UPDATE @KalocIpkey SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
											SET @lnTotalNoKalocIpkey = @@ROWCOUNT

											-- Scan through KalocIpkey records for this @Uniqkalocate to issue back and transfer back
											IF (@lnTotalNoKalocIpkey>0)
											BEGIN
												SET @lnCountKalocIpkey=0;
												WHILE @lnTotalNoKalocIpkey>@lnCountKalocIpkey
												BEGIN	
													SET @lnCountKalocIpkey=@lnCountKalocIpkey+1;
													SELECT @UniqKalocIpkey = UniqKalocIpkey, @Fk_IpkeyUnique = Fk_IpkeyUnique, 
															@nPick_qty = nPick_qty, @nOverIssQty = nOverIssQty, @OverIpkeyUnique = OverIpkeyUnique
														FROM @KalocIpkey WHERE nRecno = @lnCountKalocIPkey

													IF @@ROWCOUNT > 0
														BEGIN
															IF @nOverIssQty<>0
																BEGIN
																INSERT INTO iTransferIpkey (iXferIPkeyUnique, Invtxfer_n, QtyTransfer, FromIpkeyUnique, ToIpkeyunique)
																	VALUES (dbo.fn_GenerateUniqueNumber(), @Invtxfer_n, @nOverIssQty, @OverIpkeyUnique, @OverIpkeyUnique)	-- use same ipkeyuniq so it still use the same ipkey

																INSERT INTO IssueIpkey (IssueIpkeyUnique, Invtisu_no, QtyIssued, IpkeyUnique) 
																	VALUES (dbo.fn_GenerateUniqueNumber(), @Invtisu_no, @nOverIssQty, @OverIpkeyUnique)	-- Issue from the same ipkey

															END
													END
												END -- WHILE @lnTotalNoKalocIpkey>@lnCountKalocIpkey
											END -- (@lnTotalNoKalocIpkey>0)

										END -- @UseIpkey = 1
									
									END -- @OverIssQty<> 0
									END --IF @lFromWoWip = 1
								ELSE
									BEGIN
									IF @OverIssQty<> 0
										BEGIN
										-- Issue from over-issued w_key which is not WO-WIP location
										SET @Invtisu_no = dbo.fn_GenerateUniqueNumber()
										INSERT INTO Invt_isu (W_key,Uniq_key,IssuedTo,QtyIsu,U_of_meas, Wono,Gl_nbr,LotCode,Expdate,Reference, 
											Saveinit,Ponum,UniqMfgrHD, Date, Invtisu_no, cModid, SourceDev) 
										VALUES (@OverW_key,@KitUniq_key,'(WO:'+@gWono,@OverIssQty,@KitU_of_meas, @gWono,@WipGlNbr, 
											@LotCode, @Expdate, @Reference,	@lcUserID, @Ponum, @UniqMfgrHd, GETDATE(), @Invtisu_no, 'U', 'I')
										IF @UseIpkey = 1	-- Need to Update issueIpkey and iTransferIpkey
											BEGIN
											SET @lnTableVarCnt = 0
											DELETE FROM @KalocIpkey WHERE 1=1

											INSERT INTO @KalocIpkey (UniqKalocIpkey, UniqKalocate, Fk_IpkeyUnique, nPick_qty, nOverIssQty, OverIpkeyUnique)
												SELECT UniqKalocIpkey, UniqKalocate, Fk_IpkeyUnique, nPick_qty, nOverIssQty, OverIpkeyUnique
													FROM KalocIpkey
													WHERE UniqKalocate = @UniqKalocate
													AND nOverIssQty > 0 

											UPDATE @KalocIpkey SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
											SET @lnTotalNoKalocIpkey = @@ROWCOUNT

											-- Scan through KalocIpkey records for this @Uniqkalocate to issue back and transfer back
											IF (@lnTotalNoKalocIpkey>0)
											BEGIN
												SET @lnCountKalocIpkey=0;
												WHILE @lnTotalNoKalocIpkey>@lnCountKalocIpkey
												BEGIN	
													SET @lnCountKalocIpkey=@lnCountKalocIpkey+1;
													SELECT @UniqKalocIpkey = UniqKalocIpkey, @Fk_IpkeyUnique = Fk_IpkeyUnique, 
															@nPick_qty = nPick_qty, @nOverIssQty = nOverIssQty, @OverIpkeyUnique = OverIpkeyUnique
														FROM @KalocIpkey WHERE nRecno = @lnCountKalocIPkey

													IF @@ROWCOUNT > 0
														BEGIN
															IF @nOverIssQty<>0
																BEGIN
																INSERT INTO IssueIpkey (IssueIpkeyUnique, Invtisu_no, QtyIssued, IpkeyUnique) 
																	VALUES (dbo.fn_GenerateUniqueNumber(), @Invtisu_no, @nOverIssQty, @OverIpkeyUnique)	-- Issue from the same ipkey

															END
													END
												END -- WHILE @lnTotalNoKalocIpkey>@lnCountKalocIpkey
											END -- (@lnTotalNoKalocIpkey>0)
										END -- @UseIpkey = 1

									END -- @OverIssQty > 0
									
								END -- @lFromWoWip = 1
							END --@ReturnToInventory = 0	
						END -- @@ROWCOUNT > 0
					END --WHILE @lnTotalNoKalocate>@lnCountKalocate
				END -- (@lnTotalNoKalocate>0)

				DELETE FROM Kalocipkey WHERE UniqKalocate IN (SELECT UniqKalocate FROM Kalocate WHERE Kaseqnum=@Kaseqnum)
				DELETE FROM Kamain WHERE Kaseqnum = @Kaseqnum
				DELETE FROM Kalocate WHERE Kaseqnum = @Kaseqnum
			
			END

			-- (4) The record exist in both Kit and BOM, need to check the qty to decide if need to issue/transfer
			IF @lFoundinBOM = 1
				BEGIN
				IF @KitReq_qty > @BomReqQty	-- Kit Req qty is more than new BOM req qty
					BEGIN
					IF @KitAct_qty > @BomReqQty	-- picked more than needed, so now need to decreased issued and move to over-issued
						BEGIN
						SET @lDelta = ABS(@BomReqQty - (CASE WHEN @KitAct_qty<@KitReq_Qty THEN @KitAct_qty ELSE @KitReq_qty END))

						-- Go through Kalocate, Kalocipkey to issue/transfer based on if @ReturnToInventory = 1 or 0
						SET @lnTableVarCnt = 0
						DELETE FROM @Kalocate WHERE 1=1
						INSERT INTO @Kalocate (UniqKalocate, Kaseqnum, W_key, Pick_qty, Lotcode, Expdate, Reference, Ponum, Overissqty, Overw_key, Uniqmfgrhd)
							SELECT UniqKalocate, Kaseqnum, W_key, Pick_qty, Lotcode, Expdate, Reference, Ponum, Overissqty, Overw_key, Uniqmfgrhd
								FROM Kalocate 
								WHERE Kaseqnum = @Kaseqnum
								AND Pick_qty - Overissqty > 0 
						UPDATE @Kalocate SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
						SET @lnTotalNoKalocate = @@ROWCOUNT

						-- Scan through Kalocate records for this @Kaseqnum to issue back and transfer back
						IF (@lnTotalNoKalocate>0)
						BEGIN
							SET @lnCountKalocate=0;
							WHILE @lnTotalNoKalocate>@lnCountKalocate AND @lDelta > 0
							BEGIN	
								SET @lnCountKalocate=@lnCountKalocate+1;
								SELECT @UniqKalocate = UniqKalocate, @W_key = w_key, @Pick_qty = Pick_qty, @Lotcode = Lotcode, @Expdate = Expdate,
										@Reference = Reference, @Ponum = Ponum, @OverissQty = OverissQty, @Overw_key = Overw_key, @UniqMfgrhd = UniqMfgrhd
									FROM @Kalocate WHERE nRecno = @lnCountKalocate

								IF @@ROWCOUNT > 0	-- If find Kalocate record
									BEGIN

									-------------------------------------------------------
									-- Check if the original location is IN-STORE. Do not return it to the IN-STORE location
									--find a not IN_STORE location or create one
									-- Check if the @w_key is an instore location, need to return to non-instore location, also get several fields to be checked later
									SELECT @Instore = Instore, @UniqSupno = UniqSupno, @Uniqwh = UniqWh 
										FROM Invtmfgr 
										WHERE W_key = @W_key

									SET @lUseW_key = @W_key
									IF @Instore = 1
										BEGIN
										EXEC sp_GetNotInstoreLocation4Mfgrhd @UniqMfgrhd, @lUsew_key OUTPUT
									END

									-- Find if invtmfgr has WO-WIP for same Uniqmfgrhd, Instore, Uniqsupno if not will create one invtmfgr in stored procedure
									EXEC sp_GetWOWIPLocation4WonoKit @gWono, @lUseW_key, @lcOverW_key OUTPUT
									-------------------------------------------------------
									IF @Pick_Qty - @OverissQty < @lDelta AND @Pick_Qty - @OverissQty <> 0
										BEGIN
										SET @IssueThisTime = @Pick_Qty - @OverissQty
										SET @NeedNewKalocateRec = 0
										END
									ELSE
										BEGIN
										SET @IssueThisTime = @lDelta
										SET @NeedNewKalocateRec = 1
									END

									-- Put issued qty back to inventory by issuing negative qty and become over-issued
									IF @IssueThisTime<>0
										BEGIN
										SET @Invtisu_no = dbo.fn_GenerateUniqueNumber()
										INSERT INTO Invt_isu (W_key,Uniq_key,IssuedTo,QtyIsu,U_of_meas, Wono,Gl_nbr,LotCode,Expdate,Reference, 
											Saveinit,Ponum,UniqMfgrHD, Date, Invtisu_no, cModid, SourceDev) 
										VALUES (@lUseW_key,@KitUniq_key,'(WO:'+@gWono,-@IssueThisTime,@KitU_of_meas, @gWono,@WipGlNbr, 
											@LotCode, @Expdate, @Reference,	@lcUserID, @Ponum, @UniqMfgrHd, GETDATE(), @Invtisu_no, 'U', 'I')

										SET @Invtxfer_n = dbo.fn_GenerateUniqueNumber()
										INSERT INTO Invttrns (Uniq_key,QTYXFER,REASON,FromWkey,ToWkey, LotCode, ExpDate,Reference,Ponum,UniqMfgrHd, Invtxfer_n, 
											Date, StdCost, cModId, Wono, Kaseqnum, SaveInit, sourceDev) 
										VALUES (@KitUniq_key, @IssueThisTime, 'KIT Over Issue', @lUseW_key,@lcOverW_key, @LotCode, @ExpDate, @Reference, @Ponum, 
											@UniqMfgrHD, @Invtxfer_n, GETDATE(), @StdCost, 'U', @gWono, @Kaseqnum, @lcUserId, 'I')

										-- Update Kalocate records and see if need to insert new Kalocate if @NeedNewKalocateRec = 1
										IF @NeedNewKalocateRec = 0
											BEGIN
											UPDATE Kalocate
												SET Overw_key = @lcOverW_key,
													OverIssQty = OverIssQty + @IssueThisTime
											WHERE UniqKalocate = @UniqKalocate
											END
										ELSE
											BEGIN
											UPDATE Kalocate
												SET Pick_qty = Pick_qty - @IssueThisTime
											WHERE UniqKalocate = @UniqKalocate

											-- Try to find another kalocate for the w_key=@lUseW_key, overw_key = @lcOverW_key, if found update, otherwise create a new kalocate record
											SELECT @GetUniqKalocate = UniqKalocate
												FROM Kalocate
												WHERE Kaseqnum = @Kaseqnum
												AND W_key = @lUseW_key
												AND Overw_key = @lcOverW_key
												AND LotCode = @Lotcode
												AND ISNULL(Expdate,1) = ISNULL(@Expdate,1) 
												AND Reference = @Reference
												AND Ponum = @Ponum
											
											IF @@ROWCOUNT = 0	-- didn't find, create one
												BEGIN
												SET @GetUniqKalocate = dbo.fn_GenerateUniqueNumber()
												INSERT INTO Kalocate (UniqKalocate, Kaseqnum, W_key, Pick_qty, Lotcode, Expdate, Reference, OverIssQty, Overw_key, Ponum, UniqMfgrhd, Wono)
													VALUES (@GetUniqKalocate, @Kaseqnum, @lUseW_key, @IssueThisTime, @Lotcode, @Expdate, @Reference, @IssueThisTime, @lcOverW_key, @Ponum, @UniqMfgrhd, @gWono)
												END
											ELSE
												BEGIN
												UPDATE Kalocate
												SET Pick_qty = Pick_qty + @IssueThisTime,
													OverIssQty = OverIssQty + @IssueThisTime
												WHERE UniqKalocate = @GetUniqKalocate
											END
										END -- @NeedNewKalocateRec = 0

									END -- @IssueThisTime<>0
								
									IF @UseIpkey = 1	-- Need to Update issueIpkey and iTransferIpkey
										BEGIN
										SET @lnTableVarCnt = 0
										DELETE FROM @KalocIpkey WHERE 1=1

										INSERT INTO @KalocIpkey (UniqKalocIpkey, UniqKalocate, Fk_IpkeyUnique, nPick_qty, nOverIssQty, OverIpkeyUnique)
											SELECT UniqKalocIpkey, UniqKalocate, Fk_IpkeyUnique, nPick_qty, nOverIssQty, OverIpkeyUnique
												FROM KalocIpkey
												WHERE UniqKalocate = @UniqKalocate
												AND nPick_qty - nOverIssQty > 0 

										UPDATE @KalocIpkey SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
										SET @lnTotalNoKalocIpkey = @@ROWCOUNT

										-- Scan through KalocIpkey records for this @Uniqkalocate to issue back and transfer back
										IF (@lnTotalNoKalocIpkey>0)
										BEGIN
											SET @lnCountKalocIpkey=0;
											SET @lDelta2 = @IssueThisTime
											WHILE @lnTotalNoKalocIpkey>@lnCountKalocIpkey AND @lDelta2 > 0
											BEGIN	
												SET @lnCountKalocIpkey=@lnCountKalocIpkey+1;
												SELECT @UniqKalocIpkey = UniqKalocIpkey, @Fk_IpkeyUnique = Fk_IpkeyUnique, 
														@nPick_qty = nPick_qty, @nOverIssQty = nOverIssQty, @OverIpkeyUnique = OverIpkeyUnique
													FROM @KalocIpkey WHERE nRecno = @lnCountKalocIPkey

												IF @@ROWCOUNT > 0
													BEGIN

													IF @nPick_Qty - @nOverissQty < @lDelta2 AND @nPick_Qty - @nOverissQty <> 0
														BEGIN
														SET @IssueThisTime2 = @nPick_Qty - @nOverissQty
														END
													ELSE
														BEGIN
														SET @IssueThisTime2 = @lDelta2
													END
													IF @IssueThisTime2 > 0
														BEGIN
														INSERT INTO IssueIpkey (IssueIpkeyUnique, Invtisu_no, QtyIssued, IpkeyUnique) 
															VALUES (dbo.fn_GenerateUniqueNumber(), @Invtisu_no, -@IssueThisTime2, @Fk_IpkeyUnique)
														SET @NewTransferIpkey = dbo.fn_GenerateUniqueNumber()
														INSERT INTO iTransferIpkey (iXferIPkeyUnique, Invtxfer_n, QtyTransfer, FromIpkeyUnique, ToIpkeyunique)
															VALUES (dbo.fn_GenerateUniqueNumber(), @Invtxfer_n, @IssueThisTime2, @Fk_IpkeyUnique, @NewTransferIpkey)	-- transfer to a new WO-WIP ipkey location

														-- Update Kalocipkey records and see if need to insert new Kalocipkey if @NeedNewKalocateRec = 1
														IF @NeedNewKalocateRec = 0
															BEGIN
															UPDATE Kalocipkey
																SET nOverIssQty = nOverIssQty + @IssueThisTime2,
																	OverIpkeyUnique = @NewTransferIpkey
															WHERE UniqKalocIpkey = @UniqKalocipkey
															END
														ELSE
															BEGIN
															UPDATE KalocIpkey
																SET nPick_qty = nPick_qty - @IssueThisTime2
															WHERE UniqKalocIpkey = @UniqKalocipkey

															INSERT INTO Kalocipkey (Uniqkalocipkey, Uniqkalocate, Fk_ipkeyunique, nPick_qty, nOverIssQty, OverIpkeyUnique) 
																VALUES (dbo.fn_GenerateUniqueNumber(), @GetUniqKalocate, @Fk_ipkeyunique, @IssueThisTime2, @IssueThisTime2, @NewTransferIpkey)
												
											
														END -- @NeedNewKalocateRec = 0

													END
												END -- @@ROWCOUNT > 0

												SET @lDelta2 = @lDelta2 - @IssuethisTime2
											END -- WHILE @lnTotalNoKalocIpkey>@lnCountKalocIpkey
										END -- (@lnTotalNoKalocIpkey>0)

									END -- @UseIpkey = 1
									SET @lDelta = @lDelta - @IssueThisTime
								END -- @@ROWCOUNT > 0	-- If find Kalocate record
								
							END -- @lnTotalNoKalocate>@lnCountKalocate

						END -- IF (@lnTotalNoKalocate>0)
					END --

					UPDATE Kamain 
						SET ShortQty = @BomReqQty - @KitAct_qty 
						WHERE Kaseqnum = @Kaseqnum

					-- Insert Kadetail
					INSERT INTO Kadetail (Kaseqnum, ShReason, ShortQty, ShQualify, ShortBal, AuditDate, AuditBy, UniqueRec, Wono)
						VALUES (@Kaseqnum, 'KIT UPDATE', -(@KitShortQty - (@BomReqQty - @KitAct_qty)) ,'EDT', @BomReqQty - @KitAct_qty , GETDATE(), @lcUserId, dbo.fn_GenerateUniqueNumber(), @gWono)

				END -- @KitReq_qty > @BomReqQty	-- Kit Req qty is more than new BOM req qty
				
				IF @KitReq_qty<@BomReqQty
				BEGIN
					IF @KitShortQty< 0.00 -- had overissue need to reduce and create issue or move back to stock
						BEGIN

						BEGIN
						IF @KitAct_QTY <= @BomReqQty -- --transfer all overissue and issue
							BEGIN

							-- Go through Kalocate, Kalocipkey to issue/transfer
							SET @lnTableVarCnt = 0
							DELETE FROM @Kalocate WHERE 1=1
							INSERT INTO @Kalocate (UniqKalocate, Kaseqnum, W_key, Pick_qty, Lotcode, Expdate, Reference, Ponum, Overissqty, Overw_key, Uniqmfgrhd)
								SELECT UniqKalocate, Kaseqnum, W_key, Pick_qty, Lotcode, Expdate, Reference, Ponum, Overissqty, Overw_key, Uniqmfgrhd
									FROM Kalocate 
									WHERE Kaseqnum = @Kaseqnum
									AND Overissqty > 0 
							UPDATE @Kalocate SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
							SET @lnTotalNoKalocate = @@ROWCOUNT

							-- Scan through Kalocate records for this @Kaseqnum to issue back and transfer back
							IF (@lnTotalNoKalocate>0)
							BEGIN
								SET @lnCountKalocate=0;
								WHILE @lnTotalNoKalocate>@lnCountKalocate
								BEGIN	
									SET @lnCountKalocate=@lnCountKalocate+1;
									SELECT @UniqKalocate = UniqKalocate, @W_key = w_key, @Pick_qty = Pick_qty, @Lotcode = Lotcode, @Expdate = Expdate,
											@Reference = Reference, @Ponum = Ponum, @OverissQty = OverissQty, @Overw_key = Overw_key, @UniqMfgrhd = UniqMfgrhd
										FROM @Kalocate WHERE nRecno = @lnCountKalocate

									IF @@ROWCOUNT > 0	-- If find Kalocate record
										BEGIN
										-- Transfer back
										SET @Invtxfer_n = dbo.fn_GenerateUniqueNumber()
										INSERT INTO Invttrns (Uniq_key,QTYXFER,REASON,FromWkey,ToWkey, LotCode, ExpDate,Reference,Ponum,UniqMfgrHd, Invtxfer_n, 
											Date, StdCost, cModId, Wono, Kaseqnum, SaveInit, sourceDev) 
										VALUES (@KitUniq_key, @OverissQty, 'KIT Reduce Issue', @Overw_key,@W_key, @LotCode, @ExpDate, @Reference, @Ponum, 
											@UniqMfgrHD, @Invtxfer_n, GETDATE(), @StdCost, 'U', @gWono, @Kaseqnum, @lcUserId, 'I')

										-- Issue to WO
										SET @Invtisu_no = dbo.fn_GenerateUniqueNumber()
										INSERT INTO Invt_isu (W_key,Uniq_key,IssuedTo,QtyIsu,U_of_meas, Wono,Gl_nbr,LotCode,Expdate,Reference, 
											Saveinit,Ponum,UniqMfgrHD, Date, Invtisu_no, cModid, SourceDev) 
										VALUES (@W_key,@KitUniq_key,'(WO:'+@gWono,@OverissQty,@KitU_of_meas, @gWono,@WipGlNbr, 
											@LotCode, @Expdate, @Reference,	@lcUserID, @Ponum, @UniqMfgrHd, GETDATE(), @Invtisu_no, 'U', 'I')

										IF @UseIpkey = 1	-- Need to Update issueIpkey and iTransferIpkey
											BEGIN
											SET @lnTableVarCnt = 0
											DELETE FROM @KalocIpkey WHERE 1=1

											INSERT INTO @KalocIpkey (UniqKalocIpkey, UniqKalocate, Fk_IpkeyUnique, nPick_qty, nOverIssQty, OverIpkeyUnique)
												SELECT UniqKalocIpkey, UniqKalocate, Fk_IpkeyUnique, nPick_qty, nOverIssQty, OverIpkeyUnique
													FROM KalocIpkey
													WHERE UniqKalocate = @UniqKalocate
													AND nOverIssQty > 0 OR OverIpkeyUnique<>''

											UPDATE @KalocIpkey SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
											SET @lnTotalNoKalocIpkey = @@ROWCOUNT

											-- Scan through KalocIpkey records for this @Uniqkalocate to issue back and transfer back
											IF (@lnTotalNoKalocIpkey>0)
												BEGIN
												SET @lnCountKalocIpkey=0;
												SET @lDelta2 = @OverissQty
												WHILE @lnTotalNoKalocIpkey>@lnCountKalocIpkey AND @lDelta2 > 0
												BEGIN	
													SET @lnCountKalocIpkey=@lnCountKalocIpkey+1;
													SELECT @UniqKalocIpkey = UniqKalocIpkey, @Fk_IpkeyUnique = Fk_IpkeyUnique, 
															@nPick_qty = nPick_qty, @nOverIssQty = nOverIssQty, @OverIpkeyUnique = OverIpkeyUnique
														FROM @KalocIpkey WHERE nRecno = @lnCountKalocIPkey

													IF @@ROWCOUNT > 0
														BEGIN
														SET @IssueThisTime2 = CASE WHEN @lDelta2>@nOverIssQty THEN @nOverIssQty ELSE @lDelta2 END

														IF @IssueThisTime2 > 0
														SET @GetNewIpkey = dbo.fn_GenerateUniqueNumber()
														INSERT INTO iTransferIpkey (iXferIPkeyUnique, Invtxfer_n, QtyTransfer, FromIpkeyUnique, ToIpkeyunique)
															VALUES (dbo.fn_GenerateUniqueNumber(), @Invtxfer_n, @IssueThisTime2, @OverIpkeyUnique, @GetNewIpkey)

														INSERT INTO IssueIpkey (IssueIpkeyUnique, Invtisu_no, QtyIssued, IpkeyUnique) 
															VALUES (dbo.fn_GenerateUniqueNumber(), @Invtisu_no, @IssueThisTime2, @GetNewIpkey)	-- Issue from the same ipkey

														UPDATE Kalocipkey
															SET nOverIssQty = 0, 
																OverIpkeyUnique = ''
															WHERE UniqKalocIpkey = @UniqKalocIpkey

														SET @lDelta2 = @lDelta2 - @IssueThisTime2
													END
												END
											END -- @lnTotalNoKalocIpkey
										END -- IF @UseIpkey = 1

										-- Update Kalocate
										UPDATE Kalocate
											SET OverW_key = '',
												OverIssQty = 0 
											WHERE Uniqkalocate = @UniqKalocate

									END -- @@ROWCOUNT > 0	-- If find Kalocate record
								END -- WHILE @lnTotalNoKalocate>@lnCountKalocate AND @lDelta > 0
							END -- IF (@lnTotalNoKalocate>0)

							UPDATE Kamain 
								SET ShortQty = @BomReqQty - @KitAct_qty
								WHERE Kaseqnum = @Kaseqnum

							-- Insert Kadetail
							INSERT INTO Kadetail (Kaseqnum, ShReason, ShortQty, ShQualify, ShortBal, AuditDate, AuditBy, UniqueRec, Wono)
								VALUES (@Kaseqnum, 'KIT UPDATE', -(@KitShortQty - (@BomReqQty - @KitAct_qty)) , CASE WHEN @KitShortQty = 0 THEN 'ADD' ELSE 'EDT' END, @BomReqQty - @KitAct_qty , GETDATE(), @lcUserId, dbo.fn_GenerateUniqueNumber(), @gWono)

							END
						ELSE
						-- IF @KitAct_QTY <= @BomReqQty
							BEGIN

							SET @DeltaIssue = ABS(@KitShortQty - (@BomReqQty - @KitAct_qty))

							-- Go through Kalocate, Kalocipkey to issue/transfer
							SET @lnTableVarCnt = 0
							DELETE FROM @Kalocate WHERE 1=1
							INSERT INTO @Kalocate (UniqKalocate, Kaseqnum, W_key, Pick_qty, Lotcode, Expdate, Reference, Ponum, Overissqty, Overw_key, Uniqmfgrhd)
								SELECT UniqKalocate, Kaseqnum, W_key, Pick_qty, Lotcode, Expdate, Reference, Ponum, Overissqty, Overw_key, Uniqmfgrhd
									FROM Kalocate 
									WHERE Kaseqnum = @Kaseqnum
									AND Overissqty > 0 
							UPDATE @Kalocate SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
							SET @lnTotalNoKalocate = @@ROWCOUNT

							-- Scan through Kalocate records for this @Kaseqnum to issue back and transfer back
							IF (@lnTotalNoKalocate>0)
							BEGIN
								SET @lnCountKalocate=0;
								WHILE @lnTotalNoKalocate>@lnCountKalocate AND @DeltaIssue > 0
								BEGIN	
									SET @lnCountKalocate=@lnCountKalocate+1;
									SELECT @UniqKalocate = UniqKalocate, @W_key = w_key, @Pick_qty = Pick_qty, @Lotcode = Lotcode, @Expdate = Expdate,
											@Reference = Reference, @Ponum = Ponum, @OverissQty = OverissQty, @Overw_key = Overw_key, @UniqMfgrhd = UniqMfgrhd
										FROM @Kalocate WHERE nRecno = @lnCountKalocate

									IF @@ROWCOUNT > 0	-- If find Kalocate record
										BEGIN
										SET @IssueThisTime3 = CASE WHEN @OverissQty >= @DeltaIssue THEN @DeltaIssue ELSE @OverIssQty END
										
										-- Transfer back
										SET @Invtxfer_n = dbo.fn_GenerateUniqueNumber()
										INSERT INTO Invttrns (Uniq_key,QTYXFER,REASON,FromWkey,ToWkey, LotCode, ExpDate,Reference,Ponum,UniqMfgrHd, Invtxfer_n, 
											Date, StdCost, cModId, Wono, Kaseqnum, SaveInit, sourceDev) 
										VALUES (@KitUniq_key, @IssueThisTime3, 'KIT Reduce Issue', @Overw_key,@W_key, @LotCode, @ExpDate, @Reference, @Ponum, 
											@UniqMfgrHD, @Invtxfer_n, GETDATE(), @StdCost, 'U', @gWono, @Kaseqnum, @lcUserId, 'I')

										-- Issue to WO
										SET @Invtisu_no = dbo.fn_GenerateUniqueNumber()
										INSERT INTO Invt_isu (W_key,Uniq_key,IssuedTo,QtyIsu,U_of_meas, Wono,Gl_nbr,LotCode,Expdate,Reference, 
											Saveinit,Ponum,UniqMfgrHD, Date, Invtisu_no, cModid, SourceDev) 
										VALUES (@W_key,@KitUniq_key,'(WO:'+@gWono,@IssueThisTime3,@KitU_of_meas, @gWono,@WipGlNbr, 
											@LotCode, @Expdate, @Reference,	@lcUserID, @Ponum, @UniqMfgrHd, GETDATE(), @Invtisu_no, 'U', 'I')



										IF @UseIpkey = 1	-- Need to Update issueIpkey and iTransferIpkey
											BEGIN
											SET @lnTableVarCnt = 0
											DELETE FROM @KalocIpkey WHERE 1=1

											INSERT INTO @KalocIpkey (UniqKalocIpkey, UniqKalocate, Fk_IpkeyUnique, nPick_qty, nOverIssQty, OverIpkeyUnique)
												SELECT UniqKalocIpkey, UniqKalocate, Fk_IpkeyUnique, nPick_qty, nOverIssQty, OverIpkeyUnique
													FROM KalocIpkey
													WHERE UniqKalocate = @UniqKalocate
													AND nOverIssQty > 0 OR OverIpkeyUnique<>''

											UPDATE @KalocIpkey SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
											SET @lnTotalNoKalocIpkey = @@ROWCOUNT

											-- Scan through KalocIpkey records for this @Uniqkalocate to issue back and transfer back
											IF (@lnTotalNoKalocIpkey>0)
												BEGIN
												SET @lnCountKalocIpkey=0;
												SET @lDelta3 = @IssueThisTime3
												WHILE @lnTotalNoKalocIpkey>@lnCountKalocIpkey AND @lDelta3 > 0
												BEGIN	
													SET @lnCountKalocIpkey=@lnCountKalocIpkey+1;
													SELECT @UniqKalocIpkey = UniqKalocIpkey, @Fk_IpkeyUnique = Fk_IpkeyUnique, 
															@nPick_qty = nPick_qty, @nOverIssQty = nOverIssQty, @OverIpkeyUnique = OverIpkeyUnique
														FROM @KalocIpkey WHERE nRecno = @lnCountKalocIPkey

													IF @@ROWCOUNT > 0
														BEGIN
														SET @IssueThisTime4 = CASE WHEN @lDelta3>@nOverIssQty THEN @nOverIssQty ELSE @lDelta3 END

														IF @IssueThisTime4 > 0
														SET @GetNewIpkey = dbo.fn_GenerateUniqueNumber()
														INSERT INTO iTransferIpkey (iXferIPkeyUnique, Invtxfer_n, QtyTransfer, FromIpkeyUnique, ToIpkeyunique)
															VALUES (dbo.fn_GenerateUniqueNumber(), @Invtxfer_n, @IssueThisTime4, @OverIpkeyUnique, @GetNewIpkey)

														INSERT INTO IssueIpkey (IssueIpkeyUnique, Invtisu_no, QtyIssued, IpkeyUnique) 
															VALUES (dbo.fn_GenerateUniqueNumber(), @Invtisu_no, @IssueThisTime4, @GetNewIpkey)	-- Issue from the same ipkey

														UPDATE Kalocipkey
															SET nOverIssQty = 0, 
																OverIpkeyUnique = ''
															WHERE UniqKalocIpkey = @UniqKalocIpkey

														SET @lDelta3 = @lDelta3 - @IssueThisTime4
													END
												END
											END -- @lnTotalNoKalocIpkey
										END -- IF @UseIpkey = 1

										-- Update Kalocate
										UPDATE Kalocate
											SET OverIssQty = OverIssQty - @IssueThisTime3,
												OverW_key = CASE WHEN OverIssQty - @IssueThisTime3 > 0 THEN OverW_key ELSE '' END
											WHERE Uniqkalocate = @UniqKalocate

									END -- @@ROWCOUNT > 0	-- If find Kalocate record
									SET @DeltaIssue = @DeltaIssue - @IssueThisTime3
								END -- WHILE @lnTotalNoKalocate>@lnCountKalocate AND @lDelta > 0
							END -- IF (@lnTotalNoKalocate>0)

							UPDATE Kamain 
								SET ShortQty = @BomReqQty - @KitAct_qty
								WHERE Kaseqnum = @Kaseqnum

							-- Insert Kadetail
							INSERT INTO Kadetail (Kaseqnum, ShReason, ShortQty, ShQualify, ShortBal, AuditDate, AuditBy, UniqueRec, Wono)
								VALUES (@Kaseqnum, 'KIT UPDATE', -(@KitShortQty - (@BomReqQty - @KitAct_qty)) , CASE WHEN @KitShortQty = 0 THEN 'ADD' ELSE 'EDT' END, @BomReqQty - @KitAct_qty , GETDATE(), @lcUserId, dbo.fn_GenerateUniqueNumber(), @gWono)

							END
						END --IF @KitAct_QTY <= @BomReqQty
					END --IF @KitShorQty< 0.00
				END -- @KitReq_qty<@BomReqQty
			END --IF @lFoundinBOM = 1
		END -- End of IF (@@ROWCOUNT<>0)
	END -- End of WHILE @lnTotalNo>@lnCount
END -- End of @lnTotalNo>0

-- Now will check if any new BOM items need to be added into Kit
---------------------------------------------------------------
INSERT @KitNewItem (Wono,Dept_id,Uniq_key,Initials,EntryDate, KaseqNum,Bomparent,ShortQty,Qty)
	SELECT @gWono AS Wono, Dept_id, Uniq_key, @lcUserId AS Initials, GETDATE() AS EntryDate, dbo.fn_GenerateUniqueNumber(), Bomparent, ReqQty, Qty 
		FROM @AllBomDetView B
		WHERE NOT EXISTS 
			(SELECT Bomparent,Uniq_key,Dept_id, nSequence
				FROM @KitMainView K
				WHERE B.Bomparent = K.Bomparent
				AND B.Dept_id = K.Dept_id
				AND B.Uniq_key = K.Uniq_key
				AND B.nSequence = K.nSequence)

-- Insert Kamain
INSERT INTO Kamain (Wono,Dept_id,Uniq_key,Initials,EntryDate, KaseqNum,Bomparent,ShortQty,Qty)
	SELECT Wono,Dept_id,Uniq_key,Initials,EntryDate, KaseqNum,Bomparent,ShortQty,Qty 
		FROM @KitNewItem

-- Insert Kadetail
INSERT INTO Kadetail (Kaseqnum, ShReason, ShortQty, ShQualify, ShortBal, AuditDate, AuditBy, UniqueRec, Wono)
	SELECT Kaseqnum, 'KIT MODULE' AS ShReason, ShortQty, 'ADD', ShortQty AS ShortBal, GETDATE(), @lcUserid AS AuditBy, dbo.fn_GenerateUniqueNumber() AS UniqueRec, @gWono AS Wono
		FROM @KitNewItem


UPDATE Woentry
	SET KitLstChDT  = GETDATE(),
		KitLstChInit = @lcUserId
	WHERE Wono = @gWono
        
IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END