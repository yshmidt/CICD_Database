-- =============================================
-- Author:		Vicky Lu
-- Create date: 2011/09/01
-- Description:	Update ECO WO
-- 07/19/13 VL added code to update if the WO has partial completion, need to issue only woentry.complete calculated component req qty and issue all extra into new work order
-- 02/19/14 VL added Gl_nbr value for inserting to Invt_isu table, it's missed
-- 06/03/14 VL Foudn if the WO is partially completed, when moving balance to new WO, didn't have code to move those SN to new WO
-- 07/13/14 VL Changed to use not intore w_key
-- Modified: 10/10/14 YS removed invtmfhd table and replaced with 2 new tables
-- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int
-- 10/31/14 YS removed fk_ipkeyunique from kalocate
-- 02/17/15 VL Added one more parameter to fn_PhanntomSubSelect() to not pull inactive parts
-- 08/27/15 VL changed StdCostper1Build from numeric(13,5) to numeric(29,5), Inovar has really bit number and caused overflow, bom_qty numeric(9,2), bld_qty numeric(7,0) and stdcost numeric(13,5)
--			   also changed @ZOldWoKitReq.qty from numeric(9,2) to numeric(12,2)
-- 04/25/16 VL When ECO update work order, the allcoation created for the old work orders should be un-allocated because the WO is going to be closed
-- 02/14/17 VL set @lnDelta = 0 after adjust overissued qty and regular qty, if still > 0, set to = 0 otherwise will stay in the loop of WHILE @lnDelta > 0
-- 02/28/17 VL change from @lcUpdW_key to @lcUseW_key when issue over-issued qty back to inventory
-- 09/19/17 YS added Jobtype to woentry to separate Job type from the Status (openclos)
--03/02/18 YS changed lotcode size to 25
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[sp_UpdEcoWo] @gUniqEcNo AS char(10) = ' ', @lcNewUniq_key char(10) = ' ', @lcUserId char(8) = ' '
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
DECLARE @lnTotalNo int, @lnCount int, @lcEcoWono char(10), @lcOldUniq_key char(10), @llSerialYes bit, @lnEcoComplete numeric(7,0),
		@lnNewBldQty numeric(7,0), @lcEcoNewWono char(10), @ldOldDue_date smalldatetime, @lKitIgnoreScrap bit, @lnTotalNoKamain int, 
		@lnCountKamain int, @lnTableVarCnt int, @lnDelta numeric(12,2), @lcAdjUniq_key char(10), @lcAdjDept_id char(4), @lnAdjAct_Qty numeric(12,2),
		@lnAdjReqQty numeric(12,2), @lcAdjKaseqnum char(10), @lcAdjPart_no char(35), @lcAdjRevision char(8), @lnTotalNoKalocate int, 
		@lnCountKalocate int, @lnUpdPick_qty numeric(12,2),	@lnUpdOverissQty numeric(12,2), @lcUpdUniqKalocate char(10), 
		@lcUpdOverW_key char(10), @lcUpdW_key char(10), @lcUpdUniqMfgrhd char(10), @lnAdjQty numeric(12,2), @lnCompStdCost numeric(13,5), 
		@lcCompU_of_meas char(4), @lcNewKaseqnum char(10), @lcMsg varchar(max), @lnTotalNoReturnQty int, @lnCountReturnQty int, @lnNewReqQty numeric(12,2),
		@lnAdjQty2 numeric(12,2), @lcNewW_key char(10), @lnNewReturnQty numeric(12,2), @lnDelta2 numeric(12,2), @lcNewUniqmfgrhd char(10), @lnLeftQty numeric(12,2),
		@lcWOWIPW_key char(10), @llXxWonoSys bit, @lcEcoUniqEcWono char(10), @lcNewUniqKalocate char(10), @lcNEWStagDeptkey char(10),
		@lcUseW_key char(10)
		
DECLARE @ZQuotDept TABLE (OldUniqnumber char(10), Number numeric(4,0), NewUniqnumber char(10))
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
DECLARE @ZOldWoKitReq TABLE (Item_no numeric(4,0),Part_no char(35),Revision char(8),Custpartno char(35),
		Custrev char(8),Part_class char(8),Part_type char(8),Descript char(45),Qty numeric(12,2), Scrap_qty numeric(9,2), StdCostper1Build numeric(29,5),
		Scrap_Cost numeric(13,5), SetupScrap_cost numeric(13,5), Sort varchar(4), Bomparent char(10),Uniq_key char(10),Dept_id char(4),Item_note text,Offset numeric(3,0),
		Term_dt smalldatetime, Eff_dt smalldatetime,Custno char(10),U_of_meas char(4),Inv_note text,
		Part_sourc char(10),Perpanel numeric(4,0),Used_inkit char(1), Scrap numeric(6,2), 
		SetupScrap numeric(4,0),UniqBomNo char(10),Buyer_type char(3),StdCost numeric(13,5),
		Phant_make bit, Make_buy bit, MatlType char(5), TopStdCost numeric(13,5), LeadTime numeric(4,0),
		UseSetScrp bit, SerialYes bit, StdBldQty numeric(8,0), Level numeric(3,0), ReqQty numeric(12,2), nRecno int);
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
DECLARE @ZKaMainAdj TABLE (Uniq_key char(10), Dept_id char(4), Act_Qty numeric(12,2), ReqQty numeric(12,2), Kaseqnum char(10), Part_no char(35), Revision char(8), nRecno int)
--10/31/14 YS removed fk_ipkeyunique from kalocate
--03/02/18 YS changed lotcode size to 25
DECLARE @ZKalocate TABLE (UniqKalocate char(10), Kaseqnum char(10), W_key char(10), Pick_qty numeric(12,2), LotCode nvarchar(25), Expdate smalldatetime,
							Reference char(12), OverissQty numeric(12,2), OverW_key char(10), Ponum char(15), Uniqmfgrhd char(10),  Wono char(10), nRecno int, OrderPref numeric(2,0))
