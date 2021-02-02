-- =============================================
-- Author:		Vicky
-- Create date: <Create Date,,>
-- Description:	Used by Cycle Count module
--- Modified : 07/29/14 YS have list of the columns in the insert statement, otherwise when columns are removed or added the code will breake
-- --08/19/14 YS changed error message at the bottom of this SP
-- 05/31/17 VL added functional currency code and remove serialno and serialuniq, will need to re-check code when work on this module
	---03/02/18 YS change size of the lotcode field to 25
-- =============================================
CREATE PROCEDURE [dbo].[sp_CycleUpdateInvt] @lcUserID AS char(8)
AS
BEGIN

-- 03/17/14 VL changed severity from 1 to 11 for RAISERROR, so it won't still go throuth but actually not
SET NOCOUNT ON;
-- 05/14/12 VL moved insert not exist invtlot code from here to CycleNotPostView
BEGIN TRANSACTION
BEGIN TRY;

-- 03/03/14 VL added Is_updated field
-- 05/31/17 VL added functional currency code
	---03/02/18 YS change size of the lotcode field to 25
DECLARE @tCcRecord4Post TABLE (nrecno int identity, W_key char(10), Uniq_Key char(10), StdCost numeric(13,5), LotCode nvarchar(25), 
								ExpDate smalldatetime, Reference char(12), Ponum char(15), Wh_Gl_Nbr char(13), SerialYes bit, 
								Qty_oh numeric(12,2), Ccount numeric(12,2), UniqMfgrhd char(10), UniqCcno char(10), U_of_meas char(4), 
								Part_Sourc char(10), UniqSupno char(10), ccDate smalldatetime, Is_Updated bit, StdCostPR numeric(13,5))

-- 05/15/12 VL added Is_rel_gl bit
-- 05/31/17 VL added functional currency code and remove serialno and serialuniq
---03/02/18 YS change size of the lotcode field to 25
DECLARE @t4Invt_rec TABLE (W_key char(10), Uniq_key char(10), Date smalldatetime, QtyRec numeric(12,2), StdCost numeric(13,5), LotCode nvarchar(25), 
					Expdate smalldatetime, Reference char(12), SaveInit char(8), Gl_nbr char(13), Gl_nbr_Inv char(13), CommRec char(50), 
					UniqMfgrhd char(10), InvtRec_no char(10), U_of_meas char(4), Is_rel_gl bit, StdCostPR numeric(13,5))
						
-- 05/31/17 VL added functional currency code and remove serialno and serialuniq						
---03/02/18 YS change size of the lotcode field to 25
DECLARE @t4Invt_isu TABLE (W_key char(10), Uniq_key char(10), IssuedTo char(20), QtyIsu numeric(12,2), Date smalldatetime, 
					Gl_nbr char(13), Gl_nbr_Inv char(13), StdCost numeric(13,5), LotCode nvarchar(25), ExpDate smalldatetime, Reference char(12), 
					SaveInit char(8), Ponum char(15), Uniqmfgrhd char(10), U_of_meas char(4), 
					Invtisu_no char(10), cModid char(1), Is_rel_gl bit, StdCostPR numeric(13,5))
					
-- 05/31/17 VL added functional currency code		
---03/02/18 YS change size of the lotcode field to 25											
DECLARE @IAdj_Gl_no char(13), @llGL_Installed bit, @lnTotalCc int, @lnCount int, @ccW_key char(10), @ccUniq_key char(10), @ccStdcost numeric(13,5), 
		@ccLotCode nvarchar(25), @ccExpdate smalldatetime, @ccReference char(12), @ccPonum char(15), @ccWh_gl_nbr char(13), @ccSerialYes bit, 
		@ccQTY_OH numeric(12,2), @ccCcount numeric(12,2), @ccUniqMfgrhd char(10), @ccUniqCcno char(10), @ccU_of_meas char(4), 
		@ccPart_Sourc char(10), @ccUniqSupno char(10), @ccCcDate smalldatetime, @llRunCase bit, @ccStdCostPR numeric(13,5)

