
-- =============================================
-- Author:			Debbie
-- Create date:		10/23/2012
-- Description:		Created for the Sales Order Picklist report within Sales Order module
-- Reports:			sopickl.rpt 
-- Modified:	10/13/14   YS: removed invtmfhd table 
--				03/12/15 YS more changes to remove invtmfhd table
--				11/18/15 DRP:  added the @userId and /*CUSTOMER LIST*/ 
--				09/01/16 DRP:  removed the micssys we don't need to include the licname on the procedure results.  Also changed the procedure to union records that have w_key associated at the Sodetail level and records that do not have w_key associated to it.  
--				Prior to this change I would pull all of the INVTMFHD, INVTMFGR, WAREHOUS tables into the report again individually to get the records that were not assigned a w_key and for larger dataset this was not working and causing time outs. 
-- 06/26/19 VL should filter out closed and cancelled items
-- =============================================
CREATE PROCEDURE  [dbo].[rptSoPickList]

		@lcSoNo as char(10) = ''  -- Sales Order will be populated here
		,@userId uniqueidentifier=null

as
begin

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'Active' ;
		--SELECT * FROM @tCustomer	

/*RECORD SELECTION*/
/*first compile items that have the W_key selected at the Sales Order level (which means the user selected the inventory location to pick it from)*/
select	somain.SONO,somain.IS_RMA,customer.CUSTNAME,somain.PONO,somain.ORD_TYPE,sodetail.LINE_NO,inventor.UNIQ_KEY,inventor.PART_NO,inventor.REVISION,inventor.PART_CLASS,inventor.part_type,inventor.DESCRIPT
		,sodetail.ORD_QTY,sodetail.BALANCE,'' AS NotSelMfgrHead
		,M.PARTMFGR AS PartMfgr
		, M.mfgr_pt_no as MfgrPn
		,INVTMFGR.LOCATION as Location
		,INVTMFGR.QTY_OH as QtyOnHand
		,INVTMFGR.QTY_OH-INVTMFGR.RESERVED as AvailQty
		, '' as NotSel
		, WAREHOUS.WAREHOUSE as Warehous
from	SOMAIN
		inner join CUSTOMER on somain.CUSTNO = CUSTOMER.CUSTNO
		left outer join SODETAIL on somain.SONO = sodetail.SONO
		left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY
		left outer join INVTMFGR on sodetail.UNIQ_KEY = invtmfgr.UNIQ_KEY and sodetail.W_KEY = invtmfgr.W_KEY
		--	10/13/14   YS: removed invtmfhd table 
		--left outer join invtmfhd on invtmfgr.UNIQMFGRHD = invtmfhd.UNIQMFGRHD
		OUTER APPLY (select l.uniqmfgrhd,partmfgr,mfgr_pt_no from InvtMPNLink L inner join mfgrmaster on l.mfgrmasterid=mfgrmaster.mfgrmasterid  
			where invtmfgr.UNIQMFGRHD = L.UNIQMFGRHD )M
		left outer join WAREHOUS on invtmfgr.UNIQWH = WAREHOUS.UNIQWH
		left outer join INVT_RES on sodetail.UNIQ_KEY = invt_res.UNIQ_KEY and sodetail.UNIQUELN = invt_res.UNIQUELN

where	SOMAIN.sono = dbo.padl(@lcSoNo,10,'0')  
		and SODETAIL.UNIQ_KEY <> '' 
		and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=SOMAIN.custno)
		and sodetail.w_key <> ''
		-- 06/26/19 VL should filter out closed and cancel items
		and not (SODETAIL.STATUS in ('Closed', 'Cancel'))

