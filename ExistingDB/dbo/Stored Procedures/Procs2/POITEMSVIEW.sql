-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--10/08/13 YS added SUPLPARTNO for web manex
--10/17/13 YS added calculated fiedls for delta material cost and target price
-- 01/09/14 My mother's BD today. She is 85. Also I added lotdetail information for the web development. 
--01/21/14 YS added Cert_req from inventory 
-- 03/17/14 YS fix 'delta' price calculations
-- 10/09/14 YS removed invtmfhd table and replaced with 2 new tables
-- 01/23/15 VL added CosteachFC and extamntFC for FC project
-- 11/09/16 VL added presentation fields
-- =============================================
CREATE proc [dbo].[POITEMSVIEW] (@gcPoNum char(15) ='')
AS

SELECT Poitems.itemno,
  CASE WHEN Poitems.uniq_key<>'' THEN Inventor.part_no ELSE Poitems.part_no END AS part_view,
  CASE WHEN Poitems.uniq_key<>'' then Inventor.revision else Poitems.revision end AS rev_view,
  CASE WHEN Poitems.uniq_key<>'' then Inventor.part_class else Poitems.part_class end AS class_view,
  CASE WHEN Poitems.uniq_key<>'' then Inventor.part_type else Poitems.part_type end AS type_view,
  case when Poitems.uniq_key<>'' then Inventor.descript else Poitems.descript end AS descript_view,
  Poitems.ord_qty,Poitems.ord_qty-Poitems.acpt_qty AS balance,
  Poitems.costeach, Poitems.ord_qty*Poitems.costeach AS extamnt,
  Poitems.is_tax, Poitems.uniqlnno, Poitems.uniq_key, Poitems.ponum,
  Poitems.recv_qty, Poitems.rej_qty, Poitems.acpt_qty, Poitems.note1,
  Poitems.tax_pct, Poitems.is_contr, Poitems.overage, Poitems.poittype,
  Poitems.l_print, Poitems.no_pkg, Poitems.part_no, Poitems.revision,
  Poitems.descript, Poitems.partmfgr, Poitems.mfgr_pt_no, Poitems.package,
  Poitems.part_class, Poitems.part_type, Poitems.u_of_meas,
  Poitems.pur_uofm, Poitems.s_ord_qty,
  Poitems.isfirm,Poitems.firstarticle,Poitems.uniqmfgrhd,
  Poitems.inspexcept,Poitems.inspexception,ISNULL(Inventor.insp_req,CAST(0 as bit)) as Insp_req,
  ISNULL(Inventor.cert_req,CAST(0 as bit)) as cert_req,
  ISNULL(Inventor.stdcost,CAST(0.00 as numeric(13,5))) as StdCost, 
  ISNULL(Inventor.pur_ltime, CAST(0 as numeric(5,0))) as Pur_lTime, 
  ISNULL(Inventor.pur_lunit,CAST(' ' as CHAR(2))) as pur_lunit,
  ISNULL(Inventor.matl_cost,CAST(0.00 as numeric(13,5))) as Matl_Cost,
  ISNULL(Inventor.targetprice,CAST(0.00 as numeric(13,5))) as TargetPrice,
  ISNULL(Inventor.serialyes,CAST(0 as Bit)) AS serialyes, 
  ISNULL(Inventor.minord,CAST(0 as numeric(7,0))) as MinOrd,
  ISNULL(Inventor.ordmult,CAST(0 as numeric(7,0))) as OrdMult, Poitems.inspexcinit, Poitems.inspexcdt,
  Poitems.inspexcnote, Poitems.inspexcdoc, 
  ISNULL(M.autolocation,CAST(0 as bit)) as AutoLocation,
  CAST(0 as bit) AS lupdatestndcost, Poitems.lcancel, 
  ISNULL(M.matltype, CAST(' ' as CHAR(10))) as Matltype,
  ISNULL(M.LDISALLOWBUY , CAST(0 as bit)) as LDISALLOWBUY,
  Poitems.uniqmfsp, Poitems.inspectionote,
 --10/08/13 YS added supplier part number to the output
  cast(ISNULL(Invtmfsp.SUPLPARTNO,'') as varchar(30)) as SupplierPartNumber ,
  --10/08/13 YS conver costeach from purchase UOM to stock UOM
  cast(dbo.fn_convertPrice('Pur',Poitems.COSTEACH ,Poitems.PUR_UOFM ,poitems.U_OF_MEAS ) as numeric(13,5)) as CostEachSUM,
   --10/08/13 YS conver stdcost from stock UOM to purchase UOM 
   CAST(CASE WHEN Inventor.stdcost IS null  THEN 0.00 else
   dbo.fn_convertPrice('Stk',Inventor.stdcost ,Poitems.PUR_UOFM ,poitems.U_OF_MEAS) END as numeric(13,5)) as StdCostPUM,
   --10/08/13 YS conver targetprice from stock UOM to purchase UOM 
   CAST(CASE WHEN Inventor.targetprice IS null  THEN 0.00 else
	dbo.fn_convertPrice('Stk',Inventor.targetprice ,Poitems.PUR_UOFM ,poitems.U_OF_MEAS ) END as numeric(13,5)) as targetpricePUM,
   --10/08/13 YS conver material cost from stock UOM to purchase UOM 
   CAST(CASE WHEN Inventor.Matl_Cost IS null  THEN 0.00 else
	dbo.fn_convertPrice('Stk',Inventor.Matl_Cost ,Poitems.PUR_UOFM ,poitems.U_OF_MEAS ) END as numeric(13,5)) as Matl_CostPUM,
  -- 10/17/13 YS added delta cost for PUOM only. If target or material cost is 0 then delat will be 0
  -- 03/17/14 YS move 'end' for case prior to - Poitems.COSTEACH
  cast(CASE WHEN Inventor.Matl_Cost IS NULL OR Inventor.Matl_Cost =0.00 THEN CAST(0 as numeric(13,5))  
		ELSE dbo.fn_convertPrice('Stk',Inventor.Matl_Cost ,Poitems.PUR_UOFM ,poitems.U_OF_MEAS ) END - Poitems.COSTEACH as  numeric(13,5)) as MatlCostDeltaPUOM,
  -- 10/17/13 YS added delta cost for PUOM only. If target or material cost is 0 then delat will be 0
   -- 03/17/14 YS move 'end' for case prior to - Poitems.COSTEACH
  cast(CASE WHEN Inventor.targetprice IS NULL OR Inventor.targetprice =0 THEN  CAST(0 as numeric(13,5)) 
		ELSE dbo.fn_convertPrice('Stk',Inventor.targetprice ,Poitems.PUR_UOFM ,poitems.U_OF_MEAS ) END - Poitems.COSTEACH  as  numeric(13,5)) as TargetPriceDeltaPUOM,
  --01/09/14 YS added lot information
  ISNULL(Parttype.LotDetail,cast(0 as bit)) as LotDetail,
  ISNULL(PartType.Autodt,CAST(0 as bit)) as Autodt,
  ISNULL(Parttype.FgiExpDays,cast(0 as int)) as FgiExpDays,
  -- 01/23/15 VL added CosteachFC and extamntFC for FC project
  POITEMS.lRemvRcv ,Poitems.costeachFC, Poitems.ord_qty*Poitems.costeachFC AS extamntFC,
  -- 11/09/16 VL added Presentation currency fields
  Poitems.costeachPR, Poitems.ord_qty*Poitems.costeachPR AS extamntPR,
  ISNULL(Inventor.stdcostPR,CAST(0.00 as numeric(13,5))) as StdCostPR, ISNULL(Inventor.matl_costPR,CAST(0.00 as numeric(13,5))) as Matl_CostPR,
  ISNULL(Inventor.targetpricePR,CAST(0.00 as numeric(13,5))) as TargetPricePR,
  --10/08/13 YS conver costeach from purchase UOM to stock UOM
  cast(dbo.fn_convertPrice('Pur',Poitems.COSTEACHPR ,Poitems.PUR_UOFM ,poitems.U_OF_MEAS ) as numeric(13,5)) as CostEachSUMPR,
   --10/08/13 YS conver stdcost from stock UOM to purchase UOM 
   CAST(CASE WHEN Inventor.stdcostPR IS null  THEN 0.00 else
   dbo.fn_convertPrice('Stk',Inventor.stdcostPR ,Poitems.PUR_UOFM ,poitems.U_OF_MEAS) END as numeric(13,5)) as StdCostPUMPR,
   --10/08/13 YS conver targetprice from stock UOM to purchase UOM 
   CAST(CASE WHEN Inventor.targetpricePR IS null  THEN 0.00 else
	dbo.fn_convertPrice('Stk',Inventor.targetpricePR ,Poitems.PUR_UOFM ,poitems.U_OF_MEAS ) END as numeric(13,5)) as targetpricePUMPR,
   --10/08/13 YS conver material cost from stock UOM to purchase UOM 
   CAST(CASE WHEN Inventor.Matl_CostPR IS null  THEN 0.00 else
	dbo.fn_convertPrice('Stk',Inventor.Matl_CostPR ,Poitems.PUR_UOFM ,poitems.U_OF_MEAS ) END as numeric(13,5)) as Matl_CostPUMPR,
  -- 10/17/13 YS added delta cost for PUOM only. If target or material cost is 0 then delat will be 0
  -- 03/17/14 YS move 'end' for case prior to - Poitems.COSTEACH
  cast(CASE WHEN Inventor.Matl_CostPR IS NULL OR Inventor.Matl_CostPR =0.00 THEN CAST(0 as numeric(13,5))  
		ELSE dbo.fn_convertPrice('Stk',Inventor.Matl_CostPR ,Poitems.PUR_UOFM ,poitems.U_OF_MEAS ) END - Poitems.COSTEACHPR as  numeric(13,5)) as MatlCostDeltaPUOMPR,
  -- 10/17/13 YS added delta cost for PUOM only. If target or material cost is 0 then delat will be 0
   -- 03/17/14 YS move 'end' for case prior to - Poitems.COSTEACH
  cast(CASE WHEN Inventor.targetpricePR IS NULL OR Inventor.targetprice =0 THEN  CAST(0 as numeric(13,5)) 
		ELSE dbo.fn_convertPrice('Stk',Inventor.targetpricePR ,Poitems.PUR_UOFM ,poitems.U_OF_MEAS ) END - Poitems.COSTEACHPR  as  numeric(13,5)) as TargetPriceDeltaPUOMPR
 FROM 
    poitems 
    LEFT OUTER JOIN inventor 
   ON  Poitems.uniq_key = Inventor.uniq_key 
    -- 10/09/14 YS removed invtmfhd table and replaced with 2 new tables
	LEFT OUTER JOIN InvtMPNLink L
   ON  Poitems.uniqmfgrhd = l.uniqmfgrhd
   LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
   LEFT OUTER JOIN Invtmfsp 
   ON Poitems.UNIQMFSP=Invtmfsp.UNIQMFSP
   LEFT OUTER JOIN PARTTYPE on Inventor.UNIQ_KEY IS not NULL and Inventor.PART_CLASS=PARTTYPE.PART_CLASS and Inventor.PART_TYPE =PartType.PART_TYPE 
 WHERE  Poitems.ponum = @gcponum
 ORDER BY Poitems.itemno