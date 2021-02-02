
-- =============================================
-- Author:			Debbie
-- Create date:		11/23/15
-- Description:		Created for the Work Order Kit & Shortage Issue Material History 
-- Reports:			kithissu
-- Modified:	  
-- 11/13/17 YS/VL use temp table rather than CTE to join with the fincal SQL to see if it speeds up
-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record
-- 12/10/18 YS rewrite the SP. Kitting module was chnaged. Kalocate and Kalocser tables are not used
-- !!! need to add serial number and sid to the result
-- 10/08/19 VL added ipkey/MTC, CAPA ticket #1979
-- 06/08/2020 VL fix CAPA 2681 that SumQtyAlloc showed double qty if it's involved with MTC code
-- 12/07/20 VL: mnxSettingsManagement.settingname was changed from 'Suppress Not Used in Kit items ?' to 'suppressNotUsedInKitItems'
-- =============================================
CREATE PROCEDURE [dbo].[rptKitShortIssueHist]
--declare 
@lcWoNo char(10) = ''
,@userId uniqueidentifier=null



as
begin


SET @lcWoNo=dbo.PADL(@lcWoNo,10,'0')

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'Active' ;
		--SELECT * FROM @tCustomer	

-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record
DECLARE @lSuppressNotUsedInKit int
SELECT @lSuppressNotUsedInKit = ISNULL(wm.settingValue,mnx.settingValue)
	FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm 
	ON mnx.settingId = wm.settingId 
	-- 12/07/20 VL: mnxSettingsManagement.settingname was changed from 'Suppress Not Used in Kit items ?' to 'suppressNotUsedInKitItems'
	--WHERE mnx.settingName='Suppress Not Used in Kit items ?'
	WHERE mnx.settingName='suppressNotUsedInKitItems'	

/* new code currently without serial and sid inofrmation. Need to make available to Broadcom */

if object_id('tempdb..#tRes') is not null
drop table #tres

select wono, r.uniq_key,r.W_key, r.LOTCODE,r.EXPDATE,r.REFERENCE,r.PONUM,
-- 06/08/2020 VL fix CAPA 2681 that SumQtyAlloc showed double qty if it's involved with MTC code
--sum(r.qtyAlloc) over(partition by r.w_key) as sumQtyAlloc,
CASE WHEN iReserveIpKey.iResIpKeyUnique IS NULL THEN SUM(r.qtyAlloc) OVER(PARTITION BY r.W_key) ELSE SUM(iReserveIpKey.qtyAllocated) OVER(PARTITION BY r.W_key) END AS sumQtyAlloc,
m.partmfgr,m.mfgr_pt_no,w.warehouse,im.[LOCATION],r.INVTRES_NO,r.REFINVTRES
-- 10/08/19 VL added ipkey/MTC, CAPA ticket #1979
,iReserveIpKey.ipkeyunique AS ReservedMTC, --iReserveIpKey.qtyAllocated AS ReservedMTCQty, iResIpKeyUnique, 
SUM(iReserveIpKey.QtyAllocated) OVER (Partition by iReserveIpKey.Ipkeyunique) AS ReservedMTCQtySumByMTC
into #tRes
from invt_res r 
inner join InvtMfgr im on r.w_key=im.w_key
inner join InvtMPNLink l on im.UNIQMFGRHD=l.uniqmfgrhd
inner join MfgrMaster m on l.MfgrMasterId=m.MfgrMasterId
inner join warehous w on im.UNIQWH=w.UNIQWH
-- 10/08/19 VL added ipkey/MTC, CAPA ticket #1979
LEFT OUTER JOIN iReserveIpKey ON r.INVTRES_NO = iReserveIpKey.invtres_no
where r.wono=@lcwono
			
if object_id('tempdb..#tIssue') is not null
drop table #tIssue

select wono, r.uniq_key,r.W_key, r.LOTCODE,r.EXPDATE,r.REFERENCE,r.PONUM,
sum(r.qtyIsu) over(partition by r.w_key) as sumQtyIsu,
m.partmfgr,m.mfgr_pt_no,w.warehouse,im.[LOCATION],r.INVTISU_NO
-- 10/08/19 VL added ipkey/MTC, CAPA ticket #1979
,issueipkey.ipkeyunique AS IssuedMTC, --issueipkey.qtyissued AS IssuedMTCQty, issueIpKeyUnique, 
SUM(issueipkey.qtyissued) OVER (Partition by issueipkey.Ipkeyunique) AS IssuedMTCQtySumByMTC 
into #tIssue
from invt_isu r 
inner join InvtMfgr im on r.w_key=im.w_key
inner join InvtMPNLink l on im.UNIQMFGRHD=l.uniqmfgrhd
inner join MfgrMaster m on l.MfgrMasterId=m.MfgrMasterId
inner join warehous w on im.UNIQWH=w.UNIQWH
-- 10/08/19 VL added ipkey/MTC, CAPA ticket #1979
LEFT OUTER JOIN issueipkey ON r.INVTISU_NO = issueipkey.invtisu_no
where r.wono=@lcwono

