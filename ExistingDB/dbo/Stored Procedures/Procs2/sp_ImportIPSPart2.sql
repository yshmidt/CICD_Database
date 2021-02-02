

-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/15/13
-- Description:	This sp will update Zimport that should have valid dataset ready to upload, also will create contract, inventory records
-- Modified: 
-- 07/29/14 YS - Ipkey will be hadnled in a different way, remove the old code for now
-- 10/10/14 YS changed invtmfhd table, to use 2 new tables
-- 03/09/15 VL Changed to LEFT OUTER JOIN for parttype, otherwise empty inventor.part_type won't be selected
-- 04/14/15 YS Location length is changed to varchar(256)
-- 03/11/16 VL found should update @lUpdW_key with the @lcNewW_key, so later in invt_rec insert, it won't insert empty value to w_key field
-- 04/28/16 YS Happy BD Glynn. Added proper error handling
-- 04/28/16 YS takes too long to update even 27 records. Remove + and upper function from the where
-- 05/18/16 YS when checking for the location in the invtmfgr table check for the specific supplier.
---05/18/16 YS Check for the location that was found but is marked as deleted and remove the deleted mark
-- 09/19/16 VL Changed @lUpdContr_no from char(10) to char(20)
-- 02/02/17 YS changed contract tables
-- 06/06/17 VL Added functional currency code
-- 06/08/17 VL use presentation currency as the fcused_Uniq 2nd parameter and use dbo.fn_GetFunctionalCurrency() as 4th parameter to get correct PR values
-- 06/08/17 VL comment out all code, contract tables are changed, will have to re-visit
-- =============================================
CREATE PROCEDURE [dbo].[sp_ImportIPSPart2]
	@ltImportIPS AS tImportIPS READONLY
AS
BEGIN

---- 07/02/13 VL added DESC in SQL to get price, so it order quantity from large to less

SET NOCOUNT ON;
--DECLARE @ErrorMessage NVARCHAR(4000),
--@ErrorSeverity INT,
--@ErrorState INT,
--@gl_nbr char(13) = null ,
--@gl_nbr_issue char(13) = null;

--BEGIN TRANSACTION
--BEGIN TRY;		

---- 06/06/17 VL Added functional currency code	
--DECLARE @lInstore bit, @UserId char(8), @lUseIPKey bit, @lnTotalNo int, @lnCount int, @lcId int, 
--						@lnQty_oh numeric (12,2), @lcSerialnoM varchar(max), @lnTableVarCnt int,
--						@lcContr_Uniq char(10), @lcMfgr_Uniq char(10), @lnQty_ohPric numeric(12,2), @lcCPPric_Uniq char(10),
--						@lnCPPrice numeric(13,5), @lnCPQuantity numeric(12,2), @lnPrice numeric(13,5), @llSaveSameContrNo bit,
--						@llOverWriteOldPrice bit, @lUpdContr_uniq char(10), @lUpdContr_no char(20), @lUpdUniq_key char(10), 
--						@lUpdUniqSupno char(10), @lUpdPartmfgr char(8), @lUpdMfgr_pt_no char(30), 
--						@lUpdQty4Price numeric(12,2), @lUpdPrice numeric(13,5), @lUpdMfgr_Uniq char(10), @lUpdPric_Uniq char(10),
--						@lUpdW_key char(10), @lUpdUniqWh char(10), @lUpdLocation char(10), @lUpdUniqMfgrhd char(10), @lcNewContValue char(10), 
--						@lcNewMfgrValue char(10), @lcNewPricValue char(10), @lcNewW_key char(10), 
--						@lcIPW_key char(10), @lcIPUniq_key char(10), @lnIPQtyRec numeric(12,2), @lcIPUniqMfgrHd char(10), @lcIPU_of_meas char(4), 
--						@lcIPLotcode char(15), @ldIPExpdate smalldatetime, @lcIPReference char(12), @lnIPnQpp numeric(12,2), @lnIPStdCost numeric(13,5),
--						@lnTotalNo2 int, @lnCount2 int, @lnLoop int, @lnCount3 int, @lnTempQty numeric(12,2), @llFoundPric bit,
--						@lnCPPriceFC numeric(13,5), @lnPriceFC numeric(13,5), @lUpdPriceFC numeric(13,5), @lnIPStdCostPR numeric(13,5),
--						@lnCPPricePR numeric(13,5), @lnPricePR numeric(13,5), @lUpdPricePR numeric(13,5), @lUpdFcused_uniq char(10), @lUpdFchist_key char(10)

---- 06/06/17 VL Added functional currency code		
---- 04/14/15 YS Location length is changed to varchar(256)				
--DECLARE @ZImport TABLE (Supid char(10), UniqSupno char(10), SupName char(30), Uniq_key char(10), Qty_oh numeric(12,2),
--						Part_no char(25), Revision char(8), Partmfgr char(8), Mfgr_pt_no char(30), Part_class char(8),
--						Part_type char(8), U_of_meas char(4), Pur_Uofm char(4),	Uniqmfgrhd char(10), Matl_cost numeric(13,5),
--						StdCost numeric(13,5), Price numeric(13,5), Contr_no char(20), UniqWh char(10), Whno char(3),
--						Location varchar(256), Warehouse char(6), Invt_gl_nbr char(13), AutoLocation bit, W_key char(10),
--						Instore bit, Contr_Uniq char(10), Mfgr_Uniq char(10), Pric_uniq char(10), LotCode char(15), 
--						ExpDate smalldatetime, Reference char(12), Uniq_lot char(10), SerialNoM varchar(max), SerialNo char(30),
--						SerialUniq char(10), Qty4Price numeric(12,2), nQpp numeric (12,2), lInStore bit, UserId char(8),
--						lSaveSameContrNo bit, lOverwriteOldPrice bit, PriceFC numeric(13,5), Matl_costPR numeric(13,5),
--						StdCostPR numeric(13,5), PricePR numeric(13,5), Fcused_uniq char(10), Fchist_key char(10), ID int IDENTITY)

--DECLARE @ZUpdDiffPrice TABLE (Contr_Uniq char(10), Mfgr_Uniq char(10), Pric_Uniq char(10))						

---- 06/06/17 VL Added functional currency code
--DECLARE @ZUpdContrTB TABLE (nRecno int, Supid char(10), UniqSupno char(10), SupName char(30), Uniq_key char(10),
--						Part_no char(25), Revision char(8), Partmfgr char(8), Mfgr_pt_no char(30), Part_class char(8),
--						Part_type char(8), U_of_meas char(4), Pur_Uofm char(4),	Uniqmfgrhd char(10), StdCost numeric(13,5), 
--						Matl_cost numeric(13,5), Price numeric(13,5), Contr_no char(20), UniqWh char(10), Whno char(3),
--						Location char(17), Warehouse char(6), Invt_gl_nbr char(13), AutoLocation bit, W_key char(10),
--						Instore bit, Contr_Uniq char(10), Mfgr_Uniq char(10), Pric_uniq char(10), Qty4Price numeric(12,2),
--						PriceFC numeric(13,5), Matl_costPR numeric(13,5), StdCostPR numeric(13,5), PricePR numeric(13,5), 
--						Fcused_uniq char(10), Fchist_key char(10))
						
---- 06/06/17 VL Added functional currency code	
--DECLARE @ZContPric TABLE (nRecno int, Contr_uniq char(10), Mfgr_uniq char(10), Pric_uniq char(10), Price numeric(13,5), Qty_oh numeric(12,2), PriceFC numeric(13,5), PricePR numeric(13,5))

