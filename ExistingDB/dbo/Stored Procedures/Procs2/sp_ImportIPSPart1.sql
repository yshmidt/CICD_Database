

-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/06/13
-- Description:	This sp will validate the dataset passed in to eliminate the invalid record, if any invalid records is found, will return the data back,
-- to create XLS file
-- 05/06/13 VL start to move all codes from prg to sp
-- 05/15/13 VL found need to get user's input after check contract information, so will just return the @ZFailedTB,
-- decided to move all update ZImport part into sp_ImportIPSPart2
-- 06/26/13 VL added  OPTION (MAXRECURSION 0) after the fn_ParseSerialNumberString function to make it allow more than 100 recursion to become unlimited
--				Also fix the insert @ltSNDetail
-- 01/17/14 VL Added code to check if Qty_OH is negative, found PTI has all negative qty OH in template
-- 02/25/14 VL removed qty_oh = 0 validation, PTI needs the ability to import IPS
-- 10/10/14 YS changed invtmfhd table, to use 2 new tables
-- 03/09/15 VL Changed to LEFT OUTER JOIN for parttype, otherwise empty inventor.part_type won't be selected
-- 04/14/15 YS Location length is changed to varchar(256)
-- 09/19/16 VL Changed Contr_no in @ZFailedTB from char(10) to char(20)
-- 02/02/17 YS changed contract tables
-- 06/05/17 VL Added functional currency code
-- 06/08/17 VL use presentation currency as the fcused_Uniq 2nd parameter and use dbo.fn_GetFunctionalCurrency() as 4th parameter to get correct PR values
--03/02/18 YS changed lotcode size to 25
--07/12/18 YS increase the size of the supname column from 30 to 50
-- 03/14/19 VL added to check if same Uniq_key+Uniqmfgrhd+Location+Instore already exists even for different supplier, otherwise later add invtmfgr will get duplicate records error
-- 05/02/19 VL found I didn't have next line to check for different supplier for the code I added on 03/14/19
-- =============================================
CREATE PROCEDURE [dbo].[sp_ImportIPSPart1]
	@ltImportIPS AS tImportIPS READONLY
AS
BEGIN

SET NOCOUNT ON;

BEGIN TRANSACTION
BEGIN TRY;	
	
-- 06/05/17 VL Added functional currency code	
DECLARE @lInstore bit, @UserId char(8), @lReturn bit, @lUseIPKey bit, @lnTotalNo int, @lnCount int, @lcId int, 
						@lnQty_oh numeric (12,2), @lcSerialnoM varchar(max), @lHasBadSN bit, @lnTableVarCnt int,
						@lcContr_Uniq char(10), @lcMfgr_Uniq char(10), @lnQty_ohPric numeric(12,2), @lcCPPric_Uniq char(10),
						@lnCPPrice numeric(13,5), @lnCPQuantity numeric(12,2), @lnPrice numeric(13,5),
						@lnCPPriceFC numeric(13,5), @lnPriceFC numeric(13,5), @lnCPPricePR numeric(13,5), @lnPricePR numeric(13,5);

-- 04/14/15 YS Location length is changed to varchar(256)
-- 06/05/17 VL Added functional currency code	
--07/12/18 YS increase the size of the supname column from 30 to 50					
DECLARE @ZImport TABLE (Supid char(10), UniqSupno char(10), SupName char(50), Uniq_key char(10), Qty_oh numeric(12,2),
						Part_no char(25), Revision char(8), Partmfgr char(8), Mfgr_pt_no char(30), Part_class char(8),
						Part_type char(8), U_of_meas char(4), Pur_Uofm char(4),	Uniqmfgrhd char(10), Matl_cost numeric(13,5),
						StdCost numeric(13,5), Price numeric(13,5), Contr_no char(20), UniqWh char(10), Whno char(3),
						Location varchar(256), Warehouse char(6), Invt_gl_nbr char(13), AutoLocation bit, W_key char(10),
						--03/02/18 YS changed lotcode size to 25
						Instore bit, Contr_Uniq char(10), Mfgr_Uniq char(10), Pric_uniq char(10), LotCode nvarchar(25), 
						ExpDate smalldatetime, Reference char(12), Uniq_lot char(10), SerialNoM varchar(max), SerialNo char(30),
						SerialUniq char(10), Qty4Price numeric(12,2), nQpp numeric (12,2), lInStore bit, UserId char(8),
						lSaveSameContrNo bit, lOverwriteOldPrice bit, PriceFC numeric(13,5), Matl_costPR numeric(13,5),
						StdCostPR numeric(13,5), PricePR numeric(13,5), Fcused_uniq char(10), Fchist_key char(10), ID int IDENTITY)

-- 06/05/17 VL Added functional currency code	
--07/12/18 YS increase the size of the supname column from 30 to 50
DECLARE @ZFailedTB TABLE (Part_no char(25), Revision char(8), Contr_no char(20), SupName char(50), PartMfgr char(8), Mfgr_pt_no char(30), 
							Qty_oh numeric(12,2), Warehouse char(6), U_of_meas char(4), SN_lot bit, SerialNoM varchar(max), 
							Uniqmfgrhd char(10), Serialno char(30), Supid char(10), ExistingContrNo char(10), 
							 ImportPrice numeric(13,5), ContractPrice numeric(13,5), FailedReason char(50),
							 ImportPriceFC numeric(13,5), ContractPriceFC numeric(13,5),
							 ImportPricePR numeric(13,5), ContractPricePR numeric(13,5))
-- 06/05/17 VL Added functional currency code	
DECLARE @ZContPric TABLE (nRecno int, Contr_uniq char(10), Mfgr_uniq char(10), Pric_uniq char(10), Price numeric(13,5), Qty_oh numeric(12,2),PriceFC numeric(13,5), PricePR numeric(13,5))

-- lInstore is actually the variable This.plInStore set up in calling program
SELECT @lInstore = lInstore, @UserId = UserId FROM @ltImportIPS
SELECT @lUseIPKey = lUseIpKey FROM InvtSetup
SET @lReturn = 1
INSERT @ZImport SELECT * FROM @ltImportIPS
--update fields with leading zeros if needed
UPDATE @ZImport 
	SET Part_no = LTRIM(RTRIM(UPPER(Part_no))),
		PartMfgr = LTRIM(RTRIM(UPPER(PartMfgr))),
		Warehouse = LTRIM(RTRIM(UPPER(Warehouse))),
		InStore = CASE WHEN @lInstore = 1 THEN @lInstore ELSE Instore END


-- mValidateEmpty
-------------------
-- Check if any necessary fields are empty
IF @lReturn = 1
BEGIN
	-- 02/25/14 VL removed Qty_oh = 0.00 criteria, PTI needs a way to import instore location even with Qty_oh = 0
	INSERT INTO @ZFailedTB (Part_no, Revision, Contr_no, SupName, PartMfgr, Mfgr_pt_no, Qty_oh, Warehouse, FailedReason) 
	SELECT Part_no, Revision, Contr_no, SupName, PartMfgr, Mfgr_pt_no, Qty_oh, Warehouse, 'MissingFields' AS FaliedReason 
		FROM @ZImport
		WHERE Contr_no = '' 
		OR Supname = ''
		OR Partmfgr = '' 
		--OR qty_oh = 0.00 
		OR Part_no = ''
		OR Warehouse = ''
	
	IF @@ROWCOUNT > 0
		BEGIN
		SET @lReturn = 0
	END
