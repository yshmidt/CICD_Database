-- =============================================
-- Author:		Yelena
-- Create date: <Create Date,,>
-- Description:	
--- Modified : 07/29/14 YS removed columns from invt_rec table
--				10/09/14 YS replace invtmfhd table with 2 new tables
  ---02/02/17 YS serialno removed from database
-- =============================================
CREATE proc [dbo].[Invt_rec_view] 
	@pcW_key char(10)=null
as 

---10/09/14 YS replace invtmfhd table with 2 new tables
	SELECT Invt_rec.w_key, Invt_rec.uniq_key,
  Invt_rec.date, Invt_rec.qtyrec, 
  Invt_rec.commrec, Invt_rec.gl_nbr, Invt_rec.is_rel_gl, Invt_rec.stdcost,
  Invt_rec.gl_nbr_inv, Invt_rec.invtrec_no,
  Invt_rec.u_of_meas, WAREHOUS.WAREHOUSE,INVTMFGR.LOCATION,
  M.partmfgr, M.mfgr_pt_no, Invt_rec.lotcode,
  Invt_rec.expdate, Invt_rec.reference, Invt_rec.saveinit,
  Inventor.part_class,Inventor.part_type, Inventor.custno, Inventor.part_no, Inventor.revision,
  Inventor.custpartno, Inventor.custrev,
  Inventor.descript, Inventor.inv_note, Inventor.part_sourc,
  Inventor.loc_type, Warehous.wh_descr, Warehous.wh_gl_nbr,
  Warehous.wh_note, Invtmfgr.Uniqwh,Warehous.Whno,
  Invt_rec.transref, INVENTOR.SERIALYES,
  Invt_rec.uniq_lot,Invt_rec.uniqmfgrhd, Inventor.ordmult 
  ---02/02/17 YS removed from database
  --Serialno, Serialuniq 
 FROM inventor INNER JOIN Invt_rec ON Invt_rec.uniq_key = Inventor.uniq_key
 INNER JOIN invtmfgr ON Invt_rec.w_key = Invtmfgr.w_key 
 INNER JOIN Warehous ON Invtmfgr.Uniqwh = Warehous.Uniqwh 
 INNER JOIN InvtMPNLink L ON Invt_rec.UNIQMFGRHD=L.Uniqmfgrhd
 INNER JOIN MfgrMaster M ON L.MfgrMasterId=M.MfgrMasterId 
 WHERE InvtMfgr.W_key=@pcW_key