---- 06/06/17 VL Added functional currency code	
--DECLARE @ZIPkeyTable TABLE (nRecno int, W_key char(10), Uniq_key char(10), QtyRec numeric(12,2), Commrec char(50), Is_rel_gl bit, SaveInit char(8), 
--						Transref char(30), UniqMfgrHd char(10), U_of_meas char(4), Lotcode char(15), Expdate smalldatetime, Reference char(12), 
--						Serialno char(30), Serialuniq char(10), nQpp numeric(12,2), StdCost numeric(13,5), StdCostPR numeric(13,5))
						
---- lInstore is actually the variable This.plInStore set up in calling program
--SELECT @lInstore = lInstore, @UserId = UserId, @llSaveSameContrNo = lSaveSameContrNo, @llOverWriteOldPrice = lOverWriteOldPrice FROM @ltImportIPS
--SELECT @lUseIPKey = lUseIpKey FROM InvtSetup
--INSERT @ZImport SELECT * FROM @ltImportIPS

----update fields with leading zeros if needed
--UPDATE @ZImport 
--	SET Part_no = LTRIM(RTRIM(UPPER(Part_no))),
--		PartMfgr = LTRIM(RTRIM(UPPER(PartMfgr))),
--		Warehouse = LTRIM(RTRIM(UPPER(Warehouse))),
--		InStore = CASE WHEN @lInstore = 1 THEN @lInstore ELSE Instore END

---- Update WH info
----warehouse is OK, populate UniqWH and GL# from Warehous table
--UPDATE @ZImport 
--	SET UniqWH = Warehous.UniqWH,
--		Invt_GL_NBR = Warehous.Wh_gl_nbr,
--		WHno = Warehous.WHno,
--		Autolocation = Warehous.AutoLocation 
--	FROM Warehous, @ZImport ZImport
--	WHERE ZImport.Warehouse = Warehous.Warehouse					

---- Update Inventory info
----04/28/16 YS takes too long to update even 27 records. Remove + and upper function from the where
--UPDATE @Zimport 
--	SET Uniq_key = Inventor.Uniq_key,
--		Part_no = Inventor.Part_no,
--		Revision = Inventor.Revision,
--		Part_class = Inventor.Part_class,
--		Part_type = Inventor.Part_type,
--		U_OF_MEAS = Inventor.U_OF_Meas,
--		Pur_UOFM = Inventor.Pur_UOFM,
--		StdCost = Inventor.StdCost,
--		Matl_cost = Inventor.matl_cost,
--		nQpp = CASE WHEN @lUseIPKey = 1 THEN 
--					CASE WHEN nQpp<>0 THEN (CASE WHEN ZImport.nQpp<ZImport.Qty_Oh THEN ZImport.nQpp ELSE ZImport.Qty_oh END) ELSE 
--					CASE WHEN Inventor.OrdMult<>0 THEN (CASE WHEN Inventor.OrdMult<ZImport.Qty_oh THEN Inventor.OrdMult ELSE ZImport.Qty_oh END) ELSE ZImport.Qty_oh END END
--				ELSE 0 END,
--		-- 06/06/17 VL Added functional currency code	
--		StdCostPR = Inventor.StdCostPR,
--		Matl_costPR = Inventor.matl_costPR
----- 04/28/16 YS change to inner join
--	FROM Inventor INNER JOIN @ZImport ZImport
--	ON Inventor.Part_no =ZImport.Part_no
--	and Inventor.Revision=ZImport.Revision
--	AND Inventor.Part_sourc<>'CONSG'

---- Update SN and lot, if not serialized or lot-coded, will clear out those fields
--	-- has records that have extra SN or Lot info, will just remove those data
--UPDATE @Zimport 
--	SET SerialnoM = NULL 
--	WHERE SerialnoM IS NOT NULL
--	AND Uniq_key IN 
--		(SELECT Uniq_key 
--			FROM Inventor 
--			WHERE SerialYes = 0)

---- 03/09/15 VL Changed to LEFT OUTER JOIN for parttype, otherwise empty inventor.part_type won't be selected
--UPDATE @Zimport 
--	SET LotCode = ' ', 
--		Reference = ' ', 
--		ExpDate = ' ' 
--	WHERE LTRIM(RTRIM(LotCode))<>'' 
--	AND Uniq_key IN 
--		(SELECT Uniq_key 
--			FROM Inventor LEFT OUTER JOIN Parttype 
--			ON Inventor.part_class = PartType.Part_class
--			AND Inventor.part_type = PartType.Part_type
--			WHERE PartType.LotDetail = 0 OR PartType.LotDetail IS NULL)


----  update zimport that each sn has one record
--DECLARE @ltHasSN TABLE (nRecno int Identity, Id int, Qty_oh numeric(12,2), SerialnoM varchar(max))
--DECLARE @ltSNDetail TABLE (ID int, Qty_oh numeric(12,2), Serialno char(30))

--INSERT @ltHasSN SELECT ID, Qty_oh, SerialnoM 
--					FROM @ZImport
--					WHERE SerialNoM <> ''
--SET @lnTotalNo = @@ROWCOUNT
	
--IF (@lnTotalNo>0)
--BEGIN
--	SET @lnCount=0
--	WHILE @lnTotalNo>@lnCount
--	BEGIN	
--		SET @lnCount=@lnCount+1;
		
--		SELECT @lcId = ID, @lnQty_oh = Qty_oh, @lcSerialnoM = SerialnoM 
--			FROM @ltHasSN
--			WHERE nRecno = @lnCount
		
--	-- First update @ltSNDetail with all SN, then update empty ID, Qty_oh
--		-- 06/26/13 VL Added  OPTION (MAXRECURSION 0) after the fn_ParseSerialNumberString function to make it allow more than 100 recursion to become unlimited
--		--				Also update Id, Qty_oh at the same time		
--		INSERT INTO @ltSNDetail (ID, Qty_oh, Serialno) 
--			SELECT @lcId, @lnQty_oh, SN FROM dbo.fn_ParseSerialNumberString(@lcSerialnoM) OPTION (MAXRECURSION 0)

--		-- 06/06/17 VL Added functional currency code	
--		INSERT @ZImport 
--			(Supid, UniqSupno, SupName, Uniq_key, Qty_oh, Part_no, Revision, Partmfgr, Mfgr_pt_no, Part_class, Part_type, 
--				U_of_meas, Pur_Uofm, Uniqmfgrhd, Matl_cost, StdCost, Price, Contr_no, UniqWh, Whno, Location, Warehouse, 
--				Invt_gl_nbr, AutoLocation, W_key, Instore, Contr_Uniq, Mfgr_Uniq, Pric_uniq, LotCode, ExpDate, Reference, 
--				Uniq_lot, SerialNoM, SerialNo, SerialUniq, Qty4Price, nQpp, lInStore, UserId, Matl_costPR, StdCostPR, PriceFC, PricePR)
--		SELECT Supid, UniqSupno, SupName, Uniq_key, 1 AS Qty_oh, Part_no, Revision, Partmfgr, Mfgr_pt_no, Part_class, Part_type, 
--				U_of_meas, Pur_Uofm, Uniqmfgrhd, Matl_cost, StdCost, Price, Contr_no, UniqWh, Whno, Location, Warehouse, 
--				Invt_gl_nbr, AutoLocation, W_key, Instore, Contr_Uniq, Mfgr_Uniq, Pric_uniq, LotCode, ExpDate, Reference, 
--				Uniq_lot, '' AS SerialNoM, ltSNDetail.SerialNo, SerialUniq, Qty4Price, nQpp, lInStore, UserId, Matl_costPR, StdCostPR, PriceFC, PricePR
--			FROM @ltSNDetail ltSNDetail LEFT OUTER JOIN @ZImport ZImport
--			ON ltSNDetail.ID = ZImport.ID
			