END

-- 01/17/14 VL added to check if Qty OH < 0
-----------------------------
IF @lReturn = 1
BEGIN
	INSERT INTO @ZFailedTB (Part_no, Revision, Contr_no, SupName, PartMfgr, Mfgr_pt_no, Qty_oh, Warehouse, FailedReason) 
	SELECT Part_no, Revision, Contr_no, SupName, PartMfgr, Mfgr_pt_no, Qty_oh, Warehouse, 'NegativeQTYOH' AS FaliedReason 
		FROM @ZImport
		WHERE qty_oh < 0.00 
	
	IF @@ROWCOUNT > 0
		BEGIN
		SET @lReturn = 0
	END
END


-- mValidateWh
---------------
IF @lReturn = 1
BEGIN
	INSERT INTO @ZFailedTB (Part_no, Revision, Contr_no, SupName, PartMfgr, Mfgr_pt_no, Qty_oh, Warehouse, FailedReason) 
	SELECT Part_no, Revision, Contr_no, SupName, PartMfgr ,Mfgr_pt_no, Qty_oh, Warehouse, 'MissingWh' AS FailedReason 
		FROM @ZImport 
		WHERE Warehouse NOT IN 
			(SELECT Warehouse 
				FROM Warehous 
				WHERE Warehouse <> 'WIP' 
				AND Warehouse <> 'WO-WIP' 
				AND Warehouse <> 'MRB')
	BEGIN
	IF @@ROWCOUNT > 0
		BEGIN
			SET @lReturn = 0
		END
	ELSE
		BEGIN
			--warehouse is OK, populate UniqWH and GL# from Warehous table
			UPDATE @ZImport 
				SET UniqWH = Warehous.UniqWH,
					Invt_GL_NBR = Warehous.Wh_gl_nbr,
					WHno = Warehous.WHno,
					Autolocation = Warehous.AutoLocation 
				FROM Warehous, @ZImport ZImport
				WHERE ZImport.Warehouse = Warehous.Warehouse					
		END
	END
END

-- mValidatePartRev
--------------------
IF @lReturn = 1
BEGIN
	INSERT INTO @ZFailedTB (Part_no, Revision, Contr_no, SupName, PartMfgr, Mfgr_pt_no, Qty_oh, Warehouse, FailedReason) 
	SELECT Part_no, Revision, Contr_no, SupName, PartMfgr, Mfgr_pt_no, Qty_oh, Warehouse, 'InvalidPart' AS FailedReason
		FROM @Zimport 
		WHERE Part_no+UPPER(Revision) 
		NOT IN (SELECT part_no+UPPER(revision) 
					FROM Inventor 
					WHERE (Inventor.Part_sourc <> 'CONSG') 
					AND Inventor.Status = 'Active')

	BEGIN
	IF @@ROWCOUNT > 0
		BEGIN
			SET @lReturn = 0
		END
	ELSE
		BEGIN
			UPDATE @Zimport 
				SET Uniq_key = Inventor.Uniq_key,
					Part_no = Inventor.Part_no,
					Revision = Inventor.Revision,
					Part_class = Inventor.Part_class,
					Part_type = Inventor.Part_type,
					U_OF_MEAS = Inventor.U_OF_Meas,
					Pur_UOFM = Inventor.Pur_UOFM,
					StdCost = Inventor.StdCost,
					Matl_cost = Inventor.matl_cost,
					nQpp = CASE WHEN @lUseIPKey = 1 THEN 
								CASE WHEN nQpp<>0 THEN (CASE WHEN ZImport.nQpp<ZImport.Qty_Oh THEN ZImport.nQpp ELSE ZImport.Qty_oh END) ELSE 
								CASE WHEN Inventor.OrdMult<>0 THEN (CASE WHEN Inventor.OrdMult<ZImport.Qty_oh THEN Inventor.OrdMult ELSE ZImport.Qty_oh END) ELSE ZImport.Qty_oh END END
							ELSE 0 END,
					-- 06/05/17 VL Added functional currency code	
					StdCostPR = Inventor.StdCostPR,
					Matl_costPR = Inventor.matl_costPR
				FROM Inventor, @ZImport ZImport
				WHERE Inventor.Part_no+UPPER(Inventor.Revision)=ZImport.Part_no+UPPER(ZImport.Revision) AND Inventor.Part_sourc<>'CONSG'
					
		END
	END

END

-- mValidateUOM
--------------------
IF @lReturn = 1
BEGIN
	INSERT INTO @ZFailedTB (Part_no, Revision, Contr_no, SupName, PartMfgr, Mfgr_pt_no, Qty_oh, Warehouse, U_of_meas, FailedReason) 
	SELECT Part_no, Revision, Contr_no, SupName, PartMfgr, Mfgr_pt_no, Qty_oh, Warehouse, U_of_meas, 'FractionsPart' AS FailedReason
		FROM @ZImport
		WHERE LEFT(U_of_meas,2)='EA' 
		AND Qty_oh<>FLOOR(qty_oh)

	IF @@ROWCOUNT > 0
		BEGIN
		SET @lReturn = 0
	END
END			
	

-- mValidateMissingSNorLot
--------------------
-- check if serial number and/or lot code are require
IF @lReturn = 1
BEGIN
	INSERT INTO @ZFailedTB (Part_no, Revision, SN_lot, FailedReason) 
	SELECT zImport.Part_no, zImport.Revision, Inventor.SerialYes AS SN_Lot, 'MissSerialNoLotCode' AS FailedReason 
		FROM @ZImport Zimport,Inventor 
		WHERE Inventor.Uniq_key = Zimport.Uniq_key 
		AND Inventor.SerialYes = 1
		AND Zimport.SerialnoM = ''
	UNION ALL 
		SELECT zImport.Part_no, zImport.Revision, PartType.LotDetail AS SN_Lot, 'MissSerialNoLotCode' AS FailedReason 
		FROM @ZImport ZImport, Inventor, PartType
		WHERE Inventor.Uniq_key = ZImport.Uniq_key
		AND PartType.Part_class+PartType.Part_type = Inventor.part_class+Inventor.part_type
		AND PartType.LotDetail = 1 
		AND zImport.LotCode = ''
	IF @@ROWCOUNT > 0
		BEGIN
		SET @lReturn = 0
	END
END		


