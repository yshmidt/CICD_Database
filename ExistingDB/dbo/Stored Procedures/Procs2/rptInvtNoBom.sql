

-- =============================================
-- Author:		Debbie
-- Create date: 03/08/2011
-- Description:	This Stored Procedure was created for the Inventory List with No Assigned Bom report 
-- Reports Using Stored Procedure:  icrpt7.rpt
-- Modified:	09/25/2012 DRP:  added the micssys.lic_name within the Stored Procedure and removed it from the Crystal Report
--				09/26/2014 DRP:  added the @userId parameter
-- =============================================
CREATE PROCEDURE [dbo].[rptInvtNoBom]

 @userId uniqueidentifier= null

		
AS 
begin 
;
with


zinvt as
( 
select	INVENTOR.UNIQ_KEY,case when PART_SOURC = 'CONSG' then CUSTPARTNO else PART_NO end as Part_no, 
		case when PART_SOURC = 'CONSG' then CUSTREV else REVISION end as Rev,
		part_class, PART_TYPE, DESCRIPT, STDCOST, PART_SOURC, BUYER_TYPE as buyer, CUSTNO, U_OF_MEAS, INVENTOR.STATUS, 
		SUM(invtmfgr.qty_oh) over(PARTITION by inventor.uniq_key) as TotQty_oh

from		INVENTOR
			inner join INVTMFGR on INVENTOR.UNIQ_KEY = INVTMFGR.UNIQ_KEY

Where		PART_SOURC <> 'MAKE'
			and inventor.UNIQ_KEY NOT IN(SELECT uniq_key from bom_Det 
											where	inventor.uniq_key =Bom_det.uniq_key 
													and (Eff_dt<=GETDATE() OR Eff_dt IS NULL)
													and (Term_dt>GETDATE() OR Term_dt IS NULL))
)
,
ZpoRec as 
(
SELECT zinvt.uniq_key,zinvt.part_no, zinvt.rev, zinvt.part_class, zinvt.part_type,
		zinvt.descript, zinvt.stdcost, zinvt.part_sourc, zinvt.buyer, zinvt.custno,
		zinvt.u_of_meas,zinvt.status, zinvt.TotQty_Oh, 
		cast(CONVERT (CHAR(19),MAX(RECVDATE), 21) as DATE) AS LastUsed, CAST('PO Receipt' as CHAR (15)) as TrnType
from zinvt
left outer join poitems on zinvt.uniq_key = POITEMS.UNIQ_KEY
inner join PORECDTL on POITEMS.UNIQLNNO = PORECDTL.UNIQLNNO
group by zinvt.uniq_key,zinvt.part_no, zinvt.rev, zinvt.part_class, zinvt.part_type,
		zinvt.descript, zinvt.stdcost, zinvt.part_sourc, zinvt.buyer, zinvt.custno,
		zinvt.u_of_meas,zinvt.status, zinvt.TotQty_Oh
)
,
Zissu as
(
select	zinvt.uniq_key,zinvt.part_no, zinvt.rev, zinvt.part_class, zinvt.part_type,
		zinvt.descript, zinvt.stdcost, zinvt.part_sourc, zinvt.buyer, zinvt.custno,
		zinvt.u_of_meas,zinvt.status,zinvt.totqty_oh
		, cast(CONVERT (CHAR(19),MAX(DATE), 21) as DATE)  AS LastUsed, CAST('Invt Issue' as CHAR (15)) as TrnType
from	zinvt 
		left outer join INVT_ISU on zinvt.UNIQ_KEY = INVT_ISU.UNIQ_KEY
group by	zinvt.uniq_key,zinvt.part_no, zinvt.rev, zinvt.part_class, zinvt.part_type,
			zinvt.descript, zinvt.stdcost, zinvt.part_sourc, zinvt.buyer, zinvt.custno,
			zinvt.u_of_meas, zinvt.STATUS, zinvt.TotQty_Oh
)
,