--		-- Delete those old SN record in ZImport
--		DELETE FROM @ZImport WHERE ID IN (SELECT ID FROM @ltHasSN)
	
--	END
--END

---- Update Supplier info
----04/28/16 YS   remove + and upper function from the where
--UPDATE @Zimport
--	SET UniqSupNo = SupInfo.UniqSupno,
--		SupId = SupInfo.Supid 
--	FROM SupInfo, @ZImport ZImport
--	WHERE Zimport.SupName = SupInfo.SupName

---- 06/06/17 VL added code to update Fcused_uniq and Fchist_key
--IF dbo.fn_IsFCInstalled() = 1
--	BEGIN
--	;WITH ZMaxDate AS
--		(SELECT MAX(Fcdatetime) AS Fcdatetime, FcUsed_Uniq
--		FROM FcHistory 
--		GROUP BY Fcused_Uniq),
--	ZFCPrice AS 
--		(SELECT FcHistory.AskPrice, AskPricePR, FcHistory.FcUsed_Uniq, FcHist_key, FcHistory.Fcdatetime
--			FROM FcHistory, ZMaxDate
--			WHERE FcHistory.FcUsed_Uniq = ZMaxDate.FcUsed_Uniq
--			AND FcHistory.Fcdatetime = ZMaxDate.Fcdatetime)
	

--	UPDATE @ZImport	
--		SET Fcused_uniq = Supinfo.Fcused_uniq,
--			Fchist_key = ZFCPrice.Fchist_key
--	FROM Supinfo INNER JOIN @ZImport ZImport
--		ON SupInfo.UniqSupno = Zimport.UniqSupno
--		INNER JOIN ZFCPrice
--		ON ZFCPrice.Fcused_uniq = SupInfo.Fcused_uniq

--	-- Update Price
--	-- if user only update PriceFC, then convert and update Price and PricePR  
--	UPDATE @ZImport SET Price = dbo.fn_Convert4FCHC('F', Fcused_uniq, PriceFC, dbo.fn_GetFunctionalCurrency(), Fchist_key),
--						PricePR = dbo.fn_Convert4FCHC('F', Fcused_uniq, PriceFC, dbo.fn_GetPresentationCurrency(), Fchist_key) 
--			WHERE PriceFC <> 0 AND Price = 0
				
--	-- if user only update Price, then convert and update PriceFC and PricePR  
--	UPDATE @ZImport SET PriceFC = dbo.fn_Convert4FCHC('H', Fcused_uniq, Price, dbo.fn_GetFunctionalCurrency(), Fchist_key),
--						-- 06/08/17 VL use presentation currency as the fcused_Uniq 2nd parameter and use dbo.fn_GetFunctionalCurrency() as 4th parameter to get correct PR values
--						PricePR = dbo.fn_Convert4FCHC('H', dbo.fn_GetPresentationCurrency(), Price, dbo.fn_GetFunctionalCurrency(), Fchist_key) 
--			WHERE PriceFC = 0 AND Price <> 0
--END
---- 06/06/17 VL End}


---- Update UPM
---- 06/08/17 VL changed invtmfhd table, to use two new tables
------04/28/16 YS takes too long to update even 27 records. remove + and upper function from the where
----UPDATE @Zimport
----	SET UniqMfgrhd=Invtmfhd.UniqMfgrhd,
----		AutoLocation = Invtmfhd.AutoLocation,
----		Mfgr_pt_no = Invtmfhd.Mfgr_pt_no 
----	-- 04/28/16 YS change to inner join
----	From Invtmfhd INNER JOIN @Zimport ZImport
----	-- 06/26/13 VL changed
----	--WHERE Invtmfhd.Uniq_key+UPPER(Invtmfhd.Mfgr_pt_no)+Invtmfhd.PartMfgr=zImport.Uniq_key+UPPER(ZImport.Mfgr_pt_no)+ZImport.PartMfgr
----	--WHERE Invtmfhd.Uniq_key=zImport.Uniq_key
----	ON Invtmfhd.Uniq_key=zImport.Uniq_key
----	--AND UPPER(Invtmfhd.Mfgr_pt_no)=UPPER(ZImport.Mfgr_pt_no)
----	AND Invtmfhd.Mfgr_pt_no=ZImport.Mfgr_pt_no
----	AND Invtmfhd.PartMfgr=ZImport.PartMfgr

----04/28/16 YS takes too long to update even 27 records. remove + and upper function from the where
--UPDATE @Zimport
--	SET UniqMfgrhd=L.UniqMfgrhd,
--		AutoLocation = M.AutoLocation,
--		Mfgr_pt_no = M.Mfgr_pt_no 
--	-- 04/28/16 YS change to inner join
--	From Invtmpnlink L INNER JOIN MfgrMaster M ON l.mfgrMasterId=M.MfgrMasterId 
--				INNER JOIN  @Zimport Z ON L.uniq_key=Z.Uniq_key
--				AND M.mfgr_pt_no=Z.Mfgr_pt_no
--				AND M.PartMfgr=Z.Partmfgr


---- Update Serial no information
--UPDATE @Zimport 
--	SET SerialUniq = dbo.fn_GenerateUniqueNumber(),
--		nQpp = CASE WHEN @lUseIPKey = 1 THEN 1 ELSE 0 END
--	WHERE SerialNo <> ''
---- if the SN already exist in invtser (shipped out or issued out), just use original serialuniq value
--UPDATE @Zimport 
--	SET SerialUniq = InvtSer.Serialuniq 
--	FROM @ZImport ZImport, Invtser 
--	WHERE ZImport.Serialno = Invtser.Serialno
--	AND ZImport.Uniq_key = Invtser.Uniq_key
				

---- Update Invtmfgr info
----04/28/16 YS takes too long to update even 27 records. remove + and upper function from the where
--UPDATE @Zimport 
--	SET W_key = Invtmfgr.W_key, 
--		Location = Invtmfgr.Location 
--	-- 04/28/16 YS change to inner join and remove upper
--	FROM @Zimport ZImport INNER JOIN Invtmfgr 
--	ON Zimport.Uniqmfgrhd = Invtmfgr.Uniqmfgrhd
--	and Zimport.Uniqwh = Invtmfgr.Uniqwh
--	and ZImport.Location = Invtmfgr.location
--	and ZImport.Instore=Invtmfgr.Instore and ZImport.Instore=@lInstore
--	and ZImport.UniqSupno=Invtmfgr.UniqSupno
--	and ((@lInstore=0  and Invtmfgr.UniqSupno='') 
--	-- 05/18/16 YS check against provided supplier
--		--or (@lInstore=1 and Invtmfgr.UniqSupno<>''))
--		or (@lInstore=1 and Invtmfgr.UniqSupno=ZImport.UniqSupno))
	


---- Check if existing contract number exist, if yes, and user wants to continue (Zimport.lSaveSameContrNo = 1), then update zimport price for those records
--IF @llSaveSameContrNo = 1	-- means we do find same contract number from sp_ImportIPSPart1 and user wants to continue to save
--BEGIN
	
--	-- populate contr_uniq field for the same contract number and supid and uniq_key
--	--02/02/17 YS modified contract tables
--	UPDATE @Zimport 
--		SET Contr_uniq = c.Contr_uniq 
--		FROM @ZImport ZImport, ContractHeader h,Contract c
--		WHERE Zimport.Contr_no = h.Contr_no 
--		AND ZImport.UniqSupno = h.UniqSupno 
--		AND Zimport.Uniq_key = c.Uniq_key
--		and h.ContractH_unique=c.contractH_unique
		
				
--	-- populate mfgr_uniq if possible
--	--04/28/16 YS takes too long to update even 27 records. Remove + and upper function from the where
--	UPDATE @Zimport 
--		SET Mfgr_uniq = ContMfgr.Mfgr_uniq 
--		FROM @ZImport ZImport, ContMfgr 
--		WHERE ZImport.Contr_uniq <> '' 
--		AND ZImport.Contr_uniq = ContMfgr.Contr_uniq 
--		AND Zimport.PartMfgr = Contmfgr.PartMfgr 
--		AND Zimport.Mfgr_pt_no =ContMfgr.Mfgr_pt_no

