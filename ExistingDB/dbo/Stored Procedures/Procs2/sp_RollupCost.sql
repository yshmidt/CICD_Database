-- =============================================
-- Modifications:	09/17/2014 DRP:  needed to change the MatlType char(5) to MatlType char(10), it was causing truncation errors in the rptKitClose Procedure
--					12/01/2014 VL:	 Need to clear out @Phantom2 first, otherwise the following phantom part will keep adding to this table
--					02/12/2015 VL:	 changed to pass 'F' to @cMake and @cMakeBuy for fn_PhantomSubSelect() function, not leave it empty, it would not get correct result in last SQL criteria
--					02/17/2015 VL:   Added one more parameter to fn_PhanntomSubSelect() to pull or not pull inactive parts
--					08/27/2015 VL:	 changed StdCostper1Build from numeric(13,5) to numeric(29,5), Inovar has really bit number and caused overflow, bom_qty numeric(9,2), bld_qty numeric(7,0) and stdcost numeric(13,5)
--					08/27/2015 VL:   changed @ZResult and @Phantom2.qty from numeric(9,2) to numeric(12,2), changed @lnQtyReq, @lnQtyReqTotal, 
--										@lnQtyReqWithoutCEILING, @lnQtyReqTotalWithoutCEILING, @lnQtyReqP, @lnQtyReqTotalP, @lnQtyReqWithoutCEILINGP, 
--										@lnQtyReqTotalWithoutCEILINGP, @ZResult.QtyReqWithoutCEILING from numeric(12,5) to numeric(12,2),  Phantom2.reqqty from numeric(8,2) to numeric(12,2)
--										Cost fields from numeric(13,5) to numeric(25,5)
--					08/17/2017 VL:	 Originally fixed an issue in [fn_PhantomSubSelect] that the qty in level 0 is not the bom_qty, it also multiply with needqty, so I changed to use bom_qty if it's level 0,
--									 But here in sp_RollupCost, the code here alreaday select the top level into @ZTop, so the level 0 in fn_PhantomSubSelect is actually level 2 which should use bom_qty*need qty, 
--									 so here add a code to update Qty in @@Phantom2 to update Qty = Qty*@ZQty in order to make all sub level qty consider the need qty
--					09/30/16	 YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports
--					04/07/17	 VL Added functional currency code for stdcost	
-- 08/27/17 VL Found the fields in fn_PhantomSubSelect() are changed, that caused the level field was not updated correctly when inserting into @Phantom2, so add the field list in insert command
-- 09/28/2018 Sachin B Change Numeric data fields size from numeric(12,5) to numeric(13,5) for the following columns SetupScrap_Cost,Ext_costWithoutCEILING,SetupScrap_CostPR,Ext_costWithoutCEILINGPR
-- 09/28/2018 Sachin B Change Part_no size from 25 to 35
-- [sp_RollupCost]  '_1LR0NALBN','2018-08-27 00:00:00.000',255151,2
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[sp_RollupCost] 
@cUniq_key AS char(10) = '', @dDue_Date AS smalldatetime, 
	@nStdBldQty numeric (8,0) = 0, @nBldQty AS numeric(7,0) = 0
AS
-- 05/26/11 Added @lKitIgnoreScrap paramemter to fn_PhantomSubSelect function

BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @cSelectDate varchar(254), @lnTotalNo int, @lnCount int, @ZUniq_key char(10), @ZPart_Sourc char(8), 
		@ZStdCost numeric(13,5), @ZQty numeric(9,2), @ZU_of_meas char(4), @ZScrap numeric(6,2), 
		@ZSetupScrap numeric(4,0), @ZPhant_Make bit, @ZUniqBomNo char(10), @ZStdBldQty numeric(8,0),
		@lKitIgnoreScrap bit, @lnQtyReq numeric(12,2), @lnQtyReqTotal numeric(12,2), 
		@lnQtyReqWithoutCEILING numeric(12,2), @lnQtyReqTotalWithoutCEILING numeric(12,2), 
		@lnCalcSetupScrap_cost numeric(12,5), @lnCalcSetupScrap_cost2 numeric(12,5),
		@lnTotalNoP int, @lnCountP int, @ZUniq_keyP char(10), @ZPart_SourcP char(8), 
		@ZStdCostP numeric(13,5), @ZQtyP numeric(9,2), @ZU_of_measP char(4), @ZScrapP numeric(6,2), 
		@ZSetupScrapP numeric(4,0), @ZPhant_MakeP bit, @ZUniqBomNoP char(10), 
		@lnQtyReqP numeric(12,2), @lnQtyReqTotalP numeric(12,2), 
		@lnQtyReqWithoutCEILINGP numeric(12,2), @lnQtyReqTotalWithoutCEILINGP numeric(12,2), 
		@lnCalcSetupScrap_costP numeric(12,5), @lUsesetscrp bit, @lnTableVarCnt int, 
		-- 04/07/17 VL added functional currency code
		@ZStdCostPR numeric(13,5), @lnCalcSetupScrap_costPR numeric(12,5), @lnCalcSetupScrap_cost2PR numeric(12,5), @ZStdCostPPR numeric(13,5), @lnCalcSetupScrap_costPPR numeric(12,5)	 ;

