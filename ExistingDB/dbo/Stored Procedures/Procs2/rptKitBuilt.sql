-- =============================================
-- Author:		Vicky Lu
-- Create date: 09/10/2013
-- Description:	As Kit Built Report
-- Report Name:	kitbuilt
-- Modified:	10/10/2013 DRP:  After review of the code that Vicky originally provided.  inserted code so that I could indicate the line shortages or phantom items. 
--					  			 Also updated some fields so that they would not display null values. 
--								 Inserted Phantom and PhParentPn fields to we can reference on the report the Phantom Parent Part number. 
--				10/17/2013 DRP:	 I had to move two lines from the FROM section up to be with the BOM_Det.  The way I had it before was causing the Line Shortages to not be included in the results. 
-- 03/12/15 YS replaced invtmfhd table with 2 new tables	
-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record
--- 03/21/19 YS rewrote the code. Kalocate table was removed. Keep the old code for reference and remove later
--04/05/19 YS added balance qty for the lot if available or manufcature
-- 10/14/19 VL added ipkey/MTC, CAPA ticket #1979
-- 11/11/20 YS added wono to the output
-- 12/07/20 VL: mnxSettingsManagement.settingname was changed from 'Suppress Not Used in Kit items ?' to 'suppressNotUsedInKitItems'
-- =============================================
CREATE PROCEDURE [dbo].[rptKitBuilt] 

@lcWono AS char(10) = ''

 , @userId uniqueidentifier=null 
AS
BEGIN

SET NOCOUNT ON;


-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record
DECLARE @lSuppressNotUsedInKit int
SELECT @lSuppressNotUsedInKit = ISNULL(wm.settingValue,mnx.settingValue)
	FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm 
	ON mnx.settingId = wm.settingId 
	-- 12/07/20 VL: mnxSettingsManagement.settingname was changed from 'Suppress Not Used in Kit items ?' to 'suppressNotUsedInKitItems'
	--WHERE mnx.settingName='Suppress Not Used in Kit items ?'
	WHERE mnx.settingName='suppressNotUsedInKitItems'	
					
--10/10/2013 DRP:  INSERT THE BELOW @WoUniq_key so that I could use it to indicate shortage (s) or phantom (f) 
DECLARE @WoUniq_key char(10);
SELECT @WoUniq_key = Uniq_key FROM WOENTRY WHERE WONO = @lcWono;

--- 03/12/15 YS replaced invtmfhd table with 2 new tables
-- 03/21/19 YS use invt_res for the allocated qty and invt_isu for the issued


if object_id('tempdb..#tRes') is not null
drop table #tRes
--04/05/19 YS added balance qty for the lot if available or manufcature
select wono, r.uniq_key,r.W_key, r.LOTCODE,r.EXPDATE,r.REFERENCE,r.PONUM,
sum(r.qtyAlloc) as sumQtyAlloc,
m.partmfgr,m.mfgr_pt_no,w.warehouse,im.[LOCATION],r.kaseqnum
-- 10/14/19 VL added ipkey/MTC, CAPA ticket #1979
,ISNULL(iReserveIpKey.ipkeyunique,SPACE(10)) AS ReservedMTC, 
ISNULL(SUM(iReserveIpKey.QtyAllocated),0.00) AS ReservedMTCQtySumByMTC
into #tRes
from invt_res r 
inner join InvtMfgr im on r.w_key=im.w_key
inner join InvtMPNLink l on im.UNIQMFGRHD=l.uniqmfgrhd
inner join MfgrMaster m on l.MfgrMasterId=m.MfgrMasterId
inner join warehous w on im.UNIQWH=w.UNIQWH
-- 10/14/19 VL added ipkey/MTC, CAPA ticket #1979
LEFT OUTER JOIN iReserveIpKey ON r.INVTRES_NO = iReserveIpKey.invtres_no
where r.wono=@lcwono
group by wono, r.uniq_key,r.W_key, r.LOTCODE,r.EXPDATE,r.REFERENCE,r.PONUM,
m.partmfgr,m.mfgr_pt_no,w.warehouse,im.[LOCATION],r.kaseqnum
-- 10/14/19 VL added next line
,iReserveIpKey.Ipkeyunique
having sum(r.qtyAlloc)<>0
			
