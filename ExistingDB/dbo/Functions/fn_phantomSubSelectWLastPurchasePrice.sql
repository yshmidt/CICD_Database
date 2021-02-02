 ----=============================================
 ----Author:		<Vicky Lu>
 ----Create date: <07/08/2010>
 ----Description:	<Get all BOM records including phantom parts>
 ----Modified: 
	----		05/20/11 VL added @lIgnoreScrap parameter, and added StdBldQty
	----		08/20/12 VL Added Scrap_cost which has only runtime scrap and SetupScrap_cost which is only Setup scrap for BOM report purpose
	----		08/21/12 VL Added one more parameter @lLeaveParentPart, Debbie added Sort field
	----		02/08/15 YS problem when phantom part doesn't have any parts to explode, the phantom will still stay on the kit list and says it short
	----		02/12/15 VL Foudn the qty calculated in req qty was incorrect
	----		02/17/15 VL Inovar reported that Kit pull inactive parts, so added another parameter to pull/not pull inactive parts
	--			05/20/15 VL added Phant_make <> 1 in last criteria to not show parent parts
	--  06/05/15 YS convert procedure to use last purchase price in place of the standard cost. Replace stdcost with LastPoCost ( see my comments inside)
	-- 06/11/15 YS fixed second sub select to point to the correct record for the component
	--			08/27/15 VL changed LastPoCostper1Build from numeric(14,6) to numeric(29,5), Inovar has really bit number and caused overflow, bom_qty numeric(9,2), bld_qty numeric(7,0) and stdcost numeric(13,5)
	--						CASE WHEN (@nNeedQty*Bom_det.Qty<=999999.99) THEN CAST(@nNeedQty *Bom_det.Qty AS numeric(9,2)) ELSE 999999.99 END AS Qty, to
	--						CASE WHEN (@nNeedQty*Bom_det.Qty<=9999999999.99) THEN CAST(@nNeedQty *Bom_det.Qty AS numeric(12,2)) ELSE 9999999999.99 END AS Qty
	--						Also added CAST() for ReqQty
	--			06/21/16 VL EMI reported an issue that Kamain.Qty used to save Bom_det.qty value, but now it's not.  VL found because we used recursive SQL, so the top level record is also mutiple with nNeedQty
	--						I will add one more bom_det.qty field in the recursive SQL, and in the last SQL statement if level = 0, use bom_det.qty as qty, not whatever calculated qty 
	--			06/28/16 VL Debbie found that the phantom part scrap cost showed it's own cost, actually,it should multiple with top part number qty, so changed Scrap_Cost to multiple it's parent qty
	--			06/28/16 VL Also multiply parent qty for TopStdCost field 
	 --	09/30/16	 YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports
	 --08/14/17 YS added columns for functional currency
-- 05/08/19 VL Changed to use order date or edit date system setup to get the POs
-- 07/31/19 VL Found the Qty column didn't calculate right.  It needs to multiply the qty from parent for level>1, created Qty_each column but leave the Qty field along, will change to use qty_each as Qty in KitBominfoview, KitAutoKitView, sp_updEcowo
-- 08/05/20 VL Found an issue that the sp_RollupCost that used in CONFG variance, MFGR variance and JOB COST, the calculation of required qty does use stdbldqty to caculate, 
-- and the SetupScrap/StdBldQty * BldQty, not like here just directly add the scrap, so changed here to work the same way to consider Stdbldqty
-- 08/28/20 VL found the () for CEILING() and ROUND() was not in correct places
-- 01/18/21 VL changed how setup scrap is calculated should not *Qty, should * the bldqty, if the bom qty <> 1, the old formula calculated extra required qty
 ----=============================================
