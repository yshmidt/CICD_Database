
-- =============================================
-- Author:		<Debbie>
-- Create date: <11/28/2011>
-- Description:	<Compiles information for the the Material Receipt Labels>
-- Used On:     <Crystal Report {poreclbl.rpt} and {poreclbz.rpt} 
--				   10/13/14 YS : replaced invtmfhd table with 2 new tables
-- =============================================
CREATE PROCEDURE [dbo].[rptMatlRecptLabelSN]
		@lcPoNum as varchar (15) = '*'
	

AS
begin 

select	t1.PONUM,t1.CONUM,SUPNAME,t1.UNIQSUPNO,t1.ITEMNO,t1.poittype,t1.UNIQLNNO,t1.PORECPKNO,t1.Part_no,t1.Rev,t1.Descript
		,t1.part_class,t1.part_type,t1.MATLTYPE,t1.UNIQMFGRHD,t1.PARTMFGR,t1.MFGR_PT_NO,t1.RECVDATE,t1.RECEIVERNO,t1.reqtype,t1.Req_Alloc,t1.serialno


from(
SELECT	POMAIN.PONUM,CONUM,SUPNAME,POMAIN.UNIQSUPNO,POITEMS.ITEMNO,poitems.POITTYPE,PORECDTL.UNIQLNNO,PORECDTL.PORECPKNO
		,case when poitems.POITTYPE = 'MRO' or poitems.POITTYPE ='Services' then poitems.PART_NO else Inventor.PART_NO end as Part_no
		,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.REVISION else inventor.REVISION end as Rev
		,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.DESCRIPT else inventor.DESCRIPT end as Descript
		,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.PART_CLASS else inventor.PART_CLASS end as Part_Class
		,case when POITEMS.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then POITEMs.PART_TYPE else inventor.PART_TYPE end as part_type
		,m.MATLTYPE,PORECDTL.UNIQMFGRHD,porecdtl.PARTMFGR,porecdtl.MFGR_PT_NO,RECVDATE,PORECDTL.RECEIVERNO
		,CASE WHEN POITTYPE <> 'Invt Part' and REQUESTTP <> 'MRO' then REQUESTTP else 
				case when POITTYPE = 'Invt Part' then requesttp  end end as ReqType 	
		,CASE WHEN POITTYPE <> 'Invt Part' and REQUESTTP <> 'MRO' then WOPRJNUMBER else 
				case when POITTYPE = 'Invt Part' then WOPRJNUMBER end end as Req_Alloc 	
		,cast(dbo.fremoveLeadingZeros(SERIALNO) as varchar(MAx)) as SerialNo
		--,porecser.serialno
		

FROM	POMAIN
		INNER JOIN SUPINFO ON POMAIN.UNIQSUPNO = SUPINFO.UNIQSUPNO
		INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
		LEFT OUTER JOIN INVENTOR ON POITEMS.UNIQ_KEY = INVENTOR.UNIQ_KEY
		inner join PORECDTL on poitems.UNIQLNNO = PORECDTL.UNIQLNNO
		LEFT OUTER JOIN PORECLOC ON PORECDTL.UNIQRECDTL = PORECLOC.FK_UNIQRECDTL
		LEFT OUTER JOIN POITSCHD ON PORECLOC.UNIQDETNO = POITSCHD.UNIQDETNO
		--				   10/13/14 YS : replaced invtmfhd table with 2 new tables
		--left outer join INVTMFHD on poitems.UNIQMFGRHD = invtmfhd.UNIQMFGRHD
		LEFT OUTER JOIN InvtMPNLink L ON poitems.UNIQMFGRHD = L.uniqmfgrhd
		LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
		left outer join PORECSER on porecloc.LOC_UNIQ = porecser.LOC_UNIQ

		
WHERE	POMAIN.PONUM = dbo.padl(@lcPoNum,15,'0')

) t1

end