if object_id('tempdb..#tIssue') is not null
drop table #tIssue

select wono, r.uniq_key,r.W_key, r.LOTCODE,r.EXPDATE,r.REFERENCE,r.PONUM,
sum(r.qtyIsu) as sumQtyIsu,
m.partmfgr,m.mfgr_pt_no,w.warehouse,im.[LOCATION],r.kaseqnum
-- 10/14/19 VL added ipkey/MTC, CAPA ticket #1979
,ISNULL(issueipkey.ipkeyunique,SPACE(10)) AS IssuedMTC,
ISNULL(SUM(issueipkey.qtyissued),0.00) AS IssuedMTCQtySumByMTC 
into #tIssue
from invt_isu r 
inner join InvtMfgr im on r.w_key=im.w_key
inner join InvtMPNLink l on im.UNIQMFGRHD=l.uniqmfgrhd
inner join MfgrMaster m on l.MfgrMasterId=m.MfgrMasterId
inner join warehous w on im.UNIQWH=w.UNIQWH
-- 10/14/19 VL added ipkey/MTC, CAPA ticket #1979
LEFT OUTER JOIN issueipkey ON r.INVTISU_NO = issueipkey.invtisu_no
where r.wono=@lcwono
group by wono, r.uniq_key,r.W_key, r.LOTCODE,r.EXPDATE,r.REFERENCE,r.PONUM,
m.partmfgr,m.mfgr_pt_no,w.warehouse,im.[LOCATION],r.kaseqnum
-- 10/14/19 VL added next line
,issueipkey.ipkeyunique
having sum(r.qtyIsu)<>0

IF OBJECT_ID('tempdb..#trans') is not null
drop table #trans


select distinct i.wono, i.uniq_key,i.W_key, i.LOTCODE,i.EXPDATE,i.REFERENCE,i.PONUM,
sumQtyIsu,i.partmfgr,i.mfgr_pt_no,i.warehouse,i.[LOCATION],i.kaseqnum,
r.wono as reswono, r.uniq_key as resuniq_key,r.W_key as resW_key, r.LOTCODE as resLotcode,
r.EXPDATE as resExpdate,r.REFERENCE as resReference,r.PONUM as responum,
sumQtyAlloc,r.partmfgr as respartmfgr,r.mfgr_pt_no as resmfgr_pt_no,r.warehouse as reswarehouse,r.[LOCATION] as reslocation,
r.KaSeqnum as reskaSeqnum
-- 10/14/19 VL added ipkey/MTC, CAPA ticket #1979
,IssuedMTC, ReservedMTC,ReservedMTCQtySumByMTC, IssuedMTCQtySumByMTC
INTO #trans
from #tIssue I FULL OUTER JOIN #tRes R on i.wono=r.wono and i.kaseqnum=r.KaSeqnum and i.w_key=r.w_key and i.LOTCODE=r.LOTCODE
and i.REFERENCE=r.REFERENCE and isnull(i.expdate,'')=isnull(r.expdate,'') and i.ponum=r.ponum
/*
test only
select * from #trans
*/
/*
isnull(lot.lotqty-lot.LOTRESQTY,0.00) as lotQtyAvailable,
im.QTY_OH-im.RESERVED as mnpQtyAvailable,

--04/05/19 YS added balance qty for the lot if available or manufcature
left outer join invtlot lot on r.W_KEY=lot.W_KEY
and r.LOTCODE=lot.LOTCODE
and ((r.EXPDATE is null and lot.expdate is null) or (r.EXPDATE=lot.expdate))
and r.REFERENCE=lot.REFERENCE
and r.ponum=lot.ponum
*/
--04/05/19 YS added balance qty for the lot if available or manufcature
--11/11/20 YS added wono to the output
select k.wono, k.UNIQ_KEY,k.lineshort,ISNULL(Item_no,0) as Item_no,k.dept_id,
case when i.part_sourc<>'CONSG' then i.part_no else i.CUSTPARTNO end as part_no,
case when i.part_sourc<>'CONSG' then I.revision else i.custrev end as Revision, I.part_sourc,
 i.part_class,i.part_type,i.descript,
 w.WAREHOUSE,q.[location],m.PartMfgr,m.mfgr_pt_no,
