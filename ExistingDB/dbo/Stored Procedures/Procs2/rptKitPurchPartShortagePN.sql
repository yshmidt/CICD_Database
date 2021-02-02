
-- =============================================
-- Author:		Vicky & Debbie
-- Create date: 09/10/2012
-- Description:	Created for the Purchased Part Shortage Summary Report by Part No within Kitting
-- Reports Using Stored Procedure:  shrtintp.rpt 
-- Modifications:  09/24/2012 DRP:  Jeanette brought to my attentin that I needed to trim the Supplier Name field so not all of the spaces where included in the resulting report
--				   09/25/2012  VL:	Changed to only insert 3 supplier in @Pur2, so later when updating @Supname, it will only have 3 as maximum
--				   10/02/2012 DRP:  within @pur2 which pulls in the misc items needed to have code added to filter out misc shortages when the Work Order is Closed/Cancelled or Archived.
--				   08/09/2013:  DEBBIE/YELENA:  With Yelena's help we added the nrec field to the results of the @zPoitems table.  and used the over partition to get the next poitschd.schd_date  	
--				   10/13/14   YS removed invtmfhd table
-- 04/14/15 YS Location length is changed to varchar(256)
--				   10/15/15 DRP:  Added @userId parameter so that we could have it setup to work with the Web Manex.  
--					10/15/15 YS Code optimization 
--					05/24/16 DRP:  needed to change the <<AvailQty numeric(8,2)>> to be <<AvailQty numeric(12,2)>> throughout the procedure, to address an overflow issue reported. 
--					07/25/16 DRP:  users report an numeric overflow error while attempting to run the report.  I found that the  @ZPoitems declared table had the Balances as numeric(12,2) but the @pur2 table had the balance as numeric(8,2) 
--									so when the code took balance information from the @zPoitems and attempted to update @pur2 it would cause an numeric overflow error. 
--- 03/28/17 YS changed length of the part_no column from 25 to 35	
-- 01/17/18 VL: Changed from CTE to table variable or temp table to speed up
-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record
-- 07/13/18 VL changed supname from char(30) to char(50)
-- 07/16/18 VL changed custname from char(35) to char(50)
-- 09/04/20 VL Fixed the table variable @ZPoBalance alias name
-- 12/07/20 VL: mnxSettingsManagement.settingname was changed from 'Suppress Not Used in Kit items ?' to 'suppressNotUsedInKitItems'
-- =============================================
CREATE PROCEDURE [dbo].[rptKitPurchPartShortagePN]

@userId uniqueidentifier=null	  

as
begin

-- 01/17/18 VL added code to drop temp tables
IF OBJECT_ID('tempdb..#ZPoitems') IS NOT NULL
	DROP TABLE #ZPoitems	
IF OBJECT_ID('tempdb..#Purch') IS NOT NULL
	DROP TABLE #Purch

--- 03/28/17 YS changed length of the part_no column from 25 to 35	
Declare @Pur1 table(WONO char(10),Dept_id char(4),Uniq_key char(120), Part_no Char(35), Revision char(25), Descript char(45), Part_Class char(8), Part_type char(8), Part_sourc char(10)
					,PUniq_key char(10),StdCost numeric(13,5),ProdNo char(35),pRevision char(8), Prod_id char(10),pDescript char(45),Flag char(1)
					,ShortQty numeric(12,2), BomCustno char(10), Int_Uniq char(10),Due_date smalldatetime,AVLLink char(10))

-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record
DECLARE @lSuppressNotUsedInKit int
SELECT @lSuppressNotUsedInKit = ISNULL(wm.settingValue,mnx.settingValue)
	FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm 
	ON mnx.settingId = wm.settingId 
	-- 12/07/20 VL: mnxSettingsManagement.settingname was changed from 'Suppress Not Used in Kit items ?' to 'suppressNotUsedInKitItems'
	--WHERE mnx.settingName='Suppress Not Used in Kit items ?'
	WHERE mnx.settingName='suppressNotUsedInKitItems'	