SELECT @llGL_Installed = Installed FROM Items WHERE ScreenName = 'GLREL   '

BEGIN
IF @llGL_Installed = 1
	SELECT @IAdj_Gl_no = IADJ_GL_NO FROM INVSETUP 
ELSE 
	SELECT @IAdj_Gl_no = SPACE(13)
END

-- 05/14/12 VL moved insert not exist invtlot code from here to CycleNotPostView
---- Now will insert record in Invtlot if those Ccrecord lot code info can not be found in Invtlot
--INSERT INVTLOT (W_KEY, LOTCODE, EXPDATE, REFERENCE, PONUM, UNIQ_LOT)
--SELECT W_Key, CASE WHEN Lotcode = '' THEN 'Unk' ELSE Lotcode END AS LotCode, Expdate, 
--	CASE WHEN Reference = '' THEN 'LOT'+RIGHT(dbo.fn_GenerateUniqueNumber(),9) ELSE Reference END AS Reference, 
--	PoNum, dbo.fn_GenerateUniqueNumber() AS Uniq_lot
--	FROM CCRECORD, INVENTOR, PartType
--	WHERE Ccrecord.UNIQ_KEY = Inventor.UNIQ_KEY
--	AND Inventor.PART_CLASS = PartType.PART_CLASS
--	AND Inventor.PART_TYPE  = PartType.PART_TYPE
--	AND PartType.LOTDETAIL = 1
--	AND Ccrecord.CCRECNCL = 1
--	AND Ccrecord.POSTED = 0
--	AND LOTCODE + CONVERT(char,Expdate,20)+REFERENCE+PONUM NOT IN 
--		(SELECT LOTCODE + CONVERT(char,Expdate,20)+REFERENCE+PONUM 
--			FROM INVTLOT)
----04/03/2012 YS every time we insert a record we should check for the errors
--IF @@ERROR<>0
--BEGIN
---- raise an error
--	RAISERROR ('Insert into InvtLot table has failed. 
--			Cannot proceed with Cycle Count Posting'
--            ,16 -- Severity.
--            ,1 )-- State 
             
--	ROLLBACK
--	RETURN 
--END	
-- 05/14/12 VL End}
	
-- Start to insert invt_rec and invt_isu
-----------------------------------------
-- Get all Ccrecord records that can be posted
-- 03/03/14 VL added Is_updated
-- 05/31/17 VL added functional currency code
INSERT @tCcRecord4Post
SELECT W_key, Ccrecord.Uniq_key, Ccrecord.Stdcost, LotCode, Expdate, Reference, Ponum, Wh_gl_nbr, SerialYes, QTY_OH, Ccount, UniqMfgrhd, 
	UniqCcno, U_of_meas, PART_SOURC, UniqSupno, ccDate, IS_UPDATED, Ccrecord.StdCostPR
	FROM CCRECORD, WAREHOUS, Inventor
	WHERE Ccrecord.UniqWh = Warehous.UNIQWH
	AND Ccrecord.UNIQ_KEY = Inventor.Uniq_key
	AND CCRECNCL = 1
	AND POSTED = 0
		