DECLARE @ZTop TABLE (nrecno int identity, Uniq_key char(10), Part_Sourc char(8), StdCost numeric(13,5),
			Qty numeric(9,2), U_of_meas char(4), Scrap numeric(6,2), SetupScrap numeric(4,0), Phant_Make bit,
			UniqBomNo char(10), StdBldQty numeric(8,0),
			-- 04/07/17 VL added functional currency code
			StdCostPR numeric(13,5)) ;
-- 09/28/2018 Sachin B Change Numeric data fields size from numeric(12,5) to numeric(13,5) for the following columns SetupScrap_Cost,Ext_costWithoutCEILING,SetupScrap_CostPR,Ext_costWithoutCEILINGPR
DECLARE @ZResult TABLE (Uniq_key char(10), Part_Sourc char(8), StdCost numeric(13,5),
			Qty numeric(12,2), U_of_meas char(4), Scrap numeric(6,2), SetupScrap numeric(4,0), Phant_Make bit,
			UniqBomNo char(10), Ext_cost numeric(25,5), SetupScrap_Cost numeric(13,5), Ext_cost_total numeric(25,5),
			QtyReqTotal numeric(16,2), StdBldQty numeric(8,0), Ext_costWithoutCEILING numeric(13,5),
			QtyReqWithoutCEILING numeric(16,2), Ext_cost_totalWithoutCEILING numeric(25,5), QtyReqTotalWithoutCEILING numeric(16,2),
			-- 04/07/17 VL added functional currency code
			StdCostPR numeric(13,5), Ext_costPR numeric(25,5), SetupScrap_CostPR numeric(13,5), Ext_cost_totalPR numeric(25,5),
			Ext_costWithoutCEILINGPR numeric(13,5), Ext_cost_totalWithoutCEILINGPR numeric(25,5));

-- 09/28/2018 Sachin B Change Part_no size from 25 to 35
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
DECLARE @Phantom2 TABLE (Item_no numeric(4,0),Part_no char(35),Revision char(8),Custpartno char(35),
		Custrev char(4),Part_class char(8),Part_type char(8),Descript char(45),Qty numeric(12,2), Scrap_qty numeric(9,2), StdCostper1Build numeric(29,5),
		Bomparent char(10),Uniq_key char(10),Dept_id char(4),Item_note text,Offset numeric(3,0),
		Term_dt smalldatetime, Eff_dt smalldatetime,Custno char(10),U_of_meas char(4),Inv_note text,
		Part_sourc char(10),Perpanel numeric(4,0),Used_inkit char(1), Scrap numeric(6,2), 
		SetupScrap numeric(4,0),UniqBomNo char(10),Buyer_type char(3),StdCost numeric(13,5),
		Phant_make bit, Make_buy bit, MatlType char(10), TopStdCost numeric(13,5),nRecno int, leadTime numeric(4,0), 
		UseSetScrp bit, SerialYes bit, StdBldQty numeric(8,0), Reqqty numeric(12,2), Level numeric(3,0),
		-- 04/07/17 VL added functional currency code
		StdCostper1BuildPR numeric(29,5), StdCostPR numeric(13,5), TopStdCostPR numeric(13,5),
		-- 08/27/17 VL added more fields for fn_PhantomSubSelect()
		Scrap_Cost numeric(14,5), SetupScrap_Cost numeric(14,5), Sort varchar(max), Status char(8));