-- 07/22/13 VL added complete, if complete>0, have to work for kitted items
DECLARE @ZEcWo TABLE (nrecno int identity, Wono char(10), BldQty numeric(7,0), Complete numeric(7,0), NewWono char(10), OldDue_date smalldatetime, UniqEcWono char(10))

-- 08/13/13 VL create a temp table stores the return to inventory w_key, qty from the kamain record that have act_qty>reqqty
DECLARE @ZKitReturnQty TABLE (nRecno int, w_key char(10), ReturnQty numeric(12,2), Uniqmfgrhd char(10), Type char(1))	-- Type = 'I' or 'O' means from invt_isu or invttrns
-- 08/19/13 VL created 2nd one to make it order by type "I" first, the type "O", will have right order to insert to @ZKitReturnQty
DECLARE @ZKitReturnQty1 TABLE (nRecno int, w_key char(10), ReturnQty numeric(12,2), Uniqmfgrhd char(10), Type char(1))	-- Type = 'I' or 'O' means from invt_isu or invttrns


BEGIN TRANSACTION
BEGIN TRY;		


SELECT @lcOldUniq_key = Uniq_key FROM ECMAIN WHERE UNIQECNO = @gUniqEcNo

SELECT @lKitIgnoreScrap = lKitIgnoreScrap
	FROM KitDef;
	
SELECT @llSerialYes = SerialYes FROM INVENTOR WHERE UNIQ_KEY = @lcNewUniq_key

-- 08/16/13 VL added code to update Ecwo.NewWono if number system is set to auto
SELECT @llXxWonoSys = XxWonoSys FROM MICSSYS 

--INSERT @ZEcWo SELECT Wono FROM ECWO WHERE UNIQECNO = @gUniqEcNo AND CHANGE = 1
INSERT @ZEcWo SELECT Ecwo.WONO, BldQty, Woentry.Complete, NewWono, Woentry.Due_date AS OldDue_date, UNIQECWONO 
	FROM ECWO, Woentry WHERE Ecwo.Wono = Woentry.Wono AND UNIQECNO = @gUniqEcNo AND CHANGE = 1

