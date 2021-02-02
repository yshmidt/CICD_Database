-- =============================================
-- Author:		Debbie
-- Create date: 10/13/2011
-- Description:	This Stored Procedure was created for the Allocated Report by Part Number and Allocated Report by WO 
-- Reports Using Stored Procedure:  icrpt18.rpt, icrpt19.rpt
-- 10/10/14 YS replace invtmfhd table with 2 new tables
-- 10/01/19 VL Added ipkey 
-- 08/17/20 VL added customer filter
-- =============================================

CREATE PROCEDURE [dbo].[rptInvtAllocWoPrjSo]
@userid uniqueidentifier = null
as
Begin

-- 08/17/20 VL added customer filter
DECLARE  @tCustomer as tCustomer    
INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;  

;
with zAllocD as	(
	select	invt_res.UNIQ_KEY
			,case when invt_res.WONO <> '' then CAST ('WoNo: ' + invt_res.WONO as CHAR (20)) 
				else case when invt_res.WONO = '' and invt_res.SONO = '' then CAST ('Proj No: ' + PJCTMAIN.PRJNUMBER as char (20)) 
					else CAST ('SoNo: ' + invt_res.sono + '/' + right(sodetail.line_no,3) as CHAR (20)) end end as AllocRec
			,sum(qtyalloc)as SumQty,lotcode,EXPDATE,REFERENCE,PONUM,PART_NO,REVISION,DESCRIPT,PART_CLASS,PART_TYPE
			,case when invt_res.WONO <> '' then OPENCLOS 
				else case when invt_res.wono = '' and invt_res.sono = '' then PRJSTATUS else sodetail.STATUS end end as Status
			,case when invt_res.wono <> '' then BLDQTY else sodetail.BALANCE end as OrdQty
			,case when INVT_RES.WONO <> '' then c2.CUSTNO else case when invt_res.WONO = '' and invt_res.SONO = '' then c1.CUSTNO else c3.CUSTNO end end as Custno
			,case when invt_res.wono <> '' then c2.CUSTNAME else case when invt_res.WONO = '' and invt_res.SONO = '' then c1.CUSTNAME else c3.custname end end as CustName   
			,case when invt_res.wono <> '' then WOENTRY.UNIQ_KEY else sodetail.UNIQ_KEY end as pUniq_key,
			m.PARTMFGR,m.MFGR_PT_NO,invt_res.w_key,INVTMFGR.uniqwh,LOCATION,WAREHOUSE
			-- 10/01/19 VL added MTC
			,iReserveIpKey.ipkeyunique
	from	INVT_RES
			left outer join inventor on invt_res.UNIQ_KEY = inventor.UNIQ_KEY
			left outer join pjctmain on invt_res.fk_prjunique = pjctmain.prjunique
			left outer join WOENTRY on invt_res.WONO = WOENTRY.wono
			LEFT outer join SOMAIN on invt_res.SONO = somain.sono
			left outer join CUSTOMER as c1 on PJCTMAIN.CUSTNO = c1.CUSTNO
			left outer join CUSTOMER as C2 on WOENTRY.custno = C2.CUSTNO
			left outer join CUSTOMER as c3 on somain.CUSTNO = c3.custno
			inner join INVTMFGR on invt_res.W_KEY = invtmfgr.W_KEY
			-- 10/10/14 YS replace invtmfhd table with 2 new tables
			--inner join INVTMFHD on invtmfgr.UNIQMFGRHD = invtmfhd.UNIQMFGRHD
			inner join InvtMPNLink L on invtmfgr.UNIQMFGRHD = L.UNIQMFGRHD
			inner join MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
			inner join WAREHOUS on invtmfgr.UNIQWH = WAREHOUS.UNIQWH
			left outer join SODETAIL on invt_res.UNIQUELN = sodetail.UNIQUELN
			-- 10/01/19 VL added iReserveIpKey for MTC
			LEFT OUTER JOIN iReserveIpKey ON Invt_res.INVTRES_NO = iReserveIpKey.invtres_no
	
	group by invt_res.uniq_key
			,case when invt_res.WONO <> '' then CAST ('WoNo: ' + invt_res.WONO as CHAR (20)) 
				else case when invt_res.WONO = '' and invt_res.SONO = '' then CAST ('Proj No: ' + PJCTMAIN.PRJNUMBER as char (20)) 
					else CAST ('SoNo: ' + invt_res.sono + '/' + right(sodetail.line_no,3) as CHAR (20)) end end
			,lotcode,expdate,reference,ponum,part_no,revision,descript,part_class, part_type
			,case when invt_res.WONO <> '' then OPENCLOS 
				else case when invt_res.wono = '' and invt_res.sono = '' then PRJSTATUS else sodetail.STATUS end end
			,case when invt_res.wono <> '' then BLDQTY else SODETAIL.BALANCe end 
			,case when INVT_RES.WONO <> '' then c2.CUSTNO else CASe when invt_res.wono = '' and invt_res.sono = '' then c1.CUSTNO else c3.custno end end 
			,case when invt_res.WONO <> '' then c2.CUSTNAME else case when invt_res.WONO ='' and invt_res.SONO = '' then c1.CUSTNAME else c3.CUSTNAME end end 
			,case when invt_res.wono <> '' then WOENTRY.UNIQ_KEY else sodetail.UNIQ_KEY end
			,m.PARTMFGR,m.MFGR_PT_NO,invt_res.w_key,INVTMFGR.uniqwh,LOCATION,WAREHOUSE
			-- 10/01/19 VL added MTC
			, iReserveIpKey.ipkeyunique 
			
	having	SUM(qtyalloc) > 0.00
				)

Select	zallocd.uniq_key,AllocRec,sumqty,lotcode,expdate,reference,ponum,zallocd.part_no, zAllocD.revision,zAllocD.DESCRIPT,zAllocD.part_class,zAllocD.part_type
		,zallocd.status,OrdQty,zallocd.Custno,zallocd.CustName,puniq_key,zAllocD.partmfgr,zAllocD.mfgr_pt_no,uniqwh,location,warehouse
				,inventor.PART_NO as pPart_no,inventor.REVISION as pRevision
				-- 10/01/19 VL added MTC
				,ipkeyunique AS MTC
		from	zAllocD
				left outer join INVENTOR on zallocd.pUniq_key = inventor.UNIQ_KEY
		-- 08/17/20 VL added customer filter
		WHERE EXISTS (SELECT 1 FROM @tCustomer T WHERE T.Custno = zAllocD.Custno)
end