isnull(trans.w_key,trans.resw_key) as w_key,
isnull(trans.LOTCODE,trans.reslotcode) as lotcode,
isnull(trans.expdate,trans.resexpdate) as expdate,
isnull(trans.REFERENCE,trans.resREFERENCE) as REFERENCE,
isnull(trans.PONUM, trans.resPONUM) as PONUM,
isnull(trans.sumQtyAlloc,0.00) as sumQtyAlloc,isnull(trans.sumQtyIsu,0.00) as sumQtyIsu,
isnull(lot.lotqty-lot.LOTRESQTY,0.00) as lotQtyAvailable,
Q.QTY_OH-Q.RESERVED as mnpQtyAvailable,
k.ignorekit, k.bomparent ,
 isnull(UniqBomNo,'') as UniqBomNo,ISNULL(dbo.fnBomrefdesg(UniqBomno),'') as RefDesg,
 Phantom = CASE K.lineshort	WHEN 1 THEN 's'	ELSE CASE @WoUniq_key WHEN K.BomParent THEN ' ' ELSE 'f' END END ,
case when K.bomparent = K.uniq_key then '' else  rtrim(I3.PART_NO) + ' / '+rtrim(I3.revision) end as PhParentPn
-- 10/14/19 VL added ipkey/MTC, CAPA ticket #1979
,trans.IssuedMTC,IssuedMTCQtySumByMTC,trans.ReservedMTC,ReservedMTCQtySumByMTC, CASE WHEN ISNULL(trans.LOTCODE,reslotcode) IS NULL THEN 'Y' ELSE 'N' END AS Islot
from kamain k 
inner join #trans trans
on k.KASEQNUM=isnull(trans.kaseqnum,reskaSeqnum)
inner join invtmfgr Q on q.w_key= isnull(trans.w_key,trans.resw_key)
inner join warehous w on q.UNIQWH=w.UNIQWH
inner join InvtMPNLink l on q.UNIQMFGRHD=l.uniqmfgrhd
inner join mfgrmaster m on l.MfgrMasterId=m.MfgrMasterId
inner join inventor I on k.uniq_key=i.uniq_key
LEFT OUTER JOIN BOM_DET ON K.BOMPARENT = BOM_DET.BOMPARENT AND K.UNIQ_KEY = Bom_det.UNIQ_KEY AND K.DEPT_ID = Bom_det.DEPT_ID 
			left outer join INVENTOR as I3 on K.BomParent = I3.UNIQ_KEY
left outer join invtlot lot on trans.W_KEY=lot.W_KEY
and trans.LOTCODE=lot.LOTCODE
and ((trans.EXPDATE is null and lot.expdate is null) or (trans.EXPDATE=lot.expdate))
and trans.REFERENCE=lot.REFERENCE
and trans.ponum=lot.ponum
where @lSuppressNotUsedInKit=0 or ignoreKit=0
order by bomparent,Item_no,warehouse,[location],Mfgr_pt_no


if object_id('tempdb..#tIssue') is not null
drop table #tIssue

IF OBJECT_ID('tempdb..#trans') is not null
drop table #trans
if object_id('tempdb..#tRes') is not null
drop table #tRes