--	-- Get all records with price = 0, will try to find contpric to update price and qty
--	DELETE FROM @ZContPric WHERE 1=1	-- Delete all old records
--	SET @lnTableVarCnt = 0
--	INSERT @ZContPric (Contr_uniq, Mfgr_uniq, Pric_uniq, Price, Qty_oh)
--		SELECT Contr_uniq, Mfgr_uniq, Pric_uniq, Price, SUM(qty_oh) AS Qty_oh
--			FROM @ZImport
--			-- 06/06/17 VL changed to consider both Price=0 and PriceFC = 0
--			--WHERE Price=0
--			WHERE Price = 0
--			AND ((dbo.fn_IsFCInstalled() = 1 AND PriceFC = 0)
--			OR (dbo.fn_IsFCInstalled() = 0 AND 1 = 1))
--			AND Mfgr_uniq <> ''
--			AND Pric_uniq = ''
--			GROUP BY Contr_uniq, Mfgr_uniq, Pric_uniq, Price

--	-- to make nrecno re-order from 1
--	UPDATE @ZContPric SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
	
--	-- now the @lnTableVarCnt should be the record count
--	SET @lnTotalNo = @lnTableVarCnt
--	SET @lnCount=0
--	WHILE @lnTotalNo>@lnCount
--	BEGIN	
--		SET @lnCount=@lnCount+1;
--		SELECT @lcContr_Uniq = Contr_Uniq, @lcMfgr_Uniq = Mfgr_Uniq, @lnQty_ohPric = Qty_oh
--			FROM @ZContPric 
--			WHERE nRecno = @lnCount
		
--		-- 07/03/13 VL add a new variable to indicate if the price record is found or not and should continue or not
--		SET @llFoundPric = 0
		
--		-- Try to find ContPric record with same Mfgr_Uniq and Quantity
--		-- 06/06/17 VL added functional currency code
--		SELECT @lcCPPric_Uniq = Pric_Uniq, @lnCPPrice = PRICE, @lnCPQuantity = Quantity, @lnCPPriceFC = PRICEFC, @lnCPPricePR = PRICEPR
--			FROM CONTPRIC
--			WHERE MFGR_UNIQ = @lcMfgr_Uniq 
--			AND QUANTITY = @lnQty_ohPric

--		BEGIN
--		IF @@ROWCOUNT > 0	-- Found
--			BEGIN
--			-- 07/03/13 VL add a new variable to indicate if the price record is found or not and should continue or not
--			SET @llFoundPric = 1
			
--			-- 06/06/17 VL added functional currency code
--			UPDATE @ZImport 
--				SET Pric_uniq = @lcCPPric_Uniq,
--					Price = @lnCPPrice,
--					Qty4price = @lnCPQuantity,
--					PriceFC = @lnCPPriceFC,
--					PricePR = @lnCPPricePR
--				WHERE Contr_uniq = @lcContr_Uniq 
--				AND Mfgr_uniq = @lcMfgr_Uniq
--			END
--		ELSE
--			BEGIN
--		-- Not found, try to get close qty and price if possible,
--			-- Try to find ContPric record with same Mfgr_Uniq and less Quantity
--			-- 06/06/17 VL added functional currency code
--			SELECT TOP 1 @lcCPPric_Uniq = Pric_Uniq, @lnCPPrice = PRICE, @lnCPQuantity = Quantity, @lnCPPriceFC = PRICEFC, @lnCPPricePR = PRICEPR	
--				FROM CONTPRIC
--				WHERE MFGR_UNIQ = @lcMfgr_Uniq 
--				AND QUANTITY < @lnQty_ohPric		
--				ORDER BY Quantity DESC
			
--			BEGIN
--			IF @@ROWCOUNT > 0	-- FOUND
--				BEGIN
--				-- 07/03/13 VL add a new variable to indicate if the price record is found or not and should continue or not
--				SET @llFoundPric = 1
--				-- 06/06/17 VL added functional currency code
--				UPDATE @ZImport 
--					SET Pric_uniq = @lcCPPric_Uniq,
--						Price = @lnCPPrice,
--						Qty4price = @lnCPQuantity,
--						PriceFC = @lnCPPriceFC,
--						PricePR = @lnCPPricePR
--					WHERE Contr_uniq = @lcContr_Uniq 
--					AND Mfgr_uniq = @lcMfgr_Uniq
--				END
--			ELSE
--				BEGIN
--				-- Not found same Mfgr_Uniq with less qty, will find large qty if any
--				-- Try to find ContPric record with same Mfgr_Uniq and larger Quantity
--				-- 06/06/17 VL added functional currency code
--				SELECT TOP 1 @lcCPPric_Uniq = Pric_Uniq, @lnCPPrice = PRICE, @lnCPQuantity = Quantity, @lnCPPriceFC = PRICEFC, @lnCPPricePR = PRICEPR	
--					FROM CONTPRIC
--					WHERE MFGR_UNIQ = @lcMfgr_Uniq 
--					AND QUANTITY > @lnQty_ohPric		
--					ORDER BY Quantity
--				IF @@ROWCOUNT > 0
--					BEGIN
--					-- 07/03/13 VL add a new variable to indicate if the price record is found or not and should continue or not
--					SET @llFoundPric = 1
					
--					-- 06/06/17 VL added functional currency code
--					UPDATE @ZImport 
--						SET Pric_uniq = @lcCPPric_Uniq,
--							Price = @lnCPPrice,
--							Qty4price = @lnCPQuantity,
--							PriceFC = @lnCPPriceFC,
--							PricePR = @lnCPPricePR
--						WHERE Contr_uniq = @lcContr_Uniq 
--						AND Mfgr_uniq = @lcMfgr_Uniq
--				END	
--				END								
--			END
--			END													
--		END
--	END
	
--	-- check for the different prices if exists
--	-- Get all records with price <> 0, will try to find contpric to update price and qty
--	DELETE FROM @ZContPric WHERE 1=1	-- Delete all old records
--	SET @lnTableVarCnt = 0
--	-- 06/06/17 VL added functional currency code
--	INSERT @ZContPric (Contr_uniq, Mfgr_uniq, Pric_uniq, Price, Qty_oh, PriceFC, PricePR)
--		SELECT Contr_uniq, Mfgr_uniq, Pric_uniq, Price, SUM(qty_oh) AS Qty_oh, PriceFC, PricePR
--			FROM @ZImport
--			-- 06/05/17 VL changed to consider both Price=0 and PriceFC = 0
--			--WHERE Price<>0
--			WHERE Price <> 0
--			AND ((dbo.fn_IsFCInstalled() = 1 AND PriceFC <> 0)
--			OR (dbo.fn_IsFCInstalled() = 0 AND 1 = 1))
--			AND Mfgr_uniq <> ''
--			AND Pric_uniq = ''
--			GROUP BY Contr_uniq, Mfgr_uniq, Pric_uniq, Price, PriceFC, PricePR

--	-- to make nrecno re-order from 1
--	UPDATE @ZContPric SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
	
