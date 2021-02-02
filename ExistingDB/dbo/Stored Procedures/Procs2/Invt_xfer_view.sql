-- =============================================
-- Author:		???
-- Create date: ???
-- Description:	Invttrns
-- Modified:	10/09/14 YS removed invtmfhd table and repalce with 2 new tables
 ---02/02/17 YS seriialno removed from table
 -- 10/27/17 YS fr/to ipkey is removed from this table
-- =============================================
CREATE proc [dbo].[Invt_xfer_view] 
 @gUniq_Key char(10)=null
as 
--10/09/14 YS removed invtmfhd table and repalce with 2 new tables
SELECT Invttrns.uniq_key, Invttrns.date,
  Invttrns.qtyxfer, Invttrns.fromwkey, Invttrns.towkey,
  Invttrns.gl_nbr, Invttrns.gl_nbr_inv, Invttrns.reason, Invttrns.stdcost,
  Invttrns.is_rel_gl, Invttrns.invtxfer_n, Invttrns.u_of_meas,INVTTRNS.Uniq_lot,
  Invttrns.lotcode, Invttrns.expdate, Invttrns.reference,Invttrns.ponum,
  Invttrns.saveinit, Invttrns.cModId,INVTTRNS.LSKIPUNALLOCCODE ,INVTTRNS.Wono, 
  Inventor.part_class, Inventor.part_type, Inventor.custno,
  Inventor.part_no, Inventor.revision, Inventor.custpartno,
  Inventor.custrev, Inventor.descript, Inventor.part_sourc, Inventor.inv_note,INVENTOR.SERIALYES ,
  m.partmfgr, m.mfgr_pt_no, 
  FromWh.Whno as FromWhno,FromMfgr.UniqWh as FromUniqWh,FromMfgr.location as FromLocation,FromWh.warehouse as FromWarehouse,  
  ToWh.Whno as ToWhno,ToMfgr.UniqWh as ToUniqwh,ToMfgr.location as ToLocation,ToWh.warehouse as ToWarehouse,  
   Invttrns.transref, 
    ---02/02/17 YS seriialno removed from table
   --Invttrns.serialno,
  ---Invttrns.serialuniq,
  Invttrns.uniqmfgrhd, 
   -- 10/27/17 YS fr/to ipkey is removed from this table
 -- Invttrns.fr_ipkeyuniq, Invttrns.to_ipkeyuniq,
 CAST(0 as bit) AS ipkeylblprint
 FROM inventor,invttrns, InvtMPNLink L, MfgrMaster M,invtmfgr FromMfgr,invtmfgr ToMfgr,warehous FromWh,WAREHOUS ToWh
 WHERE   Invttrns.uniq_key =  @gUniq_Key 
   AND  l.uniqmfgrhd = INVTTRNS.uniqmfgrhd 
   AND l.MfgrMasterid=m.mfgrmasterid
   AND  FromWh.UniqWh = Frommfgr.UniqWh
   AND ToWh.UNIQWH=ToMfgr.UNIQWH
   and INVTTRNS.FROMWKEY =FromMfgr.W_KEY 
   and INVTTRNS.TOWKEY = ToMfgr.W_KEY