-- 10/15/15 YS Why do we need distinct
Insert @Pur1	select	
						--DISTINCT 
						kamain.WONO,Kamain.Dept_id,I1.Uniq_key, I1.Part_no, I1.Revision, I1.Descript, I1.Part_Class, I1.Part_type, I1.Part_sourc,woentry.UNIQ_KEY as PUniq_key
						,I1.StdCost,I2.Part_no AS ProdNo, I2.Revision AS pRevision, I2.Prod_id, I2.Descript AS pDescript,CAST ('M' as CHAR(1)) as Flag
						,SUM(kamain.SHORTQTY) AS ShortQty, I2.BomCustno, I1.Int_Uniq,Due_date, SPACE(10) AS AVLLink
				from	KAMAIN
						inner join INVENTOR as I1 on kamain.UNIQ_KEY = I1.uniq_key
						inner join WOENTRY  on kamain.WONO = woentry.WONO
						inner join INVENTOR as I2 on woentry.UNIQ_KEY = I2.uniq_key
				where	kamain.SHORTQTY > 0.00
						-- 01/29/18 VL: Added to use KitDef.lSuppressNotUsedInKit to filter out IgnoreKit record
						-- 10/15/15 YS instead of <> use =
						--and kamain.IGNOREKIT=0
						--and KAMAIN.IGNOREKIT <> 1
						AND 1 = CASE WHEN @lSuppressNotUsedInKit = 0 THEN 1 ELSE CASE WHEN IgnoreKit = 0 THEN 1 ELSE 0 END END
						--10/15/15 YS remove left()
						AND Woentry.OpenClos NOT IN ('archived','Closed','Cancel')
						--left(Woentry.OpenClos,1)<>'C'
						-- 10/15/15 YS Why do we need distinct
						-- no need for lower()
						---AND Woentry.OpenClos<>'archived' 
						AND I1.Part_Sourc <> 'CONSG' 
				group by kamain.WONO,Kamain.Dept_id,I1.Uniq_key, I1.Part_no, I1.Revision, I1.Descript, I1.Part_Class, I1.Part_type, I1.Part_sourc,woentry.UNIQ_KEY
						,I1.StdCost,I2.Part_no, I2.Revision, I2.Prod_id, I2.Descript,I2.BOMCUSTNO,I1.INT_UNIQ,DUE_DATE

update @Pur1 set AVLLink = ISNULL(Inventor.Uniq_key, ZP.Uniq_key) 
				from @Pur1 as ZP
				LEFT OUTER JOIN Inventor ON (ZP.Uniq_key = Inventor.Int_uniq AND ZP.BomCustno = Inventor.CustNo	AND Inventor.part_sourc = 'CONSG     ')

--select * from @Pur1
--- 03/28/17 YS changed length of the part_no column from 25 to 35	
declare @NoAVLNeedWoHeader table	(wono char(10),Dept_id char(4),Uniq_key char(10),part_no char(35),Revision Char(8),Descript char(45),part_class char(8)
									,part_type Char(8),Part_sourc char(10),PUniq_key char(10),StdCost numeric(13,5),
									--- 03/28/17 YS changed length of the part_no column from 25 to 35	
									ProdNo char(35),pRevision char(8)
									,Prod_id char(10),pDescript char(45),Flag char(1),ShortQty numeric(12,2), BomCustno char(10), Int_Uniq char(10)
									,Due_date smalldatetime,PartMfgr char (8))			

;
with
ZNoInvtMfhd	 as (
				--10/13/14 YS removed invtmfhd also vhange from not in to not exists
				--SELECT Uniq_key FROM @Pur1 as P1 WHERE Uniq_key NOT IN (SELECT Uniq_key FROM Invtmfhd)
				SELECT Uniq_key FROM @Pur1 as P1 WHERE NOT EXISTS (SELECT 1 FROM InvtMPNLink L where l.uniq_key=p1.Uniq_key) 
				)
,

ZNoAVLNeedWoHeader as	(
						SELECT Wono, Dept_id, Uniq_key, Part_no, Revision, Descript, Part_Class, Part_type, Part_sourc, pUniq_key
						,StdCost, ProdNo, pRevision, Prod_id, pDescript, cast ('W' as CHAR(1)) AS Flag, ShortQty, BomCustno, Int_Uniq,Due_date
						,cast ('No BOM' as CHAR(8)) AS Partmfgr
						FROM @Pur1 as P2	
						--10/15/15 YS use  exists 
						--WHERE Uniq_key IN(SELECT Uniq_key FROM ZNoInvtmfhd)
						WHERE exists (select 1 from ZNoInvtmfhd where ZNoInvtmfhd.Uniq_key =p2.Uniq_key)
						)
insert @NoAVLNeedWoHeader select ZNoAVLNeedWoHeader.* from ZNoAVLNeedWoHeader

--select * from @NoAVLNeedWoHeader

