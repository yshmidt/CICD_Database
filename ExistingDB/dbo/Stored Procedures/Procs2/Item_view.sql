-- ======================================================================
-- Author:		
-- Create date: 
-- Description:	Inventory
---Modified:
-- 11/20/14 VL added taxable for GST project
-- 10/05/16 VL added presentation currency fields	
-- 04/12/16 YS added Use IPkey
-- ======================================================================

CREATE proc [dbo].[Item_view] @gUniq_key as CHAR(10) ='' 
AS
SELECT Inventor.uniq_key, Inventor.part_class, Inventor.part_type,
  Inventor.custno, Inventor.part_no, Inventor.revision, Inventor.prod_id,
  Inventor.custpartno, Inventor.custrev, Inventor.descript,
  Inventor.u_of_meas, Inventor.pur_uofm, Inventor.ord_policy,
  Inventor.package, Inventor.no_pkg, Inventor.inv_note,
  Inventor.buyer_type, Inventor.stdcost, Inventor.minord, Inventor.ordmult,
  Inventor.usercost, Inventor.pull_in, Inventor.push_out,
  Inventor.ptlength, Inventor.ptwidth, Inventor.ptdepth, Inventor.fginote,
  Inventor.status, Inventor.perpanel, Inventor.abc, Inventor.layer,
  Inventor.ptwt, Inventor.grosswt, Inventor.reorderqty,
  Inventor.reordpoint, Inventor.part_spec, Inventor.pur_ltime,
  Inventor.pur_lunit, Inventor.kit_ltime, Inventor.kit_lunit,
  Inventor.prod_ltime, Inventor.prod_lunit, Inventor.udffield1,
  Inventor.wt_avg, Inventor.part_sourc, Inventor.insp_req,
  Inventor.cert_req, Inventor.cert_type, Inventor.scrap,
  Inventor.setupscrap, Inventor.outsnote, Inventor.bom_status,
  Inventor.bom_note, Inventor.bom_lastdt, Inventor.serialyes,
  Inventor.loc_type, Inventor.day, Inventor.dayofmo, Inventor.dayofmo2,
  Inventor.saletypeid, Inventor.feedback,
  Inventor.laborcost, Inventor.int_uniq, Inventor.require_sn,
  Inventor.phant_make, Inventor.bomcustno, Inventor.mrp_code,
  Inventor.make_buy, Inventor.labor_oh, Inventor.matl_oh,
  Inventor.matl_cost, Inventor.overhead, Inventor.other_cost,
  Inventor.configcost, Inventor.othercost2, Inventor.matdt, Inventor.labdt,
  Inventor.ohdt, Inventor.othdt, Inventor.oth2dt, Inventor.stddt,
  Inventor.eau, Inventor.stdbldqty, Inventor.usesetscrp, Inventor.is_ncnr,
  Inventor.toolrel, Inventor.toolreldt, Inventor.toolrelint,
  Inventor.pdmrel, Inventor.pdmreldt, Inventor.pdmrelint,
  Inventor.itemlock, Inventor.lockdt, Inventor.lockinit,
  Inventor.lastchangedt, Inventor.lastchangeinit, Inventor.bomlock,
  Inventor.bomlockinit, Inventor.bomlockdt, Inventor.bomlastinit,
  Inventor.routrel, Inventor.routreldt, Inventor.routrelint,
  Inventor.targetprice, Inventor.firstarticle, Inventor.mrc,
  Inventor.targetpricedt, Inventor.ppm, Inventor.matltype,
  Inventor.newitemdt, Inventor.mtchgdt, Inventor.mtchginit, INVENTOR.Eng_note,
  Inventor.Taxable, STDCOSTPR, USERCOSTPR, LABORCOSTPR, OHCOSTPR, MATL_COSTPR, useipkey,
  OVERHEADPR, OTHER_COSTPR, CONFIGCOSTPR, OTHERCOST2PR, TARGETPRICEPR, FUNCFCUSED_UNIQ,
  PRFCUSED_UNIQ
 FROM 
     inventor 
 WHERE  Inventor.uniq_key = @gUniq_Key