SET @lnTotalNo = @@ROWCOUNT;
IF (@lnTotalNo>0)
BEGIN
	SET @lnCount=0;
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @lcEcoWono = Wono, @lnEcoComplete = Complete, @lnNewBldQty = BldQty - Complete, @lcEcoNewWono = NewWono, 
				@ldOldDue_date = OldDue_date, @lcEcoUniqEcWono = UniqEcWono
			FROM @ZEcWo WHERE nrecno = @lnCount	
		IF (@@ROWCOUNT<>0)
		BEGIN
			-- 07/22/13 VL separate into two cases: has no completion/partial completion
			BEGIN
			IF @lnEcoComplete = 0 
				BEGIN
				-- Update Woentry
				UPDATE WOENTRY
					SET UNIQ_KEY = @lcNewUniq_key, SONO = '', UNIQUELN = '', SERIALYES = @llSerialYes
					WHERE WONO = @lcEcoWono
				
				-- Update Kit Bomparent
				UPDATE Kamain 
					SET BomParent = @lcNewUniq_key 
					WHERE Wono = @lcEcoWono 
					AND Bomparent = @lcOldUniq_key
			
				-- has to update the routing to latest first, otherwise, the following update number part will fail
				EXEC [sp_UpdWoRouting] @lcOldUniq_key, @lcEcoWono;

				-- Start to update Deptkey, actvkey of all tables
				--------------------------------------------------
				-- Create ZQuotDept data for the WO first, it will be used several times later
				INSERT @ZQuotDept
					SELECT ZOld.UniqNumber AS OldUniqNumber, ZOld.Number AS Number, ZNew.Uniqnumber AS NewUniqNumber
						FROM QUOTDEPT ZOld, QUOTDEPT ZNew
						WHERE ZOld.NUMBER = ZNew.NUMBER
						AND ZOld.UNIQ_KEY = @lcOldUniq_key
						AND ZNew.UNIQ_KEY = @lcNewUniq_key
						
				-- Update Deptkey of Dept_qty
				UPDATE Dept_qty SET DEPTKEY = ZQuotDept.NewUniqnumber
					FROM DEPT_QTY, @ZQuotDept ZQuotDept
					WHERE DEPT_QTY.Number = ZQuotDept.Number
					AND DEPT_QTY.WONO = @lcEcoWono
					AND DEPT_QTY.DEPTKEY = ZQuotDept.OldUniqNumber
					
				-- Update Deptkey and ActvKey of Actv_qty
				UPDATE Actv_qty SET DEPTKEY = ZQuotDept.NewUniqnumber
					FROM Actv_qty, @ZQuotDept ZQuotDept
					WHERE Actv_qty.WONO = @lcEcoWono
					AND Actv_qty.DEPTKEY = ZQuotDept.OldUniqNumber
				
				UPDATE ACTV_QTY SET ActvKey = Quotdpdt.Uniqnbra
					FROM ACTV_QTY, QuotDpdt
					WHERE QUOTDPDT.UNIQ_KEY = @lcNewUniq_key
					AND ACTV_QTY.Deptkey = QUOTDPDT.UNIQNUMBER
					AND ACTV_QTY.NUMBERA = QUOTDPDT.NUMBERA

				-- Update Invtser
				UPDATE INVTSER SET Id_Value = ZQuotDept.NewUniqnumber, UNIQ_KEY =  @lcNewUniq_key
					FROM INVTSER, @ZQuotDept ZQuotDept
					WHERE INVTSER.ID_VALUE = ZQuotDept.OldUniqnumber
					AND INVTSER.WONO = @lcEcoWono
					AND INVTSER.ID_KEY = 'DEPTKEY'

				UPDATE INVTSER SET ACTVKEY = ZNew.Uniqnbra
					FROM INVTSER, QuotDpdt ZOld, QUOTDPDT ZNew
					WHERE ZNew.UNIQ_KEY = @lcNewUniq_key
					AND ZOld.UNIQ_KEY = @lcOldUniq_key
					AND ZOld.UNIQNBRA = INVTSER.ACTVKEY
					AND ZOld.Numbera = ZNew.Numbera
					AND INVTSER.ID_VALUE = ZNew.UNIQNUMBER
					AND ACTVKEY <> ''
					AND INVTSER.WONO = @lcEcoWono
					AND INVTSER.ID_KEY = 'DEPTKEY'
					
				-- Update Deptkey and Uniqnbra of Jshpchkl
				UPDATE Jshpchkl SET Deptkey = ZQuotDept.NewUniqnumber
					FROM Jshpchkl, @ZQuotDept ZQuotDept
					WHERE Jshpchkl.Deptkey = ZQuotDept.OldUniqnumber
					AND Jshpchkl.WONO = @lcEcoWono
					AND JSHPCHKL.DEPTKEY <> ''

				UPDATE Jshpchkl SET Uniqnbra = ZNew.Uniqnbra
					FROM Jshpchkl, QuotDpdt ZOld, QUOTDPDT ZNew
					WHERE ZNew.UNIQ_KEY = @lcNewUniq_key
					AND ZOld.UNIQ_KEY = @lcOldUniq_key
					AND ZOld.UNIQNBRA = Jshpchkl.Uniqnbra
					AND ZOld.Numbera = ZNew.Numbera
					AND Jshpchkl.Deptkey = ZNew.UNIQNUMBER
					AND Jshpchkl.Uniqnbra <> ''
					AND Jshpchkl.WONO = @lcEcoWono
					AND JSHPCHKL.DEPTKEY <> ''
				END
			ELSE
				-- If the WO has completion, need to update kit, overissu.....
				BEGIN
				-- OLD: Update Woentry for old rev, don't need to update uniq_key, sono, uniqueln, serialyes, only need to update bldqty and balance
				UPDATE WOENTRY
					SET BLDQTY = @lnEcoComplete, BALANCE = 0, OPENCLOS = 'Closed'
					WHERE WONO = @lcEcoWono
				
				-- OLD: Update Dept_qty all curr_qty to 0 (except FGI, SCRP), will move all balance to new wo
				UPDATE DEPT_QTY
					SET CURR_QTY = 0
					WHERE WONO = @lcEcoWono 
					AND DEPT_ID <> 'FGI '
					AND DEPT_ID <> 'SCRP'

				-- {04/25/16 VL added code to de-allocate parts (if any) for this work order
				-- OLD: un-allocate for this wo
				INSERT INTO Invt_res (W_key, Uniq_key, Datetime, QtyAlloc, Wono, Invtres_no, Sono, Uniqueln, LotCode, Expdate, Reference, Ponum, SaveInit, Refinvtres, FK_PRJUNIQUE, Kaseqnum)
				(SELECT W_key, Uniq_key, GETDATE() AS Datetime, -QTYALLOC AS QtyAlloc, Wono, dbo.fn_GenerateUniqueNumber() AS Invtres_no, Sono, Uniqueln, LotCode, Expdate, Reference, Ponum, @lcUserId AS SaveInit, Invtres_no AS Refinvtres, FK_PRJUNIQUE, Kaseqnum
					FROM Invt_res
					WHERE Wono = @lcEcoWono
					AND Invtres_no NOT IN (SELECT REFINVTRES FROM Invt_res WHERE Wono = @lcEcoWono)
					AND QTYALLOC > 0)
				-- 04/25/16 VL End}
								
				-- NEW: Create new Woentry record for new rev with the old rev balance
				-- 08/19/13 VL added to replace @lcEcoNewWono with number system if number set to auto
				IF @llXxWonoSys = 1
					BEGIN
					EXEC GetNextWoNumber @lcEcoNewWono OUTPUT
					-- 08/21/13 VL added also need to update EcWo.NewWono
					UPDATE ECWO SET NewWono = @lcEcoNewWono WHERE UNIQECWONO = @lcEcoUniqEcWono
				END
				-- 09/19/17 YS added Jobtype to woentry to separate Job type from the Status (openclos)
				INSERT INTO WOENTRY (WONO, UNIQ_KEY, Jobtype,OPENCLOS, ORDERDATE, DUE_DATE, BLDQTY, COMPLETE, 
					BALANCE, KITSTATUS, START_DATE, CUSTNO, KIT, RELEDATE, SERIALYES, KITLSTCHDT, KITLSTCHINIT, KITSTARTINIT, LFCSTITEM, LIS_RWK)
					-- 09/19/17 YS added Jobtype to woentry to separate Job type from the Status (openclos)
					SELECT @lcEcoNewWono AS Wono, @lcNewUniq_key, 'Standard' AS Jobtype,'Open' as OpenClos, 
					ORDERDATE, DUE_DATE, @lnNewBldQty AS BLDQTY, 0 AS COMPLETE, @lnNewBldQty AS BALANCE, 'KIT PROCSS' AS KITSTATUS, GETDATE() AS START_DATE, CUSTNO, KIT, GETDATE() AS RELEDATE, @llSerialYes AS SERIALYES, GETDATE() AS KITLSTCHDT, @lcUserId AS KITLSTCHINIT, @lcUserId AS KITSTARTINIT, LFCSTITEM, LIS_RWK
						FROM WOENTRY 
						WHERE WONO = @lcEcoWono

				-- New Update WO checklist
				EXEC sp_UpdOneWOChkLst @lcEcoNewWono, 'KIT IN PROCESS', @lcUserId

				-- 06/03/14 VL found there is no code to update invtser for new revision, need to move those SN that's are not in FGI/SCRP to new Wono
				SELECT @lcNEWStagDeptkey = Deptkey FROM DEPT_QTY WHERE WONO = @lcEcoNewWono AND DEPT_ID = 'STAG'
				UPDATE INVTSER SET UNIQ_KEY = @lcNewUniq_key, ID_VALUE = @lcNEWStagDeptkey, SAVEDTTM = GETDATE(), SaveInit = @lcUserId, WONO = @lcEcoNewWono
					WHERE WONO = @lcEcoWono 
					AND ID_KEY = 'DEPTKEY'
				-- 06/03/14 VL End}
				
				-- Create Kamain for new WO
				-- 02/17/15 VL added 10th parameter to filter out inactive parts
				INSERT KAMAIN (WONO, DEPT_ID, UNIQ_KEY, ACT_QTY, INITIALS, ENTRYDATE, KASEQNUM, BOMPARENT, SHORTQTY, QTY) 
					SELECT @lcEcoNewWono, Dept_id, Uniq_key, 0 AS Act_qty, @lcUserId, GETDATE(), dbo.fn_GenerateUniqueNumber(), @lcNewUniq_key, ReqQty AS ShortQty, Qty
						FROM [dbo].[fn_PhantomSubSelect] (@lcNewUniq_key, @lnNewBldQty, 'T', GETDATE(), 'F', 'T', 'F', @lKitIgnoreScrap,0, 0);

				-- Create Kadetail for new Wo
				INSERT INTO KaDetail (KaSeqNum,ShReason,ShortQty,ShQualify,ShortBal,AuditDate,AuditBy, UniqueRec, Wono) 
					SELECT Kaseqnum, 'KIT MODULE', ShortQty, 'ADD', ShortQty, GETDATE(), @lcUserId, dbo.fn_GenerateUniqueNumber(), @lcEcoNewWono
						FROM KAMAIN 
						WHERE WONO = @lcEcoNewWono 


				-- Update Kit
				-------------------------------------------------------------------------
				-- Now will check old wono and close kit, return qty back to inventory
				-- Create a temp table to store what's necessary for old rev with only completed build qty
				SET @lnTableVarCnt = 0
				DELETE FROM @ZOldWoKitReq WHERE 1=1
				--INSERT @ZOldWoKitReq SELECT * FROM [dbo].[fn_PhantomSubSelect] (@lcOldUniq_key, @lnEcoComplete, 'T', @ldOldDue_date, 'F', 'T', 'F', @lKitIgnoreScrap,0);
				-- 02/17/15 VL added 10th parameter to filter out inactive parts
				INSERT @ZOldWoKitReq (Item_no, Part_no, Revision, Descript, Qty, Bomparent, Uniq_key, Dept_id, U_of_meas, Used_inkit, UniqBomNo, StdCost, ReqQty)
					SELECT Item_no, Part_no, Revision, Descript, Qty, Bomparent, Uniq_key, Dept_id, U_of_meas, Used_inkit, UniqBomNo, StdCost, ReqQty
					 FROM [dbo].[fn_PhantomSubSelect] (@lcOldUniq_key, @lnEcoComplete, 'T', @ldOldDue_date, 'F', 'T', 'F', @lKitIgnoreScrap,0,0);

				-- to make nrecno re-order from 1
				UPDATE @ZOldWoKitReq SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
				
				-- Get Kit records that have issued more than needed, will have to return back to inventor and issue to new kit
				SET @lnTableVarCnt = 0
				DELETE FROM @ZKamainAdj WHERE 1=1				
				INSERT @ZKamainAdj (Uniq_key, Dept_id, Act_Qty, ReqQty, Kaseqnum, Part_no, Revision) 
				SELECT Kamain.UNIQ_KEY, Kamain.Dept_id, Kamain.ACT_QTY, ZOldWoKitReq.ReqQty, Kamain.Kaseqnum, ZOldWoKitReq.Part_no, ZOldWoKitReq.Revision
					FROM KAMAIN, @ZOldWoKitReq ZOldWoKitReq
					WHERE Kamain.UNIQ_KEY = ZOldWoKitReq.Uniq_key
					AND Kamain.DEPT_ID = ZOldWoKitReq.Dept_id
					AND Kamain.WONO = @lcEcoWono 
					AND KAMAIN.ACT_QTY > ZOldWoKitReq.ReqQty
				-- to make nrecno re-order from 1
				UPDATE @ZKamainAdj SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1

				-- now the @lnTableVarCnt should be the record count
				SET @lnTotalNoKamain = @lnTableVarCnt
				SET @lnCountKamain=0
				WHILE @lnTotalNoKamain > @lnCountKamain
				-- Start to check through Kamain which have pick_qty>ReqQty
				BEGIN	
					SET @lnCountKamain = @lnCountKamain + 1;
					SELECT @lcAdjUniq_key = Uniq_key, @lcAdjDept_id = Dept_id, @lnAdjAct_Qty = Act_qty, @lnAdjReqQty = ReqQty, 
						@lcAdjKaseqnum = Kaseqnum, @lcAdjPart_no = Part_no, @lcAdjRevision = Revision, @lnDelta = Act_Qty - ReqQty
						FROM @ZKamainAdj
						WHERE nRecno = @lnCountKamain
					
					-- Clear out the @ZKitReturnQty that stores what needs to be issued for new wo kit item
					DELETE FROM @ZKitReturnQty WHERE 1=1		
					DELETE FROM @ZKitReturnQty1 WHERE 1=1		
					WHILE @lnDelta > 0
					BEGIN
						
						-- Get StdCost for the component
						SELECT @lnCompStdCost = StdCost, 
								@lcCompU_of_meas = U_of_meas 
							FROM Inventor WHERE Uniq_key = @lcAdjUniq_key

						-- Now get all Kalocate records to decrease @lnDelta qty
						-- 1.Will get kalocate with overissqty first
						--------------------------------------------
						SET @lnTableVarCnt = 0
						DELETE FROM @ZKalocate WHERE 1=1	
						--10/10/14 YS removed invtmfhd table and replaced with 2 new tables				
						--10/31/14 YS removed fk_ipkeyunique from kalocate
						--INSERT @ZKalocate (UniqKalocate, Kaseqnum, W_key, Pick_qty, LotCode, Expdate, Reference, OverissQty, OverW_key, Ponum, 
						--		Uniqmfgrhd,  Wono, OrderPref)
						--	SELECT UniqKalocate, Kaseqnum, W_key, Pick_qty, LotCode, Expdate, Reference, OverissQty, OverW_key, Ponum, 
						--			KALOCATE.Uniqmfgrhd,  Wono, OrderPref
						--			FROM KALOCATE, InvtMfhd
						--		WHERE Kalocate.UniqMfgrhd = Invtmfhd.UniqMfgrhd
						--		AND	KASEQNUM = @lcAdjKaseqnum
						--		AND OVERISSQTY > 0
						--		ORDER BY OVERISSQTY DESC, ORDERPREF DESC
						-- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int
						INSERT @ZKalocate (UniqKalocate, Kaseqnum, W_key, Pick_qty, LotCode, Expdate, Reference, OverissQty, OverW_key, Ponum, 
								Uniqmfgrhd, Wono, OrderPref)
							SELECT UniqKalocate, Kaseqnum, W_key, Pick_qty, LotCode, Expdate, Reference, OverissQty, OverW_key, Ponum, 
									KALOCATE.Uniqmfgrhd, Wono, l.OrderPref
									FROM KALOCATE, InvtMPNLink L,MfgrMaster M
								WHERE Kalocate.UniqMfgrhd = L.UniqMfgrhd
								and l.mfgrMasterId=m.MfgrMasterId
								AND	KASEQNUM = @lcAdjKaseqnum
								AND OVERISSQTY > 0
								ORDER BY OVERISSQTY DESC, ORDERPREF DESC
						-- to make nrecno re-order from 1
						UPDATE @ZKalocate SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
						
						-- now the @lnTableVarCnt should be the record count
						SET @lnTotalNoKalocate = @lnTableVarCnt
						SET @lnCountKalocate = 0
						WHILE (@lnTotalNoKalocate > @lnCountKalocate) AND @lnDelta > 0
						BEGIN	
							SET @lnCountKalocate = @lnCountKalocate + 1;
							SELECT @lnUpdPick_qty = Pick_qty, @lnUpdOverissQty = OverissQty, @lcUpdW_key = W_key, @lcUpdOverW_key = OverW_key,
									@lcUpdUniqMfgrhd = UniqMfgrhd, @lcUpdUniqKalocate = UniqKalocate
								FROM @ZKalocate
								WHERE nRecno = @lnCountKalocate
							
							SET @lnAdjQty = CASE WHEN @lnUpdOverissQty >= @lnDelta
													THEN @lnDelta
													ELSE @lnUpdOverissQty END
		
							-- Will update Invttrns that create records from WO-WIP to original w_key
							-- Didn't consider lot code and serial number, so didn't update those fields
							
							-- 07/13/14 VL added to get same uniqmfgrhd but not in-store w_key, so won't transfer back to instore if it is
							BEGIN
								EXEC dbo.sp_GetNotInstoreLocation4Mfgrhd @lcUpdUniqMfgrhd, @lcUseW_key OUTPUT
							END
							-- 07/13/14 VL change from @lcUpdW_key to @lcUseW_key
							INSERT INTO InvtTrns (Uniq_key,Date,QTYXFER,FromWkey,ToWkey,REASON,StdCost,Invtxfer_n, SaveInit, 
								UniqMfgrHd, cModId, Wono, Kaseqnum)
								VALUES (@lcAdjUniq_key,GETDATE(), @lnAdjQty, @lcUpdOverW_key, @lcUseW_key,'KIT Over Issue',@lnCompStdCost, 
								dbo.fn_GenerateUniqueNumber(), @lcUserId, @lcUpdUniqMfgrhd, 'O', @lcEcoWono, @lcAdjKaseqnum)

							-- Update Kalocate
							UPDATE KALOCATE 
								SET PICK_QTY = @lnUpdPick_qty - @lnAdjQty,
									OVERISSQTY = @lnUpdOverissQty - @lnAdjQty,
									OverW_key = CASE WHEN @lnUpdOverissQty - @lnAdjQty = 0 THEN '' ELSE OverW_key END
								WHERE UNIQKALOCATE = @lcUpdUniqKalocate
							
							-- 08/20/13 VL comment out updating KAMAIN code because it will be updated in Invttrns insert trigger
							---- Update Kamain
							--UPDATE KAMAIN
							--	SET ACT_QTY = ACT_QTY - @lnAdjQty,
							--		SHORTQTY = 0 
							--		WHERE KASEQNUM = @lcAdjKaseqnum
									
							-- Save the w_key and qty that will use later to issue to new wono
							-- 02/28/17 VL change from @lcUpdW_key to @lcUseW_key
							INSERT @ZKitReturnQty1 (W_key, ReturnQty, Uniqmfgrhd, Type) VALUES (@lcUseW_key, @lnAdjQty, @lcUpdUniqMfgrhd, 'O')
							
							SET @lnDelta = CASE WHEN @lnDelta - @lnAdjQty>=0 THEN @lnDelta - @lnAdjQty ELSE 0 END
						END
						---------------------------------------
						--End of checking Kalocate for OverIssQty 


						-- 2.Now, if @lnDelta still > 0, need to decrease pick_qty
						--------------------------------------------
						SET @lnTableVarCnt = 0
						DELETE FROM @ZKalocate WHERE 1=1				
						-- Remove the OverIssQty>0 criteria because if the code run to here, means the @lnDelta still not zero, and those OverIssQty> 0 records 
						-- should have no overissqty anymore, so all records for this kaseqnum shoule be selected
						--10/10/14 YS removed invtmfhd table and replaced with 2 new tables	
						--INSERT @ZKalocate (UniqKalocate, Kaseqnum, W_key, Pick_qty, LotCode, Expdate, Reference, OverissQty, OverW_key, Ponum, 
						--		Uniqmfgrhd,  Wono, OrderPref)
						--	SELECT UniqKalocate, Kaseqnum, W_key, Pick_qty, LotCode, Expdate, Reference, OverissQty, OverW_key, Ponum, 
						--			KALOCATE.Uniqmfgrhd,  Wono, OrderPref
						--			FROM KALOCATE, InvtMfhd						
						--			WHERE Kalocate.UNIQMFGRHD = Invtmfhd.UNIQMFGRHD
						--			AND	KASEQNUM = @lcAdjKaseqnum
						--			AND PICK_QTY > 0
						--			ORDER BY OrderPref DESC
						-- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int
						INSERT @ZKalocate (UniqKalocate, Kaseqnum, W_key, Pick_qty, LotCode, Expdate, Reference, OverissQty, OverW_key, Ponum, 
								Uniqmfgrhd, Wono, OrderPref)
							SELECT UniqKalocate, Kaseqnum, W_key, Pick_qty, LotCode, Expdate, Reference, OverissQty, OverW_key, Ponum, 
									KALOCATE.Uniqmfgrhd, Wono, l.OrderPref
									FROM KALOCATE, InvtMPNLink L,MfgrMaster M						
									WHERE Kalocate.UNIQMFGRHD = l.UNIQMFGRHD
									and l.mfgrMasterId=M.MfgrMasterId
									AND	KASEQNUM = @lcAdjKaseqnum
									AND PICK_QTY > 0
									ORDER BY OrderPref DESC

						-- to make nrecno re-order from 1
						UPDATE @ZKalocate SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
						
						-- now the @lnTableVarCnt should be the record count
						SET @lnTotalNoKalocate = @lnTableVarCnt
						SET @lnCountKalocate = 0
						WHILE (@lnTotalNoKalocate > @lnCountKalocate) AND @lnDelta > 0
						BEGIN	
							SET @lnCountKalocate = @lnCountKalocate + 1;
							SELECT @lnUpdPick_qty = Pick_qty, @lnUpdOverissQty = OverissQty, @lcUpdW_key = W_key, @lcUpdOverW_key = OverW_key,
									@lcUpdUniqMfgrhd = UniqMfgrhd, @lcUpdUniqKalocate = UniqKalocate
								FROM @ZKalocate
								WHERE nRecno = @lnCountKalocate
							
							SET @lnAdjQty = CASE WHEN @lnUpdPick_qty >= @lnDelta
													THEN @lnDelta
													ELSE @lnUpdPick_qty END
							
							-- Regular issue will just create invt_isu records
							-- 07/13/14 VL added to get same uniqmfgrhd but not in-store w_key, so won't transfer back to instore if it is
							BEGIN
								EXEC dbo.sp_GetNotInstoreLocation4Mfgrhd @lcUpdUniqMfgrhd, @lcUseW_key OUTPUT
							END
							-- 07/13/14 VL change from @lcUpdW_key to @lcUseW_key
							-- 02/19/14 VL added Gl_nbr value
							INSERT INTO Invt_isu (W_key, Uniq_key, IssuedTo, QtyIsu, Date, U_of_meas, Invtisu_no, Wono, StdCost, Saveinit, UniqMfgrHD, Gl_nbr, cModid)
								VALUES (@lcUseW_key, @lcAdjUniq_key,'(WO:'+@lcEcoWono,-@lnAdjQty, GETDATE(), @lcCompU_of_meas, 
									dbo.fn_GenerateUniqueNumber(), @lcEcoWono, @lnCompStdCost, @lcUserId, @lcUpdUniqMfgrhd, dbo.fn_GetWIPGl(), 'O')

							-- Update Kalocate
							UPDATE KALOCATE 
								SET PICK_QTY = @lnUpdPick_qty - @lnAdjQty
								WHERE UNIQKALOCATE = @lcUpdUniqKalocate

							-- Update Kamain
							UPDATE KAMAIN
								SET ACT_QTY = CASE WHEN ACT_QTY - @lnAdjQty >= 0 THEN ACT_QTY - @lnAdjQty ELSE 0 END,
									SHORTQTY = 0 
									WHERE KASEQNUM = @lcAdjKaseqnum
									
							-- Save the w_key and qty that will use later to issue to new wono
							-- 07/15/14 VL changed from @lcUpdW_key to @lcUseW_key for later use
							INSERT @ZKitReturnQty1 (W_key, ReturnQty, Uniqmfgrhd, Type) VALUES (@lcUseW_key, @lnAdjQty, @lcUpdUniqMfgrhd, 'I')

							SET @lnDelta = CASE WHEN @lnDelta - @lnAdjQty>=0 THEN @lnDelta - @lnAdjQty ELSE 0 END
						END
						---------------------------------------
						--End of checking Kalocate for OverIssQty 					
						-- 02/14/17 VL set @lnDelta = 0 after adjust over-issued qty and pick_qty	
						SELECT @lnDelta = 0			
					END -- Enf of WHILE @lnDelta > 0
					-- 02/14/17 VL comment out the IF @lnDelta > 0 part because already set @lnDelta = 0
					-- Now if @lnDelta still not equal to 0, will return error and not continue
					--IF @lnDelta > 0
					--	BEGIN
					--	SELECT @lcMsg = 'The issued qty of part number: '+LTRIM(RTRIM(@lcAdjPart_no))+ CASE WHEN @lcAdjRevision='' THEN '' ELSE ' REV: '+
					--		LTRIM(RTRIM(@lcAdjRevision)) END + ' from work order: '+@lcEcoWono+' is not enough to return back to inventory and issue to new 
					--		work order: '+@lcEcoNewWono + '.  The transaction will be cancelled.'
					--	ROLLBACK TRANSACTION
					--	RETURN
					--END	

					
					-- Now should be ok to check the item exist in new kit item, and decide what's the reqqty to decide what insert to invt_isu and invttrns
					-- Need to check if the item is in new rev	
					SELECT @lcNewKaseqnum = Kaseqnum, @lnNewReqQty = ShortQty, @lnDelta2 = ShortQty
						FROM Kamain 
						WHERE WONO = @lcEcoNewWono 
						AND Uniq_key = @lcAdjUniq_key 
						AND Dept_id = @lcAdjDept_id
						
					IF @@ROWCOUNT > 0 -- Find associate New Kamain record, will create Kalocate and invt_isu record
					BEGIN
								
						-- to make nrecno re-order from 1
						SET @lnTableVarCnt = 0
						INSERT @ZKitReturnQty SELECT * FROM @ZKitReturnQty1 ORDER BY Type	-- Do type I first, type O
						UPDATE @ZKitReturnQty SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
						
						-- now the @lnTableVarCnt should be the record count
						SET @lnTotalNoReturnQty = @lnTableVarCnt
						SET @lnCountReturnQty = 0
						WHILE (@lnTotalNoReturnQty > @lnCountReturnQty)
						BEGIN	
							SET @lnCountReturnQty = @lnCountReturnQty + 1;
							SELECT @lcNewW_key = W_key, @lnNewReturnQty = ReturnQty, @lcNewUniqmfgrhd = Uniqmfgrhd, @lnLeftQty = ReturnQty
								FROM @ZKitReturnQty
								WHERE nRecno = @lnCountReturnQty
							
							-- IF @lnDelta2>0, will insert into invt_isu for regular issue
							IF @lnDelta2 > 0
								BEGIN
								SET @lnAdjQty2 = CASE WHEN @lnNewReturnQty >= @lnDelta2
													THEN @lnDelta2
													ELSE @lnNewReturnQty END
													
								-- Regular issue will just create invt_isu records
								-- 02/19/14 VL added Gl_nbr value
								INSERT INTO Invt_isu (W_key, Uniq_key, IssuedTo, QtyIsu, Date, U_of_meas, Invtisu_no, Wono, StdCost, Saveinit, UniqMfgrHD, Gl_nbr, cModid)
									VALUES (@lcNewW_key,@lcAdjUniq_key,'(WO:'+@lcEcoNewWono,@lnAdjQty2, GETDATE(), @lcCompU_of_meas, 
										dbo.fn_GenerateUniqueNumber(), @lcEcoNewWono, @lnCompStdCost, @lcUserId, @lcNewUniqmfgrhd, dbo.fn_GetWIPGl(),'O')

								-- Insert/Update Kalocate
								SELECT @lcNewUniqKalocate = UniqKalocate
									FROM KALOCATE
									WHERE KASEQNUM = @lcNewKaseqnum 
									AND W_KEY = @lcNewW_key

								BEGIN
								IF @@ROWCOUNT > 0	-- Found, just update Kalocate
									BEGIN
									UPDATE KALOCATE
										SET PICK_QTY = PICK_QTY+@lnAdjQty2
										WHERE UNIQKALOCATE = @lcNewUniqKalocate
									END
								ELSE
									BEGIN
									-- Insert Kalocate
									-- Didn't update lot code fields because it's not implemented in ECO WO update
									INSERT KALOCATE (UNIQKALOCATE, KASEQNUM, W_KEY, PICK_QTY, OVERISSQTY, OVERW_KEY, UNIQMFGRHD, Wono)
										VALUES (dbo.fn_GenerateUniqueNumber(), @lcNewKaseqnum, @lcNewW_key, @lnAdjQty2, 0, '', @lcNewUniqmfgrhd, @lcEcoNewWono)
									END
								END
								-- Get New UniqKalocate for later use
								SELECT @lcNewUniqKalocate = UniqKalocate
									FROM KALOCATE 
									WHERE KASEQNUM = @lcNewKaseqnum
									AND W_KEY = @lcNewW_key

								-- Update Kamain
								UPDATE KAMAIN
									SET ACT_QTY = ACT_QTY + @lnAdjQty2,
										SHORTQTY = SHORTQTY - @lnAdjQty2
										WHERE KASEQNUM = @lcNewKaseqnum								
									
								SET @lnDelta2 = CASE WHEN @lnDelta2 - @lnAdjQty2>=0 THEN @lnDelta2 - @lnAdjQty2 ELSE 0 END
								SET @lnLeftQty = @lnNewReturnQty - @lnAdjQty2
							END
							
							IF @lnDelta2 = 0 AND @lnLeftQty > 0
								BEGIN
								
								-- Get WO-WIP w_key for overissued
								EXEC sp_GetWOWIPLocation4WonoKit @lcEcoNewWono, @lcNewW_key,@lcWOWIPW_key OUTPUT
								
								INSERT INTO InvtTrns (Uniq_key,Date,QTYXFER,FromWkey,ToWkey,REASON,StdCost,Invtxfer_n, SaveInit, 
									UniqMfgrHd, cModId, Wono, Kaseqnum)
									VALUES (@lcAdjUniq_key,GETDATE(), @lnLeftQty, @lcNewW_key, @lcWOWIPW_key,'KIT Over Issue',@lnCompStdCost, 
									dbo.fn_GenerateUniqueNumber(), @lcUserId, @lcNewUniqmfgrhd, 'O', @lcEcoNewWono, @lcNewKaseqnum)

								-- Insert/Update Kalocate
								UPDATE KALOCATE
									SET PICK_QTY = PICK_QTY+@lnLeftQty,
										OVERISSQTY = OverIssQty+@lnLeftQty,
										OVERW_KEY= @lcWOWIPW_key
									WHERE UNIQKALOCATE = @lcNewUniqKalocate

								-- Update Kamain
								UPDATE KAMAIN
									SET ACT_QTY = ACT_QTY + @lnLeftQty,
										SHORTQTY = SHORTQTY - @lnLeftQty
										WHERE KASEQNUM = @lcNewKaseqnum																
										
								SET @lnDelta2 = CASE WHEN @lnDelta2 - @lnAdjQty>=0 THEN @lnDelta2 - @lnAdjQty ELSE 0 END
							END
						END
					END --@@ROWCOUNT > 0 -- Find associate New Kamain record, will create Kalocate and invt_isu record

				END -- End of @lnTotalNoKamain > @lnCountKamain
													
				END
			END -- End of @lnEcoComplete = 0 
		END -- End of (@@ROWCOUNT<>0) for @ZEcwo
	END -- End of WHILE @lnTotalNo>@lnCount
END -- End of (@lnTotalNo>0)

END TRY

BEGIN CATCH
	RAISERROR('Error occurred in updating ECO WO records. This operation will be cancelled.',11,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END	