/*-- Give default value if not assigned*/
IF @dDue_Date IS NULL
BEGIN
	SET @dDue_Date = GETDATE();
END

IF @nBldQty IS NULL
BEGIN
	SET @nBldQty = 1;
END

SELECT @lKitIgnoreScrap = lKitIgnoreScrap
	FROM KitDef;

SELECT @lUsesetscrp = Usesetscrp 
	FROM Inventor
	WHERE Uniq_key = @cUniq_key;


/* -- Create top level */
-- 02/17/15 VL added status = 'Active'
-- 04/07/17 VL added functional currency code
INSERT @ZTop
	SELECT DISTINCT Bom_det.Uniq_key, Inventor.Part_sourc, Inventor.Stdcost, Bom_det.qty, 
		Inventor.U_of_meas,	Inventor.Scrap, Inventor.setupscrap, Inventor.Phant_make, Bom_det.Uniqbomno,
		Inventor.StdBldQty,	Inventor.StdcostPR 
	FROM Bom_det, Inventor
	WHERE Bom_det.Uniq_key = Inventor.Uniq_key	
	AND Bom_det.Bomparent = @cUniq_key
	AND (Eff_dt<=@dDue_Date OR Eff_dt IS NULL) 
	AND (Term_dt>@dDue_Date OR Term_dt IS NULL)
	AND Status = 'Active'
	ORDER BY Inventor.Part_sourc;

SET @lnTotalNo = @@ROWCOUNT;
	
