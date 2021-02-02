CREATE PROC [dbo].[JobCostMaterialActualCostView] @lcWono  AS char(10) = ' ', @lcCalculateBy AS varchar(20) = 'Standard'
AS
BEGIN

DECLARE @ZActWoMatCost TABLE (nRecno int, Uniq_key char(10), CostSource char(15), IssuedQty numeric(13,2), UnitCost numeric(13,5), 
								Ext_cost numeric(15,5), TotalRate numeric(3,2))
DECLARE @ZPoRecon TABLE (CostEach numeric(13,5), OrdQty numeric(12,2), Ponum char(15), Itemno char(3), Is_Tax bit, Uniq_key char(10), Uniqlnno char(10), I_link char(10), U_of_meas char(4), PUR_UOFM char(4))						
DECLARE @ZPoExist TABLE (OrdQty numeric(10,2), CostEach numeric(13,5), Uniq_key char(10), Is_Tax bit, I_link char(10), U_of_meas char(4), PUR_UOFM char(4))				
DECLARE @ZCost TABLE (OrdQty Numeric(10,2), CostEach Numeric(13,5))
				
DECLARE @lnTableVarCnt int, @lnCnt int, @lcUniq_key char(10), @lnIssuedQty numeric(13,2), @lnUnitCost numeric(13,5), @lcI_link char(10), 
		@lnTotalRate numeric(8,4), @lcUOM char(4), @lcPUOM char(4), @lnPoExistCnt int, @lnPOSumQty numeric(10,2), @lnCost numeric(13,5), 
		@lnPoReconCnt int, @lnPOSumQty2 numeric(10,2)

SELECT @lnTableVarCnt = 0, @lnCnt = 0, @lcI_link = ''


INSERT @ZActWoMatCost (Uniq_key, CostSource, IssuedQty, UnitCost, Ext_cost, TotalRate)
SELECT Uniq_key, 'Standard' AS CostSource, SUM(Qtyisu) AS IssuedQty, StdCost AS UnitCost, SUM(Qtyisu * StdCost) AS Ext_cost, 0 AS TotalRate
	FROM Invt_isu
	WHERE Wono = @lcWono
	GROUP BY Uniq_key, StdCost
	HAVING SUM(QtyIsu) <> 0.00

UPDATE @ZActWoMatCost SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1