Zrec as
(
SELECT zinvt.uniq_key,zinvt.part_no, zinvt.rev, zinvt.part_class, zinvt.part_type,
		zinvt.descript, zinvt.stdcost, zinvt.part_sourc, zinvt.buyer, zinvt.custno,
		zinvt.u_of_meas,zinvt.status, zinvt.TotQty_Oh,
		cast(CONVERT (CHAR(19),MAX(DATE), 21) as DATE) AS LastUsed, CAST('Invt Receipt' as CHAR (15)) as TrnType
from zinvt
left outer join INVT_REC on zinvt.uniq_key = INVT_REC.UNIQ_KEY
group by zinvt.uniq_key,zinvt.part_no, zinvt.rev, zinvt.part_class, zinvt.part_type,
		zinvt.descript, zinvt.stdcost, zinvt.part_sourc, zinvt.buyer, zinvt.custno,
		zinvt.u_of_meas,zinvt.status, zinvt.TotQty_Oh
)
,
Zres as
(
SELECT zinvt.uniq_key,zinvt.part_no, zinvt.rev, zinvt.part_class, zinvt.part_type,
		zinvt.descript, zinvt.stdcost, zinvt.part_sourc, zinvt.buyer, zinvt.custno,
		zinvt.u_of_meas,zinvt.status, zinvt.TotQty_Oh, 
		cast(CONVERT (CHAR(19),MAX(DATETIME), 21) as DATE) AS LastUsed, CAST('Invt Reserved' as CHAR (15)) as TrnType
from zinvt
left outer join INVT_RES on zinvt.uniq_key = INVT_RES.UNIQ_KEY
group by zinvt.uniq_key,zinvt.part_no, zinvt.rev, zinvt.part_class, zinvt.part_type,
		zinvt.descript, zinvt.stdcost, zinvt.part_sourc, zinvt.buyer, zinvt.custno,
		zinvt.u_of_meas,zinvt.status, zinvt.TotQty_Oh
)
,
ztrns as 
(
SELECT zinvt.uniq_key,zinvt.part_no, zinvt.rev, zinvt.part_class, zinvt.part_type,
		zinvt.descript, zinvt.stdcost, zinvt.part_sourc, zinvt.buyer, zinvt.custno,
		zinvt.u_of_meas,zinvt.status, zinvt.TotQty_Oh, 
		cast(CONVERT (CHAR(19),MAX(DATE), 21) as DATE) AS LastUsed, CAST('Invt Transfer' as CHAR (15)) as TrnType
from zinvt
left outer join INVTtrns on zinvt.uniq_key = INVTTRNS.UNIQ_KEY
group by zinvt.uniq_key,zinvt.part_no, zinvt.rev, zinvt.part_class, zinvt.part_type,
		zinvt.descript, zinvt.stdcost, zinvt.part_sourc, zinvt.buyer, zinvt.custno,
		zinvt.u_of_meas,zinvt.status, zinvt.TotQty_Oh
)

select	t1.UNIQ_KEY, t1.Part_no, t1.Rev, t1.PART_CLASS, t1.PART_TYPE, t1.DESCRIPT, t1.STDCOST, t1.PART_SOURC, t1.buyer, t1.CUSTNO, t1.U_OF_MEAS, t1.status, t1.TotQty_oh,
		CASE WHEN ROW_NUMBER() OVER(Partition by Uniq_key Order by LastUsed)=1 Then SUM (t1.stdcost*t1.totQty_oh)  ELSE CAST(0.00 as Numeric(20,2)) END AS ExtCost
		--SUM(t1.STDCOST*t1.TotQty_oh) over (partition by t1.uniq_key) as ExtCost, ,
		,LastUsed, TrnType,MICSSYS.LIC_NAME
from 
(
select Zissu.* from Zissu
union all
select Zrec.* from Zrec
union all
select Zres.* from Zres
union all
select ZpoRec.* from ZpoRec
union all
select Ztrns.* from Ztrns

) t1
cross join MICSSYS
group by UNIQ_KEY, Part_no, Rev, PART_CLASS, PART_TYPE, DESCRIPT, STDCOST, PART_SOURC, buyer, CUSTNO, U_OF_MEAS, status, TotQty_oh, LastUsed, TrnType ,MICSSYS.LIC_NAME
--order by Part_no, Rev, UNIQ_KEY, LastUsed

end