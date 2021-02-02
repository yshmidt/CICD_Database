
-- =============================================
-- Author:		Debbie
-- Create date:	02/08/2013
-- Description:	Created for the Purchase Part Shortages by Work Order Report
-- Reports:		shrtwopo.rpt
-- Modified:	08/05/2014 DRP:  Requested by a user that we add the PO Buyer to the results.  	
--			05/22/2015 DRP:  Needed to remove the CONSG items from the results.  
--			09/16/16 DRP:  Request to add the Mfgr and MPN assoicated to the Purchase Order items.  --also removed the lic_name from the procedure.  Additional note that I noticed that depending on the records between the PoScheduled the results could be doubled I left the procedure as is for now and updated the report form so it would not appear as doubled.  This issue has been there for some time, I just noticed it now but did not have time to address it   
-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record
-- 03/15/18 VL: Removed using KitDef.lSuppressNotUsedInKit because user didn't want to see part was checked ignored (zendesk#1866)
-- 11/08/18 VL: Added code to only calculate qty_oh for approved AVL, zendesk#2804
-- 03/20/19 VL This report didn't work if the kit was not in process, add code to get from BOM if the no kit records created yet
-- 07/02/19 VL: Found if the BUY part has CONSG part, but has less partmfgr in CONSG part, the code that get AVL willl get the partmfgr that only exists in BUY part, has to filter out, zendesk#5482
-- 07/03/19 VL added 11/08/18, 03/20/19 and 07/02/19 missing code
---- 10/11/2019 YS change char(25) to char(35) for part_no
-- 12/07/20 VL: mnxSettingsManagement.settingname was changed from 'Suppress Not Used in Kit items ?' to 'suppressNotUsedInKitItems'
-- =============================================
CREATE PROCEDURE [dbo].[rptKitPurchPartShortWo]
--declare	
		@lcWoNo as char(10) = ''
		,@lcSupShort as char(3) = 'Yes'
		, @userId uniqueidentifier=null 
as
begin

-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record
DECLARE @lSuppressNotUsedInKit int
SELECT @lSuppressNotUsedInKit = ISNULL(wm.settingValue,mnx.settingValue)
	FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm 
	ON mnx.settingId = wm.settingId 
	-- 12/07/20 VL: mnxSettingsManagement.settingname was changed from 'Suppress Not Used in Kit items ?' to 'suppressNotUsedInKitItems'
	--WHERE mnx.settingName='Suppress Not Used in Kit items ?'
	WHERE mnx.settingName='suppressNotUsedInKitItems'	

SET @lcWoNo=dbo.PADL(@lcWoNo ,10,'0')