SET @lnTotalCc = @@ROWCOUNT;
-- First, check all soprices and insert or update plprices if necessary	
IF (@lnTotalCc>0)
BEGIN
	SET @lnCount=0;
	WHILE @lnTotalCc>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		-- 05/31/17 VL added functional currency code
		SELECT @ccW_key = W_key, @ccUniq_key = Uniq_key, @ccStdcost = StdCost, @ccLotCode = LotCode, @ccExpdate = Expdate, 
				@ccReference = Reference, @ccPonum = Ponum, @ccWh_gl_nbr = Wh_gl_nbr, @ccSerialYes = SerialYes, @ccQTY_OH = QTY_OH, 
				@ccCcount = Ccount, @ccUniqMfgrhd = UniqMfgrhd, @ccUniqCcno = UniqCcno, @ccU_of_meas = U_of_meas, @ccPart_Sourc = Part_Sourc, 
				@ccUniqSupno = UniqSupno, @ccCcDate = CcDate, @ccStdCostPR = StdCostPR
			FROM @tCcRecord4Post
			WHERE nrecno = @lnCount	
		IF (@@ROWCOUNT<>0)
		BEGIN
			SET @llRunCase = 0	-- if any of three case has been went through
			--1. check for serialized
			-------------------------
			IF @ccSerialYes = 1
			BEGIN
				-- Got some error from insert invt_rec trigger with empty value even there is no record selected from sql, changed to use temp table and insert only @@ROWCOUNT> 0
				--- Insert those SN that for same w_key, lotcode.... are in CycleSer, but not in InvtSer, will need to have invt_rec records
				--INSERT INTO Invt_Rec (W_Key, Uniq_Key, Date, QtyRec, StdCost, LotCode, ExpDate, Reference, SaveInit, Gl_nbr, 
				--		Gl_nbr_Inv, CommRec, SerialNo, SerialUniq, UniqMfgrHd, InvtRec_no, U_of_meas)
				--SELECT @ccW_key AS W_key, @ccUniq_key AS Uniq_key, GETDATE(), 1,@ccStdcost AS StdCost, @ccLotCode AS LotCode, @ccExpdate AS Expdate, 
				--		@ccReference AS Reference, @lcUserID,
				--		CASE WHEN @llGL_Installed = 1 AND @ccPart_Sourc <> 'CONSG' AND @ccUniqSupno = '' THEN @IAdj_Gl_no ELSE SPACE(13) END AS Gl_nbr,
				--		CASE WHEN @llGL_Installed = 1 AND @ccPart_Sourc <> 'CONSG' AND @ccUniqSupno = '' THEN @ccWh_gl_nbr ELSe SPACE(13) END AS Gl_nbr_Inv,
				--		'Cycle Count Adj' AS CommRec, Serialno, dbo.fn_GenerateUniqueNumber() AS SerialUniq, @ccUniqMfgrhd, 
				--		dbo.fn_GenerateUniqueNumber() AS InvtRec_no, @ccU_of_meas
				--	FROM CYCLESER
				--	WHERE UNIQCCNO = @ccUniqCcno
				--	AND SERIALNO NOT IN
				--		(SELECT SERIALNO 
				--			FROM INVTSER
				--			WHERE UNIQ_KEY = @ccUniq_key
				--			AND UNIQMFGRHD = @ccUniqMfgrhd
				--			AND LOTCODE = @ccLotCode 
				--			ANd ISNULL(EXPDATE,1) = ISNULL(@ccEXPDATE,1)
				--			AND Reference = @ccReference
				--			AND PONUM = @ccPonum
				--			AND ID_KEY = 'W_KEY'
				--			AND ID_VALUE = @ccW_key);				
				
				--04/03/2012 YS inside the do while this var table needs to be cleared or we will collect information again and again. Then when inserting into Invt_rec will have an issue with duplicate invtrec_no key
				DELETE FROM @t4Invt_rec
				--07/29/14 YS have list of the columns in the insert statement, otherwise when columns are removed or added the code will breake
				-- 05/31/17 VL added functional currency code and remove serialno and serialuniq
				INSERT @t4Invt_rec
					(W_key, Uniq_key, [Date], QtyRec, StdCost , LotCode, 
					Expdate , Reference , SaveInit , Gl_nbr , Gl_nbr_Inv , CommRec , 
					UniqMfgrhd, InvtRec_no , U_of_meas , Is_rel_gl, StdCostPR) 
					SELECT @ccW_key AS W_key, @ccUniq_key AS Uniq_key, GETDATE() AS [Date], 1 AS QtyRec, @ccStdcost AS StdCost, @ccLotCode AS LotCode, @ccExpdate AS Expdate, 
							@ccReference AS Reference, @lcUserID AS SaveInit,
							CASE WHEN @llGL_Installed = 1 AND @ccPart_Sourc <> 'CONSG' AND @ccUniqSupno = '' THEN @IAdj_Gl_no ELSE SPACE(13) END AS Gl_nbr,
							CASE WHEN @llGL_Installed = 1 AND @ccPart_Sourc <> 'CONSG' AND @ccUniqSupno = '' THEN @ccWh_gl_nbr ELSE SPACE(13) END AS Gl_nbr_Inv,
							'Cycle Count Adj' AS CommRec, @ccUniqMfgrhd AS UniqMfgrhd, 
							dbo.fn_GenerateUniqueNumber() AS InvtRec_no, @ccU_of_meas AS U_of_meas,
							CASE WHEN @llGL_Installed = 1 AND @ccPart_Sourc <> 'CONSG' AND @ccUniqSupno = '' THEN 0 ELSE 1 END AS Is_rel_gl, @ccStdCostPR AS StdCostPR 
						FROM CYCLESER
						WHERE UNIQCCNO = @ccUniqCcno
						AND SERIALNO NOT IN
							(SELECT SERIALNO 
								FROM INVTSER
								WHERE UNIQ_KEY = @ccUniq_key
								AND UNIQMFGRHD = @ccUniqMfgrhd
								AND LOTCODE = @ccLotCode 
								ANd ISNULL(EXPDATE,1) = ISNULL(@ccEXPDATE,1)
								AND Reference = @ccReference
								AND PONUM = @ccPonum
								AND ID_KEY = 'W_KEY'
								AND ID_VALUE = @ccW_key)
					
				IF @@ROWCOUNT > 0
					BEGIN
					-- 07/29/14 YS list all the fields in insert and select part of the command
						-- 05/31/17 VL added functional currency code and remove serialno and serialuniq
						INSERT INTO Invt_Rec (W_Key, Uniq_Key, Date, QtyRec, StdCost, LotCode, ExpDate, Reference, SaveInit, Gl_nbr, 
								Gl_nbr_Inv, CommRec, UniqMfgrHd, InvtRec_no, U_of_meas, Is_rel_gl, StdCostPR)
							SELECT W_Key, Uniq_Key, Date, QtyRec, StdCost, LotCode, ExpDate, Reference, SaveInit, Gl_nbr, 
								Gl_nbr_Inv, CommRec, UniqMfgrHd, InvtRec_no, U_of_meas, Is_rel_gl, StdCostPR FROM @t4Invt_rec
				END

				-- Got some error from insert invt_isu trigger with empty value (can not find invtmfgr record)even there is no record selected from sql, changed to use temp table and insert only @@ROWCOUNT> 0			
				---- Isuse those SN that are for same w_key, lotcode.... are in invtser, but not in cmser, will need to issue out
				--INSERT INTO Invt_isu (W_Key, Uniq_Key, IssuedTo, QtyIsu, Date, 
				--	Gl_nbr, Gl_Nbr_Inv,
				--	StdCost, LotCode, ExpDate, Reference, SaveInit, PoNum,
				--	SerialNo,SerialUniq,UniqMfgrHd, U_of_meas, Invtisu_no, cModid) 
				--SELECT @ccW_key AS W_key, @ccUniq_key AS Uniq_key, 'Cycle Count Adj' AS IssuedTo, 1, GETDATE(), 
				--	CASE WHEN @llGL_Installed = 1 AND @ccPart_Sourc <> 'CONSG' THEN @IAdj_Gl_no ELSE SPACE(13) END AS Gl_nbr,
				--	CASE WHEN @llGL_Installed = 1 AND @ccPart_Sourc <> 'CONSG' THEN @ccWh_gl_nbr ELSE SPACE(13) END AS Gl_nbr_Inv,
				--	@ccStdCost AS StdCost, @ccLotCode AS LotCode, @ccExpDate AS ExpDate, @ccReference AS Reference, @lcUserID, @ccPonum,
				--	Serialno, SerialUniq, @ccUniqmfgrhd AS Uniqmfgrhd, @ccU_of_meas AS U_of_meas, dbo.fn_GenerateUniqueNumber() AS Invtisu_no, 'Y' AS cModid
				--FROM INVTSER
				--WHERE UNIQ_KEY = @ccUniq_key
				--AND UNIQMFGRHD = @ccUniqMfgrhd
				--AND LOTCODE = @ccLotCode 
				--ANd ISNULL(EXPDATE,1) = ISNULL(@ccEXPDATE,1)
				--AND Reference = @ccReference
				--AND PONUM = @ccPonum
				--AND ID_KEY = 'W_KEY'
				--AND ID_VALUE = @ccW_key
				--AND Serialno NOT IN 
				--	(SELECT Serialno
				--		FROM CYCLESER
				--		WHERE UNIQCCNO = @ccUniqCcno)

				--04/03/2012 YS inside the do while this var table needs to be cleared or we will collect information again and again. Then when inserting into Invt_isu will have an issue with duplicate invtisu_no key
				DELETE FROM @t4Invt_isu
				-- 05/31/17 VL added functional currency code and remove serialno
				INSERT @t4Invt_isu								
					SELECT @ccW_key AS W_key, @ccUniq_key AS Uniq_key, 'Cycle Count Adj' AS IssuedTo, 1 AS QtyIsu, GETDATE() AS Date, 
					CASE WHEN @llGL_Installed = 1 AND @ccPart_Sourc <> 'CONSG' THEN @IAdj_Gl_no ELSE SPACE(13) END AS Gl_nbr,
					CASE WHEN @llGL_Installed = 1 AND @ccPart_Sourc <> 'CONSG' THEN @ccWh_gl_nbr ELSE SPACE(13) END AS Gl_nbr_Inv,
					@ccStdCost AS StdCost, @ccLotCode AS LotCode, @ccExpDate AS ExpDate, @ccReference AS Reference, @lcUserID AS SaveInit, @ccPonum AS Ponum,
					@ccUniqmfgrhd AS Uniqmfgrhd, @ccU_of_meas AS U_of_meas, dbo.fn_GenerateUniqueNumber() AS Invtisu_no, 'Y' AS cModid,
					CASE WHEN @llGL_Installed = 1 AND @ccPart_Sourc <> 'CONSG' THEN 0 ELSE 1 END AS Is_Rel_gl, @ccStdCostPR AS StdCostPR
						FROM INVTSER
						WHERE UNIQ_KEY = @ccUniq_key
						AND UNIQMFGRHD = @ccUniqMfgrhd
						AND LOTCODE = @ccLotCode 
						ANd ISNULL(EXPDATE,1) = ISNULL(@ccEXPDATE,1)
						AND Reference = @ccReference
						AND PONUM = @ccPonum
						AND ID_KEY = 'W_KEY'
						AND ID_VALUE = @ccW_key
						AND Serialno NOT IN 
							(SELECT Serialno
								FROM CYCLESER
								WHERE UNIQCCNO = @ccUniqCcno)
				
				IF @@ROWCOUNT > 0
					BEGIN
					-- Isuse those SN that are for same w_key, lotcode.... are in invtser, but not in cmser, will need to issue out
					-- 05/31/17 VL added functional currency code and remove serialno and serialuniq
					INSERT INTO Invt_isu (W_Key, Uniq_Key, IssuedTo, QtyIsu, Date, 
						Gl_nbr, Gl_Nbr_Inv,
						StdCost, LotCode, ExpDate, Reference, SaveInit, PoNum,
						UniqMfgrHd, U_of_meas, Invtisu_no, cModid, Is_rel_gl, STDCOSTPR) 
					SELECT * FROM @t4Invt_isu
					
				END
				SET @llRunCase = 1			
			
						
						
										
			END
			
			--2. Ccount - Qty_oh > 0 -- Need to receive
			--------------------------------------------------
			IF @ccCcount - @ccQTY_OH > 0 AND @llRunCase = 0
			BEGIN
				-- 05/31/17 VL added functional currency code
				INSERT INTO Invt_Rec (W_Key, Uniq_Key, Date, QtyRec, StdCost, LotCode, ExpDate, Reference, SaveInit, 
						Gl_nbr, Gl_nbr_Inv, CommRec, UniqMfgrHd, InvtRec_no, U_of_meas, Is_rel_gl, StdCostPR)
				VALUES (@ccW_key, @ccUniq_key, GETDATE(), @ccCcount - @ccQTY_OH, @ccStdcost, @ccLotCode, @ccExpdate, @ccReference, @lcUserID,
						CASE WHEN @llGL_Installed = 1 AND @ccPart_Sourc <> 'CONSG' AND @ccUniqSupno = '' THEN @IAdj_Gl_no ELSE SPACE(13) END,
						CASE WHEN @llGL_Installed = 1 AND @ccPart_Sourc <> 'CONSG' AND @ccUniqSupno = '' THEN @ccWh_gl_nbr ELSE SPACE(13) END,
						'Cycle Count Adj', @ccUniqMfgrhd, dbo.fn_GenerateUniqueNumber(), @ccU_of_meas,
						CASE WHEN @llGL_Installed = 1 AND @ccPart_Sourc <> 'CONSG' AND @ccUniqSupno = '' THEN 0 ELSE 1 END, @ccStdCostPR)
				
				SET @llRunCase = 1		
			END
			
			--3. Ccount - Qty_oh < 0 -- Need to issue
			--------------------------------------------------
			IF @ccCcount - @ccQTY_OH < 0 AND @llRunCase = 0
			BEGIN
				-- 05/31/17 VL added functional currency code
				INSERT INTO Invt_isu (W_Key, Uniq_Key, IssuedTo, QtyIsu, Date, 
					Gl_nbr, Gl_Nbr_Inv,
					StdCost, LotCode, ExpDate, Reference, SaveInit, PoNum,
					UniqMfgrHd, U_of_meas, Invtisu_no, cModid, IS_REL_GL, StdCostPR) 
				VALUES (@ccW_key, @ccUniq_key, 'Cycle Count Adj', -(@ccCcount - @ccQTY_OH), GETDATE(), 
					CASE WHEN @llGL_Installed = 1 AND @ccPart_Sourc <> 'CONSG' THEN @IAdj_Gl_no ELSE SPACE(13) END,
					CASE WHEN @llGL_Installed = 1 AND @ccPart_Sourc <> 'CONSG' THEN @ccWh_gl_nbr ELSE SPACE(13) END,
					@ccStdCost, @ccLotCode, @ccExpDate, @ccReference, @lcUserID, @ccPonum,
					@ccUniqmfgrhd, @ccU_of_meas, dbo.fn_GenerateUniqueNumber(), 'Y',
					CASE WHEN @llGL_Installed = 1 AND @ccPart_Sourc <> 'CONSG' THEN 0 ELSE 1 END, @ccStdCostPR)
					
				SET @llRunCase = 1		
			END				
		END
	END

END -- End of IF (@lnTotalCc>0)

-- 05/16/12 VL moved next two UPDATE from upper IF..END (@lnTotalCc>0) to outside of it, so it only update one time instead of many many times
-- After insert invt_isu and Invt_rec records for all @tCcRecord4Post

-- update Invtmfgr
UPDATE INVTMFGR
	SET Count_dt = tCcRecord4Post.ccDate,
		COUNT_TYPE = 'CC',
		COUNT_INIT = @lcUserID, 
		COUNTFLAG = ' ' 
	FROM INVTMFGR, @tCcRecord4Post tCcRecord4Post
	WHERE Invtmfgr.W_KEY = tCcRecord4Post.W_key
	AND tCcRecord4Post.Is_Updated = 0	

-- Updat Ccrecord.Posted and Is_Updated
UPDATE CCRECORD
	SET POSTED = 1,
		Is_Updated = 1
	WHERE UNIQCCNO IN 
		(SELECT UNIQCCNO 
			FROM @tCcRecord4Post 
			WHERE Is_Updated = 0)
				
END TRY

BEGIN CATCH
--08/19/14 YS changed error message
	RAISERROR('Error occurred in updating Invntory by Cycle Count. This operation will be cancelled.',11,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END	


					