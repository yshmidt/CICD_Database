-- =============================================
-- Author: Yelena Shmidt
-- Create date: 08/06/2013
-- Description: MRP - Inventory Part View by manufacturer
-- Modifications: 09/12/2013 YELENA/DEB: FOUND THAT THE BALANCE IN THE fn_ConverQtyPUOM was in the incorrection and needed to be moved to the end. see the ---Get Action messages section
--				   10/13/14 YS : replaced invtmfhd table with 2 new tables
-- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int
-- 04/14/15 YS Location length is changed to varchar(256)
--				11/18/15 DRP:	replaced <<cast('' as varchar(max)) as Mfgrs>> with <<partmfgr as Mfgrs>>  It used to display this info on the VFP report and the users requested that this info be added back in
--				12/11/15 DRP:  On a users data set I had to increase the <<PrefAvl varchar(40)>>  to be PrefAvl varchar(50) because we actually add the PrefAvl (40) and MatlType (10)
--				12/23/15 DRP:  found that the way we only had the Component Header information listed once in the results that was causing it to not print properly on the Report form header.  
--							   It was only printing on the first page and would not on any pages past the 1st page.  
--							   Created a @header table and then cross applied that table against all of the other sections that gathered detailed information for the results.  
--				02/03/16 DRP:  added the Inventory Notes (inv_note) to the results and report form. 
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 08/15/17 VL added functional currency code
-- Modified By: Vijay G
-- Date: 06/27/2017
-- Desc: Select column to get displaye value on reports : Mfgr_Pt_No,Warehouse, Location, QTY_OH, NETABLE, SftyStk,Ref
-- 07/16/18 VL changed supname from char(30) to char(50)
-- =============================================
CREATE PROCEDURE [dbo].[rptMrpInventoryPartByMfgr]
-- Add the parameters for the stored procedure here
@lcUniq_key char(10) = ''
 , @userId uniqueidentifier=null 
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
-- Insert statements for procedure here
--set up tables for report 'Inventory by Manufacturer'

--12/23/15 DRP:  created this @header table
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 08/15/17 VL added functional currency code: StdCostPR, FSymbol, PSymbol
declare @header table (	PART_NO char(35),Revision char(8),STDCOST numeric(13,5),FSymbol char(3), STDCOSTPR numeric(13,5), PSymbol char(3),Buyer_Type char(3),PART_CLASS char(8),PART_TYPE char(8),Descript char(45)
						,Part_sourc char(10),Ord_policy char(12), MRC char(15),U_OF_MEAS char(4), PUR_UOFM char(4),	PUR_LTIME numeric(3),PUR_LUNIT char(2)
						,KIT_LTIME numeric(3),KIT_LUNIT char(2),PROD_LTIME numeric(3),PROD_LUNIT char(2),UNIQ_KEY char(10), CompMATLTYPE char(10)
						,D_TO_S numeric(3),ORDMULT numeric(7,0),MINORD numeric(7,0),PULL_IN numeric(3,0) ,PUSH_OUT numeric(3,0),inv_note text
						,PrintFlag Char(2))