-- 03/20/19 VL This report didn't work if the kit was not in process, add code to get from BOM if the wono is not in kit yet
IF EXISTS(SELECT 1 FROM Kamain WHERE Wono = @lcWono)
	BEGIN
		;with PoScheduled 
		AS
		(
			SELECT	poitems.Uniq_key,Poitems.Ponum,poitschd.uniqdetno,
					CASE WHEN poitems.PUR_UOFM=poitems.U_OF_MEAS THEN Poitschd.Balance
						ELSE dbo.fn_ConverQtyUOM(poitems.PUR_UOFM,poitems.U_OF_MEAS, POITSCHD.Balance) end as Balance,Schd_date, Poitems.Uniqlnno, Itemno
					,pomain.buyer --08/05/2014 DRP:  Added per request
					-- 07/03/19 VL changed to use MfgrMaster
					--,invtmfhd.partmfgr,invtmfhd.MFGR_PT_NO	--09/16/16 DRP:  added the partmfgr and mfgr_pt_no that are associated to the po items. 
					,M.partmfgr,M.MFGR_PT_NO
			FROM	Poitems INNER JOIN Pomain ON Pomain.PONUM=poitems.PONUM 
					INNER JOIN PoitSchd ON Poitschd.UNIQLNNO =poitems.UNIQLNNO 
					-- 07/03/19 VL removed Invtmfhd and use two new tables
					--left outer join invtmfhd on poitems.uniqmfgrhd = INVTMFHD.UNIQMFGRHD 
					LEFT OUTER JOIN InvtMPNLink L ON  Poitems.uniqmfgrhd = l.uniqmfgrhd
					LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
					-- 07/03/19 VL End
			WHERE	Pomain.Postatus = 'OPEN' 
					AND Poitems.lCancel = 0 
					AND Poitschd.Balance > 0 
					AND poitems.Uniq_key IN (SELECT Uniq_key FROM KAMAIN where WONO=@lcWoNo )
		) 

		--select * from poscheduled

		-- 07/03/09 VL copied the code that get approved avl, and changed to use two new mfgr tables
		-- 11/08/18 VL added code to get invtmfgr records for only approved, and need to consider the customer part number as well to get correct invtmfgr records
		,
		ZAVLLink1 AS
		(
		--declare @lcwono char(10)='300057.001'
		-- 07/02/19 VL if the BUY part has a CONSG part linked, and CONSG part has less invtmfhd record, the code would show all invtmfhd for the BUY part, should filter out to show only partmfgr show in CONSG part like BOM AVL
			SELECT Kamain.Uniq_key, Partmfgr, Mfgr_pt_no, Bomparent, I1.Bomcustno,ISNULL(I2.Uniq_key, Kamain.Uniq_key) AS LinkUniq_key, I2.Uniq_key AS I2Uniq_key
				FROM Kamain INNER JOIN Invtmpnlink L ON Kamain.Uniq_key = L.Uniq_key 
				INNER Join MfgrMaster M ON L.MfgrMasterId = M.MfgrMasterId
				INNER JOIN Inventor I1 ON Kamain.BOMPARENT = I1.Uniq_key
				INNER JOIN Woentry ON Kamain.Wono = Woentry.Wono
				LEFT OUTER JOIN Inventor I2 
		ON (Kamain.Uniq_key=I2.Int_uniq
		AND I1.BomCustno=I2.CustNo)
				WHERE Woentry.Wono = @lcWono
				AND NOT EXISTS (SELECT 1 FROM Antiavl A WHERE A.UNIQ_KEY = ISNULL(I2.Uniq_key, Kamain.Uniq_key) AND A.PARTMFGR = M.Partmfgr AND A.Mfgr_pt_no = M.MFGR_PT_NO AND A.BOMPARENT = Kamain.BOMPARENT)
		),
		-- 07/02/19 VL added to filter out the BUY part partmfgr that did not exist in CONSG part
		ZAVLLink AS
		(
		SELECT * FROM ZAVLLink1
			WHERE (Uniq_key = LinkUniq_key) -- BUY Part has no CONSG part
			OR (Uniq_key<>LinkUniq_key AND EXISTS -- BUY part has CONSG part, only want to pick partmfgr that exists in CONSG part
				(SELECT 1 from InvtMPNLink L INNER JOIN MfgrMaster M On L.MfgrMasterId = M.MfgrMasterId 
					INNER JOIN ZAVLLink1 Z ON Z.I2Uniq_key = L.uniq_key AND Z.PartMfgr = M.PartMfgr AND Z.mfgr_pt_no = M.Mfgr_pt_no)) 
		)
		-- 07/02/19 VL End}
		-- 11/08/18 VL End}

		select	case when LINESHORT = 1 then 'LS' else cast ('' as char(2))end as ShortType,
				woentry.WONO,woentry.DUE_DATE,woentry.BLDQTY,customer.CUSTNAME,P1.PART_NO as ProductNo,P1.REVISION as ProdRev,P1.DESCRIPT as ProdDesc,kamain.KASEQNUM,
				kamain.UNIQ_KEY,I1.PART_SOURC,
				case when i1.Part_sourc = 'CONSG' then I1.CustpartNo else I1.part_no end as PartNo,
				case when I1.part_sourc = 'CONSG' then I1.CUSTREV else I1.revision end as REv,
				I1.part_class,I1.part_type,I1.descript,kamain.qty as Qtyper,kamain.SHORTQTY,
				CAST(ISNULL(sumoh.On_HandQty,0.00) as numeric(12,2)) as On_HandQty ,
				CAST(ISNULL(NotAvailable.NotAvailable,0.00) as numeric(12,2)) as NotAvailable,
				PO.ponum,po.UniqDetNo,PO.Balance,po.Schd_Date
				,po.buyer --08/05/2014 DRP:  Added per request
				,cast(case when kamain.SHORTQTY >0.00 then 0 else 1 end as bit) as FullFilled	
				--,MICSSYS.LIC_name		--09/16/16 DRP:  removed
				,PO.PartMfgr,PO.MFGR_PT_NO	--09/16/16 DRP:  added the partmfgr and mfgr_pt_no that are associated to the po items. 
		from	WOENTRY	
				inner join CUSTOMER on woentry.CUSTNO = customer.CUSTNO
				inner join INVENTOR as P1 on woentry.UNIQ_KEY = P1.UNIQ_KEY
				inner join KAMAIN on woentry.WONO = kamain.wono
				OUTER APPLY 
				-- 07/03/19 VL added code to only get from approved AVL also use two new tables
				-- 11/08/18 VL changed to only get qty_oh for approved avl
				--(SELECT UNIQ_KEY,SUM(qty_oh) as On_HandQty FROM INVTMFGR where Invtmfgr.UNIQ_KEY=Kamain.UNIQ_KEY and Invtmfgr.Is_Deleted <> 1 group by uniq_key) as SumOh  
				(SELECT Invtmfgr.UNIQ_KEY,SUM(qty_oh) as On_HandQty FROM INVTMFGR INNER JOIN InvtMPNLink L ON Invtmfgr.Uniqmfgrhd = L.Uniqmfgrhd 
					INNER JOIN MfgrMaster M ON L.MfgrMasterId = M.MfgrMasterId
					WHERE Invtmfgr.UNIQ_KEY=Kamain.UNIQ_KEY 
					AND Invtmfgr.Is_Deleted <> 1 AND L.Is_Deleted = 0 
					AND EXISTS(SELECT 1 FROM ZAVLLink Z WHERE Invtmfgr.Uniq_key = Z.Uniq_key AND M.PARTMFGR = Z.Partmfgr AND M.Mfgr_pt_no = Z.Mfgr_pt_no)
					 group by Invtmfgr.uniq_key) as SumOh  
				-- 07/03/19 VL End
				inner join INVENTOR as I1 on kamain.UNIQ_KEY = I1.UNIQ_KEY
				OUTER APPLY 
				(SELECT Uniq_key, sum(reqqty) as NotAvailable FROM MrpSch2 WHERE  MrpSch2.Uniq_key =Kamain.Uniq_key and REQQTY<>0 group by uniq_key) as NotAvailable
				left outer join PoScheduled as PO on kamain.UNIQ_KEY = PO.Uniq_key
				--cross join micssys	09/16/16 DRP:  removed
									
		where	woentry.Wono = @lcWoNo 
				-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record
				--and kamain.IGNOREKIT <> 1
				-- 03/15/18 VL: Removed using KitDef.lSuppressNotUsedInKit because user didn't want to see part was checked ignored (zendesk#1866)
				-- 01/29/18 VL: Added to use KitDef.lSuppressNotUsedInKit to filter out IgnoreKit record
				and kamain.IGNOREKIT <> 1
				--AND 1 = CASE WHEN @lSuppressNotUsedInKit = 0 THEN 1 ELSE CASE WHEN IgnoreKit = 0 THEN 1 ELSE 0 END END
				and ((@lcSupShort = 'Yes' and shortqty>0.00) OR @lcSupShort<>'Yes')
				and i1.PART_SOURC <> 'CONSG'	--05/22/2015 DRP:  Added
		