-- rename to @pur2
-- 04/14/15 YS Location length is changed to varchar(256)
--07/25/16 DRP:  changed Balance numeric(8,2) to be numeric(12,2)
--- 03/28/17 YS changed length of the part_no column from 25 to 35	
-- 07/13/18 VL changed supname from char(30) to char(50)
-- 07/16/18 VL changed custname from char(35) to char(50)
declare @Pur2 table (WONO char(10),Dept_id char(4),Uniq_key char(120), Part_no Char(35), Revision char(25), Descript char(45), Part_Class char(8), Part_type char(8), Part_sourc char(10)
					,PUniq_key char(10),StdCost numeric(13,5),
					--- 03/28/17 YS changed length of the part_no column from 25 to 35	
					ProdNo char(35),pRevision char(8), Prod_id char(10),pDescript char(45),Flag char(1),ShortQty numeric(12,2), BomCustno char(10)
					,Int_Uniq char(10),Due_date smalldatetime,AVLLink char(10),AvailQty numeric(12,2),PartMfgr char(8),Mfgr_Pt_No char(30),Warehouse char (6),Location varchar (256),w_key char(10)
					,PoNum char(15),ReqDate smalldatetime,SchdDate smalldatetime,Balance numeric(12,2),PoStatus char(8),PoSupName char(50),Dept_Name char(25),MisType char(1),UniqMfgrHd char(10)
					,Uniqwh char(10),CustName char(50),SupName Text, Note1 Text )

-- added last criteria
--10/13/14 YS removed invtmfhd table
--10/15/15 YS  why do we need distinct here? I will remove it for now
--07/25/16 DRP:  changed Balance numeric(8,2) to be numeric(12,2)
insert @Pur2 select  
					--DISTINCT 
					-- 07/13/18 VL changed supname from char(30) to char(50)
					-- 07/16/18 VL changed custname from char(35) to char(50)
					P3.*,CAST (00000000.00 as numeric(8,2)),m.PartMfgr,m.Mfgr_pt_no,WAREHOUSE,LOCATION,W_KEY,CAST('' as CHAR (15)),cast ('' as smalldatetime) 
					,CAST('' as smalldatetime) as Schd_Date,CAST (00000000.00 as numeric(12,2)) as Balance,CAST('' as CHAR (8)) as PoStatus,CAST(''as CHAR(50)) as PoSupName
					,CAST ('' as CHAR(25)) as Dept_name,CAST('F' as CHAR(1)) as Mistype,l.UNIQMFGRHD,invtmfgr.UNIQWH,CAST('' as CHAR(50)) as CustName,'' as SupName,'' AS Note1
			from	@Pur1 as P3	
					--10/13/14 YS removed invtmfhd table
					--inner join INVTMFHD on P3.UNIQ_KEY = Invtmfhd.UNIQ_KEY
					inner join InvtMPNLink L on P3.UNIQ_KEY = L.UNIQ_KEY
					INNER JOIN MfgrMaster M ON l.mfgrMasterId  =m.MfgrMasterId
					inner join INVTMFGR on l.UNIQMFGRHD = invtmfgr.UNIQMFGRHD
					inner join warehous on invtmfgr.UNIQWH = WAREHOUS.UNIQWH
			-- 10/15/15 YS change from <> to =
			where	INVTMFGR.IS_DELETED = 0
			--INVTMFGR.IS_DELETED <> 1
			and l.IS_DELETED = 0
					--and invtmfhd.IS_DELETED <> 1
					--10/13/14 YS replace not with not exists
					--and P3.AVLLink+PARTMFGR+MFGR_PT_NO+PUniq_key not IN (select uniq_key+partmfgr+mfgr_pt_no+bomparent from ANTIAVL)
					and not EXISTS (select 1  FROM AntiAvl A WHERE A.uniq_key=P3.AVLLink and 
									A.partmfgr=m.PartMfgr and a.mfgr_pt_no=m.mfgr_pt_no
									and a.bomparent=p3.PUniq_key )
					--10/13/14 YS replace "IN" WITH exists
					--AND P3.AVLLink+PARTMFGR+MFGR_PT_NO IN (SELECT Uniq_key+PARTMFGR+MFGR_PT_NO FROM Invtmfhd WHERE Is_deleted = 0)
					AND EXISTS (select 1 from InvtMPNLink L1 INNER JOIN MfgrMaster M1 ON L1.mfgrMasterId=M1.MfgrMasterId 
								WHERE l1.uniq_key=P3.AVLLink and M1.PartMfgr=M.PartMfgr and M1.mfgr_pt_no=M.mfgr_pt_no
								AND L1.is_deleted=0)
