-- =============================================
-- Author:		<Vicky Lu>
-- Create date: <07/08/2010>
-- Description:	<Get all BOM records including phantom parts>
-- Modified: 
--			05/20/11 VL added @lIgnoreScrap parameter, and added StdBldQty
--			08/20/12 VL Added Scrap_cost which has only runtime scrap and SetupScrap_cost which is only Setup scrap for BOM report purpose
--			08/21/12 VL Added one more parameter @lLeaveParentPart, Debbie added Sort field
--			02/08/15 YS problem when phantom part doesn't have any parts to explode, the phantom will still stay on the kit list and says it short
--			02/12/15 VL Foudn the qty calculated in req qty was incorrect
--			02/17/15 VL Inovar reported that Kit pull inactive parts, so added another parameter to pull/not pull inactive parts
--			05/20/15 VL added Phant_make <> 1 in last criteria to not show parent parts
--			08/27/15 VL changed StdCostper1Build from numeric(14,6) to numeric(29,5), Inovar has really bit number and caused overflow, bom_qty numeric(9,2), bld_qty numeric(7,0) and stdcost numeric(13,5)
--						CASE WHEN (@nNeedQty*Bom_det.Qty<=999999.99) THEN CAST(@nNeedQty *Bom_det.Qty AS numeric(9,2)) ELSE 999999.99 END AS Qty, to
--						CASE WHEN (@nNeedQty*Bom_det.Qty<=9999999999.99) THEN CAST(@nNeedQty *Bom_det.Qty AS numeric(12,2)) ELSE 9999999999.99 END AS Qty
--						Also added CAST() for ReqQty
--- 05/17/16 YS added qty_each to kamain table (qty column has total to build all build qty w/o the scrap). I need also to see original bom.qty
--			06/28/16 VL Debbie found that the phantom part scrap cost showed it's own cost, actually,it should multiple with top part number qty, so changed Scrap_Cost to multiple it's parent qty
--			06/28/16 VL Also multiply parent qty for TopStdCost field 
--	09/30/16	 YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports
--  03/09/17 YS This is just a note, nochanges are made: Aloha Team using Kamain.Qty to save Qty_each from this result
--	04/10/17 VL added functional currency code
--	04/11/17 VL also found a changes I did on 06/21/16 was not here: VL EMI reported an issue that Kamain.Qty used to save Bom_det.qty value, but now it's not.  VL found because we used recursive SQL, so the top level record is also mutiple with nNeedQty
--				I will add one more bom_det.qty field in the recursive SQL, and in the last SQL statement if level = 0, use bom_det.qty as qty, not whatever calculated qty 
--  on 09/01/2017 Rajendra K - Removed Select statement from union all to exclude records from make type parts 
--   10/20/17 YS reverse changes by Rajendra done on 09/01/17
-- 08/05/20 VL Found an issue that the sp_RollupCost that used in CONFG variance, MFGR variance and JOB COST, the calculation of required qty does use stdbldqty to caculate, 
-- and the SetupScrap/StdBldQty * BldQty, not like here just directly add the scrap, so changed here to work the same way to consider Stdbldqty
-- 08/28/20 VL found the () for CEILING() and ROUND() was not in correct places
-- 01/18/21 VL changed how setup scrap is calculated should not *Qty, should * the bldqty, if the bom qty <> 1, the old formula calculated extra required qty
-- =============================================
CREATE FUNCTION [dbo].[fn_phantomSubSelect]
(
	-- Add the parameters for the function here
	@cTopUniq_key char(10)='', @nNeedQty numeric(7,0) = 0,
	@cChkDate char(1)='', @dDate smalldatetime, @cMake char(3)='', @cKitInUse char(40)='', 
	@cMakeBuy char(1)='', @lIgnoreScrap bit = 0, @lLeaveParentPart bit = 0, @lGetInactivePart bit = 0
	
	-- Parameters:
	-- @cTopUniq_key - the top BOM parent uniq_key
	-- @nNeedQty - Required qty
	-- @cChkDate - Need to check date or not -- 'T' or 'F'
	-- @dDate - The WO due date
	-- @cMake - Want to explore MAKE part or not -- 'T' or 'F'
	-- @cKitInUse - Kit in use or not -- 'T' or 'F' or 'ALL'
	-- @cMakeBuy - if need to explore Make_Buy
	-- @lIgnoreScrap - calculate scrap or not, kit, costroll, MRP calculation can ignore scrap
	-- @lLeaveParentPart - Filter out the parent part numbers from the record set or not
	-- @lGetInactivePart - Include inactive parts
		
	-- Example from SO how to use it
	-- lcExpr=[']+SodetailView.Uniq_key+[', 1, 'T', ']+lDate+[', 'F', 'ALL', 'F',0,0,0]
	-- pnReturn=ThisForm.oDataTier.mCallTVFunction([fn_PhantomSubSelect(]+lcExpr+[)])
	-- SELECT * FROM SQLResult INTO CURSOR Phantom
	
	-- Example how to call it in SQL 
	-- SELECT * FROM [dbo].[fn_PhantomSubSelect] ('_1CR0TVFHM', 1, 'T', GETDATE(), 'F', 'T', 'F', 0);
)
RETURNS TABLE 
AS
RETURN
(

WITH BomExplode as 
 (
 -- 02/12/15 VL found should not use 1 to multiple Bom_det.Qty, should use top level @nNeedQty to multiple, and at bottom when calculating ReqQty, don't multiple @nNeedQty
  SELECT Bom_det.Item_no,I1.Part_no,I1.Revision,I1.Custpartno,I1.Custrev,I1.Part_class,I1.Part_type,I1.Descript,
		CASE WHEN (@nNeedQty*Bom_det.Qty<=9999999999.99) THEN CAST(@nNeedQty *Bom_det.Qty AS numeric(12,2)) ELSE 9999999999.99 END AS Qty, 
		CAST(ROUND((@nNeedQty*Bom_det.Qty*I1.Scrap)/100,2) AS numeric(9,2)) AS Scrap_qty,
		CAST(ROUND(CASE WHEN (1=0 OR Bom_Det.Qty=0.00) THEN 0000000.000000 
		ELSE Bom_Det.Qty * (CASE WHEN @nNeedQty=0 THEN 1000000/1000000 ELSE @nNeedQty END) * I1.StdCost * (1 + I1.Scrap/100)
		+CASE WHEN (I1.SetUpScrap<>0 AND I2.usesetscrp = 1 AND I2.StdBldQty<>0) THEN (I1.SetUpScrap*I1.StdCost)/I2.StdBldQty ELSE 0000000.00000 END END,5) AS numeric(29,5)) AS StdCostper1Build, 
		CAST(ROUND(CASE WHEN (1=0 OR Bom_Det.Qty=0.00) THEN 0000000.000000 
		ELSE Bom_Det.Qty * 1000000/1000000 * I1.StdCost * (1 + I1.Scrap/100) END,5) AS numeric(14,6)) AS Scrap_Cost, 
		CAST(ROUND(CASE WHEN (I1.SetUpScrap<>0 AND I2.usesetscrp = 1 AND I2.StdBldQty<>0 AND Bom_Det.Qty<>0.00) THEN (I1.SetUpScrap*I1.StdCost)/I2.StdBldQty ELSE 0000000.00000 END,5) AS numeric(14,6)) AS SetupScrap_Cost, 		
		CAST(dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY Item_no) as varchar(max))),4,'0') as varchar(max)) AS Sort,
		Bomparent,Bom_det.Uniq_key,Bom_det.Dept_id,Bom_det.Item_note,Bom_det.Offset,Bom_det.Term_dt,Bom_det.Eff_dt,I1.Custno,
		I1.U_of_meas,I1.Inv_note,
		I1.Part_sourc,I1.Perpanel,Bom_det.Used_inkit,I1.Scrap,I1.Setupscrap,Bom_det.UniqBomNo,I1.Buyer_type,I1.StdCost,I1.Phant_make,I1.Make_buy,I1.MatlType,
		-- 06/28/16 VL added ROUND()
		--Bom_det.Qty*I1.StdCost AS TopStdCost,
		CAST(ROUND(Bom_det.Qty*I1.StdCost,5) AS numeric(20,5)) AS TopStdCost,
		LeadTime = 
		CASE 
			WHEN I1.Part_Sourc = 'PHANTOM' THEN 0000
			WHEN I1.Part_Sourc = 'MAKE' AND I1.Make_Buy = 0 THEN 
				CASE 
					WHEN I1.Prod_lunit = 'DY' THEN I1.Prod_ltime
					WHEN I1.Prod_lunit = 'WK' THEN I1.Prod_ltime * 5
					WHEN I1.Prod_lunit = 'MO' THEN I1.Prod_ltime * 20
					ELSE I1.Prod_ltime
				END +
				CASE 
					WHEN I1.Kit_lunit = 'DY' THEN I1.Kit_ltime
					WHEN I1.Kit_lunit = 'WK' THEN I1.Kit_ltime * 5
					WHEN I1.Kit_lunit = 'MO' THEN I1.Kit_ltime * 20
					ELSE I1.Kit_ltime
				END
			ELSE
				CASE
					WHEN I1.Pur_lunit = 'DY' THEN I1.Pur_ltime
					WHEN I1.Pur_lunit = 'WK' THEN I1.Pur_ltime * 5
					WHEN I1.Pur_lunit = 'MO' THEN I1.Pur_ltime * 20
					ELSE I1.Pur_ltime
				END
		END,
		I2.UseSetScrp,
		I1.SerialYes,
		I2.StdBldQty,
		 --	09/30/16	 YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports
		 -- 03/09/17 YS Aloha Team using Kamain.Qty to save Qty_each from this result
		CAST(1 as Integer) as Level,
		I1.Status,cast(Bom_det.Qty as numeric(12,2)) as Qty_each,
		-- 06/21/16 VL added next line
		Bom_det.Qty AS BomQty,
		-- {04/10/17 VL added functional currency code
		CAST(ROUND(CASE WHEN (1=0 OR Bom_Det.Qty=0.00) THEN 0000000.000000 
		ELSE Bom_Det.Qty * (CASE WHEN @nNeedQty=0 THEN 1000000/1000000 ELSE @nNeedQty END) * I1.StdCostPR * (1 + I1.Scrap/100)
		+CASE WHEN (I1.SetUpScrap<>0 AND I2.usesetscrp = 1 AND I2.StdBldQty<>0) THEN (I1.SetUpScrap*I1.StdCostPR)/I2.StdBldQty ELSE 0000000.00000 END END,5) AS numeric(29,5)) AS StdCostper1BuildPR, 
		CAST(ROUND(CASE WHEN (1=0 OR Bom_Det.Qty=0.00) THEN 0000000.000000 
		ELSE Bom_Det.Qty * 1000000/1000000 * I1.StdCostPR * (1 + I1.Scrap/100) END,5) AS numeric(14,6)) AS Scrap_CostPR, 
		CAST(ROUND(CASE WHEN (I1.SetUpScrap<>0 AND I2.usesetscrp = 1 AND I2.StdBldQty<>0 AND Bom_Det.Qty<>0.00) THEN (I1.SetUpScrap*I1.StdCostPR)/I2.StdBldQty ELSE 0000000.00000 END,5) AS numeric(14,6)) AS SetupScrap_CostPR, 		
		I1.StdCostPR,
		CAST(ROUND(Bom_det.Qty*I1.StdCostPR,5) AS numeric(20,5)) AS TopStdCostPR
		-- 04/10/17 VL End}
		FROM Bom_det,Inventor I1, Inventor I2
		WHERE Bom_det.Uniq_key=I1.Uniq_key
		AND Bom_det.Bomparent = @cTopUniq_key
		AND I2.Uniq_key = @cTopUniq_key
		AND BOM_DET.USED_INKIT = CASE WHEN (@cKitInUse = 'T' OR @cKitInUse = '' OR @cKitInUse = 'ONLY') THEN 'Y'
			WHEN (@cKitInUse = 'F' OR @cKitInUse = 'NOT') THEN 'N'
			ELSE BOM_DET.USED_INKIT END
		AND 1 =
			CASE @cChkDate
				WHEN 'T' THEN CASE WHEN (Eff_dt is null or DATEDIFF(day,EFF_DT,ISNULL(@dDate,EFF_DT))>=0)
				AND (Term_dt is Null or DATEDIFF(day,ISNULL(@dDate,TERM_DT),term_dt)>0)  THEN 1 ELSE 0 END
			ELSE 1
			END
		AND 1 = CASE @lGetInactivePart WHEN 0 THEN CASE WHEN I1.Status = 'Active' THEN 1 ELSE 0 END ELSE 1 END
		
	--Removed Select statement from union all to exclude records from make type parts on 09/01/2017 - Rajendra K