CREATE FUNCTION [dbo].[fn_phantomSubSelectWLastPurchasePrice]
(
	-- Add the parameters for the function here
	
	@cTopUniq_key char(10)='', 
	@nNeedQty numeric(7,0) = 0,
	@cChkDate char(1)='', 
	@dDate smalldatetime, 
	@cMake char(3)='', 
	@cKitInUse char(40)='', 
	@cMakeBuy char(1)='', 
	@lIgnoreScrap bit = 0, 
	@lLeaveParentPart bit = 0, 
	@lGetInactivePart bit = 0
	
	
)
RETURNS TABLE 
AS
RETURN
(

-- 05/08/19 VL added to get system setup PO hist by
WITH ZPoHistBy AS (SELECT nPoHistBy FROM Invtsetup),
BomExplode as 
 (
  --06/05/15 YS added last po price for items and replace any stdcost with last po price
  --06/05/15 Avinash: Fetching a PO details where PO is closed or open and lcancel is false.
  SELECT Bom_det.Item_no,I1.Part_no,I1.Revision,I1.Custpartno,I1.Custrev,I1.Part_class,I1.Part_type,I1.Descript,
		CASE WHEN (@nNeedQty*Bom_det.Qty<=9999999999.99) THEN CAST(@nNeedQty *Bom_det.Qty AS numeric(12,2)) ELSE 9999999999.99 END AS Qty, 
		CAST(ROUND((@nNeedQty*Bom_det.Qty*I1.Scrap)/100,2) AS numeric(9,2)) AS Scrap_qty,
		CAST(ROUND(CASE WHEN (1=0 OR Bom_Det.Qty=0.00) THEN .0000000000000 
		ELSE Bom_Det.Qty * (CASE WHEN @nNeedQty=0 THEN 1000000/1000000 ELSE @nNeedQty END) * 
		isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACH,I1.U_of_meas,I1.PUR_UOFM),0.00) * (1 + I1.Scrap/100)+ CASE WHEN (I1.SetUpScrap<>0 AND I2.usesetscrp = 1 AND I2.StdBldQty<>0) 
		THEN (I1.SetUpScrap*isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACH,I1.U_of_meas,I1.PUR_UOFM) ,0.00))/I2.StdBldQty 
		ELSE 0000000.00000 END END,5) AS numeric(29,5)) AS LastPoCostper1Build, 
		CAST(ROUND(CASE WHEN (1=0 OR Bom_Det.Qty=0.00) THEN 0000000.000000 
		ELSE Bom_Det.Qty * 1000000/1000000 * ISNULL(dbo.[fn_convertPrice]('Pur',POI.COSTEACH,I1.U_of_meas,I1.PUR_UOFM),0.00) * (1 + I1.Scrap/100) END,5) AS numeric(14,6)) AS Scrap_Cost, 
		CAST(ROUND(CASE WHEN (I1.SetUpScrap<>0 AND I2.usesetscrp = 1 AND I2.StdBldQty<>0 AND Bom_Det.Qty<>0.00) THEN (I1.SetUpScrap*isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACH,I1.U_of_meas,I1.PUR_UOFM),0.00))/I2.StdBldQty ELSE 0000000.00000 END,5) AS numeric(14,6)) AS SetupScrap_Cost, 		
		CAST(dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY Item_no) as varchar(max))),4,'0') as varchar(max)) AS Sort,
		Bomparent,Bom_det.Uniq_key,Bom_det.Dept_id,Bom_det.Item_note,Bom_det.Offset,Bom_det.Term_dt,Bom_det.Eff_dt,I1.Custno,
		I1.U_of_meas,I1.Inv_note,
		I1.Part_sourc,I1.Perpanel,Bom_det.Used_inkit,I1.Scrap,I1.Setupscrap,
		Bom_det.UniqBomNo,I1.Buyer_type,isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACH,I1.U_of_meas,I1.PUR_UOFM),0.00) as costeach,
		I1.Phant_make,I1.Make_buy,I1.MatlType,
		-- 06/28/16 VL added ROUND()
		--Bom_det.Qty*isnull(POI.COSTEACH ,0.00) AS TopLastPoCost,
		CAST(ROUND(Bom_det.Qty*isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACH,I1.U_of_meas,I1.PUR_UOFM) ,0.00),5) AS numeric(20,5)) AS TopLastPoCost,
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
		CAST(1 as Integer) as Level,
		I1.Status,
		-- 06/21/16 VL added next line
		Bom_det.Qty AS BomQty,
		---08/14/17 YS added currency
		CAST(ROUND(CASE WHEN (1=0 OR Bom_Det.Qty=0.00) THEN .0000000000000 
		ELSE Bom_Det.Qty * (CASE WHEN @nNeedQty=0 THEN 1000000/1000000 ELSE @nNeedQty END) * 
		isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACHPR,I1.U_of_meas,I1.PUR_UOFM),0.00) * (1 + I1.Scrap/100)+ CASE WHEN (I1.SetUpScrap<>0 AND I2.usesetscrp = 1 AND I2.StdBldQty<>0) 
		THEN (I1.SetUpScrap*isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACHPR,I1.U_of_meas,I1.PUR_UOFM) ,0.00))/I2.StdBldQty 
		ELSE 0000000.00000 END END,5) AS numeric(29,5)) AS LastPoCostper1BuildPR, 
		CAST(ROUND(CASE WHEN (1=0 OR Bom_Det.Qty=0.00) THEN 0000000.000000 
		ELSE Bom_Det.Qty * 1000000/1000000 * ISNULL(dbo.[fn_convertPrice]('Pur',POI.COSTEACHPR,I1.U_of_meas,I1.PUR_UOFM),0.00) * (1 + I1.Scrap/100) END,5) AS numeric(14,6)) AS Scrap_CostPR, 
		CAST(ROUND(CASE WHEN (I1.SetUpScrap<>0 AND I2.usesetscrp = 1 AND I2.StdBldQty<>0 AND Bom_Det.Qty<>0.00) THEN (I1.SetUpScrap*isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACHPR,I1.U_of_meas,I1.PUR_UOFM),0.00))/I2.StdBldQty ELSE 0000000.00000 END,5) AS numeric(14,6)) AS SetupScrap_CostPR, 		
		isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACHPR,I1.U_of_meas,I1.PUR_UOFM),0.00) as costeachPr,
		CAST(ROUND(Bom_det.Qty*isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACHpr,I1.U_of_meas,I1.PUR_UOFM) ,0.00),5) AS numeric(20,5)) AS TopLastPoCostpr
		-- 07/31/19 VL added bom_det.Qty as Qty_each
		,CAST(Bom_det.Qty as numeric(12,2)) as Qty_each
		FROM Bom_det INNER JOIN Inventor I1 ON Bom_det.Uniq_key=I1.Uniq_key  --- compoents
		INNER JOIN Inventor I2 ON Bom_det.Bomparent=I2.Uniq_key  -- top part
		--08/14/17 YS added columns for functional currency
		OUTER APPLY (select top 1 COSTEACH,costeachpr,pomain.Ponum,VerDate,uniq_key from poitems inner join pomain on pomain.ponum=poitems.ponum
		and (pomain.postatus='OPEN' or POmain.POSTATUS='CLOSED') and POItems.LCANCEL=0 
		and poitems.uniq_key=bom_det.uniq_key
		-- 05/08/19 VL Changed to use order date or edit date system setup to get the POs
		--order by verdate desc ) POI
		CROSS APPLY ZPoHistBy
		order by CASE WHEN ZPoHistBy.nPoHistBy = 1 THEN PoDate ELSE VERDATE END desc ) POI
		WHERE 
		Bom_det.Bomparent = @cTopUniq_key
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
			