--	-- now the @lnTableVarCnt should be the record count
--	SET @lnTotalNo = @lnTableVarCnt
--	SET @lnCount=0
--	WHILE @lnTotalNo>@lnCount
--	BEGIN	
--		SET @lnCount=@lnCount+1;
--		-- 06/06/17 VL added functional currency code
--		SELECT @lcContr_Uniq = Contr_Uniq, @lcMfgr_Uniq = Mfgr_Uniq, @lnQty_ohPric = Qty_oh, @lnPrice = Price, @lnPriceFC = PriceFC, @lnPricePR = PricePR	
--			FROM @ZContPric 
--			WHERE nRecno = @lnCount

--		-- 07/03/13 VL add a new variable to indicate if the price record is found or not and should continue or not
--		SET @llFoundPric = 0
			
--		-- Try to find ContPric record with same Mfgr_Uniq and Quantity
--		-- 06/06/17 VL added functional currency code
--		SELECT @lcCPPric_Uniq = Pric_Uniq, @lnCPPrice = PRICE, @lnCPQuantity = Quantity, @lnCPPriceFC = PRICEFC, @lnCPPricePR = PRICEPR
--			FROM CONTPRIC
--			WHERE MFGR_UNIQ = @lcMfgr_Uniq
--			AND QUANTITY = @lnQty_ohPric

--		BEGIN
--		IF @@ROWCOUNT > 0	-- Found	
--			-- 06/06/17 VL added to consider if FC is installed
--			--IF @lnPrice <> @lnCPPrice
--			IF (dbo.fn_IsFCInstalled() = 1 AND (@lnPrice <> @lnCPPrice AND @lnPriceFC <> @lnCPPriceFC)) OR (dbo.fn_IsFCInstalled() = 0 AND @lnPrice <> @lnCPPrice)
--			BEGIN
--				INSERT INTO @ZUpdDiffPrice (Contr_Uniq, Mfgr_Uniq, Pric_Uniq)
--					VALUES (@lcContr_Uniq, @lcMfgr_Uniq, @lcCPPric_Uniq)
				
--				UPDATE @Zimport 
--					SET Qty4price = @lnCPQuantity 
--					WHERE Contr_uniq = @lcContr_Uniq
--					AND Mfgr_uniq = @lcMfgr_Uniq
--			END
--			-- 06/06/17 VL added to consider if FC is installed
--			--IF @lnPrice = @lnCPPrice
--			IF (dbo.fn_IsFCInstalled() = 1 AND (@lnPrice = @lnCPPrice AND @lnPriceFC = @lnCPPriceFC)) OR (dbo.fn_IsFCInstalled() = 0 AND @lnPrice = @lnCPPrice)
--			BEGIN
--				-- 07/03/13 VL add a new variable to indicate if the price record is found or not and should continue or not
--				SET @llFoundPric = 1

--				-- 06/06/17 VL added functional currency code
--				UPDATE @Zimport 
--					SET Pric_uniq = @lcCPPric_Uniq,
--						Price = @lnCPPrice, 
--						Qty4price = @lnCPQuantity,
--						PriceFC = @lnCPPriceFC, 
--						PricePR = @lnCPPricePR 
--					WHERE Contr_uniq = @lcContr_Uniq 
--					AND Mfgr_uniq = @lcMfgr_Uniq 		
--			END	
--		ELSE
--		-- not found same qty for same mfgr
--			BEGIN		
--			-- Try to find ContPric record with same Mfgr_Uniq and less Quantity
--			-- 07/02/13 VL added DESC, so it order quantity from large to less
--			-- 07/03/13 VL added to have same price, if found will update, otherwise a new price break
--			-- 06/06/17 VL added functional currency code
--			SELECT TOP 1 @lcCPPric_Uniq = Pric_Uniq, @lnCPPrice = PRICE, @lnCPQuantity = Quantity, @lnCPPriceFC = PRICEFC, @lnCPPricePR = PRICEPR	
--				FROM CONTPRIC
--				WHERE MFGR_UNIQ = @lcMfgr_Uniq 
--				AND QUANTITY < @lnQty_ohPric
--				-- 06/06/17 VL changed to consider FC installed
--				--AND PRICE = @lnPrice	
--				AND PRICE = @lnPrice
--				AND ((dbo.fn_IsFCInstalled() = 1 AND PriceFC = @lnPriceFC)
--				OR (dbo.fn_IsFCInstalled() = 0 AND 1 = 1))
--				ORDER BY Quantity DESC
--			BEGIN
--			IF @@ROWCOUNT > 0	-- Found
--				BEGIN	
--				-- Found same price, will update qty and price
--				-- 07/03/13 VL add a new variable to indicate if the price record is found or not and should continue or not
--				SET @llFoundPric = 1	
--				-- 06/06/17 VL added functional currency code			
--				UPDATE @Zimport 
--					SET Pric_uniq = @lcCPPric_Uniq,
--						Price = @lnCPPrice, 
--						Qty4price = @lnCPQuantity,
--						PriceFC = @lnCPPriceFC,
--						PricePR = @lnCPPricePR
--					WHERE Contr_uniq = @lcContr_Uniq 
--					AND Mfgr_uniq = @lcMfgr_Uniq 		
--				END
--			END
			
--			BEGIN
--			IF @llFoundPric = 0	-- NO found lower qyt with same price, will check if larger qty with same price
--				-- Not found same Mfgr_Uniq with less qty, will find large qty if any
--				-- Try to find ContPric record with same Mfgr_Uniq and larger Quantity
--				-- 07/02/13 VL remove DESC in the SQL, so it's order qty from less to large
--				-- 07/03/13 VL added same price criteria
--				-- 06/06/17 VL added functional currency code		
--				SELECT TOP 1 @lcCPPric_Uniq = Pric_Uniq, @lnCPPrice = PRICE, @lnCPQuantity = Quantity, @lnCPPriceFC = PRICEFC, @lnCPPricePR = PRICEPR	
--					FROM CONTPRIC
--					WHERE MFGR_UNIQ = @lcMfgr_Uniq 
--					AND QUANTITY > @lnQty_ohPric	
--					-- 06/06/17 VL changed to consider FC installed
--					--AND PRICE = @lnPrice	
--					AND PRICE = @lnPrice
--					AND ((dbo.fn_IsFCInstalled() = 1 AND PriceFC = @lnPriceFC)
--					OR (dbo.fn_IsFCInstalled() = 0 AND 1 = 1))
--					ORDER BY Quantity

--				BEGIN					
--				IF @@ROWCOUNT > 0	-- Found
--					BEGIN	
--					-- Found same price, will update qty and price
--					-- 07/03/13 VL add a new variable to indicate if the price record is found or not and should continue or not
--					-- 06/06/17 VL added functional currency code	
--					SET @llFoundPric = 1				
--					UPDATE @Zimport 
--						SET Pric_uniq = @lcCPPric_Uniq,
--							Price = @lnCPPrice, 
--							Qty4price = @lnCPQuantity,
--							PriceFC = @lnCPPriceFC, 
--							PricePR = @lnCPPricePR
--						WHERE Contr_uniq = @lcContr_Uniq 
--						AND Mfgr_uniq = @lcMfgr_Uniq 		
--					END
--				END
--				-- didn't find same qty for same mfgr, didn't find same price for larger/lower qty, only update qty
--				BEGIN
--				IF @llFoundPric = 0
--					BEGIN
--					UPDATE @Zimport 
--						SET Qty4price = @lnQty_ohPric 
--						WHERE Contr_uniq = @lcContr_Uniq
--						AND Mfgr_uniq = @lcMfgr_Uniq
--					END
--				END

--			END
			
--			END	
--		END		