UNION ALL

SELECT B2.Item_no,I1.Part_no,I1.Revision,I1.Custpartno,I1.Custrev,I1.Part_class,I1.Part_type,I1.Descript,
		CASE WHEN (P.Qty*B2.Qty<=9999999999.99) THEN CAST(P.Qty*B2.Qty AS numeric(12,2)) ELSE 9999999999.99 END AS Qty, 
		CAST(ROUND((P.Qty*B2.Qty*I1.Scrap)/100,2) AS numeric(9,2)) AS Scrap_qty,
		CAST(ROUND(CASE WHEN (P.Qty=0 OR B2.Qty=0.00) THEN 0000000.000000 
		ELSE P.Qty * B2.Qty * I1.StdCost * (1 + I1.Scrap/100)
		+CASE WHEN (I1.SetUpScrap<>0 AND I2.usesetscrp = 1 AND I2.StdBldQty<>0) THEN (I1.SetUpScrap*I1.StdCost)/I2.StdBldQty ELSE 0000000.00000 END END,5) AS numeric(29,5)) AS StdCostper1Build, 
		-- 06/28/16 VL changed Scrap_cost not just use B2.Qty, use B2.Qty*(CASE WHEN (P.Qty*B2.Qty<=9999999999.99) THEN CAST(P.Qty*B2.Qty AS numeric(12,2)) ELSE 9999999999.99 END)
		--CAST(ROUND(CASE WHEN (1=0 OR B2.Qty=0.00) THEN 0000000.000000 
		--ELSE B2.Qty * 1000000/1000000 * I1.StdCost * (1 + I1.Scrap/100) END,5) AS numeric(14,6)) AS Scrap_Cost, 
		CAST(ROUND(CASE WHEN (1=0 OR (CASE WHEN (P.Qty*B2.Qty<=9999999999.99) THEN CAST(P.Qty*B2.Qty AS numeric(12,2)) ELSE 9999999999.99 END)=0.00) THEN 0000000.000000 
		ELSE (CASE WHEN (P.Qty*B2.Qty<=9999999999.99) THEN CAST(P.Qty*B2.Qty AS numeric(12,2)) ELSE 9999999999.99 END) * 1000000/1000000 * I1.StdCost * (1 + I1.Scrap/100) END,5) AS numeric(14,6)) AS Scrap_Cost, 
		CAST(ROUND(CASE WHEN (I1.SetUpScrap<>0 AND I2.usesetscrp = 1 AND I2.StdBldQty<>0 AND B2.Qty<>0.00) THEN (I1.SetUpScrap*I1.StdCost)/I2.StdBldQty ELSE 0000000.00000 END,5) AS numeric(14,6)) AS SetupScrap_Cost, 				
		CAST(RTRIM(P.Sort)+'-'+	dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY b2.Item_no) as varchar(4))),4,'0') as varchar(max)) AS Sort,
		B2.Bomparent,B2.Uniq_key,B2.Dept_id,B2.Item_note,B2.Offset,B2.Term_dt,B2.Eff_dt,I1.Custno,
		I1.U_of_meas,I1.Inv_note,
		I1.Part_sourc,I1.Perpanel,B2.Used_inkit,I1.Scrap,I1.Setupscrap,B2.UniqBomNo,I1.Buyer_type,I1.StdCost,I1.Phant_make,I1.Make_buy,I1.MatlType,
		-- 06/28/16 VL multiply parent qty
		--B2.Qty*I1.StdCost AS TopStdCost,
		CAST(ROUND(P.Qty*B2.Qty*I1.StdCost,5) AS numeric(20,5)) AS TopStdCost,
		LeadTime = 
		CASE 
			WHEN I1.Part_Sourc = 'PHANTOM' THEN 0000
			WHEN I1.Part_Sourc = 'MAKE' AND I1.Make_Buy = 0 THEN 
				CASE 
					WHEN I1.Prod_lunit = 'DY' THEN I1.Prod_ltime
					WHEN I1.Prod_lunit = 'WK' THEN I1.Prod_ltime * 5
					WHEN I1.Prod_lunit = 'MO' THEN I1.Prod_ltime * 20
					ELSE I1.Prod_ltime
				END +
				CASE 
					WHEN I1.Kit_lunit = 'DY' THEN I1.Kit_ltime
					WHEN I1.Kit_lunit = 'WK' THEN I1.Kit_ltime * 5
					WHEN I1.Kit_lunit = 'MO' THEN I1.Kit_ltime * 20
					ELSE I1.Kit_ltime
				END
			ELSE
				CASE
					WHEN I1.Pur_lunit = 'DY' THEN I1.Pur_ltime
					WHEN I1.Pur_lunit = 'WK' THEN I1.Pur_ltime * 5
					WHEN I1.Pur_lunit = 'MO' THEN I1.Pur_ltime * 20
					ELSE I1.Pur_ltime
				END
		END,
		P.UseSetScrp,
		I1.SerialYes,
		I2.StdBldQty,
		P.Level+1,
		I1.Status,
		--- 05/17/16 YS added qty_each to kamain table (qty column has total to build all build qty w/o the scrap). I need original bom.qty
		-- 03/09/17 YS Aloha Team using Kamain.Qty to save Qty_each from this result
		cast(P.Qty_each*B2.Qty as numeric(12,2)) as Qty_each,
		-- 06/21/16 VL added next line
		B2.Qty AS BomQty,
		-- {04/10/17 VL added functional currency code
		CAST(ROUND(CASE WHEN (P.Qty=0 OR B2.Qty=0.00) THEN 0000000.000000 
		ELSE P.Qty * B2.Qty * I1.StdCostPR * (1 + I1.Scrap/100)
		+CASE WHEN (I1.SetUpScrap<>0 AND I2.usesetscrp = 1 AND I2.StdBldQty<>0) THEN (I1.SetUpScrap*I1.StdCostPR)/I2.StdBldQty ELSE 0000000.00000 END END,5) AS numeric(29,5)) AS StdCostper1BuildPR, 
		-- 06/28/16 VL changed Scrap_cost not just use B2.Qty, use B2.Qty*(CASE WHEN (P.Qty*B2.Qty<=9999999999.99) THEN CAST(P.Qty*B2.Qty AS numeric(12,2)) ELSE 9999999999.99 END)
		--CAST(ROUND(CASE WHEN (1=0 OR B2.Qty=0.00) THEN 0000000.000000 
		--ELSE B2.Qty * 1000000/1000000 * I1.StdCost * (1 + I1.Scrap/100) END,5) AS numeric(14,6)) AS Scrap_Cost, 
		CAST(ROUND(CASE WHEN (1=0 OR (CASE WHEN (P.Qty*B2.Qty<=9999999999.99) THEN CAST(P.Qty*B2.Qty AS numeric(12,2)) ELSE 9999999999.99 END)=0.00) THEN 0000000.000000 
		ELSE (CASE WHEN (P.Qty*B2.Qty<=9999999999.99) THEN CAST(P.Qty*B2.Qty AS numeric(12,2)) ELSE 9999999999.99 END) * 1000000/1000000 * I1.StdCostPR * (1 + I1.Scrap/100) END,5) AS numeric(14,6)) AS Scrap_CostPR, 
		CAST(ROUND(CASE WHEN (I1.SetUpScrap<>0 AND I2.usesetscrp = 1 AND I2.StdBldQty<>0 AND B2.Qty<>0.00) THEN (I1.SetUpScrap*I1.StdCostPR)/I2.StdBldQty ELSE 0000000.00000 END,5) AS numeric(14,6)) AS SetupScrap_CostPR, 				
		I1.StdCostPR,
		-- 06/28/16 VL multiply parent qty
		--B2.Qty*I1.StdCost AS TopStdCost,
		CAST(ROUND(P.Qty*B2.Qty*I1.StdCostPR,5) AS numeric(20,5)) AS TopStdCostPR
		-- 04/10/17 VL End}
		FROM BomExplode AS P INNER JOIN BOM_DET AS B2 ON P.Uniq_key = B2.BOMPARENT
		INNER JOIN Inventor I1 ON B2.UNIQ_KEY = I1.Uniq_key, Inventor I2
		WHERE I2.Uniq_key = P.Uniq_key
		AND 1 = CASE WHEN (@cMake = 'T' AND @cMakeBuy = 'T') THEN CASE WHEN (P.Part_sourc='PHANTOM' OR P.Part_sourc='MAKE') THEN 1 ELSE 0 END
				WHEN (@cMake = 'T' AND @cMakeBuy <> 'T') THEN CASE WHEN (P.Part_sourc='PHANTOM' OR (P.Part_sourc='MAKE' AND P.Make_Buy = 0)) THEN 1 ELSE 0 END
				ELSE CASE WHEN (P.Part_sourc='PHANTOM' OR P.Phant_make = 1) THEN 1 ELSE 0 END
				END
		AND B2.USED_INKIT = CASE WHEN (@cKitInUse = 'T' OR @cKitInUse = '' OR @cKitInUse = 'ONLY') THEN 'Y'
			WHEN (@cKitInUse = 'F' OR @cKitInUse = 'N' OR @cKitInUse = 'NOT') THEN 'N'
			ELSE B2.USED_INKIT END
		AND 1 =
			CASE @cChkDate
				WHEN 'T' THEN CASE WHEN (B2.Eff_dt is null or DATEDIFF(day,B2.EFF_DT,ISNULL(@dDate,B2.EFF_DT))>=0)
				AND (B2.Term_dt is Null or DATEDIFF(day,ISNULL(@dDate,B2.TERM_DT),B2.term_dt)>0)  THEN 1 ELSE 0 END
			ELSE 1
			END	
		AND Level < 100
		AND 1 = CASE @lGetInactivePart WHEN 0 THEN CASE WHEN I1.Status = 'Active' THEN 1 ELSE 0 END ELSE 1 END
 )