-- 04/14/15 YS Location length is changed to varchar(256)
--07/25/16 DRP:  changed Balance numeric(8,2) to be numeric(12,2)
-- 07/13/18 VL changed supname from char(30) to char(50)
-- 07/16/18 VL changed custname from char(35) to char(50)
INSERT @Pur2 SELECT	DISTINCT wono,Dept_id,Uniq_key,part_no,Revision,Descript,part_class,part_type,Part_sourc,PUniq_key,StdCost,ProdNo,pRevision,Prod_id,pDescript,Flag,ShortQty,BomCustno
					,Int_Uniq,Due_date,SPACE (10) as AvlLink,CAST (00000000.00 as numeric(8,2)),PartMfgr,cast ('' as char(30)) as Mfgr_pt_no,cast ('' as char(60)) as WAREHOUSE
					,cast ('' as varchar(256)) as LOCATION,cast ('' as char(10)) as W_KEY,CAST('' as CHAR (15)) as PoNum,cast ('' as smalldatetime) as ReqDate 
					,CAST('' as smalldatetime) as Schd_Date,CAST (00000000.00 as numeric(12,2)) as Balance,CAST('' as CHAR (8)) as PoStatus,CAST(''as CHAR(50)) as PoSupName
					,CAST ('' as CHAR(25)) as Deptname,CAST('F' as CHAR(1)) as Mistype,cast ('' as char(10)) as UNIQMFGRHD, cast ('' as char(10)) as UNIQWH
					,CAST('' as CHAR(50)) as CustName,'' as SupName, '' AS Note1 FROM @NoAVLNeedWoHeader


--** Get Resqty from Invt_res to update AvailQty
-- 1)Update Avail qty first

-- 01/17/18 VL changed from CTE to table variable to see if it speed up
--;
--WITH
--ZupdInvtQty as (SELECT SUM(Qty_oh-Reserved) AS Avail, Invtmfgr.W_key 
--				FROM Invtmfgr 
--				--10/15/15 YS use exists really distinct here too?
--				--WHERE Invtmfgr.W_key IN	(SELECT DISTINCT W_key	FROM @Pur2)
--				WHERE exists (SELECT 1 FROM @Pur2 P2 where p2.w_key=Invtmfgr.W_key)
--				-- 10/15/15 ys use =
--				--AND Is_Deleted <>1
--				and is_deleted=0
--				GROUP BY W_key
--				)
--UPDATE @Pur2	
--	SET AvailQty = AvailQty + ZUpdInvtQty.Avail
--	FROM @Pur2 Pur2, ZupdInvtQty
--	WHERE Pur2.W_key = ZupdInvtQty.W_key
-- 01/17/18 VL start new code
DECLARE @ZUpdInvtQty TABLE (Avail numeric(12,2), w_key char(10))
INSERT INTO @ZUpdInvtQty 
SELECT SUM(Qty_oh-Reserved) AS Avail, Invtmfgr.W_key 
				FROM Invtmfgr 
				--10/15/15 YS use exists really distinct here too?
				--WHERE Invtmfgr.W_key IN	(SELECT DISTINCT W_key	FROM @Pur2)
				WHERE exists (SELECT 1 FROM @Pur2 P2 where p2.w_key=Invtmfgr.W_key)
				-- 10/15/15 ys use =
				--AND Is_Deleted <>1
				and is_deleted=0
				GROUP BY W_key
-- 01/17/18 VL End}

UPDATE @Pur2	
	SET AvailQty = AvailQty + ZUpdInvtQty.Avail
	FROM @Pur2 Pur2, @ZupdInvtQty ZupdInvtQty
	WHERE Pur2.W_key = ZupdInvtQty.W_key

--2) Now update allocated qty for this wono+w_key				
;
WITH
zUpdInvtAlloc as (SELECT 
					--DISTINCT 
					SUM(QtyAlloc) AS QtyRes, W_key, Wono 
					FROM Invt_res 
					-- 10/15/15 YS no comments
					WHERE exists (select 1 from @Pur2 p2 where p2.w_key=INVT_RES.w_key and p2.wono=invt_res.wono)  
					--W_key + Wono IN (SELECT DISTINCT W_key+Wono FROM @Pur2) 
					GROUP BY W_key, Wono 
					)
UPDATE @Pur2	
	SET AvailQty = AvailQty + zUpdInvtAlloc.QtyRes
	FROM @Pur2 Pur2, zUpdInvtAlloc
	WHERE Pur2.W_key = zUpdInvtAlloc.W_key
	AND Pur2.WONO = zUpdInvtAlloc.WONO

---10/15/15 YS I did not change anything below this point. I think that the code can be modified further, seems like too many little selects and updates.

