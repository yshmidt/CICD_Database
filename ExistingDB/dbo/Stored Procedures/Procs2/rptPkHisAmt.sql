

-- =============================================
-- Author:		<Debbie>
-- Create date: <11/10/2010>
-- Description:	<compiles detailed Packing List information with $ Amount>
-- Reports:     <used on pkhisamt.rpt, pkhis_pk.rpt, pkhis_p.rpt, pkhis_so >
-- Modified:	04/17/2012 DRP:	found that if there was a large number of misc items added to the packing list that exceeded 10 that it would then begin not sorting them as desired.
--				01/15/2014 DRP:  added the @userid parameter for WebManex
-- =============================================
CREATE PROCEDURE [dbo].[rptPkHisAmt] 

@userId uniqueidentifier=null


AS
BEGIN
--04/17/2012 DRP:	found that if there was a large number of misc items added to the packing list that exceeded 10 that it would then begin not sorting them as desired. 
--					added the sortby field below to address this situation. 

select		t1.CUSTNAME, t1.STATUS, t1.Sono, t1.SHIPDATE, t1.packlistno, t1.INVOICENO, t1.PONO, t1.line_no,t1.sortby, t1.PART_NO, t1.REVISION, t1.PART_CLASS, t1.PART_TYPE,
			t1.DESCRIPT, t1.PkPriceDesc, t1.recordtype, t1.QUANTITY, t1.PRICE, t1.EXTENDED, t1.tax,
			CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then INVTOTAL ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotal,
			t1.poststatus
From(
select		CUSTOMER.CUSTNAME,	CUSTOMER.STATUS,
			case when PLMAIN.SONO = '' then cast('Manual PL' as CHAR(10)) else cast(PLMAIN.SONO as CHAR(10)) end as Sono,
			PLMAIN.shipdate,plmain.PACKLISTNO, PLMAIN.INVOICENO,SOMAIN.PONO,
			ISNULL(cast(sodetail.line_no as CHAR (10)),cast(PLPRICES.uniqueln as CHAR (10))) as Line_No,
			ISNULL(sodetail.line_no,'X'+dbo.padl(rtrim(substring(PLPRICES.uniqueln,2,6)),6,'0')) as sortby,
			--case when PLMAIN.SONO = '' then cast(PLPRICES.UNIQUELN as CHAR(7)) else cast(SODETAIL.LINE_NO as CHAR(7)) end as line_no,
			INVENTOR.PART_NO,INVENTOR.REVISION,INVENTOR.PART_CLASS,INVENTOR.PART_TYPE,INVENTOR.DESCRIPT,
			case when PLPRICES.RECORDTYPE = 'O' then cast(PLPRICES.DESCRIPT as CHAR(45)) else cast(INVENTOR.PART_NO  + INVENTOR.REVISION as CHAR(45)) end as PkPriceDesc,
			PLPRICES.RECORDTYPE, PLPRICES.QUANTITY,PLPRICES.PRICE,PLPRICES.EXTENDED,
			case when PLPRICES.TAXABLE = 1 then 'Y' else '' end as tax,PLMAIN.INVTOTAL,
			case when PLMAIN.PRINTED = 0 then 'Unposted' else case when PLMAIN.printed = 1 then 'Posted' end end as PostStatus

from		PLMAIN inner join
			CUSTOMER on CUSTOMER.CUSTNO = PLMAIN.custno left outer join
			SOMAIN on PLMAIN.SONO = SOMAIN.SONO and PLMAIN.CUSTNO = SOMAIN.CUSTNO left outer join
			PLPRICES on PLMAIN.PACKLISTNO = PLPRICES.PACKLISTNO left outer join
			SODETAIL on PLPRICES.UNIQUELN = SODETAIL.UNIQUELN left outer join
			INVENTOR on SODETAIL.UNIQ_KEY = INVENTOR.UNIQ_KEY
)t1
order by 1, 3

END