-- Filter out parent parts from record set
-- {06/21/16 VL list all fields because now the 'qty' field is different in top level
--SELECT BomExplode.*,
SELECT Item_no,Part_no,Revision,Custpartno,Custrev,Part_class,Part_type,Descript,
	 --	09/30/16	 YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports
	CASE WHEN Level = 1 THEN BomQty ELSE Qty END AS Qty, Scrap_qty,	StdCostper1Build, Scrap_Cost, SetupScrap_Cost, Sort,
		Bomparent,Uniq_key,Dept_id,Item_note,Offset,Term_dt,Eff_dt,Custno, U_of_meas, Inv_note,	Part_sourc, Perpanel,
		Used_inkit,Scrap,Setupscrap,UniqBomNo,Buyer_type,StdCost,Phant_make,Make_buy,MatlType,TopStdCost, LeadTime,UseSetScrp,SerialYes,StdBldQty,Level,Status,Qty_each,

-- 06/21/16 VL End}
-- 02/12/15 VL found should not multiple  with @nNeedQty, it should be already multiple in BomExplode, here just times scrap
	--CASE WHEN @lIgnoreScrap = 0 THEN 
	--		CASE WHEN LEFT(U_of_meas,2)='EA' THEN 
	--				CEILING((Qty*@nNeedQty)+(Qty*@nNeedQty*Scrap)/100)+CASE WHEN UseSetScrp = 1 AND Qty<>0 AND @nNeedQty<>0 THEN SetupScrap ELSE 0 END	
	--			ELSE
	--				ROUND((Qty*@nNeedQty)+(Qty*@nNeedQty*Scrap)/100,2)+CASE WHEN UseSetScrp = 1 AND Qty<>0 AND @nNeedQty<>0 THEN SetupScrap ELSE 0 END
	--			END 
	--	ELSE
	--		CASE WHEN LEFT(U_of_meas,2)='EA' THEN
	--				CEILING(Qty*@nNeedQty) 
	--			ELSE
	--				ROUND(Qty*@nNeedQty,2)
	--			END
	--	END	AS ReqQty

	-- 08/05/20 VL Found an issue that the sp_RollupCost that used in CONFG variance, MFGR variance and JOB COST, the calculation of required qty does use stdbldqty to caculate, 
	-- and the SetupScrap/StdBldQty * BldQty, not like here just directly add the scrap, so changed here to work the same way to consider Stdbldqty
	--CASE WHEN @lIgnoreScrap = 0 THEN 
	--		CASE WHEN LEFT(U_of_meas,2)='EA' THEN 
	--				CAST(CEILING((Qty)+(Qty*Scrap)/100)+CASE WHEN UseSetScrp = 1 AND Qty<>0 THEN SetupScrap ELSE 0 END AS Numeric(12,2))	
	--			ELSE
	--				CAST(ROUND((Qty)+(Qty*Scrap)/100,2)+CASE WHEN UseSetScrp = 1 AND Qty<>0 THEN SetupScrap ELSE 0 END AS Numeric(12,2))
	--			END 
	--	ELSE
	--		CASE WHEN LEFT(U_of_meas,2)='EA' THEN
	--				CAST(CEILING(Qty) AS Numeric(12,2))
	--			ELSE
	--				CAST(ROUND(Qty,2) AS Numeric(12,2))
	--			END
	--	END	AS ReqQty,
	-- 08/05/20 VL added new code
	CASE WHEN @lIgnoreScrap = 0 THEN 
			CASE WHEN LEFT(U_of_meas,2)='EA' THEN 
					-- 08/28/20 VL found the () for CEILING() and ROUND() was not in correct places
					--CAST(CEILING((Qty)+(Qty*Scrap)/100)+CASE WHEN UseSetScrp = 1 AND Qty<>0 THEN SetupScrap/(CASE WHEN Stdbldqty > 0 THEN StdBldqty ELSE 1 END)*Qty ELSE 0 END AS Numeric(12,2))	
					-- 01/18/21 VL changed how setup scrap is calculated should not *Qty, should * the bldqty
					--CAST(CEILING((Qty)+(Qty*Scrap)/100 + CASE WHEN UseSetScrp = 1 AND Qty<>0 THEN SetupScrap/(CASE WHEN Stdbldqty > 0 THEN StdBldqty ELSE 1 END)*Qty ELSE 0 END) AS Numeric(12,2))	
					CAST(CEILING((Qty)+(Qty*Scrap)/100 + CASE WHEN UseSetScrp = 1 AND Qty<>0 THEN SetupScrap/(CASE WHEN Stdbldqty > 0 THEN StdBldqty ELSE 1 END)*@nNeedQty ELSE 0 END) AS Numeric(12,2))	
				ELSE
					-- 08/28/20 VL found the () for CEILING() and ROUND() was not in correct places
					--CAST(ROUND((Qty)+(Qty*Scrap)/100,2)+CASE WHEN UseSetScrp = 1 AND Qty<>0 THEN SetupScrap/(CASE WHEN Stdbldqty > 0 THEN StdBldqty ELSE 1 END)*Qty ELSE 0 END AS Numeric(12,2))
					-- 01/18/21 VL changed how setup scrap is calculated should not *Qty, should * the bldqty
					--CAST(ROUND((Qty)+(Qty*Scrap)/100 + CASE WHEN UseSetScrp = 1 AND Qty<>0 THEN SetupScrap/(CASE WHEN Stdbldqty > 0 THEN StdBldqty ELSE 1 END)*Qty ELSE 0 END, 2) AS Numeric(12,2))
					CAST(ROUND((Qty)+(Qty*Scrap)/100 + CASE WHEN UseSetScrp = 1 AND Qty<>0 THEN SetupScrap/(CASE WHEN Stdbldqty > 0 THEN StdBldqty ELSE 1 END)*@nNeedQty ELSE 0 END, 2) AS Numeric(12,2))
				END 
		ELSE
			CASE WHEN LEFT(U_of_meas,2)='EA' THEN
					CAST(CEILING(Qty) AS Numeric(12,2))
				ELSE
					CAST(ROUND(Qty,2) AS Numeric(12,2))
				END
		END	AS ReqQty,

		-- 04/10/17 VL added functional currency code
		StdCostper1BuildPR, Scrap_CostPR, SetupScrap_CostPR, StdCostPR, TopStdCostPR