UNION ALL 
/*The add the sales order items that did not have the w_key selected these will list all Mfgr's locations.*/		
select	somain.SONO,somain.IS_RMA,customer.CUSTNAME,somain.PONO,somain.ORD_TYPE,sodetail.LINE_NO,inventor.UNIQ_KEY,inventor.PART_NO,inventor.REVISION,inventor.PART_CLASS,inventor.part_type,inventor.DESCRIPT
		,sodetail.ORD_QTY,sodetail.BALANCE
		,CASE WHEN SODETAIL.W_KEY = '' AND SODETAIL.QTYFROMINV = 0.00 
			THEN '** Mfgr/Location not specificed at order entry.  All Available locations will be listed below.' 
				ELSE '' END AS NotSelMfgrHead
		,CASE WHEN SODETAIL.W_KEY = '' AND SODETAIL.QTYFROMINV = 0.00 
			THEN IH3.PARTMFGR ELSE CASE WHEN SODETAIL.W_KEY = '' AND SODETAIL.QTYFROMINV > 0.00 
				THEN IH2.PARTMFGR ELSE '' END END AS PartMfgr
		,case when sodetail.w_key = '' and sodetail.qtyfrominv = 0.00 
			then ih3.MFGR_PT_NO else case when sodetail.w_key = '' and sodetail.qtyfrominv > 0.00 then ih2.mfgr_pt_no else '' end end as MfgrPn
		,case when SODETAIL.W_KEY = ' ' and SODETAIL.QTYFROMINV = 0.00 
			then im3.LOCATION else case when SODETAIL.W_KEY = ' ' and SODETAIL.QTYFROMINV > 0.00 then Im2.LOCATION else '' end end as Location
		,case when SODETAIL.W_KEY = ' ' and SODETAIL.QTYFROMINV > 0.00 then IM2.QTY_OH else Im3.QTY_OH end as QtyOnHand
		,case when SODETAIL.W_KEY = ' ' and SODETAIL.QTYFROMINV > 0.00 then IM2.QTY_OH-IM2.RESERVED else IM3.QTY_OH-IM3.RESERVED end as AvailQty
		,case when SODETAIL.W_KEY = ' ' and SODETAIL.QTYFROMINV = 0.00 then SODETAIL.UNIQ_KEY else ''end as NotSel
		,case when SODETAIL.W_KEY = ' ' and SODETAIL.QTYFROMINV = 0.00 then 'WHSE not specified at order entry' else
			case when SODETAIL.W_KEY = ' ' and SODETAIL.QTYFROMINV > 0.00 then W2.WAREHOUSE else '' end end as Warehous
from	SOMAIN
		inner join CUSTOMER on somain.CUSTNO = CUSTOMER.CUSTNO
		left outer join SODETAIL on somain.SONO = sodetail.SONO
		left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY
		left outer join INVT_RES on sodetail.UNIQ_KEY = invt_res.UNIQ_KEY and sodetail.UNIQUELN = invt_res.UNIQUELN
		left outer join INVTMFGR as IM2 on invt_res.UNIQ_KEY = im2.UNIQ_KEY and invt_res.W_KEY = IM2.W_KEY
		OUTER APPLY (select l.uniqmfgrhd,partmfgr,mfgr_pt_no from InvtMPNLink L inner join mfgrmaster on l.mfgrmasterid=mfgrmaster.mfgrmasterid  
			where im2.UNIQMFGRHD = L.UNIQMFGRHD ) IH2
		LEFT OUTER JOIN WAREHOUS AS W2 ON IM2.UNIQWH = W2.UNIQWH
		left outer join INVTMFGR as IM3 on invt_res.UNIQ_KEY = im3.UNIQ_KEY and invt_res.W_KEY = IM3.W_KEY
		OUTER APPLY (select l2.uniqmfgrhd,partmfgr,mfgr_pt_no from InvtMPNLink L2 inner join mfgrmaster on l2.mfgrmasterid=mfgrmaster.mfgrmasterid  
			where im3.UNIQMFGRHD = L2.UNIQMFGRHD ) Ih3
		LEFT OUTER JOIN WAREHOUS AS W3 ON IM3.UNIQWH = W3.UNIQWH
		
where	SOMAIN.sono = dbo.padl(@lcSoNo,10,'0')  
		and SODETAIL.UNIQ_KEY <> '' 
		and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=SOMAIN.custno)
		and sodetail.w_key = ''
		-- 06/26/19 VL should filter out closed and cancel items
		and not (SODETAIL.STATUS in ('Closed', 'Cancel'))
/*
/*****************************************************/
/*ORIGINAL CODE:  replaced by the above two unions on 09/01/16 DRP*/