--	END
--	-- 
--	IF @llOverWriteOldPrice = 1	-- means find different price, and user has confirmed to overwrite the price from upload file
--		BEGIN
--		-- overwrite contract price
--		UPDATE @ZImport 
--			SET Pric_uniq = ZUpdDiffPrice.Pric_Uniq
--			FROM @ZImport ZImport, @ZUpdDiffPrice ZUpdDiffPrice
--			WHERE ZImport.Contr_Uniq = ZUpdDiffPrice.Contr_Uniq
--			AND ZImport.Mfgr_Uniq = ZUpdDiffPrice.Mfgr_Uniq
--	END
--END

---- 06/06/17 VL Added functional currency code
--UPDATE @ZImport 
--	SET Price = Matl_cost, 
--		PricePR = Matl_costPR,
--		PriceFC = CASE WHEN dbo.fn_IsFCInstalled() = 1 THEN dbo.fn_Convert4FCHC('H', Fcused_uniq, Matl_cost, dbo.fn_GetFunctionalCurrency(), Fchist_key) ELSE PriceFC END
--	WHERE Price = 0	AND PriceFC = 0

--UPDATE @Zimport 
--	SET Qty4price = Qty_oh 
--	WHERE qty4price = 0	

------------------------------------------------------------------------------------------------------------
---- Now ZImport should be readu to upload to tables

---- 06/06/17 VL Added functional currency code
--INSERT @ZUpdContrTB 
--	SELECT DISTINCT 0 AS nRecno, Supid, Uniqsupno, Supname, Uniq_key, Part_no, Revision, Partmfgr, Mfgr_pt_no, Part_class, Part_type,
--					U_OF_MEAS, PUR_UOFM, UNIQMFGRHD, StdCost, Matl_cost, Price, Contr_no, UNIQWH, WHNO, LOCATION, Warehouse, 
--					Invt_gl_nbr, AutoLocation, W_key, InStore, Contr_Uniq, Mfgr_uniq, Pric_uniq, Qty4price,
--					PriceFC, Matl_costPR, StdCostPR, PricePR, Fcused_uniq,Fchist_key 
--		FROM @zImport

---- to make nrecno re-order from 1
--SET @lnTableVarCnt = 0
--UPDATE @ZUpdContrTB SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
			
--SET @lnTotalNo = @lnTableVarCnt
	
--IF (@lnTotalNo>0)
--BEGIN
--	SET @lnCount=0
--	WHILE @lnTotalNo>@lnCount
--	BEGIN	
--		SET @lnCount=@lnCount+1;
--		-- 06/06/17 VL Added functional currency code
--		SELECT @lUpdContr_uniq = Contr_Uniq, @lUpdContr_no = Contr_no, @lUpdUniq_key = Uniq_key, @lUpdUniqSupno = UniqSupno,
--				@lUpdPartmfgr = Partmfgr, @lUpdMfgr_pt_no = Mfgr_pt_no, @lUpdQty4Price = Qty4Price, @lUpdPrice = Price, 
--				@lUpdMfgr_Uniq = Mfgr_Uniq, @lUpdPric_Uniq = Pric_Uniq, @lUpdUniqWh = UniqWh, @lUpdLocation = Location,
--				@lUpdUniqMfgrhd = Uniqmfgrhd, @lUpdW_key = W_key, @lUpdPriceFC = PriceFC, @lUpdPricePR = PricePR, 
--				@lUpdFcused_uniq = Fcused_uniq, @lUpdFchist_key = Fchist_key 
--			FROM @ZUpdContrTB
--			WHERE nRecno = @lnCount
--		BEGIN
--		IF @@ROWCOUNT > 0
--			IF @lUpdContr_uniq = ''
--				BEGIN
--				SET @lcNewContValue = dbo.fn_GenerateUniqueNumber()
--				-- 06/06/17 VL Added functional currency code
--				INSERT INTO Contract (Contr_uniq, Contr_no, Uniq_key, StartDate, Prim_sup, Contr_note, UniqSupno, Fcused_uniq, Fchist_key, PRFcused_uniq, FuncFcused_uniq) 
--					VALUES (@lcNewContValue, @lUpdContr_no, @lUpdUniq_key, GETDATE(), 1 ,'Created during in - plant upload', @lUpdUniqSupno, @lUpdFcused_uniq, @lUpdFchist_key, dbo.fn_GetPresentationCurrency(), dbo.fn_GetFunctionalCurrency())
				
--				UPDATE @ZUpdContrTB SET Contr_Uniq = @lcNewContValue WHERE nRecno = @lnCount
--				-- 01/17/14 VL found if Zimport has same part number, uniqmfgrhd but different w_key, after import, the qty_oh will multiple as many as how many records in Zimport, has to add to check w_key as well
--				--UPDATE @ZImport SET Contr_Uniq = @lcNewContValue WHERE Uniqmfgrhd = @lUpdUniqMfgrhd
--				UPDATE @ZImport SET Contr_Uniq = @lcNewContValue WHERE Uniqmfgrhd = @lUpdUniqMfgrhd AND W_key = @lUpdW_key

--				--populate ContMfgr
--				SET @lcNewMfgrValue = dbo.fn_GenerateUniqueNumber()
--				INSERT INTO ContMfgr (Contr_uniq, Mfgr_uniq, Partmfgr, Mfgr_pt_no) 
--					VALUES (@lcNewContValue, @lcNewMfgrValue, @lUpdPartmfgr, @lUpdMfgr_pt_no)
				
--				UPDATE @ZUpdContrTB SET Mfgr_Uniq = @lcNewMfgrValue WHERE nRecno = @lnCount
--				-- 01/17/14 VL found if Zimport has same part number, uniqmfgrhd but different w_key, after import, the qty_oh will multiple as many as how many records in Zimport, has to add to check w_key as well
--				--UPDATE @ZImport SET Mfgr_Uniq = @lcNewMfgrValue WHERE Uniqmfgrhd = @lUpdUniqMfgrhd
--				UPDATE @ZImport SET Mfgr_Uniq = @lcNewMfgrValue WHERE Uniqmfgrhd = @lUpdUniqMfgrhd AND W_key = @lUpdW_key

--				-- populate ContPrice	
--				SET @lcNewPricValue = dbo.fn_GenerateUniqueNumber()
--				-- 06/06/17 VL Added functional currency code
--				INSERT INTO ContPric (Mfgr_uniq, Pric_uniq, Quantity, Price, Contr_uniq, PriceFC, PricePR) 
--					VALUES (@lcNewMfgrValue, @lcNewPricValue, @lUpdQty4Price, @lUpdPrice, @lcNewContValue, @lUpdPriceFC, @lUpdPricePR)
				
--				UPDATE @ZUpdContrTB SET Pric_uniq = @lcNewPricValue WHERE nRecno = @lnCount
--				-- 01/17/14 VL found if Zimport has same part number, uniqmfgrhd but different w_key, after import, the qty_oh will multiple as many as how many records in Zimport, has to add to check w_key as well
--				--UPDATE @ZImport SET Pric_uniq = @lcNewPricValue WHERE Uniqmfgrhd = @lUpdUniqMfgrhd
--				UPDATE @ZImport SET Pric_uniq = @lcNewPricValue WHERE Uniqmfgrhd = @lUpdUniqMfgrhd AND W_key = @lUpdW_key
--			END
			
--			--re-get @lUpdMfgr_Uniq again
--			SELECT @lUpdMfgr_Uniq = Mfgr_Uniq FROM @ZUpdContrTB	WHERE nRecno = @lnCount
--			IF @lUpdMfgr_Uniq = ''
--				BEGIN
--				SELECT @lcNewContValue = Contr_Uniq FROM @ZUpdContrTB WHERE nRecno = @lnCount