/*--- old manex keep for reference only. Remove when report is working to satisfaction 
-- 03/12/15 YS replaced invtmfhd table with 2 new tables
	SELECT	Kamain.Uniq_key,Kalocate.kaseqnum,Kalocate.w_key,Kalocate.pick_qty, Kalocate.lotcode, Kalocate.expdate,Kalocate.Reference,
			Kamain.BomParent,Kamain.LineShort, M.partmfgr,Invtmfgr.Location,M.mfgr_pt_no, inventor.Part_class,inventor.Part_type,
			CASE WHEN Inventor.Part_sourc<>'CONSG' THEN Inventor.Part_no ELSE Inventor.CustPartNo END AS Part_no,
			CASE WHEN Inventor.Part_sourc<>'CONSG' THEN Inventor.Revision ELSE Inventor.CustRev END AS Revision, 
			Inventor.Descript, Inventor.Part_sourc,Warehous.Warehouse, Kamain.Dept_id
--10/10/2013 DRP:  inserted the isnull for the Item_no, UniqBomNo and RefDesg fields			
			, ISNULL(Item_no,0) as Item_no, isnull(UniqBomNo,'') as UniqBomNo,ISNULL(dbo.fnBomrefdesg(UniqBomno),'') as RefDesg
--10/10/2013 DRP:  Inserted new fields Phantom and PhParentPn
			,Phantom = CASE Kamain.lineshort	WHEN 1 THEN 's'	ELSE CASE @WoUniq_key WHEN Kamain.BomParent THEN ' ' ELSE 'f'END END
			,case when kamain.bomparent = woentry.uniq_key then '' else  rtrim(I3.PART_NO) + ' / '+rtrim(I3.revision) end as PhParentPn	 
--10/10/2013 DRP:  NEEDED TO CHANGE THE FROM SECTION SO THAT i COULD POPULATE THE PHANTOM INFORMATION. 
		 --FROM Kalocate, Invtmfhd, Invtmfgr, Inventor, Warehous, Kamain LEFT OUTER JOIN BOM_DET 
		 --ON Kamain.BOMPARENT = BOM_DET.BOMPARENT
		 --AND Kamain.UNIQ_KEY = Bom_det.UNIQ_KEY
		 --AND Kamain.DEPT_ID = Bom_det.DEPT_ID 
		-- 03/12/15 YS replaced invtmfhd table with 2 new tables, also use inner join 
	 FROM	Kalocate INNER JOIN Kamain ON  Kalocate.KaseqNum = Kamain.KaseqNum
			inner join WOENTRY on kamain.WONO = woentry.wono
			INNER JOIN Inventor ON Kamain.Uniq_key=Inventor.Uniq_key
			INNER JOIN Invtmfgr On 	Invtmfgr.w_key = Kalocate.w_key
			INNER JOIN warehous On Warehous.UNIQWH = Invtmfgr.UNIQWH
			INNER JOIN Invtmpnlink L on Invtmfgr.uniqmfgrhd=L.Uniqmfgrhd
			INNER JOIN MfgrMaster M ON M.Mfgrmasterid=L.mfgrMasterId
	 		LEFT OUTER JOIN BOM_DET ON Kamain.BOMPARENT = BOM_DET.BOMPARENT AND Kamain.UNIQ_KEY = Bom_det.UNIQ_KEY AND Kamain.DEPT_ID = Bom_det.DEPT_ID 
			left outer join INVENTOR as I3 on kamain.BomParent = I3.UNIQ_KEY
	--10/17/2013 DRP:  I had the two below lines in the incorrect location.  They should have been up on the BOM_Det lin as above.  It was causing Line Shortages to fall off of the results.
			--AND Kamain.UNIQ_KEY = Bom_det.UNIQ_KEY
			--AND Kamain.DEPT_ID = Bom_det.DEPT_ID 
		 WHERE	Kamain.Wono = @lcWono 
		-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record
		AND 1 = CASE WHEN @lSuppressNotUsedInKit = 0 THEN 1 ELSE CASE WHEN IgnoreKit = 0 THEN 1 ELSE 0 END END			
	 ORDER BY Kalocate.KaseqNum,Warehouse,Location,PartMfgr
*/

END