IF OBJECT_ID('tempdbo..#trans') is not null
drop table #trans

select distinct i.wono, i.uniq_key,i.W_key, i.LOTCODE,i.EXPDATE,i.REFERENCE,i.PONUM,
sumQtyIsu,i.partmfgr,i.mfgr_pt_no,i.warehouse,i.[LOCATION],
r.wono as reswono, r.uniq_key as resuniq_key,r.W_key as resW_key, r.LOTCODE as resLotcode,
r.EXPDATE as resExpdate,r.REFERENCE as resReference,r.PONUM as responum,
sumQtyAlloc,r.partmfgr as respartmfgr,r.mfgr_pt_no as resmfgr_pt_no,r.warehouse as reswarehouse,r.[LOCATION] as reslocation
-- 10/08/19 VL added ipkey/MTC, CAPA ticket #1979
,IssuedMTC, --IssuedMTCQty ReservedMTCQty, issueIpKeyUnique, iResIpKeyUnique, 
 ReservedMTC,ReservedMTCQtySumByMTC, IssuedMTCQtySumByMTC
INTO #trans
from #tIssue I FULL OUTER JOIN #tRes R on i.wono=r.wono and i.w_key=r.w_key and i.LOTCODE=r.LOTCODE
and i.REFERENCE=r.REFERENCE and isnull(i.expdate,'')=isnull(r.expdate,'') and i.ponum=r.ponum

--where i.UNIQ_KEY='_2MX0JDMIS'
--- start
select	kamain.lineshort,case when kamain.bomparent <> WOENTRY.uniq_key then 'Ph' else '' end as PhantomLevel,
		kamain.wono,I1.part_no as Prod,I1.REVISION as ProdRev,I1.descript as ProdDesc,kamain.dept_id,
		I2.Part_no,i2.revision,I2.Part_class,I2.Part_type,I2.DESCRIPT,
		isnull(trans.w_key,trans.resw_key) as w_key,
		isnull(partmfgr,respartmfgr) as partmfgr,
		isnull(mfgr_pt_no,resmfgr_pt_no) as mfgr_pt_no,
		isnull(LOTCODE,reslotcode) as lotcode,
		isnull(EXPDATE,resexpdate) as expdate,
		isnull(REFERENCE,resreference) as reference,
		isnull(PONUM,responum) as ponum,
		isnull(trans.warehouse,trans.reswarehouse) as warehouse,
		isnull(trans.[location],trans.reslocation) as [location],
		isnull(sumQtyIsu,0.00) as QtyIssue,
		isnull(sumQtyAlloc,0.00) as QtyAlloc,
		kamain.kaseqnum
		-- 10/08/19 VL added ipkey/MTC, CAPA ticket #1979
		,trans.IssuedMTC,IssuedMTCQtySumByMTC,trans.ReservedMTC,ReservedMTCQtySumByMTC, CASE WHEN ISNULL(LOTCODE,reslotcode) IS NULL THEN 'Y' ELSE 'N' END AS Islot
		--, trans.IssuedMTCQty, trans.ReservedMTCQty,issueIpKeyUnique, iResIpKeyUnique
from	kamain 
		inner join woentry on kamain.wono = woentry.wono
		inner join inventor I1 on woentry.uniq_key = I1.uniq_key
		inner join inventor I2 on kamain.uniq_key=i2.uniq_key
		left outer join #trans trans on kamain.wono=isnull(trans.wono,reswono) and
		kamain.UNIQ_KEY=isnull(trans.uniq_key,resuniq_key)
where	kamain.WOno = @lcWoNo
and exists (select 1 from @tCustomer t inner join customer c on t.custno=c.custno where c.custno=woentry.custno)
		-- 01/29/18 VL: Added to use KitDef.lSuppressNotUsedInKit to filter out IgnoreKit record
		AND (@lSuppressNotUsedInKit = 0 or IgnoreKit = 0)
order by i2.PART_NO,i2.REVISION