IF @lcCalculateBy = 'PO'
	BEGIN

	WHILE (@lnTableVarCnt > @lnCnt)
	BEGIN	
		SET @lnCnt = @lnCnt + 1;
		SELECT @lcUniq_key = Uniq_key, @lnIssuedQty = IssuedQty, @lnUnitCost = UnitCost
			FROM @ZActWoMatCost
			WHERE nRecno = @lnCnt
								
	-- First, check if any PO reconcilation records created
	DELETE FROM @ZPoRecon WHERE 1 = 1			
	
	INSERT @ZPoRecon
	SELECT Sinvdetl.Costeach, Sinvdetl.Acpt_qty AS OrdQty, Poitems.Ponum, Poitems.Itemno,
			Sinvdetl.Is_tax, Poitems.Uniq_key, Poitems.Uniqlnno, Pomain.I_link, Poitems.U_of_meas, Poitems.PUR_UOFM
		FROM Sinvdetl, Poitems, Poitschd, Pomain
	WHERE Poitems.UniqLnno = Sinvdetl.UniqLnno
	AND Poitschd.Uniqlnno = Poitems.Uniqlnno
	AND Poitschd.Woprjnumber = @lcWono
	AND Poitschd.RequestTp = 'WO Alloc'
	AND Poitems.Uniq_key = @lcUniq_key
	AND Pomain.Ponum=Poitems.Ponum

	SELECT @lnPoReconCnt = @@ROWCOUNT
	-- no reconciled records
	IF @lnPoReconCnt = 0
	-------------------------------
		BEGIN
		--  Now see if any PO records exist to calculate the cost, will get sum of OrdQty first, 
		-- if 0, means no PO is found, will just use standard, if greater than @lnIssuedQty, just use the PO record to calculate cost
		-- if less than @lnIssuedQty, will add the difference qty with @ZActWoMatCost unitCost
		DELETE FROM @ZPoExist WHERE 1 = 1
		INSERT @ZPoExist
			SELECT Poitschd.Schd_qty AS OrdQty, Poitems.Costeach, Poitems.Uniq_key, Poitems.Is_tax, Pomain.I_link, Poitems.U_of_meas, Poitems.PUR_UOFM
				FROM poitems, Pomain, Poitschd
				WHERE Poitems.Ponum = Pomain.Ponum
				AND Pomain.PoStatus <> 'CANCEL'
				AND Poitems.Uniqlnno = Poitschd.Uniqlnno
				AND Poitschd.WoPrjNumber = @lcWono
				AND Poitschd.RequestTp = 'WO Alloc'
				AND Poitems.Uniq_key = @lcUniq_key
		
		SET @lnPoExistCnt = @@ROWCOUNT -- any PO exist for this WO/uniq_key
		SELECT @lcI_link = ISNULL(I_link,'') FROM @ZPoExist WHERE Is_Tax = 1
		SELECT @lnTotalRate = ISNULL(SUM(TaxTabl.Tax_rate),0.0000)
			FROM TaxTabl, ShipTax 
			WHERE ShipTax.TaxType = 'S' 
			AND ShipTax.RecordType = 'I' 
			AND TaxTabl.Tax_Id = ShipTax.Tax_id 
			AND ShipTax.LinkAdd = @lcI_link
		
		BEGIN
		IF @lnPoExistCnt = 0
			BEGIN
				CONTINUE
			END
		ELSE
			BEGIN
				DELETE FROM @ZCost WHERE 1 = 1
				INSERT @ZCost
				SELECT dbo.fn_ConverQtyUOM(ZPoExist.PUR_UOFM, ZPoExist.U_of_meas, ZPoExist.OrdQty) AS OrdQty, 
						dbo.fn_convertPrice('Pur',ZPoExist.Costeach, ZPoExist.PUR_UOFM, ZPoExist.U_of_meas) AS Costeach
					FROM @ZPoExist ZPoExist
				SELECT @lnPOSumQty = ISNULL(SUM(Ordqty),0.00) FROM @ZCost
				
				BEGIN
				IF @lnPOSumQty >= @lnIssuedQty -- Enough PO Qty to calculate
					BEGIN
						SELECT @lnCost = CASE WHEN SUM(OrdQty) <> 0 THEN ISNULL(ROUND(SUM(CostEach*OrdQty)/SUM(OrdQty),5),0) ELSE 0 END 
							FROM @ZCost	
										
						UPDATE @ZActWoMatCost
							SET CostSource = 'PO',
								UnitCost = @lnCost,
								TotalRate = @lnTotalRate,
								Ext_cost = IssuedQty*@lnCost+(IssuedQty * @lnCost * @lnTotalRate)/100
					
					END	
				ELSE
					-- @lnIssuedQty > @lnPOSumQty	-- PO qty not enough to calculate, will append the rest with standard cost info
					BEGIN
						INSERT @ZCost (OrdQty, CostEach) VALUES (@lnIssuedQty - @lnPOSumQty, @lnUnitCost)
					
						SELECT @lnCost = CASE WHEN SUM(OrdQty) <> 0 THEN ISNULL(ROUND(SUM(CostEach*OrdQty)/SUM(OrdQty),5),0) ELSE 0 END 
							FROM @ZCost	
						UPDATE @ZActWoMatCost
						SET CostSource = 'PO/Standard',
							UnitCost = @lnCost,
							TotalRate = @lnTotalRate,
							Ext_cost = IssuedQty*@lnCost+(IssuedQty * @lnCost * @lnTotalRate)/100
											
					END -- End of @lnIssuedQty > @lnPOSumQty
				
				END -- End of @lnPOSumQty >= @lnIssuedQty
						
			END
		END

	END -- END of @lnPoReconCnt = 0
	IF @lnPoReconCnt > 0	
	-------------------------------
		BEGIN
		
		-- Get Taxrate
		SELECT @lcI_link = ISNULL(I_link,'') FROM @ZPoRecon WHERE Is_Tax = 1
		SELECT @lnTotalRate = ISNULL(SUM(TaxTabl.Tax_rate),0.0000)
			FROM TaxTabl, ShipTax 
			WHERE ShipTax.TaxType = 'S' 
			AND ShipTax.RecordType = 'I' 
			AND TaxTabl.Tax_Id = ShipTax.Tax_id 
			AND ShipTax.LinkAdd = @lcI_link
			
		DELETE FROM @ZCost WHERE 1 = 1
		INSERT @ZCost
		SELECT dbo.fn_ConverQtyUOM(ZPoRecon.PUR_UOFM, ZPoRecon.U_of_meas, ZPoRecon.OrdQty) AS OrdQty, 
				dbo.fn_convertPrice('Pur',ZPoRecon.Costeach, ZPoRecon.PUR_UOFM, ZPoRecon.U_of_meas) AS Costeach
			FROM @ZPoRecon ZPoRecon
		SELECT @lnPOSumQty = ISNULL(SUM(Ordqty),0.00) FROM @ZCost

		BEGIN
		IF @lnPOSumQty >= @lnIssuedQty -- Enough PO recon Qty to calculate
			BEGIN
				SELECT @lnCost = CASE WHEN SUM(OrdQty) <> 0 THEN ISNULL(ROUND(SUM(CostEach*OrdQty)/SUM(OrdQty),5),0) ELSE 0 END 
					FROM @ZCost	

				UPDATE @ZActWoMatCost
					SET CostSource = 'PO',
						UnitCost = @lnCost,
						TotalRate = @lnTotalRate,
						Ext_cost = IssuedQty*@lnCost+(IssuedQty * @lnCost * @lnTotalRate)/100
			
			END	
		ELSE
			-- @lnPOSumQty < @lnIssuedQty -- not enough PO recon Qty to calculate, will get the rest of POitems for those PO recon and the rest of PO for the wono/uniq_key
			BEGIN
			DELETE FROM @ZPoExist WHERE 1 = 1
			-- if @ZPoRecon is more than one record, group by uniqlnno and later used in @Poexist
			;WITH ZPoreconSum
				AS
				(SELECT ISNULL(SUM(OrdQty),0) AS OrdQty, Uniqlnno
					FROM @ZPoRecon ZPoRecon
					GROUP BY Uniqlnno
				)
			INSERT @ZPoExist
				SELECT Poitschd.Schd_qty-zporeconsum.OrdQty AS OrdQty, Poitems.Costeach, Poitems.Uniq_key, Poitems.Is_tax, Pomain.I_link, Poitems.U_of_meas, Poitems.PUR_UOFM
					FROM Poitems, ZPoreconSum, Pomain, Poitschd
					WHERE Poitems.UNIQLNNO = ZPoreconSum.Uniqlnno
					AND Poitems.Ponum = Pomain.Ponum
					AND Pomain.PoStatus <> 'CANCEL'
					AND Poitems.Uniqlnno = Poitschd.Uniqlnno
					AND Poitems.Uniq_key = @lcUniq_key
					AND Poitschd.WoPrjNumber = @lcWono
					AND Poitschd.RequestTp = 'WO Alloc'
					AND Poitschd.Schd_qty-zporeconsum.OrdQty > 0
				UNION 
				SELECT Poitschd.Schd_qty AS OrdQty, Poitems.Costeach, Poitems.Uniq_key, Poitems.Is_tax, Pomain.I_link, Poitems.U_of_meas, Poitems.PUR_UOFM
					FROM Poitems, Pomain, Poitschd 
					WHERE Poitems.Uniqlnno NOT IN (SELECT Uniqlnno FROM ZPoreconSum)
					AND Poitems.Ponum = Pomain.Ponum
					AND Pomain.PoStatus <> 'CANCEL'
					AND Poitems.Uniqlnno = Poitschd.Uniqlnno
					AND Poitschd.WoPrjNumber = @lcWono
					AND Poitschd.RequestTp = 'WO Alloc'
					AND Poitems.Uniq_key = @lcUniq_key

			SET @lnPoExistCnt = @@ROWCOUNT -- any PO left exist for this Porecon record
			IF @lnPoExistCnt = 0
				BEGIN
					INSERT @ZCost (OrdQty, CostEach) VALUES (@lnIssuedQty - @lnPOSumQty, @lnUnitCost)
				
					SELECT @lnCost = CASE WHEN SUM(OrdQty) <> 0 THEN ISNULL(ROUND(SUM(CostEach*OrdQty)/SUM(OrdQty),5),0) ELSE 0 END 
						FROM @ZCost	
					UPDATE @ZActWoMatCost
					SET CostSource = 'PO/Standard',
						UnitCost = @lnCost,
						TotalRate = @lnTotalRate,
						Ext_cost = IssuedQty*@lnCost+(IssuedQty * @lnCost * @lnTotalRate)/100
				END
			ELSE	
				-- Has record in PO RECON, not enouth and found some in PO, will now check if enough				
				BEGIN											
					INSERT @ZCost
					SELECT dbo.fn_ConverQtyUOM(ZPoExist.PUR_UOFM, ZPoExist.U_of_meas, ZPoExist.OrdQty) AS OrdQty, 
							dbo.fn_convertPrice('Pur',ZPoExist.Costeach, ZPoExist.PUR_UOFM, ZPoExist.U_of_meas) AS Costeach
						FROM @ZPoExist ZPoExist
					SELECT @lnPOSumQty2 = ISNULL(SUM(Ordqty),0.00) FROM @ZCost
					
					BEGIN
					-- Now @lnPOSumQty2 also include the ordqty from @ZPoRecon, will compare with @lnIssuedQty
					IF @lnPOSumQty2 >= @lnIssuedQty	-- Enough
						BEGIN
							SELECT @lnCost = ISNULL(ROUND(SUM(CostEach*OrdQty)/SUM(OrdQty),5),0) 
								FROM @ZCost						
							UPDATE @ZActWoMatCost
							SET CostSource = 'PO/Standard',
								UnitCost = @lnCost,
								TotalRate = @lnTotalRate,
								Ext_cost = IssuedQty*@lnCost+(IssuedQty * @lnCost * @lnTotalRate)/100					
						END
					ELSE
						-- Still not enough after from POrecon and PO, will insert with standard
						BEGIN
							INSERT @ZCost (OrdQty, CostEach) VALUES (@lnIssuedQty - @lnPOSumQty2, @lnUnitCost)
						
							SELECT @lnCost = ISNULL(ROUND(SUM(CostEach*OrdQty)/SUM(OrdQty),5),0) 
								FROM @ZCost						
							UPDATE @ZActWoMatCost
							SET CostSource = 'PO/Standard',
								UnitCost = @lnCost,
								TotalRate = @lnTotalRate,
								Ext_cost = IssuedQty*@lnCost+(IssuedQty * @lnCost * @lnTotalRate)/100		
						END	
					END		
				END
			
			END -- End of @lnPoExistCnt
		END -- End of @lnPOSumQty >= @lnIssuedQty -- Enough PO recon Qty to calculate
	END -- End of @lnPoReconCnt > 0

	END -- End of WHILE (@lnTableVarCnt > @lnCnt)

END -- End of @lcCalculateBy = 'PO'

IF @lcCalculateBy = 'Weighted Avg'
	BEGIN
	
	UPDATE @ZActWoMatCost
	SET CostSource = 'Weighted Avg',
		UnitCost = dbo.fn_GetLastNPoAvgCost(Uniq_key,5),
		Ext_cost = IssuedQty*@lnCost+(IssuedQty * dbo.fn_GetLastNPoAvgCost(Uniq_key,5))/100		
	WHERE dbo.fn_GetLastNPoAvgCost(Uniq_key,5) <> 0.0000

END ---- End of @lcCalculateBy = 'Weighted Avg'

--IF @lcCalculateBy = 'Standard'
	-- Do nothing, just used @ZActWoMatCost to calculate



-- Return the sum of actual cost
SELECT *
	FROM @ZActWoMatCost
-- The sum of actual cost is : SELECT ISNULL(SUM(Ext_Cost),0.00) FROM @ZActWoMatCost

END