-- =============================================
-- Author:		???
-- Create date: ???
-- Description:	Inventory issue 
-- Modified: 10/09/14 YS removed invtmfhd table and replace with 2 new tables
--02/02/17 YS remove serialno fileds from the invt_isu table
-- 03/18/20 VL added kaseqnum column
-- 08/08/20 VL added fk_userid column
-- =============================================
CREATE proc [dbo].[invt_isu_view]
@gUniq_Key char(10) = null
as
 -- 10/09/14 YS removed invtmfhd table and replace with 2 new tables
SELECT Invt_isu.w_key, Invt_isu.uniq_key, Invt_isu.issuedto,
  Invt_isu.qtyisu, Invt_isu.date, Invt_isu.u_of_meas, Invt_isu.gl_nbr,
  Invt_isu.invtisu_no, Invt_isu.gl_nbr_inv, Invt_isu.Wono, Invt_isu.is_rel_gl,
  Invt_isu.lotcode, Invt_isu.expdate, Invt_isu.reference,
  Invt_isu.saveinit, Inventor.part_class,
  INVENTOR.SERIALYES ,
  Inventor.part_type, Inventor.custno, Inventor.part_no, Inventor.revision,
  Inventor.prod_id, Inventor.custpartno, Inventor.custrev,
  Inventor.descript, Inventor.inv_note, Inventor.part_sourc,WAREHOUS.WHNO,INVTMFGR.UNIQWH,
  Warehous.warehouse, Warehous.wh_descr, Warehous.wh_gl_nbr,
  M.partmfgr, M.mfgr_pt_no, Invtmfgr.qty_oh,
  Invtmfgr.reserved, Invtmfgr.netable, Invtmfgr.location,
  Invtmfgr.instore, Invtmfgr.Uniqsupno, Invt_isu.stdcost,
  Invt_isu.ponum, Invt_isu.transref, 
  --02/02/17 YS remove serialno fileds from the invt_isu table
  --Invt_isu.serialno,
  --02/02/17 YS remove serialno fileds from the invt_isu table
  --Invt_isu.serialuniq,
  Invt_isu.instorereturn, Invt_isu.uniqmfgrhd, 
  Invt_isu.deptkey,  Invt_isu.actvkey, Invt_isu.cModId,
  Invt_isu.lSkipUnAllocCode , SPACE(10) as Uniq_lot, uniqueln, 1.0 AS nSavePriority, Invt_isu.Kaseqnum,
  Invt_isu.fk_userid
 	FROM Invt_isu INNER JOIN Inventor ON Invt_isu.uniq_key=Inventor.UNIQ_KEY
	INNER JOIN Invtmfgr ON Invtmfgr.w_key = Invt_isu.w_key 
	INNER JOIN Warehous ON Warehous.Uniqwh = Invtmfgr.Uniqwh
	INNER JOIN InvtMPNLink L ON Invtmfgr.UNIQMFGRHD=L.UniqMfgrhd
	INNER JOIN MfgrMaster M ON L.MfgrMasterId=M.MfgrMasterId 
 WHERE  Invt_isu.uniq_key =  @gUniq_Key 
   