FROM BomExplode 
--WHERE UNIQ_KEY NOT IN (SELECT DISTINCT Bomparent FROM BomExplode)
-- 02/08/15 YS problem when phantom part doesn't have any parts to explode, the phantom will still stay on the kit list and says it short
--WHERE UNIQ_KEY NOT IN (SELECT DISTINCT Bomparent FROM BomExplode WHERE 1 = CASE WHEN @lLeaveParentPart = 0 THEN 1 ELSE 2 END))

WHERE @lLeaveParentPart=1 OR 
	-- 05/20/15 VL added Phant_make <> 1
	--(@lLeaveParentPart=0 and  @cMake = 'F' and @cMakeBuy='F' and Part_sourc<>'PHANTOM')
	(@lLeaveParentPart=0 and  @cMake = 'F' and @cMakeBuy='F' and Part_sourc<>'PHANTOM' ANd Phant_make <> 1)
	OR (@lLeaveParentPart=0 and  @cMake = 'T' and @cMakeBuy='F' and Part_sourc<>'PHANTOM' and (Part_sourc<>'MAKE' or make_buy=1)
	OR (@lLeaveParentPart=0 and  @cMake = 'T' and @cMakeBuy='T' and Part_sourc<>'PHANTOM' and Part_sourc<>'MAKE') 
	)
	)