-- mValidateExtraSNorLot
--------------------
-- check if serial number and/or lot code are require
IF @lReturn = 1
BEGIN;
	-- has records that have extra SN or Lot info, will just remove those data
 	UPDATE @Zimport 
 		SET SerialnoM = NULL 
 		WHERE SerialnoM IS NOT NULL
 		AND Uniq_key IN 
 			(SELECT Uniq_key 
 				FROM Inventor 
 				WHERE SerialYes = 0)
	-- 03/09/15 VL Changed to LEFT OUTER JOIN for parttype, otherwise empty inventor.part_type won't be selected
 	UPDATE @Zimport 
 		SET LotCode = ' ', 
 			Reference = ' ', 
 			ExpDate = ' ' 
 		WHERE LTRIM(RTRIM(LotCode))<>'' 
 		AND Uniq_key IN 
 			(SELECT Uniq_key 
 				FROM Inventor LEFT OUTER JOIN Parttype ON Inventor.part_class=PartType.Part_class and Inventor.part_type =PartType.Part_type
 				WHERE PartType.LotDetail = 0 OR PartType.LotDetail IS NULL)
END


-- mSerialValidate
--------------------
-- check if qty_oh matchs the SN entered for those records that serialM is not empty, after passing the validation, update zimport that each sn has one record
IF @lReturn = 1
BEGIN
	DECLARE @ltHasSN TABLE (nRecno int Identity, Id int, Qty_oh numeric(12,2), SerialnoM varchar(max))
	DECLARE @ltSNDetail TABLE (ID int, Qty_oh numeric(12,2), Serialno char(30))
	DECLARE @ltBadSerialno TABLE (Id int) ;
	INSERT @ltHasSN SELECT ID, Qty_oh, SerialnoM 
						FROM @ZImport
						WHERE SerialNoM <> ''
	SET @lnTotalNo = @@ROWCOUNT
	SET @lHasBadSN = 0
	
	IF (@lnTotalNo>0)
	BEGIN
		SET @lnCount=0
		WHILE @lnTotalNo>@lnCount
		BEGIN	
			SET @lnCount=@lnCount+1;
			
			SELECT @lcId = ID, @lnQty_oh = Qty_oh, @lcSerialnoM = SerialnoM 
				FROM @ltHasSN
				WHERE nRecno = @lnCount
			
			-- First update @ltSNDetail with all SN, then update empty ID, Qty_oh
			-- 06/26/13 VL Added  OPTION (MAXRECURSION 0) after the fn_ParseSerialNumberString function to make it allow more than 100 recursion to become unlimited
			--				Also update Id, Qty_oh at the same time
			INSERT INTO @ltSNDetail (ID, Qty_oh, Serialno) 
				SELECT @lcId, @lnQty_oh, SN FROM dbo.fn_ParseSerialNumberString(@lcSerialnoM) OPTION (MAXRECURSION 0)

			-- if number of serial number <> qty_oh, insert to @ltBadSerialno, will return all records for XLS later
			IF @@ROWCOUNT <> @lnQty_oh
				BEGIN
				SET @lHasBadSN = 1
				INSERT INTO @ltBadSerialno (Id) VALUES (@lcId)				
			END
			
		END
		
		-- Now check if any bad SN is created
		BEGIN
		IF @lHasBadSN = 1
			BEGIN
			INSERT INTO @ZFailedTB (SupName, Part_no, Revision, qty_oh, SerialNoM, Contr_no, PartMfgr ,Mfgr_pt_no, FailedReason) 
			SELECT SupName, Part_no, Revision, qty_oh, SerialNoM, Contr_no, PartMfgr ,Mfgr_pt_no, 'ChkSerialNo' AS FailedReason
				FROM @ZImport
				WHERE ID IN 
					(SELECT ID 
						FROM @ltBadSerialno)
			IF @@ROWCOUNT > 0
				BEGIN
				SET @lReturn = 0
			END
			END
		ELSE
			-- NO bad SN, will update Zimport
			BEGIN
				-- 06/05/17 VL Added functional currency code	
				INSERT @ZImport 
					(Supid, UniqSupno, SupName, Uniq_key, Qty_oh, Part_no, Revision, Partmfgr, Mfgr_pt_no, Part_class, Part_type, 
						U_of_meas, Pur_Uofm, Uniqmfgrhd, Matl_cost, StdCost, Price, Contr_no, UniqWh, Whno, Location, Warehouse, 
						Invt_gl_nbr, AutoLocation, W_key, Instore, Contr_Uniq, Mfgr_Uniq, Pric_uniq, LotCode, ExpDate, Reference, 
						Uniq_lot, SerialNoM, SerialNo, SerialUniq, Qty4Price, nQpp, lInStore, UserId, PriceFC, Matl_costPR, StdCostPR, PricePR)
				SELECT Supid, UniqSupno, SupName, Uniq_key, 1 AS Qty_oh, Part_no, Revision, Partmfgr, Mfgr_pt_no, Part_class, Part_type, 
						U_of_meas, Pur_Uofm, Uniqmfgrhd, Matl_cost, StdCost, Price, Contr_no, UniqWh, Whno, Location, Warehouse, 
						Invt_gl_nbr, AutoLocation, W_key, Instore, Contr_Uniq, Mfgr_Uniq, Pric_uniq, LotCode, ExpDate, Reference, 
						Uniq_lot, '' AS SerialNoM, ltSNDetail.SerialNo, SerialUniq, Qty4Price, nQpp, lInStore, UserId, PriceFC, Matl_costPR, StdCostPR, PricePR
					FROM @ltSNDetail ltSNDetail LEFT OUTER JOIN @ZImport ZImport
					ON ltSNDetail.ID = ZImport.ID
					
				-- Delete those old SN record in ZImport
				DELETE FROM @ZImport WHERE ID IN (SELECT ID FROM @ltHasSN)
			END
		END
	END

END

-- 06/05/17 VL added validation that if FC is installed only price or priceFC can be entered
-- mValidatePrice
----------------------
IF @lReturn = 1 AND dbo.fn_IsFCInstalled() = 1
BEGIN
	INSERT INTO @ZFailedTB (SupName, Supid, Contr_no, PartMfgr, Mfgr_pt_no, Part_no, Revision, Qty_oh, Warehouse, U_of_meas, Serialno, ImportPrice, ImportPriceFC, FailedReason) 
	SELECT Zimport.SupName, Zimport.Supid, Zimport.Contr_no, Zimport.PartMfgr, zImport.Mfgr_pt_no, 
		ZImport.Part_no, ZImport.Revision, ZImport.Qty_oh, ZImport.Warehouse, ZImport.U_of_meas, ZImport.Serialno, ZImport.Price, ZImport.PriceFC, 'OnlyOneCurrencyPriceShouldBeEntered' AS FailedReason
		FROM @Zimport ZImport
		WHERE Price<>0
		AND PriceFC<>0
			
	IF @@ROWCOUNT > 0
		BEGIN
			SET @lReturn = 0
		END
END

