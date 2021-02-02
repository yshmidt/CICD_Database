-- =============================================
-- Author:		Vicky Lu
-- Create date: 2012/05/09
-- Description:	Update Inventory from Phyinvt
-- Modified: 07/29/14 YS - list all the columns when inserting into a table, otherwise when columns are moved or added or removed, the code will break.
-- 10/10/14 YS removed invtmfhd table and repalced with 2 new tables
-- 03/09/15 VL try to use CTE cursor to speed up the subselect from invtlot
--- 02/03/17 YS this SP is not goingto work with the new structure. Comment it out for now
-- 05/31/17 VL will need to re-check and add functional currency code:StdCostPR when we work on this SP
-- =============================================
CREATE PROCEDURE [dbo].[sp_PhyinvtUpdInventory] @lcUniqPiHead char(10) = ' ', @lcUserID AS char(8)
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

-- 05/23/12 VL changed to update all invtmfgr that's picked in phyinvt for @lcUniqPiHead
-- 12/16/13 VL Found previous fix didn't work right, it tried to update invtmfgr for all phyinvt records, should only update for @lcUniqPiHead

--DECLARE @tUpdInvtLot TABLE (W_key char(10), LotCode char(15), Expdate smalldatetime, Reference char(12), Ponum char(15), Uniq_lot char(10), UniqPhyNo char(10))

--DECLARE @tPhyInvtRecord4Upd TABLE (nrecno int identity, W_key char(10), Uniq_Key char(10), StdCost numeric(13,5), LotCode char(15), 
--								ExpDate smalldatetime, Reference char(12), Ponum char(15), Wh_Gl_Nbr char(13), SerialYes bit, 
--								Qty_oh numeric(12,2), PhyCount numeric(12,2), UniqMfgrhd char(10), UniqPhyno char(10), U_of_meas char(4), 
--								Part_Sourc char(10), PhyDate smalldatetime, Uniq_lot char(10))

--DECLARE @t4Invt_rec TABLE (W_key char(10), Uniq_key char(10), Date smalldatetime, QtyRec numeric(12,2), StdCost numeric(13,5), LotCode char(15), 
--					Expdate smalldatetime, Reference char(12), SaveInit char(8), Gl_nbr char(13), Gl_nbr_Inv char(13), CommRec char(50), 
--					Serialno char(30), SerialUniq char(10), UniqMfgrhd char(10), InvtRec_no char(10), U_of_meas char(4), Is_rel_gl bit,
--					Uniq_lot char(10))
						
--DECLARE @t4Invt_isu TABLE (W_key char(10), Uniq_key char(10), IssuedTo char(20), QtyIsu numeric(12,2), Date smalldatetime, 
--					Gl_nbr char(13), Gl_nbr_Inv char(13), StdCost numeric(13,5), LotCode char(15), ExpDate smalldatetime, Reference char(12), 
--					SaveInit char(8), Ponum char(15), Serialno char(30), SerialUniq char(10), Uniqmfgrhd char(10), U_of_meas char(4), 
--					Invtisu_no char(10), cModid char(1), Is_rel_gl bit)
					
--DECLARE @IAdj_Gl_no char(13), @llGL_Installed bit, @lnTotalCc int, @lnCount int, @PhyW_key char(10), @PhyUniq_key char(10), @PhyStdcost numeric(13,5), 
--		@PhyLotCode char(15), @PhyExpdate smalldatetime, @PhyReference char(12), @PhyPonum char(15), @PhyWh_gl_nbr char(13), @PhySerialYes bit, 
--		@PhyQTY_OH numeric(12,2), @PhyPhyCount numeric(12,2), @PhyUniqMfgrhd char(10), @PhyUniqPhyNo char(10), @PhyU_of_meas char(4), 
--		@PhyPart_Sourc char(10), @PhyPhyDate smalldatetime, @llRunCase bit, @PhyInvtType numeric(1,0), @PhyUniq_lot char(10)