--				--populate ContMfgr
--				SET @lcNewMfgrValue = dbo.fn_GenerateUniqueNumber()
--				INSERT INTO ContMfgr (Contr_uniq, Mfgr_uniq, Partmfgr, Mfgr_pt_no) 
--					VALUES (@lcNewContValue, @lcNewMfgrValue, @lUpdPartmfgr, @lUpdMfgr_pt_no)
				
--				UPDATE @ZUpdContrTB SET Mfgr_Uniq = @lcNewMfgrValue WHERE nRecno = @lnCount
--				-- 01/17/14 VL found if Zimport has same part number, uniqmfgrhd but different w_key, after import, the qty_oh will multiple as many as how many records in Zimport, has to add to check w_key as well
--				--UPDATE @ZImport SET Mfgr_Uniq = @lcNewMfgrValue WHERE Uniqmfgrhd = @lUpdUniqMfgrhd
--				UPDATE @ZImport SET Mfgr_Uniq = @lcNewMfgrValue WHERE Uniqmfgrhd = @lUpdUniqMfgrhd AND W_key = @lUpdW_key
				
--				-- populate ContPrice	
--				SET @lcNewPricValue = dbo.fn_GenerateUniqueNumber()
--				-- 06/06/17 VL Added functional currency code
--				INSERT INTO ContPric (Mfgr_uniq, Pric_uniq, Quantity, Price, Contr_uniq, PriceFC, PricePR) 
--					VALUES (@lcNewMfgrValue, @lcNewPricValue, @lUpdQty4Price, @lUpdPrice, @lcNewContValue, @lUpdPriceFC, @lUpdPricePR)
				
--				UPDATE @ZUpdContrTB SET Pric_uniq = @lcNewPricValue WHERE nRecno = @lnCount
--				-- 01/17/14 VL found if Zimport has same part number, uniqmfgrhd but different w_key, after import, the qty_oh will multiple as many as how many records in Zimport, has to add to check w_key as well
--				--UPDATE @ZImport SET Pric_uniq = @lcNewPricValue WHERE Uniqmfgrhd = @lUpdUniqMfgrhd
--				UPDATE @ZImport SET Pric_uniq = @lcNewPricValue WHERE Uniqmfgrhd = @lUpdUniqMfgrhd AND W_key = @lUpdW_key
--			END

--			SELECT @lUpdPric_Uniq = Pric_Uniq FROM @ZUpdContrTB	WHERE nRecno = @lnCount
--			BEGIN
--			IF @lUpdPric_Uniq = ''
--				BEGIN
--					SELECT @lcNewContValue = Contr_Uniq, @lcNewMfgrValue = Mfgr_Uniq FROM @ZUpdContrTB WHERE nRecno = @lnCount

--					-- populate ContPrice	
--					SET @lcNewPricValue = dbo.fn_GenerateUniqueNumber()
--					-- 06/06/17 VL Added functional currency code
--					INSERT INTO ContPric (Mfgr_uniq, Pric_uniq, Quantity, Price, Contr_uniq, PriceFC, PricePR) 
--						VALUES (@lcNewMfgrValue, @lcNewPricValue, @lUpdQty4Price, @lUpdPrice, @lcNewContValue, @lUpdPriceFC, @lUpdPricePR)
					
--					UPDATE @ZUpdContrTB SET Pric_uniq = @lcNewPricValue WHERE nRecno = @lnCount
--					-- 01/17/14 VL found if Zimport has same part number, uniqmfgrhd but different w_key, after import, the qty_oh will multiple as many as how many records in Zimport, has to add to check w_key as well
--					--UPDATE @ZImport SET Pric_uniq = @lcNewPricValue WHERE Uniqmfgrhd = @lUpdUniqMfgrhd
--					UPDATE @ZImport SET Pric_uniq = @lcNewPricValue WHERE Uniqmfgrhd = @lUpdUniqMfgrhd AND W_key = @lUpdW_key
--				END		
--			ELSE
--				BEGIN
--					-- if not empty pric uniq update prices in the contract table with the uploaded
--					-- 06/06/17 VL Added functional currency code
--					UPDATE CONTPRIC SET PRICE = @lUpdPrice, PRICEFC = @lUpdPriceFC, PRICEPR = @lUpdPricePR WHERE PRIC_UNIQ = @lUpdPric_Uniq
--				END
--			END


--			-- check if location needs to be created
--			IF @lUpdW_key = ''
--				BEGIN
--				SET @lcNewW_key = dbo.fn_GenerateUniqueNumber()
--				--04/28/16 YS handle the error
--				begin try
--				INSERT INTO InvtMfgr (UniqWh,UniqMfgrhd,Uniq_key,Netable,Location,W_key,InStore,UniqSupno) 
--					VALUES (@lUpdUniqWh, @lUpdUniqMfgrhd, @lUpdUniq_key, 1, @lUpdLocation, @lcNewW_key, 1, @lUpdUniqSupno)
--				end try
--				begin catch
--					set @ErrorMessage = 'Error Inserting Recorord into Invtmfgr for partMfgr: '+rtrim(@lUpdPartmfgr)+', MPN: '+rtrim(@lUpdMfgr_pt_no)+'. Please check uniqueness of the WH/Location.'
--					RAISERROR (@ErrorMessage, -- Message text.
--					 16, -- Severity.
--						1 -- State.
--				);
--				end catch
--				UPDATE @ZUpdContrTB SET W_key = @lcNewW_key WHERE nRecno = @lnCount
--				UPDATE @ZImport SET W_key = @lcNewW_key WHERE Uniqmfgrhd = @lUpdUniqMfgrhd AND UniqWh = @lUpdUniqWh AND Location = @lUpdLocation
				
--				-- 03/11/16 VL found should update @lUpdW_key with the @lcNewW_key, so later in invt_rec insert, it won't insert empty value to w_key field
--				SET @lUpdW_key = @lcNewW_key
			
--			END
--			begin try
--			---05/16/18 YS Check for the location that was found but is marked as deleted and remove the deleted mark
--			update Invtmfgr set is_deleted=0 where @lUpdW_key<>'' and w_key=@lUpdW_key and is_deleted=1
--			end try
--			begin catch
--					set @ErrorMessage = 'Error updating Invtmfgr record for partMfgr: '+rtrim(@lUpdPartmfgr)+', MPN: '+rtrim(@lUpdMfgr_pt_no)+
--					'W_key: '+@lUpdW_key+'. Please check uniqueness of the WH/Location.'
--					RAISERROR (@ErrorMessage, -- Message text.
--					 16, -- Severity.
--						1 -- State.
--				);
--				end catch
			

--------
			
--			IF @lUseIPKey = 0
--				BEGIN
--				-- Insert invt_rec regular way if not use IPKEY
--				-- 01/17/14 VL found if Zimport has same part number, uniqmfgrhd but different w_key, after import, the qty_oh will multiple as many as how many records in Zimport, has to add to check w_key as well
--				--07/29/14 YS remove ipkeyunique,cpkgid, and nqpp from invt_rec table
--				-- 06/06/17 VL won't update StdCostPR, will let trigger to update
--				INSERT INTO Invt_rec (W_key, Uniq_key, QtyRec, Commrec, Is_rel_gl, SaveInit, Transref, UniqMfgrHd, 
--						U_of_meas, Lotcode, Expdate, Reference, Serialno, Serialuniq, GL_NBR_INV, 
--						InvtRec_no, Date, StdCost) 
--					SELECT ZImport.W_key, zImport.Uniq_key, zImport.Qty_oh, 'In-PLANT Inventory',1, ZImport.UserId, 'From IPS import', zImport.UniqMfgrHd, 
--						zImport.U_of_meas, zImport.LotCode, zimport.Expdate, zimport.Reference, zImport.Serialno, zImport.SerialUniq, dbo.fn_GETINVGLNBR(ZImport.W_key,'R',0), 
--						dbo.fn_GenerateUniqueNumber(), GETDATE(), Inventor.STDCOST 
--						FROM @ZImport Zimport, Inventor, Invtmfgr
--						WHERE ZImport.Uniq_key = Inventor.Uniq_key
--						AND ZImport.W_key = Invtmfgr.W_key
--						AND ZImport.Uniqmfgrhd = @lUpdUniqMfgrhd
--						AND ZImport.W_key = @lUpdW_key
						