-- mValidateSupplier
------------------------
IF @lReturn = 1
BEGIN
	INSERT INTO @ZFailedTB (Part_no, Revision, Contr_no, SupName, PartMfgr ,Mfgr_pt_no, Qty_oh, Warehouse, FailedReason) 
	SELECT Part_no, Revision, Contr_no, SupName, PartMfgr ,Mfgr_pt_no, Qty_oh, Warehouse, 'WrongSupName' AS FailedReason
		FROM @ZImport 
		WHERE UPPER(LTRIM(RTRIM(Supname))) NOT IN 
			(SELECT UPPER(LTRIM(RTRIM(SupName))) FROM SupInfo)
	BEGIN
	IF @@ROWCOUNT > 0
		BEGIN
		SET @lReturn = 0
		END
	ELSE
		BEGIN
			UPDATE @Zimport
				SET UniqSupNo = SupInfo.UniqSupno,
					SupId = SupInfo.Supid 
				FROM SupInfo, @ZImport ZImport
				WHERE UPPER(Zimport.SupName) = UPPER(SupInfo.SupName)

			-- 06/05/17 VL added code to update Fcused_uniq and Fchist_key
			IF dbo.fn_IsFCInstalled() = 1
				BEGIN
				;WITH ZMaxDate AS
					(SELECT MAX(Fcdatetime) AS Fcdatetime, FcUsed_Uniq
					FROM FcHistory 
					GROUP BY Fcused_Uniq),
				ZFCPrice AS 
					(SELECT FcHistory.AskPrice, AskPricePR, FcHistory.FcUsed_Uniq, FcHist_key, FcHistory.Fcdatetime
						FROM FcHistory, ZMaxDate
						WHERE FcHistory.FcUsed_Uniq = ZMaxDate.FcUsed_Uniq
						AND FcHistory.Fcdatetime = ZMaxDate.Fcdatetime)
	

				UPDATE @ZImport	
					SET Fcused_uniq = Supinfo.Fcused_uniq,
						Fchist_key = ZFCPrice.Fchist_key
				FROM Supinfo INNER JOIN @ZImport ZImport
					ON SupInfo.UniqSupNo = Zimport.UniqSupNo
					INNER JOIN ZFCPrice
					ON ZFCPrice.Fcused_uniq = SupInfo.Fcused_uniq

				-- Update Price
				-- if user only update PriceFC, then convert and update Price and PricePR  
				UPDATE @ZImport SET Price = dbo.fn_Convert4FCHC('F', Fcused_uniq, PriceFC, dbo.fn_GetFunctionalCurrency(), Fchist_key),
									PricePR = dbo.fn_Convert4FCHC('F', Fcused_uniq, PriceFC, dbo.fn_GetPresentationCurrency(), Fchist_key) 
						WHERE PriceFC <> 0 AND Price = 0
				
				-- if user only update Price, then convert and update PriceFC and PricePR  
				UPDATE @ZImport SET PriceFC = dbo.fn_Convert4FCHC('H', Fcused_uniq, Price, dbo.fn_GetFunctionalCurrency(), Fchist_key),
									-- 06/08/17 VL use presentation currency as the fcused_Uniq 2nd parameter and use dbo.fn_GetFunctionalCurrency() as 4th parameter to get correct PR values
									PricePR = dbo.fn_Convert4FCHC('H', dbo.fn_GetPresentationCurrency(), Price, dbo.fn_GetFunctionalCurrency(), Fchist_key) 
						WHERE PriceFC = 0 AND Price <> 0
			END
			-- 06/05/17 VL End}
		END		
	END
	
END


-- mValidateMPN
------------------------
IF @lReturn = 1
BEGIN
	INSERT INTO @ZFailedTB (Part_no, Revision, Contr_no, SupName, PartMfgr ,Mfgr_pt_no, Qty_oh, Warehouse, FailedReason) 
	-- 06/26/13 VL Changed to speed up
	--SELECT Part_no, Revision, Contr_no, SupName, PartMfgr, Mfgr_pt_no, Qty_oh, Warehouse, 'MissingPartmfg' AS FailedReason 
	--	FROM @ZImport 
	--	WHERE Uniq_key + Partmfgr + UPPER(Mfgr_pt_no) NOT IN 
	--		(SELECT Uniq_key + Partmfgr + UPPER(Mfgr_pt_no) 
	--			FROM Invtmfhd
	--			WHERE Invtmfhd.Is_deleted = 0)
	
	-- 10/10/14 YS changed invtmfhd table, to use 2 new tables
	--SELECT Part_no, Revision, Contr_no, SupName, PartMfgr, Mfgr_pt_no, Qty_oh, Warehouse, 'MissingPartmfg' AS FailedReason 
	--	FROM @ZImport ZImport
	--	WHERE ZImport.Partmfgr + UPPER(ZImport.Mfgr_pt_no) NOT IN 
	--		(SELECT Partmfgr + UPPER(Mfgr_pt_no) 
	--			FROM Invtmfhd
	--			WHERE Invtmfhd.Uniq_key = ZImport.Uniq_key 
	--			AND Invtmfhd.Is_deleted = 0)

	SELECT Part_no, Revision, Contr_no, SupName, PartMfgr, Mfgr_pt_no, Qty_oh, Warehouse, 'MissingPartmfg' AS FailedReason 
		FROM @ZImport Z
		WHERE NOT EXISTS  
			(SELECT 1 
				FROM InvtMPNLink L INNER JOIN MfgrMaster M ON l.mfgrMasterId=M.MfgrMasterId
				WHERE L.Uniq_key = Z.Uniq_key and M.PartMfgr=z.Partmfgr and M.Mfgr_pt_no=z.mfgr_pt_no
				AND L.Is_deleted = 0 and M.IS_DELETED=0)
	
	--BEGIN
	IF @@ROWCOUNT > 0
		BEGIN
		SET @lReturn = 0
		END
	ELSE
		BEGIN
			-- 10/10/14 YS changed invtmfhd table, to use 2 new tables
			--UPDATE @Zimport
			--	SET UniqMfgrhd=Invtmfhd.UniqMfgrhd,
			--		AutoLocation = Invtmfhd.AutoLocation,
			--		Mfgr_pt_no = Invtmfhd.Mfgr_pt_no 
			--	From Invtmfhd, @Zimport ZImport
			-- 06/26/13 VL changed
				----WHERE Invtmfhd.Uniq_key+UPPER(Invtmfhd.Mfgr_pt_no)+Invtmfhd.PartMfgr=zImport.Uniq_key+UPPER(ZImport.Mfgr_pt_no)+ZImport.PartMfgr
				--WHERE Invtmfhd.Uniq_key=zImport.Uniq_key
				--AND UPPER(Invtmfhd.Mfgr_pt_no) = UPPER(ZImport.Mfgr_pt_no)
				--AND Invtmfhd.PartMfgr=ZImport.PartMfgr		
			UPDATE @Zimport
				SET UniqMfgrhd=L.UniqMfgrhd,
					AutoLocation = M.AutoLocation,
					Mfgr_pt_no = M.Mfgr_pt_no 
				From Invtmpnlink L INNER JOIN MfgrMaster M ON l.mfgrMasterId=M.MfgrMasterId 
				INNER JOIN  @Zimport Z ON L.uniq_key=Z.Uniq_key
				AND M.mfgr_pt_no=Z.Mfgr_pt_no
				AND M.PartMfgr=Z.Partmfgr

				
							
		END		
	--END