UNION ALL

--06/05/15 Avinash: Fetching a PO details where PO is closed or open and lcancel is false.
 -- 06/11/15 YS fixed second sub select to point to the correct record for the component
SELECT B2.Item_no,I1.Part_no,I1.Revision,I1.Custpartno,I1.Custrev,I1.Part_class,I1.Part_type,I1.Descript,
		CASE WHEN (P.Qty*B2.Qty<=9999999999.99) THEN CAST(P.Qty*B2.Qty AS numeric(12,2)) ELSE 9999999999.99 END AS Qty, 
		CAST(ROUND((P.Qty*B2.Qty*I1.Scrap)/100,2) AS numeric(9,2)) AS Scrap_qty,
		CAST(ROUND(CASE WHEN (P.Qty=0 OR B2.Qty=0.00) THEN 0000000.000000 
		ELSE P.Qty * B2.Qty * isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACH,I1.U_of_meas,I1.PUR_UOFM),0.00) * (1 + I1.Scrap/100)
		+CASE WHEN (I1.SetUpScrap<>0 AND I2.usesetscrp = 1 AND I2.StdBldQty<>0) THEN (I1.SetUpScrap*isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACH,I1.U_of_meas,I1.PUR_UOFM),0.00))/I2.StdBldQty ELSE 0000000.00000 END END,5) AS numeric(29,5)) AS LastPoCostper1Build, 
		-- 06/28/16 VL changed Scrap_cost not just use B2.Qty, use B2.Qty*(CASE WHEN (P.Qty*B2.Qty<=9999999999.99) THEN CAST(P.Qty*B2.Qty AS numeric(12,2)) ELSE 9999999999.99 END)
		--CAST(ROUND(CASE WHEN (1=0 OR B2.Qty=0.00) THEN 0000000.000000 
		--ELSE B2.Qty * 1000000/1000000 * isnull(POI.COSTEACH,0.00) * (1 + I1.Scrap/100) END,5) AS numeric(14,6)) AS Scrap_Cost, 
		CAST(ROUND(CASE WHEN (1=0 OR (CASE WHEN (P.Qty*B2.Qty<=9999999999.99) THEN CAST(P.Qty*B2.Qty AS numeric(12,2)) ELSE 9999999999.99 END)=0.00) THEN 0000000.000000 
		ELSE (CASE WHEN (P.Qty*B2.Qty<=9999999999.99) THEN CAST(P.Qty*B2.Qty AS numeric(12,2)) ELSE 9999999999.99 END)* 1000000/1000000 * isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACH,I1.U_of_meas,I1.PUR_UOFM),0.00) * (1 + I1.Scrap/100) END,5) AS numeric(14,6)) AS Scrap_Cost, 
		CAST(ROUND(CASE WHEN (I1.SetUpScrap<>0 AND I2.usesetscrp = 1 AND I2.StdBldQty<>0 AND B2.Qty<>0.00) THEN (I1.SetUpScrap*isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACH,I1.U_of_meas,I1.PUR_UOFM),0.00))/I2.StdBldQty ELSE 0000000.00000 END,5) AS numeric(14,6)) AS SetupScrap_Cost, 				
		CAST(RTRIM(P.Sort)+'-'+	dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY b2.Item_no) as varchar(4))),4,'0') as varchar(max)) AS Sort,
		B2.Bomparent,B2.Uniq_key,B2.Dept_id,B2.Item_note,B2.Offset,B2.Term_dt,B2.Eff_dt,I1.Custno,
		I1.U_of_meas,I1.Inv_note,
		I1.Part_sourc,I1.Perpanel,B2.Used_inkit,I1.Scrap,I1.Setupscrap,B2.UniqBomNo,I1.Buyer_type,
		isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACH,I1.U_of_meas,I1.PUR_UOFM),0.00) as costeach,I1.Phant_make,I1.Make_buy,I1.MatlType,
		-- 06/28/16 VL multiply parent qty
		--B2.Qty*isnull(POI.COSTEACH,0.00) AS TopLastPoCost,
		CAST(ROUND(P.Qty*B2.Qty*isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACH,I1.U_of_meas,I1.PUR_UOFM),0.00),5) AS numeric(20,5)) AS TopLastPoCost,
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
		-- 06/21/16 VL added next line
		B2.Qty AS BomQty,
		---08/14/17 YS added currency
		CAST(ROUND(CASE WHEN (P.Qty=0 OR B2.Qty=0.00) THEN 0000000.000000 
		ELSE P.Qty * B2.Qty * isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACHPR,I1.U_of_meas,I1.PUR_UOFM),0.00) * (1 + I1.Scrap/100)
		+CASE WHEN (I1.SetUpScrap<>0 AND I2.usesetscrp = 1 AND I2.StdBldQty<>0) THEN (I1.SetUpScrap*isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACHPR,I1.U_of_meas,I1.PUR_UOFM),0.00))/I2.StdBldQty ELSE 0000000.00000 END END,5) AS numeric(29,5)) AS LastPoCostper1BuildPR, 
		CAST(ROUND(CASE WHEN (1=0 OR (CASE WHEN (P.Qty*B2.Qty<=9999999999.99) THEN CAST(P.Qty*B2.Qty AS numeric(12,2)) ELSE 9999999999.99 END)=0.00) THEN 0000000.000000 
		ELSE (CASE WHEN (P.Qty*B2.Qty<=9999999999.99) THEN CAST(P.Qty*B2.Qty AS numeric(12,2)) ELSE 9999999999.99 END)* 1000000/1000000 * isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACHpr,I1.U_of_meas,I1.PUR_UOFM),0.00) * (1 + I1.Scrap/100) END,5) AS numeric(14,6)) AS Scrap_CostPR, 
		CAST(ROUND(CASE WHEN (I1.SetUpScrap<>0 AND I2.usesetscrp = 1 AND I2.StdBldQty<>0 AND B2.Qty<>0.00) THEN (I1.SetUpScrap*isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACHpr,I1.U_of_meas,I1.PUR_UOFM),0.00))/I2.StdBldQty ELSE 0000000.00000 END,5) AS numeric(14,6)) AS SetupScrap_CostPR, 				
		isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACHpr,I1.U_of_meas,I1.PUR_UOFM),0.00) as costeachPr,
		CAST(ROUND(P.Qty*B2.Qty*isnull(dbo.[fn_convertPrice]('Pur',POI.COSTEACHpr,I1.U_of_meas,I1.PUR_UOFM),0.00),5) AS numeric(20,5)) AS TopLastPoCostPr
		-- 07/31/19 VL added bom_det.Qty as Qty_each
		,CAST(P.Qty_each*B2.Qty AS numeric(12,2)) as Qty_each
		FROM BomExplode AS P 
		INNER JOIN BOM_DET AS B2 ON P.Uniq_key = B2.BOMPARENT  -- sub assembly parent
		INNER JOIN Inventor I1 on B2.Uniq_key=I1.uniq_key -- components for sub-assembly
		INNER JOIN Inventor I2 ON B2.BOMPARENT = I2.Uniq_key  -- part info for subassembly
		-- 05/08/19 VL added ZPoHistBy
		CROSS APPLY ZPoHistBy
		OUTER APPLY (select COSTEACH,costeachpr,pomain.Ponum,VerDate,uniq_key, 
		-- 05/08/19 VL Changed to use order date or edit date system setup to get the POs
		--row_NUMBER() OVER (partition by poitems.uniq_key order by verdate desc) as n,
		row_NUMBER() OVER (partition by poitems.uniq_key order by CASE WHEN ZPoHistBy.nPoHistBy = 1 THEN PoDate ELSE VERDATE END desc) as n
		from poitems inner join pomain on pomain.ponum=poitems.ponum
		and (pomain.postatus='OPEN' or POmain.POSTATUS='CLOSED') and POItems.LCANCEL=0 
		and poitems.uniq_key=B2.uniq_key
		) POI
		WHERE  (poi.n=1 or poi.n is null)
		and 1 = CASE WHEN (@cMake = 'T' AND @cMakeBuy = 'T') THEN CASE WHEN (P.Part_sourc='PHANTOM' OR P.Part_sourc='MAKE') THEN 1 ELSE 0 END
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
-- {06/21/16 VL list all fields because now the 'qty' field is different in top level
--SELECT BomExplode.*,
SELECT Item_no,Part_no,Revision,Custpartno,Custrev,Part_class,Part_type,Descript,
	 --	09/30/16	 YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports
	CASE WHEN Level = 1 THEN BomQty ELSE Qty END AS Qty, Scrap_qty,	LastPoCostper1Build, Scrap_Cost, SetupScrap_Cost, Sort,
		Bomparent,Uniq_key,Dept_id,Item_note,Offset,Term_dt,Eff_dt,Custno, U_of_meas, Inv_note,	Part_sourc, Perpanel,
		Used_inkit,Scrap,Setupscrap,UniqBomNo,Buyer_type,costeach,Phant_make,Make_buy,MatlType,TopLastPoCost, LeadTime,UseSetScrp,SerialYes,StdBldQty,Level,Status, 
-- 06/21/16 VL End}
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
		---08/14/17 YS added currency
		LastPoCostper1Buildpr, Scrap_Costpr, SetupScrap_CostPR,TopLastPoCostpr,costeachPr
		-- 07/31/19 VL added bom_det.Qty as Qty_each
		,Qty_each
	FROM BomExplode 
-- 05/20/15 VL added Phant_make <> 1
WHERE @lLeaveParentPart=1 OR 
	(@lLeaveParentPart=0 and  @cMake = 'F' and @cMakeBuy='F' and Part_sourc<>'PHANTOM' ANd Phant_make <> 1)
	OR (@lLeaveParentPart=0 and  @cMake = 'T' and @cMakeBuy='F' and Part_sourc<>'PHANTOM' and (Part_sourc<>'MAKE' or make_buy=1)
	OR (@lLeaveParentPart=0 and  @cMake = 'T' and @cMakeBuy='T' and Part_sourc<>'PHANTOM' and Part_sourc<>'MAKE') 
	)
	)