--SELECT * FROM @Pur2

--08/09/2013:  DEBBIE/YELENA:  With Yelena's help we added the nrec field to the results of the @zPoitems table.  and used the over partition to get the next poitschd.schd_date
--07/25/16 DRP:  changed Balance numeric(8,2) to be numeric(12,2)
--** get PO data
-- 01/17/18 VL changed to use temp table, in EAL's data, it's really slow for the next two SQL
--declare @ZPoitems table (PoNum char(15),CoNum numeric(3),ItemNo char(3),Uniqlnno char(10),postatus char(8),uniqdetno char(10),Schd_date smalldatetime
--						,Req_date smalldatetime,Balance numeric(12,2),PoSupName char(30),Note1 text,UniqWh char(10),uniqmfgrhd char(10),uniq_key char(10)
--						,CnvtBalance numeric(12,2),nrec integer)
-- 07/13/18 VL changed supname from char(30) to char(50)
CREATE TABLE #ZPoitems (PoNum char(15),CoNum numeric(3),ItemNo char(3),Uniqlnno char(10),postatus char(8),uniqdetno char(10),Schd_date smalldatetime
						,Req_date smalldatetime,Balance numeric(12,2),PoSupName char(50),Note1 text,UniqWh char(10),uniqmfgrhd char(10),uniq_key char(10)
						,CnvtBalance numeric(12,2),nrec integer)

CREATE NONCLUSTERED INDEX UniqMfgrhd ON #ZPoitems (UniqMfgrhd)


INSERT #ZPoitems 
			SELECT	Poitems.Ponum,Pomain.Conum,ItemNo,Poitems.Uniqlnno,Pomain.Postatus,Poitschd.Uniqdetno,Poitschd.Schd_date
					,Poitschd.Req_date,Poitschd.Balance,Supinfo.SupName,Poitems.Note1, Poitschd.UniqWh, Poitems.Uniqmfgrhd,Poitems.Uniq_key
					,Poitschd.Balance AS CnvtBalance,ROW_NUMBER() OVER (PARTITION by poitems.uniqmfgrhd,poitschd.uniqwh order by poitschd.schd_date) as nRec 
			FROM	Poitems,PoMain,Poitschd,Supinfo,@pur2 as P4
			WHERE	Poitschd.Uniqlnno=Poitems.Uniqlnno 
					AND Poitems.Uniqmfgrhd = P4.UniqMfgrhd 
					AND Poitschd.UniqWh=P4.UniqWh 
					AND Poitschd.Balance>0
					AND Pomain.UniqSupNo=Supinfo.UniqSUpno 
					AND LEFT(Pomain.Postatus,1)<>'C' 
					AND Pomain.Ponum=Poitems.Ponum 

-- 01/17/18 VL changed from CTE to table variable to see if it speed up
--;
--WITH ZPoBalance as	(
--				SELECT	ZPoitems.*, Inventor.pur_uofm, Inventor.U_of_meas 
--				FROM	@ZPoitems ZPoitems, Inventor
--				WHERE	ZPoitems.Uniq_key = Inventor.Uniq_key
--						AND Inventor.Pur_uofm <> Inventor.U_of_meas 	
--					)	
-- 01/17/18 VL changed from table variable @Zpoitems to @Zpoitems
DECLARE @ZPoBalance TABLE (UniqWh char(10),uniqmfgrhd char(10), Pur_uofm char(4), U_of_meas char(4))
INSERT INTO @ZPoBalance 
	SELECT UniqWh, UniqMfgrhd, Inventor.pur_uofm, Inventor.U_of_meas 
		FROM #ZPoitems ZPoitems, Inventor
				WHERE	ZPoitems.Uniq_key = Inventor.Uniq_key
						AND Inventor.Pur_uofm <> Inventor.U_of_meas 

-- Convert balance from pur uom to stock uom	
-- 01/17/18 VL changed from table variable @Zpoitems to @Zpoitems		
-- 09/04/20 VL Fixed the table variable @ZPoBalance alias name
UPDATE #ZPoitems	
	SET CnvtBalance = dbo.fn_ConverQtyUOM(ZPoBalance.Pur_uofm, ZPoBalance.U_of_meas, ZPoitems.CnvtBalance)
	FROM #ZPoitems ZPoitems, @ZPoBalance ZPoBalance
	WHERE ZPoitems.UniqWh = ZPoBalance.UniqWh
	AND ZPoitems.UniqMfgrhd = ZPoBalance.UniqMfgrhd