END


-- mValidateDisallowBuy
------------------------
IF @lReturn = 1 AND @lInstore = 1
BEGIN
	INSERT INTO @ZFailedTB (Part_no, Revision, Contr_no, SupName, PartMfgr ,Mfgr_pt_no, Qty_oh, Warehouse, FailedReason) 
	-- 10/10/14 YS replaced invtmfhd table with 2 new tables
	--SELECT Part_no, Revision, Contr_no, SupName, PartMfgr, Mfgr_pt_no, Qty_oh, Warehouse, 'DisalowBuyPartmfg' AS FailedReason
	--	FROM @Zimport
	--	WHERE Uniq_key + Partmfgr + UPPER(Mfgr_pt_no) IN 
	--		(SELECT Uniq_key + Partmfgr + UPPER(Mfgr_pt_no) 
	--			FROM Invtmfhd
	--			WHERE Invtmfhd.lDisallowbuy = 1
	--			AND InvtMfhd.IS_DELETED = 0)
	SELECT Part_no, Revision, Contr_no, SupName, PartMfgr, Mfgr_pt_no, Qty_oh, Warehouse, 'DisalowBuyPartmfg' AS FailedReason 
		FROM @ZImport Z
		WHERE EXISTS  
			(SELECT 1 
				FROM InvtMPNLink L INNER JOIN MfgrMaster M ON l.mfgrMasterId=M.MfgrMasterId
				WHERE L.Uniq_key = Z.Uniq_key and M.PartMfgr=z.Partmfgr and M.Mfgr_pt_no=z.mfgr_pt_no
				AND M.lDisallowbuy = 1
				AND L.Is_deleted = 0 and M.IS_DELETED=0)
	
	IF @@ROWCOUNT > 0
	BEGIN
		SET @lReturn = 0
	END
END


-- mChk4DuplSerial
--------------------
-- first, check if serial number is unique for the same MPN. 
IF @lReturn = 1
BEGIN
	;
	WITH ZDuplSerno AS
	(
	SELECT UniqMfgrhd, SerialNo, COUNT(*) AS n
		FROM @ZImport
		WHERE SerialNo <> ''
		GROUP BY UniqMfgrhd, SerialNo 
		HAVING COUNT(*) > 1
	)
	INSERT INTO @ZFailedTB (Part_no, Revision, PartMfgr, Mfgr_pt_no, SerialNo, FailedReason) 
	SELECT DISTINCT Part_no, Revision, PartMfgr, Mfgr_pt_no, ZDuplSerno.SerialNo, 'DuplSerialNumber' AS FailedReason
		FROM @Zimport ZImport, ZDuplSerno
		WHERE ZImport.Uniqmfgrhd = ZDuplSerno.Uniqmfgrhd
		-- 06/26/13 VL added next line
		AND ZImport.SerialNo = ZDuplSerno.Serialno;
				
	IF @@ROWCOUNT > 0
		BEGIN
		SET @lReturn = 0
	END			

END

-- now check if serial numbers are already exists in the invtser file
IF @lReturn = 1
BEGIN
	;
	WITH ZDuplSerno AS
	(
	SELECT Uniqmfgrhd, Serialno
		FROM @ZImport
		WHERE Uniqmfgrhd+Serialno IN
			(SELECT Uniqmfgrhd+Serialno 
				FROM InvtSer 
				WHERE Id_key <> 'INVTISU_NO' 
				AND Id_key <> 'PACKLISTNO')
	)
	INSERT INTO @ZFailedTB (Part_no, Revision, PartMfgr, Mfgr_pt_no, SerialNo, FailedReason) 
	SELECT DISTINCT Part_no, Revision, PartMfgr, Mfgr_pt_no, Zduplserno.SerialNo, 'DuplSerialNumber2' AS FailedReason
		FROM @ZImport ZImport, ZDuplserno
		WHERE Zimport.Uniqmfgrhd = ZDuplserno.Uniqmfgrhd
		-- 06/26/13 VL added next line
		AND ZImport.SerialNo = ZDuplSerno.Serialno;

	BEGIN						
	IF @@ROWCOUNT > 0
		BEGIN
			SET @lReturn = 0
		END
	ELSE
		BEGIN
		-- Update Serial no information
		UPDATE @Zimport 
			SET SerialUniq = dbo.fn_GenerateUniqueNumber(),
				nQpp = CASE WHEN @lUseIPKey = 1 THEN 1 ELSE 0 END
			WHERE SerialNo <> ''
		-- if the SN already exist in invtser (shipped out or issued out), just use original serialuniq value
		UPDATE @Zimport 
			SET SerialUniq = InvtSer.Serialuniq 
			FROM @ZImport ZImport, Invtser 
			WHERE ZImport.Serialno = Invtser.Serialno
			AND ZImport.Uniq_key = Invtser.Uniq_key
				
		END
	END			
END

-- 03/14/19 VL added
-- Check if same Uniq_key+Uniqmfgrhd+Location+Instore already exists even for different supplier, otherwise later add invtmfgr will get duplicate records error
----------------------
IF @lReturn = 1
BEGIN
	INSERT INTO @ZFailedTB (Part_no, Revision, Contr_no, SupName, PartMfgr ,Mfgr_pt_no, Qty_oh, Warehouse, FailedReason) 
	SELECT Part_no, Revision, Contr_no, SupName, PartMfgr, Mfgr_pt_no, ZImport.Qty_oh, Warehouse, 'SameMPNLocation' AS FailedReason 
		FROM @ZImport ZImport INNER JOIN Invtmfgr
		ON ZImport.Uniq_key = Invtmfgr.Uniq_key
		AND ZImport.Uniqmfgrhd = Invtmfgr.Uniqmfgrhd
		AND ZImport.Uniqwh = Invtmfgr.Uniqwh
		AND ZImport.Location = Invtmfgr.Location
		AND ZImport.Instore = Invtmfgr.Instore
		-- 05/02/19 VL found I didn't have next line to check for different supplier
		AND ZImport.UniqSupno <> Invtmfgr.uniqsupno

	IF @@ROWCOUNT > 0
		BEGIN
		SET @lReturn = 0
	END

END
-- 03/14/19 VL End}