--			END
--			-- 07/29/14 YS remove this code. The structure for ipkey is changed. Will modify when ready
--			--IF @lUseIPKey = 1
--			--	BEGIN
--			--	-- Insert INVT_REC for using IPKEY, but has SN or Qty_oh = nQpp
--			--	-- 01/17/14 VL found if Zimport has same part number, uniqmfgrhd but different w_key, after import, the qty_oh will multiple as many as how many records in Zimport, has to add to check w_key as well
--			--	INSERT INTO Invt_rec (W_key, Uniq_key, QtyRec, Commrec, Is_rel_gl, SaveInit, Transref, UniqMfgrHd, 
--			--			U_of_meas, Lotcode, Expdate, Reference, Serialno, Serialuniq, GL_NBR_INV, 
--			--			InvtRec_no, Date, StdCost, IpKeyUnique, cPkgId, nQpp) 
--			--		SELECT ZImport.W_key, zImport.Uniq_key, zImport.Qty_oh, 'In-PLANT Inventory',1, ZImport.UserId, 'From IPS import', zImport.UniqMfgrHd, 
--			--			zImport.U_of_meas, zImport.LotCode, zimport.Expdate, zimport.Reference, zImport.Serialno, zImport.SerialUniq, dbo.fn_GETINVGLNBR(ZImport.W_key,'R',0), 
--			--			dbo.fn_GenerateUniqueNumber(), GETDATE(), Inventor.STDCOST, 
--			--			RIGHT(dbo.fn_GenerateUniqueNumber(),9) AS IpKeyUnique, 
--			--			'Package 1' AS cPkgID, 
--			--			CASE WHEN ZImport.Serialno <> '' THEN 1 ELSE ZImport.nQpp END AS nQpp
--			--			FROM @ZImport Zimport, Inventor, Invtmfgr
--			--			WHERE ZImport.Uniq_key = Inventor.Uniq_key
--			--			AND ZImport.W_key = Invtmfgr.W_key
--			--			AND ZImport.Uniqmfgrhd = @lUpdUniqMfgrhd
--			--			AND ZImport.W_key = @lUpdW_key
--			--			AND (ZImport.SerialNo <> ''
--			--			OR (ZImport.SerialNo = '' 
--			--			AND ZImport.Qty_oh = Zimport.nQpp))
						
			
			
--			--	-- Prepare a table that's from zimport and qty_oh<>nQpp and ipke is used and no SN, need to create multiple invt_rec records for nQpp
--			--	SET @lnCount2 = 0
--			--	INSERT INTO @ZIPkeyTable (W_key, Uniq_key, QtyRec, UniqMfgrHd, U_of_meas, Lotcode, Expdate, Reference, Serialno, Serialuniq, nQpp, StdCost)
--			--		SELECT W_key, Uniq_key, Qty_oh, UniqMfgrHd, U_of_meas, Lotcode, Expdate, Reference, Serialno, Serialuniq, nQpp, StdCost
--			--			FROM @ZImport ZImport 
--			--			WHERE SerialNo = ''
--			--			AND Qty_oh <> nQpp

--			--	-- to make nrecno re-order from 1
--			--	UPDATE @ZIPkeyTable SET @lnCount2 = nRecno = @lnCount2 + 1
--			--	SET @lnTotalNo2 = @lnCount2
				
--			--	IF (@lnTotalNo2>0)
--			--	BEGIN
--			--		SET @lnCount2=0
--			--		WHILE @lnTotalNo2>@lnCount2
--			--		BEGIN	
--			--			SET @lnCount2=@lnCount2+1;
						
--			--			SELECT @lcIPW_key = W_key, @lcIPUniq_key = Uniq_key, @lnIPQtyRec = QtyRec, @lcIPUniqMfgrHd = Uniqmfgrhd, 
--			--				@lcIPU_of_meas = U_of_meas, @lcIPLotcode = LotCode, @ldIPExpdate = Expdate, @lcIPReference = Reference, 
--			--				@lnIPnQpp = nQpp, @lnIPStdCost = StdCost
--			--				FROM @ZIPkeyTable
--			--				WHERE nRecno = @lnCount2
--			--			BEGIN
--			--			IF @@ROWCOUNT > 0
--			--			SET @lnLoop = CEILING(@lnIPQtyRec/@lnIPnQpp)
						
--			--			IF (@lnLoop > 0)
--			--			BEGIN
--			--				SET @lnCount3 = 0
--			--				WHILE @lnLoop > @lnCount3 AND @lnIPQtyRec >= 0
--			--				BEGIN
--			--					SET @lnCount3 = @lnCount3 + 1;
--			--					SET @lnTempQty = CASE WHEN @lnIPQtyRec > @lnIPnQpp THEN @lnIPnQpp ELSE @lnIPQtyRec END
--			--				INSERT INTO Invt_rec (W_key, Uniq_key, QtyRec, Commrec, Is_rel_gl, SaveInit, Transref, UniqMfgrHd, 
--			--					U_of_meas, Lotcode, Expdate, Reference, Serialno, Serialuniq, GL_NBR_INV, 
--			--					InvtRec_no, Date, StdCost, IpKeyUnique, cPkgId, nQpp) 
--			--				SELECT @lcIPW_key AS W_key, @lcIPUniq_key AS Uniq_key, 
--			--					@lnTempQty AS QtyRec, 'In-PLANT Inventory' AS Commrec, 
--			--					1 AS Is_rel_gl, @UserId AS SaveInit, 'From IPS import', @lcIPUniqMfgrHd AS UniqMfgrHd, @lcIPU_of_meas AS U_of_meas, 
--			--					@lcIPLotcode AS LotCode, @ldIPExpdate AS Expdate, @lcIPReference AS Reference, '' AS Serialno, 
--			--					'' AS SerialUniq, dbo.fn_GETINVGLNBR(@lcIPW_key,'R',0), dbo.fn_GenerateUniqueNumber(), GETDATE(), @lnIPStdCost, 
--			--					RIGHT(dbo.fn_GenerateUniqueNumber(),9) AS IpKeyUnique, 'Package '+LTRIM(RTRIM(CAST(@lnCount3 AS char(5)))) AS cPkgID, 
--			--					@lnTempQty AS nQpp
							
--			--				SET @lnIPQtyRec = @lnIPQtyRec - @lnTempQty
			
--			--				END	
--			--			END
						
--			--			END
--			--		END			
--			--	END	
--			--END -- END of @lUseIPKey = 1
--		END
--	END
--END


--END TRY
----04/28/16 YS Added error handling
--BEGIN CATCH
--	IF @@TRANCOUNT > 0
--		ROLLBACK TRANSACTION;

--	SELECT @ErrorMessage = ERROR_MESSAGE(),
--			@ErrorSeverity = ERROR_SEVERITY(),
--			@ErrorState = ERROR_STATE();
--	RAISERROR (@ErrorMessage, -- Message text.
--               @ErrorSeverity, -- Severity.
--               @ErrorState -- State.
--               );
	
	
--END CATCH

--IF @@TRANCOUNT > 0
--    COMMIT TRANSACTION;
END		