IF (@lnTotalNo>0)
BEGIN	
	SET @lnCount=0;
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		
		SELECT @ZUniq_key = Uniq_key, @ZPart_Sourc = Part_sourc, @ZStdCost = StdCost, @ZQty = Qty,
			@ZU_of_meas = U_of_meas, @ZScrap = Scrap, @ZSetupScrap =SetupScrap, @ZPhant_Make = Phant_Make,
			@ZUniqBomNo = UniqBomNo, @ZStdBldQty = StdBldQty,
			-- 04/07/17 VL added functional currency code
			@ZStdCostPR = StdCostPR
		FROM @ZTop WHERE nrecno = @lnCount;

		IF (@@ROWCOUNT<>0)
		BEGIN
			/*-----------------------------------------------------------------------------------*/	
			IF @ZPart_Sourc<>'PHANTOM   ' AND NOT(@ZPart_sourc = 'MAKE      ' AND @ZPhant_make = 1)
			BEGIN
				IF (@lKitIgnoreScrap = 0)
					BEGIN
					SET @lnQtyReq = 
						CASE WHEN LEFT(@ZU_of_meas,2)='EA' THEN CEILING(@ZQty+(@ZQty*@ZScrap)/100)
							ELSE ROUND(@ZQty+(@ZQty*@ZScrap)/100,2)
						END;
					SET @lnQtyReqTotal =
						CASE WHEN LEFT(@ZU_of_meas,2)='EA' THEN CEILING(@nBldQty*@ZQty+(@nBldQty*@ZQty*@ZScrap)/100)
							ELSE ROUND(@nBldQty*@ZQty+(@nBldQty*@ZQty*@ZScrap)/100,2)
						END;
					SET	@lnQtyReqWithoutCEILING = @ZQty + ROUND(@ZQty*@ZScrap/100,2)
					SET @lnQtyReqTotalWithoutCEILING = ROUND(@nBldQty*@ZQty+@nBldQty*@ZQty*@ZScrap/100,2)
					END
				ELSE
					BEGIN
					SET @lnQtyReq = 
						CASE WHEN LEFT(@ZU_of_meas,2)='EA' THEN CEILING(@ZQty)
							ELSE ROUND(@ZQty,2)
						END;
					SET @lnQtyReqTotal =
						CASE WHEN LEFT(@ZU_of_meas,2)='EA' THEN CEILING(@nBldQty*@ZQty)
							ELSE ROUND(@nBldQty*@ZQty,2)
						END;
					SET @lnQtyReqWithoutCEILING = @ZQty;
					SET @lnQtyReqTotalWithoutCEILING = ROUND(@nBldQty*@ZQty,2);
					END

				IF @lKitIgnoreScrap = 0
					IF @lnQtyReq<>0 AND @lUsesetscrp =1
						IF @nStdBldQty <> 0
							BEGIN
							SET @lnCalcSetupScrap_cost = (@ZSetupscrap/@nStdBldQty)*@ZStdcost
							-- 04/07/17 VL added functional currency code
							SET @lnCalcSetupScrap_costPR = (@ZSetupscrap/@nStdBldQty)*@ZStdcostPR
							END
						ELSE
							BEGIN
							-- 04/07/17 VL added functional currency code
							SET @lnCalcSetupScrap_cost = @ZSetupscrap*@ZStdcost
							SET @lnCalcSetupScrap_costPR = @ZSetupscrap*@ZStdcostPR
							END
					ELSE
						BEGIN
						SET @lnCalcSetupScrap_cost = 0;
						-- 04/07/17 VL added functional currency code
						SET @lnCalcSetupScrap_costPR = 0;
						END
				ELSE
					BEGIN
					SET @lnCalcSetupScrap_cost = 0;
					-- 04/07/17 VL added functional currency code
					SET @lnCalcSetupScrap_costPR = 0;
					END
				
				-- 04/07/17 VL added functional currency code
				INSERT INTO @ZResult (Uniq_key, Part_Sourc, StdCost, Qty, U_of_meas, Scrap, SetupScrap, Phant_Make,
							UniqBomNo, Ext_cost, SetupScrap_Cost, Ext_cost_total, QtyReqTotal, StdBldQty, 
							Ext_costWithoutCEILING,	QtyReqWithoutCEILING, Ext_cost_totalWithoutCEILING, 
							QtyReqTotalWithoutCEILING, 
							StdCostPR, Ext_costPR, SetupScrap_CostPR, Ext_cost_totalPR, 
							Ext_costWithoutCEILINGPR, Ext_cost_totalWithoutCEILINGPR  )
					VALUES (@ZUniq_key, @ZPart_Sourc, @ZStdCost, @lnQtyReq, @ZU_of_meas, @ZScrap, @ZSetupScrap, @ZPhant_Make,
							@ZUniqBomNo, @lnQtyReq*@ZStdCost, @lnCalcSetupScrap_cost, @lnQtyReqTotal*@ZStdcost, @lnQtyReqTotal, @ZStdBldQty,
							@lnQtyReqWithoutCEILING * @ZStdcost, @lnQtyReqWithoutCEILING, @lnQtyReqTotalWithoutCEILING * @ZStdcost,
							@lnQtyReqTotalWithoutCEILING,
							@ZStdCostPR, @lnQtyReq*@ZStdCostPR, @lnCalcSetupScrap_costPR, @lnQtyReqTotal*@ZStdcostPR,
							@lnQtyReqWithoutCEILING * @ZStdcostPR, @lnQtyReqTotalWithoutCEILING * @ZStdcostPR);


			END	/* @ZPart_Sourc<>'PHANTOM   ' AND NOT(@ZPart_sourc = 'MAKE      ' AND @ZPhant_make = 1)*/

			/*-----------------------------------------------------------------------------------*/	
			IF @ZPart_Sourc='PHANTOM   ' OR (@ZPart_sourc='MAKE      ' AND @ZPhant_make = 1)
			BEGIN
				--INSERT INTO @Phantom2 EXEC [sp_PhantomSubSelect] @ZUniq_key, @ZQty, 'T', @dDue_Date, '', '', ''
				-- 08/28/12 VL added 9th parameter for leave parent part in dataset for f_PhantomSubSelect
				-- 12/01/14 VL delete @phantom2 and use @lnTableVarCnt to update nRecno, and change this field from identity to only int field
				DELETE FROM @Phantom2 WHERE 1 = 1
				SET @lnTableVarCnt = 0
				
				-- 02/12/15 VL changed to pass 'F' to @cMake and @cMakeBuy, not leave it empty, it would not get correct result in last SQL criteria
				-- 02/17/15 VL added to pass 0 to 10th parameter to fn_PhantomSubSelect to not pull inactive parts
				-- 04/07/17 VL added functional currency code
				
				-- 08/27/17 VL found the fields in fn_phantomsubSelect() are changed, so changed to list all fields not just insert @Phantom2 SELECT...
				--INSERT @Phantom2 
				--	SELECT Item_no, Part_no, Revision,Custpartno,Custrev,Part_class,Part_type,Descript,Qty, Scrap_qty, 
				--		StdCostper1Build,Bomparent,Uniq_key,Dept_id,Item_note,Offset,Term_dt, Eff_dt,Custno,U_of_meas,Inv_note,
				--		Part_sourc,Perpanel,Used_inkit, Scrap, SetupScrap,UniqBomNo,Buyer_type,StdCost,	Phant_make, Make_buy, 
				--		MatlType, TopStdCost,leadTime, UseSetScrp, SerialYes, StdBldQty, Reqqty, Level, 0 AS nRecno,
				--		StdCostper1BuildPR, StdCostPR, TopStdCostPR
				--FROM [dbo].[fn_PhantomSubSelect] (@ZUniq_key, @ZQty, 'T', @dDue_Date, 'F', '', 'F', @lKitIgnoreScrap,0, 0)

				INSERT @Phantom2 (Item_no,Part_no,Revision,Custpartno,Custrev,Part_class,Part_type,Descript,
	 					Qty, Scrap_qty,	StdCostper1Build, Scrap_Cost, SetupScrap_Cost, Sort,
						Bomparent,Uniq_key,Dept_id,Item_note,Offset,Term_dt,Eff_dt,Custno, U_of_meas, Inv_note,	Part_sourc, Perpanel,
						Used_inkit,Scrap,Setupscrap,UniqBomNo,Buyer_type,StdCost,Phant_make,Make_buy,MatlType,TopStdCost, LeadTime,UseSetScrp,SerialYes,StdBldQty,Level,Status,Reqqty, nRecno,
						StdCostper1BuildPR, StdCostPR, TopStdCostPR)
					SELECT Item_no,Part_no,Revision,Custpartno,Custrev,Part_class,Part_type,Descript,
	 					Qty, Scrap_qty,	StdCostper1Build, Scrap_Cost, SetupScrap_Cost, Sort,
						Bomparent,Uniq_key,Dept_id,Item_note,Offset,Term_dt,Eff_dt,Custno, U_of_meas, Inv_note,	Part_sourc, Perpanel,
						Used_inkit,Scrap,Setupscrap,UniqBomNo,Buyer_type,StdCost,Phant_make,Make_buy,MatlType,TopStdCost, LeadTime,UseSetScrp,SerialYes,StdBldQty,Level,Status,Reqqty, 0 AS Recno,
						StdCostper1BuildPR, StdCostPR, TopStdCostPR
					FROM [dbo].[fn_PhantomSubSelect] (@ZUniq_key, @ZQty, 'T', @dDue_Date, 'F', '', 'F', @lKitIgnoreScrap,0, 0)

				-- 08/17/16 VL Update Qty = Qty @Zqty because actually the level 0 is the level 1 in the whole bom because the level 0 is in @ZTop
				 --	09/30/16	 YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports
				--UPDATE @Phantom2 SET Qty = Qty*@ZQty WHERE Level = 0
				UPDATE @Phantom2 SET Qty = Qty*@ZQty WHERE Level = 1
				UPDATE @Phantom2 SET @lnTableVarCnt = nRecno = @lnTableVarCnt + 1
				
				SET @lnTotalNoP = @@ROWCOUNT;
				IF @lnTotalNoP > 0
				BEGIN	
					SET @lnCountP=0;
					WHILE @lnTotalNoP>@lnCountP
					BEGIN	
						SET @lnCountP=@lnCountP+1;
						SELECT @ZUniq_keyP = Uniq_key, @ZPart_SourcP = Part_sourc, @ZStdCostP = StdCost, @ZQtyP = Qty,
							@ZU_of_measP = U_of_meas, @ZScrapP = Scrap, @ZSetupScrapP =SetupScrap, @ZPhant_MakeP = Phant_Make,
							@ZUniqBomNoP = UniqBomNo,
							-- 04/07/17 VL added functional currency code
							@ZStdCostPPR = StdCostPR
							FROM @Phantom2 WHERE nrecno = @lnCountP
						IF (@@ROWCOUNT<>0)
						BEGIN
							IF @lKitIgnoreScrap = 0
								BEGIN
								SET @lnQtyReq = 
									CASE WHEN LEFT(@ZU_of_measP,2)='EA' THEN CEILING(@ZQtyP+(@ZQtyP*@ZScrapP)/100)
										ELSE ROUND(@ZQtyP+(@ZQtyP*@ZScrapP)/100,2)
									END
								SET @lnQtyReqTotal= 
									CASE WHEN LEFT(@ZU_of_measP,2)='EA' THEN CEILING(@nBldQty*@ZQtyP+(@nBldQty*@ZQtyP*@ZScrapP)/100)
										ELSE ROUND(@nBldQty*@ZQtyP+(@nBldQty*@ZQtyP*@ZScrapP)/100,2)
									END
								SET @lnQtyReqWithoutCEILING = @ZQtyP + ROUND(@ZQtyP*@ZScrapP/100,2)
								SET @lnQtyReqTotalWithoutCEILING = ROUND(@nBldQty*@ZQtyP+@nBldQty*@ZQtyP*@ZScrapP/100,2)
								END
							ELSE
								BEGIN
								SET @lnQtyReq = @ZQtyP
								SET @lnQtyReqTotal = 
									CASE WHEN LEFT(@ZU_of_measP,2)='EA' THEN CEILING(@nBldQty*@ZQtyP)
										ELSE @nBldQty*@ZQtyP
									END
								SET @lnQtyReqWithoutCEILING = @ZQtyP
								SET @lnQtyReqTotalWithoutCEILING = ROUND(@nBldQty*@ZQtyP,2)
								END

							IF @lKitIgnoreScrap = 0
								IF @lnQtyReq<>0 AND @lUsesetscrp =1
									IF @ZStdBldQty <> 0
										BEGIN
										SET @lnCalcSetupScrap_cost2 = (@ZSetupscrapP/@ZStdBldQty)*@ZStdcostP
										-- 04/07/17 VL added functional currency code
										SET @lnCalcSetupScrap_cost2PR = (@ZSetupscrapP/@ZStdBldQty)*@ZStdcostPPR
										END
									ELSE
										BEGIN
										SET @lnCalcSetupScrap_cost2 = @ZSetupscrapP*@ZStdcostP
										-- 04/07/17 VL added functional currency code
										SET @lnCalcSetupScrap_cost2PR = @ZSetupscrapP*@ZStdcostPPR
										END
								ELSE
									BEGIN
									SET @lnCalcSetupScrap_cost2 = 0
									-- 04/07/17 VL added functional currency code
									SET @lnCalcSetupScrap_cost2PR = 0
									END
							ELSE
								BEGIN
								SET @lnCalcSetupScrap_cost2 = 0
								-- 04/07/17 VL added functional currency code
								SET @lnCalcSetupScrap_cost2PR = 0
								END
							
							-- 04/07/17 VL added functional currency code
							INSERT INTO @ZResult (Uniq_key, Part_Sourc, StdCost, Qty, U_of_meas, Scrap, SetupScrap, Phant_Make,
										UniqBomNo, Ext_cost, SetupScrap_Cost, Ext_cost_total, QtyReqTotal, StdBldQty, 
										Ext_costWithoutCEILING,	QtyReqWithoutCEILING, Ext_cost_totalWithoutCEILING, 
										QtyReqTotalWithoutCEILING,
										StdCostPR, Ext_costPR, SetupScrap_CostPR, Ext_cost_totalPR, Ext_costWithoutCEILINGPR, Ext_cost_totalWithoutCEILINGPR)
								VALUES (@ZUniq_keyP, @ZPart_SourcP, @ZStdCostP, @lnQtyReq, @ZU_of_measP, @ZScrapP, @ZSetupScrapP, @ZPhant_MakeP,
										@ZUniqBomNoP, @lnQtyReq*@ZStdCostP, @lnCalcSetupScrap_cost2, @lnQtyReqTotal*@ZStdcostP, @lnQtyReqTotal, @ZStdBldQty ,
										@lnQtyReqWithoutCEILING * @ZStdcostP, @lnQtyReqWithoutCEILING, @lnQtyReqTotalWithoutCEILING * @ZStdcostP,
										@lnQtyReqTotalWithoutCEILING,
										@ZStdCostPPR, @lnQtyReq*@ZStdCostPPR, @lnCalcSetupScrap_cost2PR, @lnQtyReqTotal*@ZStdcostPPR, @lnQtyReqWithoutCEILING * @ZStdcostPPR,@lnQtyReqTotalWithoutCEILING * @ZStdcostPPR)

						END
					END
		
				END
			END
		END
	END
END

SELECT * FROM @ZResult
RETURN

END