--Below will add any misc. shortages that might have been added to the kit. 			
		union all
				select	cast ('MS' as char(2)) as ShortType,
				woentry.WONO,woentry.DUE_DATE,woentry.BLDQTY,customer.CUSTNAME,P1.PART_NO as Productno,p1.REVISION as ProdRev,p1.DESCRIPT,
				MISCMAIN.MISCKEY as kaseqnum,CAST('' as CHAR(10)) as Uniq_key,MISCmain.Part_sourc as part_sourc,MISCMAIN.PART_NO as Partno,MISCMAIN.REVISION as Rev,
				MISCMAIN.PART_CLASS,MISCMAIN.PART_TYPE,MISCMAIN.DESCRIPT,
				MISCMAIN.QTY as QtyPer,MISCMAIN.SHORTQTY,CAST (0.00 as numeric(12,2)) as On_HandQty,
				CAST (0.00 as numeric(12,2)),
				CAST ('' as CHAR(15)),CAST('' as CHAR(10)),CAST(0.00 as numeric(12,2)),
				CAST('' as smalldatetime) as SchdDate
				,CAST('' as CHAR(3)) as buyer	--08/05/2014 DRP:  Added per request
				,cast(case when MISCMAIN.SHORTQTY > 0.00 then 0 else 1 end as bit) as FullFilled
				--,MICSSYS.LIC_NAME		--09/16/16 DRP:  removed
				,cast('' as char(8)) as PartMfgr,cast('' as char(30)) as MFGR_PT_NO		--09/16/16 DRP:  added the partmfgr and mfgr_pt_no that are associated to the po items. 							
		from	WOENTRY	
				inner join CUSTOMER on woentry.CUSTNO = customer.CUSTNO
				inner join INVENTOR as P1 on woentry.UNIQ_KEY = P1.UNIQ_KEY
				left outer join MISCMAIN on woentry.WONO = MISCMAIN.wono
				--cross join MICSSYS	--09/16/16 DRP:  removed
				
		where	MISCMAIN.WONO = @lcWoNo
				and ((@lcSupShort = 'Yes' and shortqty>0.00) OR @lcSupShort<>'Yes')
				AND MISCmain.Part_sourc <> 'CONSG'	--05/25/2015 DRP:  Added
		ORDER BY 12,13		
	END