--08/09/2013:  DEBBIE/YELENA:  Now added the ZPoitems.nRec = 1 so that we take the next PO Items schedule. 
-- Now update @pur2
-- 01/17/18 VL changed from table variable @Zpoitems to @Zpoitems
UPDATE @Pur2	
	SET Ponum = ZPoitems.Ponum,
		ReqDate = ZPoitems.Req_Date,
		SchdDate = ZPoitems.Schd_Date,
		Balance = ZPoitems.Balance,
		PoStatus = ZPoitems.PoStatus,
		PoSupName = ZPoitems.PoSupName,
		Note1 = ZPoitems.Note1
	FROM @Pur2 Pur, #ZPoitems ZPoitems
	WHERE Pur.UniqWh = ZPoitems.UniqWh
	AND Pur.UniqMfgrhd = ZPoitems.UniqMfgrhd
	and ZPoitems.nRec=1
	


-- Now should be ok to start with supplier info
DECLARE @SupName TABLE (nRecno int, Partmfgr char(8), Part_class char(8), SupName Text)
-- Create @SupName2 for manipulating data inserted to @SupName
-- 07/13/18 VL changed supname from char(30) to char(50)
DECLARE @SupName2 TABLE (Partmfgr char(8), Part_class char(8), SupName char(50))
DECLARE @str varchar(4000), @lnTotalCount int, @lnCnt int, @lnTableVarCnt int, @lcPartmfgr char(8), @lcPart_class char(8)

SET @lnCnt = 0
SET @lnTableVarCnt = 0

-- Get supplier partmfgr, part_class info for @Pur2 supplier
-- 09/25/12 VL changed to only insert 3 supplier in @Pur2, so later when updating @Supname, it will only have 3 as maximum
--INSERT @SupName2 (SupName, Partmfgr, Part_class)
--	SELECT DISTINCT SupName, Partmfgr, Part_class 
--		FROM SupClass, SupMfgr, Supinfo
--		WHERE Supinfo.UniqSupno = SUPCLASS.UniqSupno
--		AND SupClass.UniqSupno = SupMfgr.UniqSupno
--		AND (LTRIM(RTRIM(Supinfo.Status))='PREFERRED' OR LTRIM(RTRIM(Supinfo.Status))='APPROVED')
--		AND PARTMFGR+PART_CLASS IN (SELECT PARTMFGR+PART_CLASS FROM @Pur2)
--	ORDER BY Partmfgr, Part_class
;
WITH ZPrepareSup1 AS
(SELECT DISTINCT SupName, Partmfgr, Part_class 
		FROM SupClass, SupMfgr, Supinfo
		WHERE Supinfo.UniqSupno = SUPCLASS.UniqSupno
		AND SupClass.UniqSupno = SupMfgr.UniqSupno
		AND (LTRIM(RTRIM(Supinfo.Status))='PREFERRED' OR LTRIM(RTRIM(Supinfo.Status))='APPROVED')
		AND PARTMFGR+PART_CLASS IN (SELECT PARTMFGR+PART_CLASS FROM @Pur2)
),
ZPrePareSup AS
(SELECT SupName, Partmfgr, Part_class, ROW_NUMBER() OVER(PARTITION BY Partmfgr, Part_class ORDER BY SupName ASC) AS 'RowNum' 
	from ZPrepareSup1
)

INSERT @SupName2 (SupName, Partmfgr, Part_class)
	SELECT SupName, Partmfgr, Part_class
	FROM ZPrePareSup 
	WHERE RowNum <= 3
-- 09/25/12 VL End	

SET @lnTotalCount = @@ROWCOUNT;
INSERT @SupName (Partmfgr, Part_class) SELECT Partmfgr, Part_class FROM @SupName2
UPDATE @SupName SET @lnTableVarCnt = nRecno = @lnTableVarCnt + 1

-- Start to create Sup1, sup2, sup3... data for @SupName.Supname
IF @lnTotalCount <> 0		
BEGIN
	WHILE @lnTotalCount> @lnCnt
	BEGIN
	SET @lnCnt = @lnCnt + 1	
	SELECT @lcPartmfgr = Partmfgr, @lcPart_class = Part_class FROM @SupName WHERE nRecno = @lnCnt;
	IF @@ROWCOUNT > 0
		BEGIN
		SET @str = NULL