DECLARE @report TABLE (-- these fields for the header
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 08/15/17 VL added functional currency code: StdCostPR, FSymbol, PSymbol
						PART_NO char(35),Revision char(8),STDCOST numeric(13,5),FSymbol char(3), STDCOSTPR numeric(13,5), PSymbol char(3),Buyer_Type char(3),PART_CLASS char(8),PART_TYPE char(8),Descript char(45)
						,Part_sourc char(10),Ord_policy char(12), MRC char(15),U_OF_MEAS char(4), PUR_UOFM char(4),PUR_LTIME numeric(3),PUR_LUNIT char(2)
						,KIT_LTIME numeric(3),KIT_LUNIT char(2),PROD_LTIME numeric(3),PROD_LUNIT char(2),UNIQ_KEY char(10), CompMATLTYPE char(10)
						, D_TO_S numeric(3),ORDMULT numeric(7,0),MINORD numeric(7,0),PULL_IN numeric(3,0) ,PUSH_OUT numeric(3,0),inv_note text,
						-- end of the header fields
						-- 04/14/15 YS Location length is changed to varchar(256)
						-- 07/16/18 VL changed supname from char(30) to char(50)
						MATLTYPE char(10),PartMfgr Char(8), Mfgr_Pt_No Char(30), Netable bit, Warehouse Char(6), Location varChar(256),ReqQty Numeric(9,0)
						, Balance Numeric(18,0), ParentPt Char(10), ReqDate smallDatetime, WoNo Char(15), Ref Char(25), [Action] Char(30), Mfgrs varchar(max)
						,[Days] int,PrintFlag Char(2), Qty_oh Numeric(13,2), Parent varchar(40), PoNum Char(15), SupName Char(50) , DtTakeAct SmallDateTime
						, Due_date smallDateTime,Mfgr_Part varchar(40), FromWhere varchar(19), PrefAvl varchar(50), SftyStk Numeric(7,0), cDefSup Char(35)
						,nRow Integer,TotalOh numeric(14,2),nid integer identity, PRIMARY KEY (nid ))