-- mValidateLocation
----------------------
IF @lReturn = 1
BEGIN
	;
	WITH ZNotAuto AS
	(
		SELECT *
			FROM @Zimport
			WHERE Autolocation = 0
	)
	INSERT INTO @ZFailedTB (SupName, Supid, Contr_no, PartMfgr, Mfgr_pt_no, Part_no, Revision, Qty_oh, Warehouse, U_of_meas, Serialno, FailedReason) 
	SELECT SupName, Supid, Contr_no, PartMfgr, Mfgr_pt_no, Part_no, Revision, Qty_oh, Warehouse, U_of_meas, Serialno, 'MissingLocation' AS FailedReason
		FROM ZNotAuto
		WHERE Uniqmfgrhd+Uniqwh+UPPER(Location)+ CASE WHEN @lInstore = 1 THEN 'Y' ELSE
								CASE WHEN Instore = 1 THEN 'Y' ELSE 'N' END END+UniqSupno NOT IN 
			(SELECT Invtmfgr.Uniqmfgrhd+Invtmfgr.Uniqwh+UPPER(Invtmfgr.Location)+ CASE WHEN Invtmfgr.Instore = 1 THEN 'Y' ELSE 'N' END+ Invtmfgr.UniqSupno 
				FROM Invtmfgr, ZNotAuto
				WHERE Invtmfgr.Uniq_key = ZNotAuto.Uniq_key)
	BEGIN
	IF @@ROWCOUNT > 0
		BEGIN
			SET @lReturn = 0
		END
	ELSE
		BEGIN
			UPDATE @Zimport 
				SET W_key = Invtmfgr.W_key, 
					Location = Invtmfgr.Location 
				FROM @Zimport ZImport, Invtmfgr 
				WHERE Zimport.Uniqmfgrhd + Zimport.Uniqwh + UPPER(ZImport.Location)+CASE WHEN @lInstore = 1 THEN 'Y' ELSE
								CASE WHEN ZImport.Instore = 1 THEN 'Y' ELSE 'N' END END+ZImport.UniqSupno
					=Invtmfgr.Uniqmfgrhd+Invtmfgr.Uniqwh+UPPER(Invtmfgr.location)+CASE WHEN Invtmfgr.Instore = 1 THEN 'Y' ELSE 'N' END+Invtmfgr.UniqSupno
		END
	END
END

-- 06/20/13 VL comment out now
---- mValidDupInvtMfgWhLoc
---- 05/30/13 VL found the insert record into invtmfgr might have duplicate Uniqmfgrhd+UniqWh+Location+Instore which is unique, but the above code filter out auto-location might filter out the record and cause duplicate later
--IF @lReturn = 1
--BEGIN
--	INSERT INTO @ZFailedTB (SupName, Supid, Contr_no, PartMfgr, Mfgr_pt_no, Part_no, Revision, Qty_oh, Warehouse, U_of_meas, Serialno, FailedReason) 
--	SELECT SupName, Supid, Contr_no, PartMfgr, Mfgr_pt_no, Part_no, Revision, Qty_oh, Warehouse, U_of_meas, Serialno, 'DupMfgrWHLocation' AS FailedReason
--		FROM @ZImport
--		WHERE Uniqmfgrhd+Uniqwh+UPPER(Location)+ CASE WHEN @lInstore = 1 THEN 'Y' ELSE
--								CASE WHEN Instore = 1 THEN 'Y' ELSE 'N' END END IN 
--			(SELECT Invtmfgr.Uniqmfgrhd+Invtmfgr.Uniqwh+UPPER(Invtmfgr.Location)+ CASE WHEN Invtmfgr.Instore = 1 THEN 'Y' ELSE 'N' END 
--				FROM Invtmfgr)
--	IF @@ROWCOUNT > 0
--		BEGIN
--			SET @lReturn = 0
--		END
--END
-- 06/20/13 VL End}


-- mValidateContract
----------------------
IF @lReturn = 1
BEGIN
	INSERT INTO @ZFailedTB (SupName, Supid, Contr_no, ExistingContrNo, PartMfgr, Mfgr_pt_no, Part_no, Revision, Qty_oh, Warehouse, U_of_meas, Serialno, FailedReason) 
	SELECT Zimport.SupName, Zimport.Supid, Zimport.Contr_no, h.Contr_no AS ExistingContrNo, Zimport.PartMfgr, zImport.Mfgr_pt_no, 
		ZImport.Part_no, ZImport.Revision, ZImport.Qty_oh, ZImport.Warehouse, ZImport.U_of_meas, ZImport.Serialno, 'ExistingContract4SamePartAndSupplier' AS FailedReason
		--02/02/17 YS contract tables are changed
		FROM @Zimport ZImport, ContractHeader H,
		Contract c
		WHERE Zimport.UniqSupno = H.UniqSupno
		AND Zimport.Uniq_key = C.Uniq_key
		AND Zimport.Contr_no<>H.Contr_no
		and h.contractH_unique=c.contracth_unique
	
	IF @@ROWCOUNT > 0
		BEGIN
			SET @lReturn = 0
		END
END