-->> 09/24/2012 DRP:  Jeanette brought to my attentin that I needed to trim the Supplier Name field so not all of the spaces where included in the resulting report
		--SELECT @str = COALESCE(@str + ',', '') + Supname
		SELECT @str = COALESCE(@str + ', ', '') + LTRIM(RTRIM(Supname ))
			FROM @SupName2 
			WHERE Partmfgr = @lcPartmfgr
			AND Part_class = @lcPart_class
			ORDER BY SupName
		-- Show first 3 supname
		SET @str = LEFT(@str,92)
		UPDATE @SupName 
			SET Supname = @str 
			WHERE Partmfgr = @lcPartmfgr
			AND Part_class = @lcPart_class
		
	END
	END
END		

--Now Update @Pur2.SupName (by linking partmfgr and part_class to @SupName)
UPDATE @Pur2
	SET Supname = SupName.SupName
	FROM @Pur2 Pur2, @SupName SupName
	WHERE Pur2.PartMfgr = SupName.Partmfgr
	AND Pur2.Part_Class = SupName.Part_class

-- Update Dept_name field in @Pur2
UPDATE @Pur2
	SET Dept_name = Depts.DEPT_NAME
	FROM @Pur2 Pur2, DEPTS
	WHERE Pur2.Dept_id = Depts.DEPT_ID	


	--- 03/28/17 YS changed length of the part_no column from 25 to 35	
	DECLARE @ZFlagW TABLE (Wono char(10), Uniq_key char(10), Part_no char(35), Revision char(25), ShortQty numeric(12,2), pUniq_key char(10), Prodno char(35),
							Due_date smalldatetime, Flag char(1), Dept_id char(4), Dept_name char(25))
	INSERT @ZFlagW
		SELECT DISTINCT Wono,Uniq_key,Part_no,Revision,ShortQty,pUniq_key,ProdNo,Due_date,'W' AS Flag,Dept_id,Dept_name 
		FROM @Pur2
	
	UPDATE @Pur2
		SET WONO = '',
			ShortQty = 0,
			Dept_id = '',
			Dept_Name = '',
			Due_date = Null
		WHERE 1 = 1
		
	INSERT @Pur2 (WONO, Uniq_key, Part_no, Revision, ShortQty, pUniq_key, ProdNo, Due_date, Flag, Dept_id, Dept_name )
		SELECT * FROM @ZFlagW	


-- Now update with MISC
--10/02/2012 DRP:  within @pur2 which pulls in the misc items needed to have code added to filter out misc shortages when the Work Order is Closed/Cancelled or Archived.
INSERT @Pur2 (ShortQty, WONO, Part_no, Revision, Descript, Part_Class, Part_type, Part_Sourc, MisType, 
			Uniq_key, Due_date, ProdNo, pRevision, Prod_id, Flag,Dept_id, Dept_Name, pUniq_key, StdCost, pDescript)
	SELECT ShortQty, Miscmain.WONO, Miscmain.Part_no, Miscmain.Revision, Miscmain.Descript, Miscmain.Part_Class, Miscmain.Part_type, 
			Miscmain.Part_Sourc, 1 AS MisType, 
			dbo.fn_GenerateUniqueNumber() AS Uniq_key, Due_date, Inventor.PART_NO AS Part_no, Inventor.REVISION AS pRevision, 
			Inventor.PROD_ID, 'W' AS Flag, Miscmain.DEPT_ID, ISNULL(Depts.Dept_name, SPACE(25)) AS Dept_name, Inventor.UNIQ_KEY AS pUniq_key,
			StdCost, Inventor.DESCRIPT AS pDescript		
		FROM Woentry,Inventor,Miscmain LEFT OUTER JOIN Depts 
		ON Miscmain.Dept_id = Depts.Dept_id
		WHERE Woentry.Wono = Miscmain.Wono 
		AND ShortQty > 0 
		AND Miscmain.part_sourc <> 'CONSG'
		AND Woentry.Uniq_key = Inventor.Uniq_key
		AND left(Woentry.OpenClos,1)<>'C'
		AND LOWER(Woentry.OpenClos)<>'archived'