-- get header for the paRT (@LCuNIQ_KEY AND mark the record with PrintFlag='1'
--12/23/15 DRP:  changed this section of code to insert into the @header
INSERT INTO @header (PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT,UNIQ_KEY, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT 
					,inv_note
					,PrintFlag)

SELECT	MrpInvt.PART_NO,MrpInvt.Revision,MrpInvt.STDCOST,MrpInvt.Buyer_Type,MrpInvt.PART_CLASS,MrpInvt.PART_TYPE,MrpInvt.Descript
		,MrpInvt.Part_sourc,MrpInvt.Ord_policy, MrpInvt.MRC,MrpInvt.U_OF_MEAS,MrpInvt.PUR_UOFM ,MrpInvt.PUR_LTIME ,MrpInvt.PUR_LUNIT
		,mrpInvt.KIT_LTIME ,MrpInvt.KIT_LUNIT,mrpinvt.PROD_LTIME,mrpinvt.PROD_LUNIT,MrpInvt.UNIQ_KEY, MrpInvt.MATLTYPE
		, ISNULL(InvtAbc.D_TO_S,cast(0.00 as numeric(3))) as D_TO_S,mrpinvt.ORDMULT ,mrpinvt.MINORD,mrpinvt.PULL_IN ,mrpinvt.PUSH_OUT 
		,inv_note
		,PrintFlag='1'
from	MrpInvt 
		left outer join invtAbc on Mrpinvt.ABC =invtAbc.ABC_TYPE 
where	mrpInvt.Uniq_key=@lcUniq_key


-- 07/16/18 VL changed supname from char(30) to char(50)
INSERT INTO @report (PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT,inv_note
					,UNIQ_KEY,LOCATION,MFGR_PT_NO,NETABLE,PARTMFGR,QTY_OH,cDefSup, Warehouse,PrintFlag,MatlType,TotalOh,nRow )
SELECT	PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
		PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT,inv_note,
		MrpWh.UNIQ_KEY,MrpWh.LOCATION,MrpWh.MFGR_PT_NO,MrpWh.NETABLE,MrpWh.PARTMFGR,QTY_OH ,ISNULL(S.SupName,SPACE(50)) as cDefSup
		,Warehouse, 'A' AS PrintFlag, m.MatlType
		,CASE WHEN ROW_NUMBER() OVER (Partition by Netable order by MrpWh.orderpref)=1 
			THEN SUM(Qty_oh) OVER (PARTITION BY Netable) ELSE cast(0.00 as numeric(12,2)) END as TotalOh,
		ROW_NUMBER() OVER (Partition by Netable order by MrpWh.orderpref) as nRow
FROM	MrpWh 
		INNER JOIN Warehous ON Warehous.Uniqwh = MrpWh.Uniqwh
--10/13/14 YS : replaced invtmfhd table with 2 new tables
--INNER JOIN INVTMFHD ON Mrpwh.UNIQMFGRHD =INVTMFHD.UNIQMFGRHD
		INNER JOIN InvtMPNLink L ON MrpWh.UNIQMFGRHD=L.uniqmfgrhd
		INNER JOIN MfgrMaster M ON L.mfgrmasterid=m.mfgrmasterid
		LEFT OUTER JOIN (SELECT	SupName,Uniqmfgrhd
						 FROM	INVTMFSP INNER JOIN SUPINFO on Invtmfsp.uniqsupno =SUPINFO.UNIQSUPNO
						 WHERE	INVTMFSP.Is_deleted=0 and Invtmfsp.PfdSupl=1 ) S ON MrpWh.UNIQMFGRHD =S.UNIQMFGRHD
		CROSS APPLY (SELECT *  from @header  WHERE printFlag='1' and UNIQ_KEY=Mrpwh.Uniq_key) RA	--12/23/15 DRP:  added
WHERE	--MrpWh.Uniq_Key = @lcUniq_Key
		--AND
		 (WAREHOUSE<>'WO-WIP' OR (WAREHOUSE='WO-WIP' and QTY_OH>0.00))


-- Get Inventory Balance
-- use reqqty for the balance column
INSERT INTO @report (PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM
					 ,PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT,inv_note
					 ,[UNIQ_KEY],[REQQTY],[REF],[BALANCE],[PARENTPT],[REQDATE],[WONO],[ACTION],[MFGRS],PrintFlag)
SELECT	PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM
		,PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT,inv_note,
		mrpsch2.UNIQ_KEY,[REQQTY],[REF],[REQQTY],[PARENTPT],[REQDATE],[WONO],[ACTION],[MFGRS], 'C' AS PrintFlag
FROM	MrpSch2
		CROSS APPLY (SELECT *  from @header  WHERE printFlag='1' and UNIQ_KEY=MRPSCH2.Uniq_key) RC	--12/23/15 DRP:  Added
WHERE	MrpSch2.Uniq_Key = @lcUniq_Key
		AND Ref LIKE '%Available Inventory%'


--Get Demands from MRP schedule
-- 07/16/18 VL changed supname from char(30) to char(50)
INSERT INTO @report  (PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM
					 ,PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					 ,Ref, ReqQty, ReqDate,Mfgrs, Balance, UNIQ_KEY,Parent,PrintFlag,
					 ---get Supply in one SQL to make sure that identity is inserted in the order of the reqdate
					 PoNum, SupName, PartMfgr, Wono)
SELECT	RD.PART_NO,RD.Revision,RD.STDCOST,RD.Buyer_Type,RD.PART_CLASS,RD.PART_TYPE,RD.Descript,RD.Part_sourc,RD.Ord_policy, RD.MRC,RD.U_OF_MEAS, RD.PUR_UOFM
		,RD.PUR_LTIME ,RD.PUR_LUNIT,RD.KIT_LTIME ,RD.KIT_LUNIT,RD.PROD_LTIME,RD.PROD_LUNIT,CompMATLTYPE, D_TO_S,RD.ORDMULT ,RD.MINORD,RD.PULL_IN ,RD.PUSH_OUT
		,Ref, ReqQty, ReqDate, replace(CAST(Mfgrs as nvarchar(max)),N'`',N', ') as Mfgrs, Balance,Mrpsch2.UNIQ_KEY 
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
		,CAST(CASE WHEN PjctMain.PRJNUMBER IS NULL THEN ISNULL(MrpInvt.Part_No,SPACE(35))
					ELSE RTRIM(LTRIM(ISNULL(MrpInvt.Part_No,' '))) + ' Pjt ' + PjctMain.PrjNumber END as varchar(40)) AS Parent,'D' AS PrintFlag,
		-- empty columns for supply part
		SPACE(15) as PoNum, SPACE(50) as SupName, SPACE(8) AS PartMfgr,SPACE(10) as Wono
FROM	MrpSch2 LEFT OUTER JOIN MrpInvt ON MrpSch2.ParentPt=MrpInvt.Uniq_Key
		LEFT OUTER JOIN PjctMain ON MrpSch2.PRJUNIQUE = PjctMain.PrjUnique
		CROSS APPLY (SELECT *  from @header  WHERE printFlag='1' and UNIQ_KEY=MRPSCH2.Uniq_key) RD	--12/23/15 DRP:  Added
WHERE MrpSch2.Uniq_Key = @lcUniq_Key
AND ReqQty < 0


UNION
SELECT	PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM
		,PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
		-- empty columns matching demands
		,CAST(CASE WHEN WONO<>'' THEN 'Delv. W0' + WoNo ELSE ' ' END as varchar(25)) AS Ref, Balance AS ReqQty, ReqDate
		,partmfgr as Mfgrs	--,cast('' as varchar(max)) as Mfgrs	--11/18/15 DRP:  We used to display the partmfgr in VFP and users wanted this info back on the report
		, cast(0.00 as Numeric(18,0)) as Balance, mrpsuppl.UNIQ_KEY,CAST('' as varchar(40)) as Parent,'D' as PrintFlag,
		---get Supply in one SQL to make sure that identity is inserted in the order of the reqdate
		PoNum, SupName, PartMfgr, Wono
FROM	MrpSuppl 
		LEFT OUTER JOIN SupInfo ON MrpSuppl.UNIQSUPNO = SupInfo.UNIQSUPNO
		CROSS APPLY (SELECT *  from @header  WHERE printFlag='1' and UNIQ_KEY=MRPsuppl.Uniq_key) RD	--12/23/15 DRP:  Added
WHERE	MrpSuppl.Uniq_Key = @lcUniq_Key
		AND MrpSuppl.Balance <> 0
ORDER BY ReqDate
---- Get Supply from Work Orders & PO's
--INSERT INTO @report (PoNum, SupName, Uniq_Key, PartMfgr, ReqDate, ReqQty, Wono, PrintFlag, Ref)
-- SELECT PoNum, SupName, Uniq_Key, PartMfgr, ReqDate, Balance AS ReqQty, Wono, 'D' AS PrintFlag,
-- CAST(CASE WHEN WONO<>'' THEN 'Delv. W0' + WoNo ELSE ' ' END as varchar(25)) AS Ref
-- FROM MrpSuppl LEFT OUTER JOIN SupInfo
-- ON MrpSuppl.UNIQSUPNO = SupInfo.UNIQSUPNO
-- WHERE MrpSuppl.Uniq_Key = @lcUniq_Key
-- AND MrpSuppl.Balance <> 0
---Get Action messages

INSERT INTO @report (PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM
					 ,PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT,inv_note
					 ,Due_Date, Balance, UNIQ_KEY,ReqQty, DttakeAct, ReqDate, Mfgrs, [Days], PrefAvl , [Action], PrintFlag )
SELECT	RH.PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM
		,PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, RH.CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT,cast('' as char(10)) as inv_note
		,Due_Date,
--09/12/2013 YELENA/DEB: FOUND THAT THE BALANCE IN THE fn_ConverQtyPUOM was in the incorrection and needed to be moved to the end.
--09/12/2013: --CASE WHEN RH.U_OF_MEAS =RH.PUR_UOFM THEN Balance ELSE dbo.[fn_ConverQtyPUOM](Balance,RH.PUR_UOFM,RH.U_OF_MEAS) END as Balance,
		CASE WHEN RH.U_OF_MEAS =RH.PUR_UOFM OR RH.PUR_UOFM='' THEN Balance ELSE dbo.[fn_ConverQtyPUOM](RH.PUR_UOFM,RH.U_OF_MEAS,Balance) END as Balance,
		MrpAct.UNIQ_KEY ,
--09/12/2013: --CASE WHEN RH.U_OF_MEAS =RH.PUR_UOFM THEN ReqQty ELSE dbo.[fn_ConverQtyPUOM](ReqQty,RH.PUR_UOFM,RH.U_OF_MEAS) END as ReqQty,
		CASE WHEN RH.U_OF_MEAS =RH.PUR_UOFM OR RH.PUR_UOFM='' THEN ReqQty ELSE dbo.[fn_ConverQtyPUOM](RH.PUR_UOFM,RH.U_OF_MEAS,ReqQty) END as ReqQty,
		DttakeAct, ReqDate, Mfgrs, [Days], RTRIM(PrefAVL) + ' ' + MatlType as PrefAvl ,
		CAST(CASE WHEN PrjNumber IS null THEN [Action] ELSE [Action] + ' Pjt ' + PrjNumber END as varchar(30)) AS [Action], 'F' AS PrintFlag
FROM	MrpAct LEFT OUTER JOIN PjctMain ON MrpAct.PrjUnique = PjctMain.PrjUnique
		--CROSS APPLY (SELECT UNIQ_KEY,U_OF_MEAS ,PUR_UOFM from @report WHERE printFlag='1' and UNIQ_KEY=MrpAct.Uniq_key) RH
		CROSS APPLY (SELECT *  from @header WHERE printFlag='1' and UNIQ_KEY=MrpAct.Uniq_key) RH
WHERE	MrpAct.Uniq_Key = @lcUniq_Key


UPDATE @Report SET Ref= 'PO ' + PoNum, Parent = SupName WHERE PoNum IS not NULL and PoNum<>''
UPDATE @Report set [Days] = DATEDIFF(Day,DtTakeAct,MpsSys.MrpDate) FROM MPSSYS WHERE DATEDIFF(Day,DtTakeAct,MpsSys.MrpDate)>=0 AND NOT DtTakeAct is null
--SELECT * from @report order by PrintFlag,ReqDate
Declare @mBalance as numeric(18,0)
SELECT @mBalance = balance from @report where PrintFlag='C'
--SELECT * from @report where printFlag='D' order by PrintFlag,ReqDate
update @report SET @mBalance=Balance=@mBalance+Reqqty WHERE printFlag='D'

-- 08/15/17 VL separate FC and non FC
/*----------------------
None FC installation
 Modified By: Vijay G
 Date: 06/27/2017
 Desc: Select column to get displaye value on reports : Mfgr_Pt_No,Warehouse, Location, QTY_OH, NETABLE, SftyStk,Ref
*/----------------------
IF dbo.fn_IsFCInstalled() = 0 
	BEGIN
		SELECT PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM
			 ,PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT,inv_note
			 ,Due_Date, Balance, UNIQ_KEY,ReqQty, DttakeAct, ReqDate, Mfgrs, [Days], PrefAvl , [Action], PrintFlag,PartMfgr, Mfgr_Pt_No,Warehouse, Location, QTY_OH, NETABLE, SftyStk,Ref
			from @report order by PrintFlag,ReqDate
	END
ELSE
/*-----------------
 FC installation
 Modified By: Vijay G
 Date: 06/27/2017
 Desc: Select column to get displaye value on reports : Mfgr_Pt_No,Warehouse, Location, QTY_OH, NETABLE, SftyStk,Ref
*/-----------------
	BEGIN
		-- 08/15/17 VL I know we got StdCost from mrpinvt, but StdcostPr didn't, here I just both updated from inventor
		UPDATE R SET StdCost = Inventor.StdCost,
					 StdCostPR = Inventor.StdCostPR, 
					 FSymbol = ISNULL(FF.Symbol,''),
					 PSymbol = ISNULL(PF.Symbol,'')
			FROM @Report R, Inventor 
		LEFT OUTER JOIN Fcused FF ON Inventor.FuncFcused_uniq = FF.Fcused_uniq
		LEFT OUTER JOIN Fcused PF ON Inventor.PrFcused_uniq = PF.Fcused_uniq	
		WHERE Inventor.Uniq_key = R.uniq_key

		SELECT PART_NO,Revision,STDCOST,FSymbol,StdCostPR,PSymbol,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM
			 ,PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT,inv_note
			 ,Due_Date, Balance, UNIQ_KEY,ReqQty, DttakeAct, ReqDate, Mfgrs, [Days], PrefAvl , [Action], PrintFlag,PartMfgr, Mfgr_Pt_No,Warehouse, Location, QTY_OH, NETABLE, SftyStk,Ref
			from @report order by PrintFlag,ReqDate 
	END

END