-- Check if existing contract number exist
----------------------------------------------
IF @lReturn = 1
BEGIN
	INSERT INTO @ZFailedTB (SupName, Supid, Contr_no, PartMfgr, Mfgr_pt_no, Part_no, Revision, FailedReason) 
		SELECT Zimport.SupName, Zimport.SupID, Zimport.Contr_no, Zimport.PartMfgr, zImport.Mfgr_pt_no, ZImport.Part_no, ZImport.Revision, 'ExistingContractNumbers' AS FailedReason  
			--02/02/17 YS modified contract tables
			FROM @Zimport ZImport, 
			---contract
			contractheader h
			WHERE Zimport.UniqSupno = h.UniqSupno
			AND Zimport.Contr_no = h.Contr_no

	BEGIN
	IF @@ROWCOUNT > 0
	-- ususally, will just return, but decide to continue
	-- will create another set to insert to @FailedTB if different price is found, so in VFP, can have both data ready for users
	
	-- populate contr_uniq field for the same contract number and supid and uniq_key
	--02/02/17 YS modified contract tables
	UPDATE @Zimport 
		SET Contr_uniq = c.Contr_uniq 
		FROM @ZImport ZImport, ContractHeader h,Contract c
		WHERE Zimport.Contr_no = h.Contr_no 
		AND ZImport.UniqSupno = h.UniqSupno 
		AND Zimport.Uniq_key = c.Uniq_key
		and h.ContractH_unique=c.contractH_unique
		
	-- populate mfgr_uniq if possible
	UPDATE @Zimport 
		SET Mfgr_uniq = ContMfgr.Mfgr_uniq 
		FROM @ZImport ZImport, ContMfgr 
		WHERE ZImport.Contr_uniq <> '' 
		AND ZImport.Contr_uniq = ContMfgr.Contr_uniq 
		AND Zimport.PartMfgr = Contmfgr.PartMfgr 
		AND UPPER(Zimport.Mfgr_pt_no) = UPPER(ContMfgr.Mfgr_pt_no)

	-- Get all records with price = 0, will try to find contpric to update price and qty
	DELETE FROM @ZContPric WHERE 1=1	-- Delete all old records
	SET @lnTableVarCnt = 0
	-- 06/05/17 VL Added functional currency code	
	INSERT @ZContPric (nRecno, Contr_uniq, Mfgr_uniq, Pric_uniq, Price, Qty_oh, PriceFC, PricePR)
		SELECT 0 AS nRecno, Contr_uniq, Mfgr_uniq, Pric_uniq, Price, SUM(qty_oh) AS Qty_oh, PriceFC, PricePR
			FROM @ZImport
			-- 06/05/17 VL changed to consider both Price=0 and PriceFC = 0
			--WHERE Price=0
			WHERE Price = 0
			AND ((dbo.fn_IsFCInstalled() = 1 AND PriceFC = 0)
			OR (dbo.fn_IsFCInstalled() = 0 AND 1 = 1))
			AND Mfgr_uniq <> ''
			AND Pric_uniq = ''
			GROUP BY Contr_uniq, Mfgr_uniq, Pric_uniq, Price, PriceFC, PricePR

	-- to make nrecno re-order from 1
	UPDATE @ZContPric SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
	
	-- now the @lnTableVarCnt should be the record count
	SET @lnTotalNo = @lnTableVarCnt
	SET @lnCount=0
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @lcContr_Uniq = Contr_Uniq, @lcMfgr_Uniq = Mfgr_Uniq, @lnQty_ohPric = Qty_oh
			FROM @ZContPric 
			WHERE nRecno = @lnCount
			
		-- Try to find ContPric record with same Mfgr_Uniq and Quantity
		-- 06/05/17 VL Added functional currency code	
		SELECT @lcCPPric_Uniq = Pric_Uniq, @lnCPPrice = PRICE, @lnCPQuantity = Quantity, @lnCPPriceFC = PRICEFC, @lnCPPricePR = PRICEPR		
			FROM CONTPRIC
			WHERE MFGR_UNIQ = @lcMfgr_Uniq 
			AND QUANTITY = @lnQty_ohPric

		BEGIN
		IF @@ROWCOUNT > 0	-- Found
			BEGIN
			-- 06/05/17 VL Added functional currency code
			UPDATE @ZImport 
				SET Pric_uniq = @lcCPPric_Uniq,
					Price = @lnCPPrice,
					Qty4price = @lnCPQuantity,
					PriceFC = @lnCPPriceFC,
					PricePR = @lnCPPricePR
				WHERE Contr_uniq = @lcContr_Uniq 
				AND Mfgr_uniq = @lcMfgr_Uniq
			END
		ELSE
			BEGIN
		-- Not found, try to get close qty and price if possible,
			-- Try to find ContPric record with same Mfgr_Uniq and less Quantity
			-- 06/05/17 VL Added functional currency code
			SELECT TOP 1 @lcCPPric_Uniq = Pric_Uniq, @lnCPPrice = PRICE, @lnCPQuantity = Quantity, @lnCPPriceFC = PRICEFC, @lnCPPricePR = PRICEPR	
				FROM CONTPRIC
				WHERE MFGR_UNIQ = @lcMfgr_Uniq 
				AND QUANTITY < @lnQty_ohPric		
				ORDER BY Quantity	
			
			BEGIN
			IF @@ROWCOUNT > 0	-- FOUND
				BEGIN
				-- 06/05/17 VL Added functional currency code
				UPDATE @ZImport 
					SET Pric_uniq = @lcCPPric_Uniq,
						Price = @lnCPPrice,
						Qty4price = @lnCPQuantity,
						PriceFC = @lnCPPriceFC,
						PricePR = @lnCPPricePR
					WHERE Contr_uniq = @lcContr_Uniq 
					AND Mfgr_uniq = @lcMfgr_Uniq
				END
			ELSE
				BEGIN
				-- Not found same Mfgr_Uniq with less qty, will find large qty if any
				-- Try to find ContPric record with same Mfgr_Uniq and larger Quantity
				-- 06/05/17 VL Added functional currency code
				SELECT TOP 1 @lcCPPric_Uniq = Pric_Uniq, @lnCPPrice = PRICE, @lnCPQuantity = Quantity, @lnCPPriceFC = PRICEFC, @lnCPPricePR = PRICEPR		
					FROM CONTPRIC
					WHERE MFGR_UNIQ = @lcMfgr_Uniq 
					AND QUANTITY > @lnQty_ohPric		
					ORDER BY Quantity DESC	
				IF @@ROWCOUNT > 0
					BEGIN
					UPDATE @ZImport 
						SET Pric_uniq = @lcCPPric_Uniq,
							Price = @lnCPPrice,
							Qty4price = @lnCPQuantity,
							PriceFC = @lnCPPriceFC,
							PricePR = @lnCPPricePR
						WHERE Contr_uniq = @lcContr_Uniq 
						AND Mfgr_uniq = @lcMfgr_Uniq
				END	
				END								
			END
			END													
		END
	END
	
	-- check for the different prices if exists
	-- Get all records with price <> 0, will try to find contpric to update price and qty
	DELETE FROM @ZContPric WHERE 1=1	-- Delete all old records
	SET @lnTableVarCnt = 0
	-- 06/05/17 VL Added functional currency code
	INSERT @ZContPric (Contr_uniq, Mfgr_uniq, Pric_uniq, Price, Qty_oh, PriceFC, PricePR)
		SELECT Contr_uniq, Mfgr_uniq, Pric_uniq, Price, SUM(qty_oh) AS Qty_oh, PriceFC, PricePR
			FROM @ZImport
			-- 06/05/17 VL changed to consider both Price=0 and PriceFC = 0
			--WHERE Price<>0
			WHERE Price <> 0
			AND ((dbo.fn_IsFCInstalled() = 1 AND PriceFC <> 0)
			OR (dbo.fn_IsFCInstalled() = 0 AND 1 = 1))
			AND Mfgr_uniq <> ''
			AND Pric_uniq = ''
			GROUP BY Contr_uniq, Mfgr_uniq, Pric_uniq, Price, PriceFC, PricePR

	-- to make nrecno re-order from 1
	UPDATE @ZContPric SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
	
	-- now the @lnTableVarCnt should be the record count
	SET @lnTotalNo = @lnTableVarCnt
	SET @lnCount=0
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		-- 06/05/17 VL Added functional currency code
		SELECT @lcContr_Uniq = Contr_Uniq, @lcMfgr_Uniq = Mfgr_Uniq, @lnQty_ohPric = Qty_oh, @lnPrice = Price, @lnPriceFC = PriceFC, @lnPricePR = PricePR	
			FROM @ZContPric 
			WHERE nRecno = @lnCount
			
		-- Try to find ContPric record with same Mfgr_Uniq and Quantity
		-- 06/05/17 VL Added functional currency code
		SELECT @lcCPPric_Uniq = Pric_Uniq, @lnCPPrice = PRICE, @lnCPQuantity = Quantity, @lnCPPriceFC = PRICEFC, @lnCPPricePR = PRICEPR
			FROM CONTPRIC
			WHERE MFGR_UNIQ = @lcMfgr_Uniq
			AND QUANTITY = @lnQty_ohPric

		BEGIN
		IF @@ROWCOUNT > 0	-- Found	
			-- 06/05/17 VL added to consider if FC is installed
			--IF @lnPrice <> @lnCPPrice
			IF (dbo.fn_IsFCInstalled() = 1 AND (@lnPrice <> @lnCPPrice AND @lnPriceFC <> @lnCPPriceFC)) OR (dbo.fn_IsFCInstalled() = 0 AND @lnPrice <> @lnCPPrice)
				BEGIN
				-- 06/05/17 VL Added functional currency code
				INSERT INTO @ZFailedTB (SupName,Part_no,Revision,Contr_no,PartMfgr,mfgr_pt_no, Qty_oh, Warehouse, U_of_meas, Serialno, ImportPrice, ContractPrice, FailedReason, ImportPriceFC, ContractPriceFC, ImportPricePR, ContractPricePR)
					SELECT SupName,Part_no,Revision,Contr_no,PartMfgr,mfgr_pt_no,Qty_oh, Warehouse, U_of_meas, Serialno, @lnPrice AS ImportPrice, @lnCPPrice AS ContractPrice, 'ExistingContractPrice' AS FailedReason, @lnPriceFC AS ImportPriceFC, @lnCPPriceFC AS ContractPriceFC, @lnPricePR AS ImportPricePR, @lnCPPricePR AS ContractPricePR
						FROM @ZImport
						WHERE Contr_Uniq = @lcContr_Uniq
						AND Mfgr_Uniq = @lcMfgr_Uniq
				
				SET @lReturn = 0
				
				UPDATE @Zimport 
					SET Qty4price = @lnCPQuantity 
					WHERE Contr_uniq = @lcContr_Uniq
					AND Mfgr_uniq = @lcMfgr_Uniq
			END
			-- 06/05/17 VL added to consider if FC is installed
			--IF @lnPrice = @lnCPPrice
			IF (dbo.fn_IsFCInstalled() = 1 AND (@lnPrice = @lnCPPrice AND @lnPriceFC = @lnCPPriceFC)) OR (dbo.fn_IsFCInstalled() = 0 AND @lnPrice = @lnCPPrice)
			BEGIN
				UPDATE @Zimport 
					SET Pric_uniq = @lcCPPric_Uniq,
						Price = @lnCPPrice, 
						Qty4price = @lnCPQuantity,
						-- 06/05/17 VL Added functional currency code
						PriceFC = @lnCPPriceFC,
						PricePR = @lnCPPricePR
					WHERE Contr_uniq = @lcContr_Uniq 
					AND Mfgr_uniq = @lcMfgr_Uniq 		
			END	
		ELSE
		-- not found
			BEGIN		
			-- Try to find ContPric record with same Mfgr_Uniq and less Quantity than import qty
			-- 06/05/17 VL Added functional currency code
			SELECT TOP 1 @lcCPPric_Uniq = Pric_Uniq, @lnCPPrice = PRICE, @lnCPQuantity = Quantity, @lnCPPriceFC = PRICEFC, @lnCPPricePR = PRICEPR		
				FROM CONTPRIC
				WHERE MFGR_UNIQ = @lcMfgr_Uniq 
				AND QUANTITY < @lnQty_ohPric		
				ORDER BY Quantity	
			BEGIN
			IF @@ROWCOUNT > 0	-- Found
				BEGIN	
				-- Found same price, will update qty and price
				-- 06/05/17 VL added to consider if FC is installed
				--IF @lnPrice = @lnCPPrice
				IF (dbo.fn_IsFCInstalled() = 1 AND (@lnPrice = @lnCPPrice AND @lnPriceFC = @lnCPPriceFC)) OR (dbo.fn_IsFCInstalled() = 0 AND @lnPrice = @lnCPPrice)
					BEGIN
					UPDATE @Zimport 
						SET Pric_uniq = @lcCPPric_Uniq,
							Price = @lnCPPrice, 
							Qty4price = @lnCPQuantity,
							PricePR = @lnCPPricePR,
							PriceFC = @lnCPPriceFC
						WHERE Contr_uniq = @lcContr_Uniq 
						AND Mfgr_uniq = @lcMfgr_Uniq 		
					END
				ELSE
					-- Price is different, only update qty
					BEGIN
					UPDATE @Zimport 
						SET Qty4price = @lnQty_ohPric
						WHERE Contr_uniq = @lcContr_Uniq
						AND Mfgr_uniq = @lcMfgr_Uniq
					END
				END
			ELSE
				-- Not found same Mfgr_Uniq with less qty, will find large qty if any
				-- Try to find ContPric record with same Mfgr_Uniq and larger Quantity
				-- 06/27/13 VL changed to remove DESC after ORDER BY to get the qty that's larger than import qty but the minimum one
				-- 06/05/17 VL Added functional currency code
				SELECT TOP 1 @lcCPPric_Uniq = Pric_Uniq, @lnCPPrice = PRICE, @lnCPQuantity = Quantity, @lnCPPricePR = PRICEPR, @lnCPPriceFC = PRICEFC	
					FROM CONTPRIC
					WHERE MFGR_UNIQ = @lcMfgr_Uniq 
					AND QUANTITY > @lnQty_ohPric		
					ORDER BY Quantity

				BEGIN					
				IF @@ROWCOUNT > 0	-- Found
					BEGIN	
					-- Found same price, will update qty and price
					-- 06/05/17 VL added to consider if FC is installed
					--IF @lnPrice = @lnCPPrice
					IF (dbo.fn_IsFCInstalled() = 1 AND (@lnPrice = @lnCPPrice AND @lnPriceFC = @lnCPPriceFC)) OR (dbo.fn_IsFCInstalled() = 0 AND @lnPrice = @lnCPPrice)
						BEGIN
						UPDATE @Zimport 
							SET Pric_uniq = @lcCPPric_Uniq,
								Price = @lnCPPrice, 
								Qty4price = @lnCPQuantity,
								PricePR = @lnCPPricePR,
								PriceFC = @lnCPPriceFC
							WHERE Contr_uniq = @lcContr_Uniq 
							AND Mfgr_uniq = @lcMfgr_Uniq 		
						END
					ELSE
						-- Price is different, only update qty
						BEGIN
						UPDATE @Zimport 
							SET Qty4price = @lnQty_ohPric
							WHERE Contr_uniq = @lcContr_Uniq
							AND Mfgr_uniq = @lcMfgr_Uniq
						END
					END
				
				END

			END
			
			END	
		END		

	END
	END-- @@ROWCOUNT > 0, FailedTB for ExistingContractNumbers

END

-- 06/05/17 VL Added functional currency code
UPDATE @ZImport 
	SET Price = Matl_cost, 
		PricePR = Matl_costPR,
		PriceFC = CASE WHEN dbo.fn_IsFCInstalled() = 1 THEN dbo.fn_Convert4FCHC('H', Fcused_uniq, Matl_cost, dbo.fn_GetFunctionalCurrency(), Fchist_key) ELSE PriceFC END
	WHERE Price = 0	AND PriceFC = 0

UPDATE @Zimport 
	SET Qty4price = Qty_oh 
	WHERE qty4price = 0	

-- Prepare to return @ZFailedTB that's for creating XLS file, if return data has 'ExistingContractNumbers' or 'ExistingContractPrice', 
--	then will ask user if want to continue, if with other failed reason, just return .F.
SELECT * FROM @ZFailedTB

END TRY

BEGIN CATCH
	RAISERROR('Error occurred in importing IPS part records. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END		