--SELECT @llGL_Installed = Installed FROM Items WHERE ScreenName = 'GLREL   '
--SELECT @PhyInvtType = InvtType FROM PHYINVTH WHERE UNIQPIHEAD = @lcUniqPiHead

--BEGIN
--IF @llGL_Installed = 1
--	SELECT @IAdj_Gl_no = IADJ_GL_NO FROM INVSETUP 
--ELSE 
--	SELECT @IAdj_Gl_no = SPACE(13)
--END

--BEGIN TRANSACTION
--BEGIN TRY;

---- Prepare a table that Phinvt lot records can not find in invtlot, will be inserted into invtlot and update phyinvt(didn't have lot info because qty = 0)
---- 05/21/12 VL added ISNULL() to criteria for null value
---- 03/09/15 VL try to use CTE cursor to speed up the subselect from invtlot
----INSERT @tUpdInvtLot (W_KEY, LOTCODE, EXPDATE, REFERENCE, PONUM, UNIQ_LOT, UniqPhyNo)
----SELECT W_Key, CASE WHEN Lotcode = '' THEN 'Sys Generated' ELSE Lotcode END AS LotCode,
---- CASE WHEN ExpDate IS NULL THEN GETDATE() ELSE Expdate END AS Expdate,
---- CASE WHEN Reference = '' THEN 'LOT'+RIGHT(dbo.fn_GenerateUniqueNumber(),9) ELSE Reference END AS Reference,
---- PoNum, CASE WHEN Uniq_lot = '' THEN dbo.fn_GenerateUniqueNumber() ELSE Uniq_lot END AS Uniq_lot, UniqPhyNo
---- FROM PHYINVT, INVENTOR, PartType
---- WHERE PHYINVT.UNIQ_KEY = Inventor.UNIQ_KEY
---- AND Inventor.PART_CLASS = PartType.PART_CLASS
---- AND Inventor.PART_TYPE = PartType.PART_TYPE
---- AND PartType.LOTDETAIL = 1
---- AND InvRecncl = 1
---- AND UniqPiHead = @lcUniqPiHead
---- AND LOTCODE + CONVERT(char,ISNULL(Expdate,SPACE(20)),20)+REFERENCE+PONUM NOT IN
---- (SELECT LOTCODE + CONVERT(char,ISNULL(Expdate,SPACE(20)),20)+REFERENCE+PONUM
---- FROM INVTLOT)
--;WITH Zlot1 AS (SELECT LOTCODE, Expdate, REFERENCE, PONUM
--FROM INVTLOT
--WHERE W_KEY IN
--(SELECT W_key FROM Phyinvt
--WHERE InvRecncl = 1
--AND UniqPiHead = @lcUniqPiHead)
--)
--INSERT @tUpdInvtLot (W_KEY, LOTCODE, EXPDATE, REFERENCE, PONUM, UNIQ_LOT, UniqPhyNo)
--SELECT W_Key, CASE WHEN Lotcode = '' THEN 'Sys Generated' ELSE Lotcode END AS LotCode,
--CASE WHEN ExpDate IS NULL THEN GETDATE() ELSE Expdate END AS Expdate,
--CASE WHEN Reference = '' THEN 'LOT'+RIGHT(dbo.fn_GenerateUniqueNumber(),9) ELSE Reference END AS Reference,
--PoNum, CASE WHEN Uniq_lot = '' THEN dbo.fn_GenerateUniqueNumber() ELSE Uniq_lot END AS Uniq_lot, UniqPhyNo
--FROM PHYINVT, INVENTOR, PartType
--WHERE PHYINVT.UNIQ_KEY = Inventor.UNIQ_KEY
--AND Inventor.PART_CLASS = PartType.PART_CLASS
--AND Inventor.PART_TYPE = PartType.PART_TYPE
--AND PartType.LOTDETAIL = 1
--AND InvRecncl = 1
--AND UniqPiHead = @lcUniqPiHead
--AND LOTCODE + CONVERT(char,ISNULL(Expdate,SPACE(20)),20)+REFERENCE+PONUM NOT IN
--(SELECT LOTCODE + CONVERT(char,ISNULL(Expdate,SPACE(20)),20)+REFERENCE+PONUM
--FROM Zlot1)
---- Now will insert record in Invtlot if those Phyinvt lot code info can not be found in Invtlot
----INSERT INVTLOT (W_KEY, LOTCODE, EXPDATE, REFERENCE, PONUM, UNIQ_LOT)
----	SELECT W_KEY, LOTCODE, EXPDATE, REFERENCE, PONUM, UNIQ_LOT 
----	FROM @tUpdInvtLot
----04/03/2012 YS every time we insert a record we should check for the errors
--IF @@ERROR<>0
--BEGIN
---- raise an error
--	RAISERROR ('Insert into InvtLot table has failed. 
--			Cannot proceed with Physical Inventory Posting'
--            ,16 -- Severity.
--            ,1 )-- State 
             
--	ROLLBACK
--	RETURN 
--END	

---- now, update Phinvt lotcode fields because before if the qty = 0, there might not have lot code info
--UPDATE PHYINVT
--	SET LOTCODE = tUpdInvtLot.LotCode,
--		Expdate = tUpdInvtLot.Expdate,
--		REFERENCE = tUpdInvtLot.Reference,
--		PONUM = tUpdInvtLot.Ponum
--	FROM PHYINVT, @tUpdInvtLot tUpdInvtLot
--	WHERE PhyInvt.UNIQPHYNO = tUpdInvtLot.UniqPhyNo

--IF @@ERROR<>0
--BEGIN
---- raise an error
--	RAISERROR ('Updating physical invenotry lot code records has failed. 
--			Cannot proceed with Physical Inventory Posting'
--            ,16 -- Severity.
--            ,1 )-- State 
             
--	ROLLBACK
--	RETURN 
--END	



---- Start to insert invt_rec and invt_isu
-------------------------------------------
---- Get all Physical Inventory records that can be posted
--INSERT @tPhyInvtRecord4Upd
----10/10/14 YS no need to include invtmfhd table (confirmed qith Vicky)
--SELECT PhyInvt.W_key, PhyInvt.Uniq_key, Inventor.Stdcost, LotCode, Expdate, Reference, Ponum, Wh_gl_nbr, SerialYes, PhyInvt.QTY_OH, PhyCount, 
--	INVTMFGR.UniqMfgrhd, UniqPhyno, U_of_meas, PART_SOURC, PhyDate, Uniq_lot
--	FROM PhyInvt, WAREHOUS, Inventor, Invtmfgr
--	WHERE Inventor.Uniq_key = Phyinvt.Uniq_key
--	AND Phyinvt.W_key = Invtmfgr.W_key
--	AND Invtmfgr.Uniqwh = Warehous.Uniqwh
--	AND Phyinvt.Uniqpihead = @lcUniqPiHead
--	AND PhyInvt.QTY_OH <> Phyinvt.PHYCOUNT
--	AND Phyinvt.INVRECNCL = 1

--SET @lnTotalCc = @@ROWCOUNT;
---- First, check all soprices and insert or update plprices if necessary	
--IF (@lnTotalCc>0)
--BEGIN
--	SET @lnCount=0;
--	WHILE @lnTotalCc>@lnCount
--	BEGIN	
--		SET @lnCount=@lnCount+1;
--		SELECT @PhyW_key = W_key, @PhyUniq_key = Uniq_key, @PhyStdcost = StdCost, @PhyLotCode = LotCode, @PhyExpdate = Expdate, 
--				@PhyReference = Reference, @PhyPonum = Ponum, @PhyWh_gl_nbr = Wh_gl_nbr, @PhySerialYes = SerialYes, @PhyQTY_OH = QTY_OH, 
--				@PhyPhyCount = PhyCount, @PhyUniqMfgrhd = UniqMfgrhd, @PhyUniqPhyNo = UniqPhyno, @PhyU_of_meas = U_of_meas, @PhyPart_Sourc = Part_Sourc, 
--				@PhyPhyDate = PhyDate, @PhyUniq_lot = Uniq_lot
--			FROM @tPhyInvtRecord4Upd
--			WHERE nrecno = @lnCount	

-- 		IF (@@ROWCOUNT<>0)
--		BEGIN
--			SET @llRunCase = 0	-- if any of three case has been went through
--			--1. check for serialized
--			-------------------------
--			IF @PhySerialYes = 1
--			BEGIN
--				-- not in invtser, but in phyinvtser, will insert
--				DELETE FROM @t4Invt_rec
--				-- 07/29/14 YS - list all the columns when inserting into a table, otherwise when columns are moved or added or removed, the code will break.						
--				INSERT @t4Invt_rec
--					(W_key, Uniq_key  , [Date], QtyRec, StdCost , LotCode , 
--					Expdate , Reference , SaveInit , Gl_nbr , Gl_nbr_Inv , CommRec , 
--					Serialno , SerialUniq , UniqMfgrhd , InvtRec_no , U_of_meas , Is_rel_gl ,
--					Uniq_lot )
--					SELECT @PhyW_key AS W_key, @PhyUniq_key AS Uniq_key, GETDATE() AS Date, 1 AS QtyRec, @PhyStdcost AS StdCost, 
--							@PhyLotCode AS LotCode, @PhyExpdate AS Expdate, @PhyReference AS Reference, @lcUserID AS SaveInit,
--							CASE WHEN @llGL_Installed = 1 AND @PhyInvtType = 1 THEN @IAdj_Gl_no ELSE SPACE(13) END AS Gl_nbr,
--							CASE WHEN @llGL_Installed = 1 AND @PhyInvtType = 1 THEN @PhyWh_gl_nbr ELSe SPACE(13) END AS Gl_nbr_Inv,
--							'Phy Invt Count Adj' AS CommRec, Serialno, dbo.fn_GenerateUniqueNumber() AS SerialUniq, @PhyUniqMfgrhd AS UniqMfgrhd, 
--							dbo.fn_GenerateUniqueNumber() AS InvtRec_no, @PhyU_of_meas AS U_of_meas, 
--							CASE WHEN @llGL_Installed = 1 AND @PhyInvtType = 1 THEN 0 ELSE 1 END AS Is_rel_gl, @PhyUniq_lot AS Uniq_lot
--						FROM PhyInvtSer
--						WHERE UniqPhyNo = @PhyUniqPhyNo
--						AND SERIALNO NOT IN
--							(SELECT SERIALNO 
--								FROM INVTSER
--								WHERE UNIQ_KEY = @PhyUniq_key
--								AND UNIQMFGRHD = @PhyUniqMfgrhd
--								AND LOTCODE = @PhyLotCode 
--								ANd ISNULL(EXPDATE,1) = ISNULL(@PhyEXPDATE,1)
--								AND Reference = @PhyReference
--								AND PONUM = @PhyPonum
--								AND ID_KEY = 'W_KEY'
--								AND ID_VALUE = @PhyW_key)
					
--				IF @@ROWCOUNT > 0
--					BEGIN
--					-- 07/29/14 YS - list all the columns when inserting into a table, otherwise when columns are moved or added or removed, the code will break.						
--					INSERT INTO Invt_Rec (W_Key, Uniq_Key, Date, QtyRec, StdCost, LotCode, ExpDate, Reference, SaveInit, Gl_nbr, 
--								Gl_nbr_Inv, CommRec, SerialNo, SerialUniq, UniqMfgrHd, InvtRec_no, U_of_meas, Is_rel_gl, Uniq_lot)
--							SELECT W_Key, Uniq_Key, Date, QtyRec, StdCost, LotCode, ExpDate, Reference, SaveInit, Gl_nbr, 
--								Gl_nbr_Inv, CommRec, SerialNo, SerialUniq, UniqMfgrHd, InvtRec_no, U_of_meas, Is_rel_gl, Uniq_lot 
--					FROM @t4Invt_rec
--				END -- IF @@ROWCOUNT > 0
				
--				-- in invtser but not in phyinvtser, will issue out
--				DELETE FROM @t4Invt_isu
				
--				-- 05/16/12 VL use same 'Y' cModid for cycle count and physical inventory
--				INSERT @t4Invt_isu								
--					SELECT @PhyW_key AS W_key, @PhyUniq_key AS Uniq_key, 'Phy Invt Count Adj' AS IssuedTo, 1 AS QtyIsu, GETDATE() AS Date, 
--					CASE WHEN @llGL_Installed = 1 AND (@PhyInvtType = 1 OR @PhyInvtType = 3) THEN @IAdj_Gl_no ELSE SPACE(13) END AS Gl_nbr,
--					CASE WHEN @llGL_Installed = 1 AND (@PhyInvtType = 1 OR @PhyInvtType = 3) THEN @PhyWh_gl_nbr ELSE SPACE(13) END AS Gl_nbr_Inv,
--					@PhyStdCost AS StdCost, @PhyLotCode AS LotCode, @PhyExpDate AS ExpDate, @PhyReference AS Reference, @lcUserID AS SaveInit, 
--					@PhyPonum AS Ponum,	Serialno, SerialUniq, @PhyUniqmfgrhd AS Uniqmfgrhd, @PhyU_of_meas AS U_of_meas, 
--					dbo.fn_GenerateUniqueNumber() AS Invtisu_no, 'Y' AS cModid, 
--					CASE WHEN @llGL_Installed = 1 AND (@PhyInvtType = 1 OR @PhyInvtType = 3) THEN 0 ELSE 1 END AS Is_rel_gl
--						FROM INVTSER
--						WHERE UNIQ_KEY = @PhyUniq_key
--						AND UNIQMFGRHD = @PhyUniqMfgrhd
--						AND LOTCODE = @PhyLotCode 
--						ANd ISNULL(EXPDATE,1) = ISNULL(@PhyEXPDATE,1)
--						AND Reference = @PhyReference
--						AND PONUM = @PhyPonum
--						AND ID_KEY = 'W_KEY'
--						AND ID_VALUE = @PhyW_key
--						AND Serialno NOT IN 
--							(SELECT Serialno
--								FROM PhyInvtSer
--								WHERE UniqPhyno = @PhyUniqPhyNo)
				
--				IF @@ROWCOUNT > 0
--					BEGIN
--					-- Isuse those SN that are for same w_key, lotcode.... are in invtser, but not in cmser, will need to issue out
--					INSERT INTO Invt_isu (W_Key, Uniq_Key, IssuedTo, QtyIsu, Date, 
--						Gl_nbr, Gl_Nbr_Inv,
--						StdCost, LotCode, ExpDate, Reference, SaveInit, PoNum,
--						SerialNo,SerialUniq,UniqMfgrHd, U_of_meas, Invtisu_no, cModid, Is_rel_gl) 
--					SELECT * FROM @t4Invt_isu
					
--				END
--				SET @llRunCase = 1			
--			END				


--			--2. PhyCount - Qty_oh > 0 -- Need to receive
--			--------------------------------------------------
--			IF @PhyPhyCount - @PhyQTY_OH > 0 AND @llRunCase = 0
--			BEGIN
--				INSERT INTO Invt_Rec (W_Key, Uniq_Key, Date, QtyRec, StdCost, LotCode, ExpDate, Reference, SaveInit, 
--						Gl_nbr, Gl_nbr_Inv, CommRec, UniqMfgrHd, InvtRec_no, U_of_meas, Is_rel_gl, Uniq_lot)
--				VALUES (@PhyW_key, @PhyUniq_key, GETDATE(), @PhyPhyCount - @PhyQTY_OH, @PhyStdcost, @PhyLotCode, @PhyExpdate, @PhyReference, @lcUserID,
--						CASE WHEN @llGL_Installed = 1 AND @PhyInvtType = 1 THEN @IAdj_Gl_no ELSE SPACE(13) END,
--						CASE WHEN @llGL_Installed = 1 AND @PhyInvtType = 1 THEN @PhyWh_gl_nbr ELSe SPACE(13) END,
--						'Phy Invt Count Adj', @PhyUniqMfgrhd, dbo.fn_GenerateUniqueNumber(), @PhyU_of_meas,
--						CASE WHEN @llGL_Installed = 1 AND @PhyInvtType = 1 THEN 0 ELSE 1 END, @PhyUniq_lot)
				
--				SET @llRunCase = 1		
--			END
			
			
--			--3. Phycount - Qty_oh < 0 -- Need to issue
--			--------------------------------------------------
--			IF @PhyPhyCount - @PhyQTY_OH < 0 AND @llRunCase = 0
--			BEGIN
--				INSERT INTO Invt_isu (W_Key, Uniq_Key, IssuedTo, QtyIsu, Date, 
--					Gl_nbr, Gl_Nbr_Inv,
--					StdCost, LotCode, ExpDate, Reference, SaveInit, PoNum,
--					UniqMfgrHd, U_of_meas, Invtisu_no, cModid, IS_REL_GL) 
--				VALUES (@PhyW_key, @PhyUniq_key, 'Phy Invt Count Adj', -(@PhyPhyCount - @PhyQTY_OH), GETDATE(), 
--					CASE WHEN @llGL_Installed = 1 AND (@PhyInvtType = 1 OR @PhyInvtType = 3) THEN @IAdj_Gl_no ELSE SPACE(13) END,
--					CASE WHEN @llGL_Installed = 1 AND (@PhyInvtType = 1 OR @PhyInvtType = 3) THEN @PhyWh_gl_nbr ELSE SPACE(13) END,
--					@PhyStdCost, @PhyLotCode, @PhyExpDate, @PhyReference, @lcUserID, @PhyPonum,
--					@PhyUniqmfgrhd, @PhyU_of_meas, dbo.fn_GenerateUniqueNumber(), 'Y',
--					CASE WHEN @llGL_Installed = 1 AND (@PhyInvtType = 1 OR @PhyInvtType = 3) THEN 0 ELSE 1 END)
											
--				SET @llRunCase = 1		
--			END				
						
--		END		
--	END			
							
--END			
	
---- After insert invt_isu and Invt_rec records for all @tCcRecord4Post

---- update Invtmfgr
---- 05/23/12 VL fixed, should update all invtmfgr records that's picked in Phyinvt for that UniqPihead, not just whatever got changed (@tUpdInvtLot)
----UPDATE INVTMFGR
----	SET Count_dt = tPhyInvtRecord4Upd.PhyDate,
----		COUNT_TYPE = 'PI',
----		COUNT_INIT = @lcUserID, 
----		COUNTFLAG = ' ' 
----	FROM INVTMFGR, @tPhyInvtRecord4Upd tPhyInvtRecord4Upd
----	WHERE Invtmfgr.W_KEY = tPhyInvtRecord4Upd.W_key
--UPDATE INVTMFGR
--	SET Count_dt = PhyInvt.PhyDate,
--		COUNT_TYPE = 'PI',
--		COUNT_INIT = @lcUserID, 
--		COUNTFLAG = ' ' 
--	FROM INVTMFGR, PhyInvt
--	WHERE Invtmfgr.W_KEY = PhyInvt.W_key
--	-- 12/16/13 VL added next line to make only for this PI only
--	AND UNIQPIHEAD = @lcUniqPiHead


---- Update PhyInvtH
--UPDATE PhyInvtH
--	SET PiStatus = 'Completed'
--	WHERE UNIQPIHEAD = @lcUniqPiHead
	

--END TRY

--BEGIN CATCH
--	RAISERROR('Error occurred in updating physical inventory records. This operation will be cancelled.',1,1)
--	IF @@TRANCOUNT > 0
--		ROLLBACK TRANSACTION;
--END CATCH

--IF @@TRANCOUNT > 0
--    COMMIT TRANSACTION;
END	