-- because Note1 and Supname are Text type, can not use SELECT DISTINCT, will copy DISTINCT data to @Purch, then update Note1 and Supname from @Pur2
-- 04/14/15 YS Location length is changed to varchar(256)
--07/25/16 DRP:  changed Balance numeric(8,2) to be numeric(12,2)
--- 03/28/17 YS changed length of the part_no column from 25 to 35	
-- 01/17/18 VL changed to use temp table, in EAL's data, it's really slow for the next two SQL
--DECLARE @Purch TABLE  (WONO char(10),Dept_id char(4),Uniq_key char(120), Part_no Char(35), Revision char(25), Descript char(45), Part_Class char(8), Part_type char(8), Part_sourc char(10)
--					,PUniq_key char(10),StdCost numeric(13,5),
--					--- 03/28/17 YS changed length of the part_no column from 25 to 35	
--					ProdNo char(35),pRevision char(8), Prod_id char(10),pDescript char(45),Flag char(1),ShortQty numeric(12,2), BomCustno char(10)
--					,Int_Uniq char(10),Due_date smalldatetime,AVLLink char(10),AvailQty numeric(12,2),PartMfgr char(8),Mfgr_Pt_No char(30),Warehouse char (6),Location varchar (256),w_key char(10)
--					,PoNum char(15),ReqDate smalldatetime,SchdDate smalldatetime,Balance numeric(12,2),PoStatus char(8),PoSupName char(30),Dept_Name char(25),MisType char(1),UniqMfgrHd char(10)
--					,Uniqwh char(10),CustName char(35),SupName Text, Note1 Text )
-- 07/13/18 VL changed supname from char(30) to char(50)
-- 07/16/18 VL changed custname from char(35) to char(50)
CREATE TABLE #Purch (WONO char(10),Dept_id char(4),Uniq_key char(120), Part_no Char(35), Revision char(25), Descript char(45), Part_Class char(8), Part_type char(8), Part_sourc char(10)
					,PUniq_key char(10),StdCost numeric(13,5),
					--- 03/28/17 YS changed length of the part_no column from 25 to 35	
					ProdNo char(35),pRevision char(8), Prod_id char(10),pDescript char(45),Flag char(1),ShortQty numeric(12,2), BomCustno char(10)
					,Int_Uniq char(10),Due_date smalldatetime,AVLLink char(10),AvailQty numeric(12,2),PartMfgr char(8),Mfgr_Pt_No char(30),Warehouse char (6),Location varchar (256),w_key char(10)
					,PoNum char(15),ReqDate smalldatetime,SchdDate smalldatetime,Balance numeric(12,2),PoStatus char(8),PoSupName char(50),Dept_Name char(25),MisType char(1),UniqMfgrHd char(10)
					,Uniqwh char(10),CustName char(50),SupName Text, Note1 Text )

-- 01/17/18 VL also created index
CREATE NONCLUSTERED INDEX Ponum ON #Purch (Ponum)
CREATE NONCLUSTERED INDEX Uniq_key ON #Purch (Uniq_key)
CREATE NONCLUSTERED INDEX Part_class ON #Purch (Part_class)
CREATE NONCLUSTERED INDEX Partmfgr ON #Purch (Partmfgr)
	
-- 01/17/18 VL changed from table variable					
INSERT #Purch (wono,uniq_key,part_no,revision,descript,part_class,part_type,shortqty,custname,part_sourc,partmfgr,availqty,stdcost,mfgr_pt_no,warehouse,location,
		w_key,dept_id,dept_name,ponum,reqdate,schddate,balance,postatus,puniq_key,prodno,prevision,pdescript,due_date,flag,mistype,posupname)
	SELECT DISTINCT wono,uniq_key,part_no,revision,descript,part_class,part_type,shortqty,custname,part_sourc,partmfgr,availqty,stdcost,mfgr_pt_no,warehouse,location,
			w_key,dept_id,dept_name,ponum,reqdate,schddate,balance,postatus,puniq_key,prodno,prevision,pdescript,due_date,flag,mistype,posupname
		FROM @Pur2
--SELECT * from @Purch

--Now update Note1 and Supname 'Text' fields
-- 01/17/18 VL changed from table variable	
UPDATE #Purch
	SET Note1 = Pur2.Note1
	FROM #Purch Purch, @Pur2 Pur2
	WHERE Purch.PoNum = Pur2.PoNum
	AND Purch.Uniq_key = Pur2.Uniq_key

-- 01/17/18 VL changed from table variable	
UPDATE #Purch
	SET Supname = Pur2.Supname
	FROM #Purch Purch, @Pur2 Pur2
	WHERE Purch.Part_class = Pur2.Part_class
	AND Purch.Partmfgr = Pur2.Partmfgr
										
-- 01/17/18 VL changed from table variable	
SELECT P5.*,LIC_NAME FROM #Purch as P5 cross join MICSSYS ORDER BY Part_no,Revision,pUniq_key,Flag,Partmfgr,Mfgr_pt_no,Due_date,Wono,Dept_id

-- 01/17/18 VL added code to drop temp tables
IF OBJECT_ID('tempdb..#ZPoitems') IS NOT NULL
	DROP TABLE #ZPoitems	
IF OBJECT_ID('tempdb..#Purch') IS NOT NULL
	DROP TABLE #Purch

end