ELSE
-- 03/20/19 VL added if Kit is not in process
	BEGIN
	---- 10/11/2019 YS change char(25) to char(35) for part_no
		DECLARE @ZKitReq TABLE (Dept_id char(4), Uniq_key char(10), BomParent char(10), Qty numeric(12,2), ShortQty numeric(12,2),
			Used_inKit char(1), Part_Sourc char(8), Part_no char(35), Revision char(8), Descript char(45), Part_class char(8), 
			Part_type char(8), U_of_meas char(4), Scrap numeric(6,2), SetupScrap numeric(4,0), CustPartNo char(35), SerialYes bit)

		INSERT @ZKitReq EXEC [KitBomInfoView] @lcWono;
		;with PoScheduled 
		AS
		(
			SELECT	poitems.Uniq_key,Poitems.Ponum,poitschd.uniqdetno,
					CASE WHEN poitems.PUR_UOFM=poitems.U_OF_MEAS THEN Poitschd.Balance
						ELSE dbo.fn_ConverQtyUOM(poitems.PUR_UOFM,poitems.U_OF_MEAS, POITSCHD.Balance) end as Balance,Schd_date, Poitems.Uniqlnno, Itemno
					,pomain.buyer --08/05/2014 DRP:  Added per request
					-- 07/03/19 VL changed to use MfgrMaster
					--,invtmfhd.partmfgr,invtmfhd.MFGR_PT_NO	--09/16/16 DRP:  added the partmfgr and mfgr_pt_no that are associated to the po items. 
					,M.partmfgr,M.MFGR_PT_NO
			FROM	Poitems INNER JOIN Pomain ON Pomain.PONUM=poitems.PONUM 
					INNER JOIN PoitSchd ON Poitschd.UNIQLNNO =poitems.UNIQLNNO 
					-- 07/03/19 VL removed Invtmfhd and use two new tables
					--left outer join invtmfhd on poitems.uniqmfgrhd = INVTMFHD.UNIQMFGRHD 
					LEFT OUTER JOIN InvtMPNLink L ON  Poitems.uniqmfgrhd = l.uniqmfgrhd
					LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
					-- 07/03/19 VL End
					WHERE	Pomain.Postatus = 'OPEN' 
					AND Poitems.lCancel = 0 
					AND Poitschd.Balance > 0 
					AND poitems.Uniq_key IN (SELECT Uniq_key FROM @ZKitReq)
		) 

		--select * from poscheduled
		-- 07/03/09 VL copied the code that get approved avl, and changed to use two new mfgr tables
		-- 11/08/18 VL added code to get invtmfgr records for only approved, and need to consider the customer part number as well to get correct invtmfgr records
		,
		ZAVLLink1 AS
		(
		--declare @lcwono char(10)='300057.001'
		-- 07/02/19 VL if the BUY part has a CONSG part linked, and CONSG part has less invtmfhd record, the code would show all invtmfhd for the BUY part, should filter out to show only partmfgr show in CONSG part like BOM AVL
			SELECT ZKitReq.Uniq_key, Partmfgr, Mfgr_pt_no, Bomparent, I1.Bomcustno,ISNULL(I2.Uniq_key, ZKitReq.Uniq_key) AS LinkUniq_key, I2.Uniq_key AS I2Uniq_key
				FROM @ZKitReq ZKitReq INNER JOIN Invtmpnlink L ON ZKitReq.Uniq_key = L.Uniq_key 
				INNER Join MfgrMaster M ON L.MfgrMasterId = M.MfgrMasterId
				INNER JOIN Inventor I1 ON ZKitReq.BOMPARENT = I1.Uniq_key
				--INNER JOIN Woentry ON ZKitReq.Wono = Woentry.Wono
				LEFT OUTER JOIN Inventor I2 
		ON (ZKitReq.Uniq_key=I2.Int_uniq
		AND I1.BomCustno=I2.CustNo)
				, Woentry
				WHERE Woentry.Wono = @lcWono
				AND NOT EXISTS (SELECT 1 FROM Antiavl A WHERE A.UNIQ_KEY = ISNULL(I2.Uniq_key, ZKitReq.Uniq_key) AND A.PARTMFGR = M.Partmfgr AND A.Mfgr_pt_no = M.MFGR_PT_NO AND A.BOMPARENT = ZKitReq.BOMPARENT)
		),
		-- 07/02/19 VL added to filter out the BUY part partmfgr that did not exist in CONSG part
		ZAVLLink AS
		(
		SELECT * FROM ZAVLLink1
			WHERE (Uniq_key = LinkUniq_key) -- BUY Part has no CONSG part
			OR (Uniq_key<>LinkUniq_key AND EXISTS -- BUY part has CONSG part, only want to pick partmfgr that exists in CONSG part
				(SELECT 1 from InvtMPNLink L INNER JOIN MfgrMaster M On L.MfgrMasterId = M.MfgrMasterId 
					INNER JOIN ZAVLLink1 Z ON Z.I2Uniq_key = L.uniq_key AND Z.PartMfgr = M.PartMfgr AND Z.mfgr_pt_no = M.Mfgr_pt_no)) 
		)
		-- 07/02/19 VL End}
		-- 11/08/18 VL End}

		select	cast ('' as char(2)) as ShortType,
				woentry.WONO,woentry.DUE_DATE,woentry.BLDQTY,customer.CUSTNAME,P1.PART_NO as ProductNo,P1.REVISION as ProdRev,P1.DESCRIPT as ProdDesc,SPACE(10) AS KASEQNUM,
				ZKitReq.UNIQ_KEY,I1.PART_SOURC,
				case when i1.Part_sourc = 'CONSG' then I1.CustpartNo else I1.part_no end as PartNo,
				case when I1.part_sourc = 'CONSG' then I1.CUSTREV else I1.revision end as REv,
				I1.part_class,I1.part_type,I1.descript,ZKitReq.qty as Qtyper,ZKitReq.SHORTQTY,
				CAST(ISNULL(sumoh.On_HandQty,0.00) as numeric(12,2)) as On_HandQty ,
				CAST(ISNULL(NotAvailable.NotAvailable,0.00) as numeric(12,2)) as NotAvailable,
				PO.ponum,po.UniqDetNo,PO.Balance,po.Schd_Date
				,po.buyer --08/05/2014 DRP:  Added per request
				,cast(case when ZKitReq.SHORTQTY >0.00 then 0 else 1 end as bit) as FullFilled	
				--,MICSSYS.LIC_name		--09/16/16 DRP:  removed
				,PO.PartMfgr,PO.MFGR_PT_NO	--09/16/16 DRP:  added the partmfgr and mfgr_pt_no that are associated to the po items. 
		from	WOENTRY	
				inner join CUSTOMER on woentry.CUSTNO = customer.CUSTNO
				inner join INVENTOR as P1 on woentry.UNIQ_KEY = P1.UNIQ_KEY
				--inner join @ZKitReq ZKitReq on woentry.WONO = ZKitReq.wono
				, @ZKitReq ZKitReq
				OUTER APPLY 
				-- 07/03/19 VL added code to only get from approved AVL also use two new tables
				-- 11/08/18 VL changed to only get qty_oh for approved avl
				--(SELECT UNIQ_KEY,SUM(qty_oh) as On_HandQty FROM INVTMFGR where Invtmfgr.UNIQ_KEY=Kamain.UNIQ_KEY and Invtmfgr.Is_Deleted <> 1 group by uniq_key) as SumOh  
				(SELECT Invtmfgr.UNIQ_KEY,SUM(qty_oh) as On_HandQty FROM INVTMFGR INNER JOIN InvtMPNLink L ON Invtmfgr.Uniqmfgrhd = L.Uniqmfgrhd 
					INNER JOIN MfgrMaster M ON L.MfgrMasterId = M.MfgrMasterId
					WHERE Invtmfgr.UNIQ_KEY=ZKitReq.UNIQ_KEY 
					AND Invtmfgr.Is_Deleted <> 1 AND L.Is_Deleted = 0 
					AND EXISTS(SELECT 1 FROM ZAVLLink Z WHERE Invtmfgr.Uniq_key = Z.Uniq_key AND M.PARTMFGR = Z.Partmfgr AND M.Mfgr_pt_no = Z.Mfgr_pt_no)
					 group by Invtmfgr.uniq_key) as SumOh  
				inner join INVENTOR as I1 on ZKitReq.UNIQ_KEY = I1.UNIQ_KEY
				OUTER APPLY 
				(SELECT Uniq_key, sum(reqqty) as NotAvailable FROM MrpSch2 WHERE  MrpSch2.Uniq_key =ZKitReq.Uniq_key and REQQTY<>0 group by uniq_key) as NotAvailable
				left outer join PoScheduled as PO on ZKitReq.UNIQ_KEY = PO.Uniq_key
				--cross join micssys	09/16/16 DRP:  removed
				
		where	woentry.Wono = @lcWoNo 
				and ((@lcSupShort = 'Yes' and shortqty>0.00) OR @lcSupShort<>'Yes')
				and i1.PART_SOURC <> 'CONSG'	--05/22/2015 DRP:  Added
		
		ORDER BY 12,13		
	END
	-- 03/20/19 VL End}

end