--select	somain.SONO,somain.IS_RMA,customer.CUSTNAME,somain.PONO,somain.ORD_TYPE,sodetail.LINE_NO,inventor.UNIQ_KEY,inventor.PART_NO,inventor.REVISION,inventor.PART_CLASS,inventor.part_type,inventor.DESCRIPT
--		,sodetail.ORD_QTY,sodetail.BALANCE
--		,CASE WHEN SODETAIL.W_KEY = '' AND SODETAIL.QTYFROMINV = 0.00 
--			THEN '** Mfgr/Location not specificed at order entry.  All Available locations will be listed below.' 
--				ELSE '' END AS NotSelMfgrHead
--		,CASE WHEN SODETAIL.W_KEY = '' AND SODETAIL.QTYFROMINV = 0.00 
--			THEN '' ELSE CASE WHEN SODETAIL.W_KEY = '' AND SODETAIL.QTYFROMINV > 0.00 
--				THEN IH2.PARTMFGR ELSE M.PARTMFGR END END AS PartMfgr
--		,case when sodetail.w_key = '' and sodetail.qtyfrominv = 0.00 
--			then '' else case when sodetail.w_key = '' and sodetail.qtyfrominv > 0.00 then ih2.mfgr_pt_no else M.mfgr_pt_no end end as MfgrPn
--		,case when SODETAIL.W_KEY = ' ' and SODETAIL.QTYFROMINV = 0.00 
--			then '' else case when SODETAIL.W_KEY = ' ' and SODETAIL.QTYFROMINV > 0.00 then IM2.LOCATION else INVTMFGR.LOCATION end end as Location
--		,case when SODETAIL.W_KEY = ' ' and SODETAIL.QTYFROMINV > 0.00 then IM2.QTY_OH else INVTMFGR.QTY_OH end as QtyOnHand
--		,case when SODETAIL.W_KEY = ' ' and SODETAIL.QTYFROMINV > 0.00 then IM2.QTY_OH-IM2.RESERVED else INVTMFGR.QTY_OH-INVTMFGR.RESERVED end as AvailQty
--		,case when SODETAIL.W_KEY = ' ' and SODETAIL.QTYFROMINV = 0.00 then SODETAIL.UNIQ_KEY else ''end as NotSel
--		,case when SODETAIL.W_KEY = ' ' and SODETAIL.QTYFROMINV = 0.00 then 'WHSE not specified at order entry' else
--			case when SODETAIL.W_KEY = ' ' and SODETAIL.QTYFROMINV > 0.00 then W2.WAREHOUSE else WAREHOUS.WAREHOUSE end end as Warehous,MICSSYS.LIC_NAME
--from	SOMAIN
--		inner join CUSTOMER on somain.CUSTNO = CUSTOMER.CUSTNO
--		left outer join SODETAIL on somain.SONO = sodetail.SONO
--		left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY
--		left outer join INVTMFGR on sodetail.UNIQ_KEY = invtmfgr.UNIQ_KEY and sodetail.W_KEY = invtmfgr.W_KEY
--			10/13/14   YS: removed invtmfhd table 
--		left outer join invtmfhd on invtmfgr.UNIQMFGRHD = invtmfhd.UNIQMFGRHD
--		OUTER APPLY (select l.uniqmfgrhd,partmfgr,mfgr_pt_no from InvtMPNLink L inner join mfgrmaster on l.mfgrmasterid=mfgrmaster.mfgrmasterid  
--			where invtmfgr.UNIQMFGRHD = L.UNIQMFGRHD )M
--		left outer join WAREHOUS on invtmfgr.UNIQWH = WAREHOUS.UNIQWH
--		left outer join INVT_RES on sodetail.UNIQ_KEY = invt_res.UNIQ_KEY and sodetail.UNIQUELN = invt_res.UNIQUELN
--		03/12/15 YS removed invtmfhd
--		left outer join INVTMFGR as IM2 on invt_res.UNIQ_KEY = im2.UNIQ_KEY and invt_res.W_KEY = IM2.W_KEY
--		left outer join INVTMFHD as IH2	 on IM2.UNIQMFGRHD = IH2.UNIQMFGRHD
--		OUTER APPLY (select l.uniqmfgrhd,partmfgr,mfgr_pt_no from InvtMPNLink L inner join mfgrmaster on l.mfgrmasterid=mfgrmaster.mfgrmasterid  
--			where im2.UNIQMFGRHD = L.UNIQMFGRHD ) IH2
--		LEFT OUTER JOIN WAREHOUS AS W2 ON IM2.UNIQWH = W2.UNIQWH
--		CROSS JOIN MICSSYS
		
		
--where	SOMAIN.sono = dbo.padl(@lcSoNo,10,'0')  
--		and SODETAIL.UNIQ_KEY <> '' 
--		and not (SODETAIL.STATUS in ('Closed', 'Cancel'))
--		and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=SOMAIN.custno)
		*/
end