/* old code
-- 11/13/17 VL drop the temp table
if OBJECT_ID('tempdb..#tempRpt') is not null
 drop table #tempRpt;

/*RECORD SELECTION SECTION*/
	;
	with
	--this section will go through and compile any Serialno information 
	PLSerial AS
			(
			--03/01/2012 DRP: had to change the casting of the serial numbers to interger in order for it to work with both Numeric/Alpha Numeric combination of serial numbers selected
			--03/01/2012 DRP:	SELECT CAST(PS.Serialno as numeric(30,0)) as iSerialno,ps.packlistno,PS.UNIQUELN  
			--10/05/2012 DRP:  had to replace  <<select CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as integer) AS iSerialNo>>
			--			  	 with <<select CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as bigint) AS iSerialNo>>	 
			/*04/08/2014 drp: SELECT CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as bigint) as iSerialno,ps.packlistno,PS.UNIQUELN  */
			SELECT CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as numeric(30,0)) as iSerialno,ps.wono,PS.uniqkalocate,ps.is_overissued   
			FROM KALOCSER PS 
			where PS.wono = @lcWoNo
			AND PATINDEX('%[^0-9]%',PS.serialno)=0 
			)
			,startingPoints as
			(
			select A.*, ROW_NUMBER() OVER(PARTITION BY A.wono,uniqkalocate,is_overissued ORDER BY iSerialno) AS rownum
			FROM PLSerial AS A WHERE NOT EXISTS (SELECT 1 FROM PLSerial AS B WHERE B.iSerialno=A.iSerialno-1 and B.wono =A.wono and B.UNIQKALOCATE=A.UNIQKALOCATE and B.is_overissued = A.is_overissued )
			)
			--SELECT * FROM StartingPoints  
   		,
		EndingPoints AS
		(
		select A.*, ROW_NUMBER() OVER(PARTITION BY wono,uniqkalocate,is_overissued ORDER BY iSerialno) AS rownum
		FROM PLSerial AS A WHERE NOT EXISTS (SELECT 1 FROM PLSerial AS B WHERE B.iSerialno=A.iSerialno+1 and B.wono =A.wono and B.UNIQKALOCATE=A.UNIQKALOCATE and B.is_overissued = A.IS_OVERISSUED) 
		)
		--SELECT * FROM EndingPoints
		,
		StartEndSerialno AS 
		(
		SELECT S.*,S.iSerialno AS start_range, E.iSerialno AS end_range
		FROM StartingPoints AS S
		JOIN EndingPoints AS E
		ON E.rownum = S.rownum and E.wono = S.wono and E.uniqkalocate =S.UNIQkalocate and E.IS_OVERISSUED = s.IS_OVERISSUED
		)
		,FinalSerialno AS
		(
		SELECT CASE WHEN A.start_range=A.End_range
				THEN CAST(RTRIM(CONVERT(char(30),A.start_range))  as varchar(MAX)) ELSE
				CAST(RTRIM(CONVERT(char(30),A.start_range))+'-'+RTRIM(CONVERT(char(30),A.End_range)) as varchar(MAX)) END as Serialno,
				wono,UNIQKALOCATE,is_overissued
		FROM StartEndSerialno  A
		UNION 
		SELECT CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as varchar(max)) as Serialno,PS.wono,PS.uniqkalocate,is_overissued  
			from kalocser ps 
			where ps.wono = @lcwono
			and (PS.Serialno LIKE '%[a-z]%' OR PATINDEX('%[^0-9A-Za-z]%',Ps.serialno)<>0) 
		)
		--select * from FinalSerialno	

-- 11/13/17 VL tried to use temp table to join with the fincal SQL to see if it speeds up
SELECT * INTO #tempRpt FROM FinalSerialno

select	kamain.lineshort,case when kamain.bomparent <> WOENTRY.uniq_key then 'Ph' else '' end as PhantomLevel,kalocate.wono,I1.part_no as Prod,I1.REVISION as ProdRev,I1.descript as ProdDesc
		,I2.Part_no,i2.revision,I2.Part_class,I2.Part_type,I2.DESCRIPT, invtmfhd.PARTMFGR,invtmfhd.MFGR_PT_NO
		,warehouse,invtmfgr.LOCATION,kalocate.lotcode,kalocate.expdate,kalocate.reference,KALOCATE.ponum,KALOCATE.PICK_QTY
		,CAST(stuff((select', '+ps.Serialno	from #tempRpt PS
													where	PS.wono = kalocate.wono
															AND PS.UNIQKALOCATE = KALOCATE.UNIQKALOCATE
															and PS.IS_OVERISSUED = 0
													ORDER BY SERIALNO FOR XML PATH ('')),1,2,'') AS VARCHAR (MAX)) AS Serialno
		,CAST(stuff((select', '+ps.Serialno	from #tempRpt PS
													where	PS.wono = kalocate.wono
															AND PS.UNIQKALOCATE = KALOCATE.UNIQKALOCATE
															and PS.IS_OVERISSUED = 1
													ORDER BY SERIALNO FOR XML PATH ('')),1,2,'') AS VARCHAR (MAX)) AS OverIssSerialno
		,kalocate.kaseqnum
from	kalocate 
		inner join woentry on kalocate.wono = woentry.wono
		inner join inventor I1 on woentry.uniq_key = I1.uniq_key
		inner join invtmfgr on kalocate.w_key = invtmfgr.w_key
		inner join invtmfhd on invtmfgr.uniqmfgrhd = invtmfhd.UNIQMFGRHD
		inner join inventor I2 on invtmfhd.uniq_key = I2.Uniq_key 
		inner join warehous on invtmfgr.uniqwh = warehous.uniqwh
		left outer join kamain on kalocate.kaseqnum = kamain.kaseqnum

where	kalocate.WOno = @lcWoNo
		and exists (select 1 from @tCustomer t inner join customer c on t.custno=c.custno where c.custno=woentry.custno)
		-- 01/29/18 VL: Added to use KitDef.lSuppressNotUsedInKit to filter out IgnoreKit record
		AND 1 = CASE WHEN @lSuppressNotUsedInKit = 0 THEN 1 ELSE CASE WHEN IgnoreKit = 0 THEN 1 ELSE 0 END END

*/

END