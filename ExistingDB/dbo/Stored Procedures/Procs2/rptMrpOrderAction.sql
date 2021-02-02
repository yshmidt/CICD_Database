-- =============================================
-- Author: Vicky Lu
-- Create date: 01/30/18
-- Description: MRP - Order Action
-- Modifications: 
-- 01/30/18 VL:	 Copied rptMrpInventoryPartByMfgr and modified it
-- 02/08/18 VL:  Changed from only work for one part to have part number range
-- 02/26/18 VL:  Added criteria to only show parts that have Mrpact records
-- 02/27/18 VL:  didn't get location, warehouse, and qty_oh, just put space or 0 for it, so the "DISTINCT" will only take different partmfgr, not consider warehouse/location level
-- 02/28/18 VL:  Changed to add the last part of the report into RptLine because can not make it show at the end of each report group
-- 03/19/18 VL:  removed the TOP 5 from Action message, copied from PO history but forgot to remove
-- 03/28/18 VL:  added DISTINCT so it only generate one header
-- 07/16/18 VL changed supname from char(30) to char(50)
--10/10/2019 YS part number char(35)
-- 04/14/20 VL changed to use 2 new tables, also adjust the report field positions to show correctly on Stimulsoft eport
-- =============================================
CREATE PROCEDURE [dbo].[rptMrpOrderAction]
-- Add the parameters for the stored procedure here
--declare
	-- 02/08/18 VL changed from one uniq_key to part number range
	--@lcUniq_key char(10) = ''
	@lcUniq_keyStart char(10)=''
	,@lcUniq_keyEnd char(10)=''
	,@userId uniqueidentifier=null 
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
-- Insert statements for procedure here
--10/10/2019 YS part number char(35)
declare @header table (	PART_NO char(35),Revision char(8),STDCOST numeric(13,5),Buyer_Type char(3),PART_CLASS char(8),PART_TYPE char(8),Descript char(45)
						,Part_sourc char(10),Ord_policy char(12), MRC char(15),U_OF_MEAS char(4), PUR_UOFM char(4),	PUR_LTIME numeric(3),PUR_LUNIT char(2)
						,KIT_LTIME numeric(3),KIT_LUNIT char(2),PROD_LTIME numeric(3),PROD_LUNIT char(2),UNIQ_KEY char(10), CompMATLTYPE char(10)
						,D_TO_S numeric(3),ORDMULT numeric(7,0),MINORD numeric(7,0),PULL_IN numeric(3,0) ,PUSH_OUT numeric(3,0),inv_note text
						,PrintFlag Char(2))

-- 07/16/18 VL changed supname from char(30) to char(50)
DECLARE @report TABLE (-- these fields for the header
						PART_NO char(35),Revision char(8),STDCOST numeric(13,5),Buyer_Type char(3),PART_CLASS char(8),PART_TYPE char(8),Descript char(45)
						,Part_sourc char(10),Ord_policy char(12), MRC char(15),U_OF_MEAS char(4), PUR_UOFM char(4),PUR_LTIME numeric(3),PUR_LUNIT char(2)
						,KIT_LTIME numeric(3),KIT_LUNIT char(2),PROD_LTIME numeric(3),PROD_LUNIT char(2),UNIQ_KEY char(10), CompMATLTYPE char(10)
						,D_TO_S numeric(3),ORDMULT numeric(7,0),MINORD numeric(7,0),PULL_IN numeric(3,0) ,PUSH_OUT numeric(3,0),inv_note text
						-- end of the header fields
						,MATLTYPE char(10),PartMfgr Char(8), Mfgr_Pt_No Char(30), Netable bit, Warehouse Char(6), Location Char(17),ReqQty Numeric(9,0)
						,Balance Numeric(18,0), ParentPt Char(10), ReqDate smallDatetime, WoNo Char(15), Ref Char(25), [Action] Char(30), Mfgrs varchar(max)
						,[Days] int,PrintFlag Char(1), Qty_oh Numeric(13,2), Parent varchar(40), PoNum Char(15), SupName Char(50) , DtTakeAct SmallDateTime
						,Due_date smallDateTime, Schd_qty numeric(12,2), CostEach numeric(13,5), Acpt_qty numeric(12,2), Date smalldatetime, OrderPref numeric(2,0)
						,nRow Integer,TotalOh numeric(14,2),nid integer identity, PRIMARY KEY (nid ), RptType char(2), RptLine char(300), RptLine2 char(300), RptType2 char(2))

-- {02/08/18 VL create a table variable to keep all the selected uniq_key first
DECLARE @zParts TABLE (Uniq_key char(10))
DECLARE @lcPartStart char(35)='',@lcRevisionStart char(8)='',
	@lcPartEnd char(35)='',@lcRevisionEnd char(8)=''
		
		--11/24/15 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key	
		IF  @lcUniq_keyStart IS NULL or  @lcUniq_keyStart ='' 
			SELECT @lcPartStart=' ', @lcRevisionStart=' '
		ELSE
		SELECT @lcPartStart = ISNULL(I.Part_no,' '), 
			@lcRevisionStart = ISNULL(I.Revision,' ') 
		FROM Inventor I where Uniq_key=@lcUniq_keyStart
		
		-- find ending part number
		IF  @lcUniq_keyEnd IS NULL or  @lcUniq_keyEnd ='' 
			SELECT @lcPartEnd = REPLICATE('Z',25), @lcRevisionEnd=REPLICATE('Z',8)
		ELSE
			SELECT @lcPartEnd =ISNULL(I.Part_no,' '), 
				@lcRevisionEnd = ISNULL(I.Revision,' ') 
			FROM Inventor I where Uniq_key=@lcUniq_keyEnd	

INSERT @zParts 
	SELECT Uniq_key 
	FROM Inventor
	WHERE (Part_no>= @lcPartStart AND Revision >= @lcRevisionStart)
	AND (Part_no <= @lcPartEnd AND Revision <= @lcRevisionEnd)
	--AND NOT (Part_Sourc = 'MAKE' AND Make_Buy = 0)
	--AND PART_SOURC <> 'PHANTOM'
	AND (Part_Sourc = 'BUY' 
	OR (Part_Sourc = 'MAKE' AND Make_Buy = 1))
	-- 02/26/18 VL added to only get parts that's in MrpAct table
	AND EXISTS (SELECT Uniq_key FROM MrpAct WHERE Uniq_key = Inventor.UNIQ_KEY)
	

-- 02/08/18 VL End}

-- 02/09/18 VL get correct date format setting 
DECLARE @DateSetting char(20), @DateNo int
 SELECT @DateSetting = ISNULL(wm.settingValue,mnx.settingValue)
	FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm 
	ON mnx.settingId = wm.settingId 
	WHERE mnx.settingName='cultureLanguage'
SELECT @DateNo = CASE WHEN @DateSetting IN ('ENGLISH','US SPANISH') THEN 20 ELSE
				CASE WHEN @DateSetting IN ('CHINESE(SIMPLIFIED)','CHINESE(TRADITIONAL)') THEN 11 ELSE
				CASE WHEN @DateSetting IN ('MALAYSIA','HINDI') THEN 5 ELSE 3 END END END 
-- 02/09/18 VL End]

-- get header for the paRT (@LCuNIQ_KEY AND mark the record with PrintFlag='1'
--12/23/15 DRP:  changed this section of code to insert into the 
INSERT INTO @header (PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT,UNIQ_KEY, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT 
					,inv_note
					,PrintFlag)
SELECT	MrpInvt.PART_NO,MrpInvt.Revision,MrpInvt.STDCOST,MrpInvt.Buyer_Type,MrpInvt.PART_CLASS,MrpInvt.PART_TYPE,MrpInvt.Descript
		,MrpInvt.Part_sourc,MrpInvt.Ord_policy, MrpInvt.MRC,MrpInvt.U_OF_MEAS,MrpInvt.PUR_UOFM,MrpInvt.PUR_LTIME ,MrpInvt.PUR_LUNIT
		,mrpInvt.KIT_LTIME ,MrpInvt.KIT_LUNIT,mrpinvt.PROD_LTIME,mrpinvt.PROD_LUNIT,MrpInvt.UNIQ_KEY, MrpInvt.MATLTYPE
		,ISNULL(InvtAbc.D_TO_S,cast(0.00 as numeric(3))) as D_TO_S,mrpinvt.ORDMULT ,mrpinvt.MINORD,mrpinvt.PULL_IN ,mrpinvt.PUSH_OUT 
		,inv_note
		,PrintFlag='1'
from	MrpInvt 
		left outer join invtAbc on Mrpinvt.ABC =invtAbc.ABC_TYPE 
where
	-- 02/08/18 VL changed from one uniq_key to part number range	
	--mrpInvt.Uniq_key=@lcUniq_key
	mrpInvt.Uniq_key IN (SELECT Uniq_key FROM @zParts)


----------------------------------
-- Get Warehouse information
----------------------------------
-- get supplier info to update the warehouse record later
-- 02/27/18 VL didn't get location, warehouse, and qty_oh, just put space or 0 for it, so the "DISTINCT" will only take different partmfgr, not consider warehouse/location level
-- 07/16/18 VL changed supname from char(30) to char(50)
INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY,LOCATION,MFGR_PT_NO, NETABLE,PARTMFGR, QTY_OH, Warehouse,OrderPref,Supname,PrintFlag, RptType, RptLine )
SELECT	DISTINCT PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
		PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
		,MrpWh.UNIQ_KEY,SPACE(17) AS LOCATION,MrpWh.MFGR_PT_NO,1 AS NETABLE,MrpWh.PARTMFGR, 0 AS QTY_OH, SPACE(6) AS Warehouse, 
		OrderPref,ISNULL(S.Supname,SPACE(35)) AS Supname,'A' AS PrintFlag, 
		-- 02/09/18 VL changed to save all data into one line
		'RD' AS RptType,
		SPACE(10)+MrpWh.Mfgr_pt_no+SPACE(10)+MrpWh.Partmfgr+SPACE(10)+CAST(OrderPref AS char(2))+SPACE(20)+ISNULL(S.Supname,SPACE(50)) AS RptLine
		
FROM	MrpWh INNER JOIN Warehous ON Warehous.Uniqwh = MrpWh.Uniqwh
		LEFT OUTER JOIN 
		-- 04/14/20 VL changed to use 2 new tables
		--(SELECT SupName, Partmfgr, Mfgr_pt_no
		--					FROM INVTMFSP INNER JOIN SUPINFO on Invtmfsp.uniqsupno =SUPINFO.UNIQSUPNO
		--					INNER JOIN Invtmfhd ON Invtmfsp.UNIQMFGRHD = Invtmfhd.UNIQMFGRHD
		--					WHERE INVTMFSP.Is_deleted=0 and Invtmfsp.PfdSupl=1) S ON MrpWh.Partmfgr = S.Partmfgr AND MrpWh.Mfgr_pt_no = S.Mfgr_pt_no
		(SELECT SupName, Partmfgr, Mfgr_pt_no
							FROM INVTMFSP INNER JOIN SUPINFO on Invtmfsp.uniqsupno =SUPINFO.UNIQSUPNO
							INNER JOIN Invtmpnlink L ON Invtmfsp.UNIQMFGRHD = L.uniqmfgrhd
							INNER JOIN Mfgrmaster M on L.mfgrmasterid=M.mfgrmasterid
							WHERE INVTMFSP.Is_deleted=0 and Invtmfsp.PfdSupl=1) S ON MrpWh.Partmfgr = S.Partmfgr AND MrpWh.Mfgr_pt_no = S.Mfgr_pt_no
		CROSS APPLY (SELECT *  from @header  WHERE printFlag='1' and UNIQ_KEY=Mrpwh.Uniq_key) RA	--12/23/15 DRP:  added
WHERE	
	-- 02/08/18 VL changed from one uniq_key to part number range	
	-- MrpWh.Uniq_Key=@lcUniq_key
	MrpWh.Uniq_key IN (SELECT Uniq_key FROM @zParts)
ORDER BY Uniq_key, Partmfgr

-- 02/12/18 VL added line to separate section
INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY,PrintFlag, RptType, RptLine )
SELECT DISTINCT PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY,PrintFlag,'H0' AS RptType, dbo.PADL('',130,'_') AS RptLine
		FROM @report 
		WHERE PrintFlag = 'A'
		AND RptType = 'RD'

-- 02/09/18 VL added header information
INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY,PrintFlag, RptType, RptLine )
SELECT DISTINCT PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY,PrintFlag,'H1' AS RptType, 'SOURCE INFORMATION:' AS RptLine
		FROM @report 
		WHERE PrintFlag = 'A'
		AND RptType = 'RD'
-- detail header info
INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY,PrintFlag, RptType, RptLine )
SELECT DISTINCT PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY,PrintFlag, 'H2' AS RptType, 
					SPACE(10)+'MFGR PART NUMBER' +SPACE(24)+'MFGR'+SPACE(14)+'ORDER PREFERENCE' + SPACE(6) + 'DEFAULT SUPPLIER' AS RptLine
					
		FROM @report 
		WHERE PrintFlag = 'A'
		AND RptType = 'RD'


-- Insert blank line
--INSERT INTO @report	(PrintFlag)
--VALUES ('B')

----------------------------------
-- Get Open Purchase Orders
----------------------------------
-- 02/28/18 VL changed LEFT(CONVERT(char,Due_date,@DateNo),10) to ISNULL(LEFT(CONVERT(char,Due_date,@DateNo),10),SPACE(10)), LEFT(CONVERT(char,Reqdate,@DateNo),10) to ISNULL(LEFT(CONVERT(char,Reqdate,@DateNo),10),SPACE(10)) to assign space if Due_date,RetDate are null
INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY, Ponum, ReqDate, ReqQty, Schd_qty, CostEach, Partmfgr,Mfgr_pt_no, Balance, Due_date,Supname,PrintFlag, RptType, RptLine )
SELECT	DISTINCT PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
		PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
		,MrpPo.UNIQ_KEY, Ponum, ReqDate, ReqQty, Schd_qty, CostEach, Partmfgr, Mfgr_pt_no, Balance, Due_date,Supname,'C' AS PrintFlag,
		-- 02/09/18 VL changed to save all data into one line
		'RD' AS RptType,
		SPACE(10)+MrpPo.Ponum+SPACE(5)+SupName+SPACE(5)+SPACE(5)+dbo.PADL(RTRIM(LTRIM(STR(schd_qty,12,2))),15,' ')+SPACE(5)+dbo.PADL(RTRIM(LTRIM(str(Balance,13,2))),15,' ')
		+SPACE(5)+ISNULL(LEFT(CONVERT(char,Due_date,@DateNo),10),SPACE(10))+SPACE(3)+dbo.PADL(RTRIM(LTRIM(STR(ReqQty,12,2))),15,' ')+SPACE(3)+ISNULL(LEFT(CONVERT(char,Reqdate,@DateNo),10),SPACE(10))+SPACE(3)+dbo.PADL(RTRIM(LTRIM(str(Costeach,13,5))),15,' ') AS RptLine
FROM	MrpPo INNER JOIN SupInfo
		ON MrpPo.UNIQSUPNO = Supinfo.UNIQSUPNO
		CROSS APPLY (SELECT *  from @header  WHERE printFlag='1' and UNIQ_KEY=MrpPo.Uniq_key) RA	--12/23/15 DRP:  added
WHERE	
	-- 02/08/18 VL changed from one uniq_key to part number range	
	--MrpPo.Uniq_Key=@lcUniq_key
	MrpPo.Uniq_key IN (SELECT Uniq_key FROM @zParts)
ORDER BY Uniq_key, DUE_DATE


-- detail header info
-- 07/16/18 VL changed supname from char(30) to char(50), so change the space(40) after 'VENDOR' to space(55)
INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY,PrintFlag, RptType, RptLine )
SELECT	DISTINCT PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
		PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
		,UNIQ_KEY, PrintFlag,'H2' AS RptType, 
		SPACE(10)+'PO NUMBER'+SPACE(11)+'VENDOR'+SPACE(55)+'ORDER QTY'+SPACE(9)+ 'CURRENT QTY'
		+SPACE(5)+'DUE DATE'+ SPACE(13)+'NEW QTY'+SPACE(3)+'NEW DATE'+SPACE(5)+'UNIT PRICE' AS RptLine
		FROM @report 
		WHERE PrintFlag = 'C'
		AND RptType = 'RD'

-- Insert '<< NO OPEN PURCHASE ORDERS >>' if no open PO records inserted in previous statement
-- 02/08/18 VL changed from only find for one uniq_key to part number range, so insert record for printflag = 'C' for those uniq_key that didn't have records created in printFlag = 'C'
--IF @@ROWCOUNT = 0
--	INSERT INTO @report	(Mfgrs,Uniq_key, PrintFlag)
--		VALUES ('<< NO OPEN PURCHASE ORDERS >>','C')
--INSERT INTO @report	(Mfgrs,Uniq_key, PrintFlag, RptType, RptLine)
--	SELECT '<< NO OPEN PURCHASE ORDERS >>' AS Mfgrs,Uniq_key,'C' AS PrintFlag, 'RD' AS RptType, SPACE(20)+'<< NO OPEN PURCHASE ORDERS >>' AS RptLine
--		FROM @header 
--		WHERE Uniq_key NOT IN 
--			(SELECT Uniq_key FROM @Report WHERE PrintFlag = 'C')

-- 02/28/18 VL changed SPACE(20) to SPACE(30) for '<< NO OPEN PURCHASE ORDERS >>' AS RptLine
INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY, PrintFlag,RptType, RptLine)
SELECT PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
		PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT,
		UNIQ_KEY, 'C' AS PrintFlag, 'RD' AS RptType, SPACE(30)+'<< NO OPEN PURCHASE ORDERS >>' AS RptLine
		FROM @header 
		WHERE Uniq_key NOT IN 
			(SELECT Uniq_key FROM @Report WHERE PrintFlag = 'C')


-- 02/12/18 VL added line to separate section
INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY, PrintFlag, RptType, RptLine )
SELECT	DISTINCT PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY, PrintFlag,'H0' AS RptType, dbo.PADL('',130,'_') AS RptLine
		FROM @report 
		WHERE PrintFlag = 'C'
		AND RptType = 'RD'

-- 02/09/18 VL added header information
INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY, PrintFlag, RptType, RptLine )
SELECT	DISTINCT PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY, PrintFlag,'H1' AS RptType, 'OPEN PURCHASE ORDERS:' AS RptLine
		FROM @report 
		WHERE PrintFlag = 'C'
		AND RptType = 'RD'





-- Insert blank line
--INSERT INTO @report	(PrintFlag)
--	VALUES ('D')

----------------------------------
-- Get Purchase History
----------------------------------
-- 02/28/18 VL changed CONVERT(char,Date,@DateNo) to ISNULL(CONVERT(char,Date,@DateNo),SPACE(10)) to assign space if date is null
-- 02/28/18 VL we don't use MrpPoHst table anymore, so need to get info from Sinvdetl, Poitems that Sinvdetl.Trans_date<mpssys.mrpdate
--INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
--					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
--					,UNIQ_KEY, Ponum, ReqDate, Schd_qty, CostEach, Acpt_qty, Date, Partmfgr, PrintFlag, RptType, RptLine )
--SELECT	DISTINCT TOP 5 PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
--		PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
--		,MrpPoHst.UNIQ_KEY, Ponum, Req_Date, Schd_qty, CostEach, Acpt_qty, Date, Partmfgr, 'E' AS PrintFlag, 
--		-- 02/09/18 VL changed to save all data into one line
--		'RD' AS RptType,
--		SPACE(10)+Ponum+SPACE(5)+SupName+SPACE(5)+SPACE(5)+Partmfgr+SPACE(5)+dbo.PADL(RTRIM(LTRIM(str(Costeach,13,5))),15,' ')+SPACE(5)
--		+dbo.PADL(RTRIM(LTRIM(STR(acpt_qty,12,2))),15,' ')+SPACE(5)+ISNULL(CONVERT(char,Date,@DateNo),SPACE(10)) AS RptLine
		
--FROM	MrpPoHst INNER JOIN SupInfo
--		ON MrpPoHst.UNIQSUPNO = Supinfo.UNIQSUPNO
--		CROSS APPLY (SELECT *  from @header  WHERE printFlag='1' and UNIQ_KEY=MrpPoHst.Uniq_key) RA	--12/23/15 DRP:  added
--WHERE	
--	-- 02/08/18 VL changed from one uniq_key to part number range	
--	-- MrpPoHst.Uniq_Key=@lcUniq_key
--	MrpPoHst.Uniq_key IN (SELECT Uniq_key FROM @zParts)
--ORDER BY Uniq_key, Date DESC
-- 02/28/18 VL add new code
;WITH ZTop5 AS (
SELECT	RA.PART_NO,RA.Revision,STDCOST,Buyer_Type,RA.PART_CLASS,RA.PART_TYPE,RA.Descript,Part_sourc,Ord_policy, MRC,RA.U_OF_MEAS, RA.PUR_UOFM,
		PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
		,Poitems.UNIQ_KEY, Poitems.Ponum, Sinvdetl.CostEach, Sinvdetl.Acpt_qty, Trans_Date AS Date, Partmfgr, 'E' AS PrintFlag, 
		-- 02/09/18 VL changed to save all data into one line
		'RD' AS RptType,
		SPACE(10)+Poitems.Ponum+SPACE(5)+SupName+SPACE(5)+SPACE(5)+Partmfgr+SPACE(5)+dbo.PADL(RTRIM(LTRIM(str(Sinvdetl.Costeach,13,5))),15,' ')+SPACE(5)
		+dbo.PADL(RTRIM(LTRIM(STR(Sinvdetl.acpt_qty,12,2))),15,' ')+SPACE(5)+ISNULL(CONVERT(char,Trans_date,@DateNo),SPACE(10)) AS RptLine,
		ROW_NUMBER() OVER (Partition by Poitems.Uniq_key order by Trans_date DESC) AS ROWNO
		
FROM	SINVDETL INNER JOIN Poitems 
			ON Sinvdetl.Uniqlnno = Poitems.UNIQLNNO
		INNER JOIN Pomain
			ON Poitems.Ponum = Pomain.Ponum
		INNER JOIN SupInfo
			ON Pomain.UNIQSUPNO = Supinfo.UNIQSUPNO
		CROSS APPLY (SELECT *  from @header  WHERE printFlag='1' and UNIQ_KEY=Poitems.Uniq_key) RA	--12/23/15 DRP:  added
WHERE Poitems.Uniq_key IN (SELECT Uniq_key FROM @zParts)
)
INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY, Ponum, ReqDate, Schd_qty, CostEach, Acpt_qty, Date, Partmfgr, PrintFlag, RptType, RptLine,RptType2 )
SELECT PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY, Ponum, NULL AS ReqDate, 0 AS Schd_qty, CostEach, Acpt_qty, Date, Partmfgr, PrintFlag, RptType, RptLine, CAST(Rowno AS Char) AS RptType2
FROM ZTop5 WHERE ROWNO <=5 ORDER BY Uniq_key, Date DESC
-- 02/28/18 VL End}


-- 02/09/18 VL insert  2nd level header for those records which have data first, later insert for "NO PURCHASE HISTORY" for those uniq_key which has no history recoed, then create "1st level header for all uniq_key, so if no record for the uniq_key, won't show PONUM.... 2nd level header
-- detail header info
-- 07/16/18 VL changed supname from char(30) to char(50), so change SPACE(40) after 'VENDOR' to SPACE(55)
INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY, PrintFlag, RptType, RptLine )
SELECT DISTINCT PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
		PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT,
		UNIQ_KEY, PrintFlag, 'H2' AS RptType,
		SPACE(10)+'PO NUMBER'+SPACE(11)+'VENDOR'+SPACE(55)+'MFGR'+SPACE(9)+ 'UNIT PRICE' + SPACE(18)+'REC QTY' +SPACE(5)+'RECD DATE' AS RptLine
		FROM @report 
		WHERE PrintFlag = 'E'
		AND RptType = 'RD'

-- Insert '<< NO PURCHASE HISTORY >>' if no open PO records inserted in previous statement
-- 02/08/18 VL changed from only find for one uniq_key to part number range, so insert record for printflag = 'E' for those uniq_key in @header that didn't have records created in printFlag = 'E'
--IF @@ROWCOUNT = 0
--	INSERT INTO @report	(Mfgrs,PrintFlag)
--		VALUES ('<< NO PURCHASE HISTORY >>','E')
-- 02/28/18 VL changed SPACE(20) to SPACE(30) for '<< NO PURCHASE HISTORY >>' AS RptLine
INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY, PrintFlag,RptType, RptLine)
SELECT DISTINCT PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
		PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT,
		UNIQ_KEY, 'E' AS PrintFlag, 'RD' AS RptType, SPACE(30)+'<< NO PURCHASE HISTORY >>' AS RptLine
		FROM @header 
		WHERE Uniq_key NOT IN 
			(SELECT Uniq_key FROM @Report WHERE PrintFlag = 'E')

--INSERT INTO @report	(Mfgrs,Uniq_key, PrintFlag, RptType, RptLine)
--	SELECT '<< NO PURCHASE HISTORY >>' AS Mfgrs,Uniq_key,'E' AS PrintFlag, 'RD' AS RptType, SPACE(20)+'<< NO PURCHASE HISTORY >>' AS RptLine
--		FROM @header 
--		WHERE Uniq_key NOT IN 
--			(SELECT Uniq_key FROM @Report WHERE PrintFlag = 'E')


-- 02/12/18 VL added line to separate section
INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY, PrintFlag, RptType, RptLine )
SELECT DISTINCT PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
		PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT,
		UNIQ_KEY, PrintFlag, 'H0' AS RptType, dbo.PADL('',130,'_') AS RptLine
		FROM @report 
		WHERE PrintFlag = 'E'
		AND RptType = 'RD'

-- 02/09/18 VL added header information
INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY, PrintFlag, RptType, RptLine )
SELECT DISTINCT PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
		PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT,
		UNIQ_KEY, PrintFlag, 'H1' AS RptType, 'PURCHASE HISTORY:' AS RptLine
		FROM @report 
		WHERE PrintFlag = 'E'
		AND RptType = 'RD'


-- 02/08/18 VL comment out the blank line, I don't think we need it
-- Insert blank line
--INSERT INTO @report	(PrintFlag)
--VALUES ('F')

----------------------------------
-- Get Action messages
----------------------------------
-- 02/28/18 VL changed LEFT(CONVERT(char,Due_Date,@DateNo),10) to ISNULL(LEFT(CONVERT(char,Due_Date,@DateNo),10),SPACE(10)),LEFT(CONVERT(char,Reqdate,@DateNo),10) to ISNULL(LEFT(CONVERT(char,Reqdate,@DateNo),10),SPACE(10)), 
-- LEFT(CONVERT(char,DtTakeAct,@DateNo),10) to ISNULL(LEFT(CONVERT(char,DtTakeAct,@DateNo),10),SPACE(10)) to assign space if Due_date, RetDate,DtTAkeAct are null
INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY, Due_date, Balance, ReqQty, DtTakeAct, ReqDate, Mfgrs, Days, Action, PrintFlag, RptType, RptLine, RptLine2 )
-- 03/19/18 VL removed the TOP 5, copied from PO history but forgot to remove
SELECT	--TOP 5 
	PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
		PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
		,MrpAct.UNIQ_KEY, Due_date, Balance, 
		CASE WHEN RH.U_OF_MEAS =RH.PUR_UOFM OR RH.PUR_UOFM='' THEN ReqQty ELSE dbo.[fn_ConverQtyPUOM](RH.PUR_UOFM,RH.U_OF_MEAS,ReqQty) END as ReqQty
		, DtTakeAct, ReqDate, Mfgrs, Days, 
		CASE WHEN PrjNumber IS NULL THEN Action +SPACE(15) ELSE Action + ' Pjt '+PrjNumber END AS Action, 'G' AS PrintFlag,
		-- 02/09/18 VL changed to save all data into one line
		'RD' AS RptType,
		SPACE(10)+CASE WHEN PrjNumber IS NULL THEN Action +SPACE(15) ELSE Action + ' Pjt '+PrjNumber END+SPACE(5)+dbo.PADL(RTRIM(LTRIM(str(Balance,9,0))),10,' ')+SPACE(5)+dbo.PADL(RTRIM(LTRIM(str(Reqqty,9,0))),10,' ')+SPACE(5)+
		ISNULL(LEFT(CONVERT(char,Due_Date,@DateNo),10),SPACE(10))+SPACE(5)+ISNULL(LEFT(CONVERT(char,ReqDate,@DateNo),10),SPACE(10))+SPACE(5)+ISNULL(LEFT(CONVERT(char,DtTakeAct,@DateNo),10),SPACE(10))+SPACE(10)+dbo.PADL(RTRIM(LTRIM(str(Days,4,0))),10,' ') AS RptLine,
		SUBSTRING(Mfgrs,1,200) AS RptLine2
				
FROM	MrpAct LEFT OUTER JOIN PjctMain 
		ON MrpAct.PrjUnique = PjctMain.PrjUnique
		CROSS APPLY (SELECT *  from @header  WHERE printFlag='1' and UNIQ_KEY=MrpAct.Uniq_key) RH	--12/23/15 DRP:  added
WHERE	
	-- 02/08/18 VL changed from one uniq_key to part number range	
	-- MrpAct.Uniq_Key=@lcUniq_key
	MrpAct.Uniq_key IN (SELECT Uniq_key FROM @zParts)
ORDER BY Uniq_key, ReqDate

-- 02/12/18 VL added line to separate section
INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY, PrintFlag, RptType, RptLine)
-- 03/28/18 VL added DISTINCT so it only generate one header
SELECT DISTINCT PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
		PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
		,UNIQ_KEY, 'G' AS PrintFlag, 'H0' AS RptType, dbo.PADL('',130,'_') AS RptLine
		FROM @report 
		WHERE PrintFlag = 'G'
		AND RptType = 'RD'

-- 02/09/18 VL added header information
INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY, PrintFlag, RptType, RptLine )
-- 03/28/18 VL added DISTINCT so it only generate one header
SELECT DISTINCT	PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
		PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
		,UNIQ_KEY, 'G' AS PrintFlag, 'H1' AS RptType, 'ACTION MESSAGE (IN PURCH UOM:'+PUR_UOFM AS RptLine
		FROM @report 
		WHERE PrintFlag = 'G'
		AND RptType = 'RD'
-- detail header info
INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY, PrintFlag, RptType, RptLine )
-- 03/28/18 VL added DISTINCT so it only generate one header
SELECT DISTINCT	PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
		PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
		,UNIQ_KEY, 'G' AS PrintFlag, 'H2' AS RptType, 
		SPACE(5)+'ACTION'+SPACE(32)+'ORG QTY'+SPACE(7)+'REQ QTY'+SPACE(16)+'ORG DATE'+SPACE(15)+'NEED DATE'+SPACE(13)+'ACTION DATE'+SPACE(5)+'DAYS LATE' AS RptLine
		FROM @report 
		WHERE PrintFlag = 'G'
		AND RptType = 'RD'

-- 02/28/18 VL tried to add last part into the report, could not make it to print for each part at the end of group
DECLARE @SummaryLine TABLE(RptLine char(300), RptType char(2))
INSERT INTO @SummaryLine (RptLine, RptType) VALUES
-- 04/14/20 VL change the length of line
--(SPACE(5)+dbo.PADR('PURCHASE HISTORY:',20,' ')+SPACE(20)+dbo.PADR('TAXABLE',20,' ')+SPACE(10)+dbo.PADL('',25,'_')+dbo.PADR('TERMS',20,' ')+SPACE(10)+dbo.PADL('',25,'_'),'RA'),
--(SPACE(5)+dbo.PADR('PO',20,' ')+SPACE(10)+dbo.PADL('',25,'_')+dbo.PADR('VERNDOR',20,' ')+SPACE(10)+dbo.PADL('',25,'_')+dbo.PADR('FOB',20,' ')+SPACE(10)+dbo.PADL('',25,'_'),'RB'),
--(SPACE(5)+dbo.PADR('PROJ',20,' ')+SPACE(10)+dbo.PADL('',25,'_')+dbo.PADR('CONFIRM',20,' ')+SPACE(10)+dbo.PADL('',25,'_')+dbo.PADR('SHIPVIA',20,' ')+SPACE(10)+dbo.PADL('',25,'_'),'RD'),
--(SPACE(5)+dbo.PADR('DATE',20,' ')+SPACE(10)+dbo.PADL('',25,'_')+dbo.PADR('PROMISED',20,' ')+SPACE(10)+dbo.PADL('',25,'_')+dbo.PADR('DEL. TO',20,' ')+SPACE(10)+dbo.PADL('',25,'_'),'RE'),
--(SPACE(5)+dbo.PADR('QUANTITY__',10,' ')+SPACE(10)+dbo.PADL('DUE DATE___',10,' ')+SPACE(10)+dbo.PADR('UNIT COST_',10,' ')+SPACE(10)+dbo.PADR('MFGR/SOURC',10,' ')+SPACE(10)+dbo.PADR('___: :___',10,' ')+SPACE(10)
--+dbo.PADR('QUANTITY__',10,' ')+SPACE(10)+dbo.PADL('DUE DATE___',10,' ')+SPACE(10)+dbo.PADR('UNIT COST_',10,' ')+SPACE(10)+dbo.PADR('MFGR/SOURC',10,' '),'RF'),
--(SPACE(5)+dbo.PADL('',10,'_')+SPACE(10)+dbo.PADL('',10,'_')+SPACE(10)+dbo.PADL('',10,'_')+SPACE(15)+dbo.PADL('',10,'_')+SPACE(10)
--+dbo.PADL('',10,'_')+SPACE(10)+dbo.PADL('',10,'_')+SPACE(10)+dbo.PADL('',10,'_')+SPACE(10)+dbo.PADL('',10,'_')+SPACE(15)+dbo.PADL('',10,'_'),'RG'),
--(SPACE(5)+dbo.PADL('',10,'_')+SPACE(10)+dbo.PADL('',10,'_')+SPACE(15)+dbo.PADL('',10,'_')+SPACE(15)+dbo.PADL('',10,'_')+SPACE(10)
--+dbo.PADL('',10,'_')+SPACE(10)+dbo.PADL('',10,'_')+SPACE(10)+dbo.PADL('',10,'_')+SPACE(10)+dbo.PADL('',10,'_')+SPACE(15)+dbo.PADL('',10,'_'),'RH'),
--(SPACE(5)+dbo.PADL('',10,'_')+SPACE(10)+dbo.PADL('',10,'_')+SPACE(15)+dbo.PADL('',10,'_')+SPACE(15)+dbo.PADL('',10,'_')+SPACE(10)
--+dbo.PADL('',10,'_')+SPACE(10)+dbo.PADL('',10,'_')+SPACE(10)+dbo.PADL('',10,'_')+SPACE(10)+dbo.PADL('',10,'_')+SPACE(15)+dbo.PADL('',10,'_'),'RI'),
--(SPACE(5)+dbo.PADL('',10,'_')+SPACE(10)+dbo.PADL('',10,'_')+SPACE(15)+dbo.PADL('',10,'_')+SPACE(15)+dbo.PADL('',10,'_')+SPACE(10)
--+dbo.PADL('',10,'_')+SPACE(10)+dbo.PADL('',10,'_')+SPACE(10)+dbo.PADL('',10,'_')+SPACE(10)+dbo.PADL('',10,'_')+SPACE(15)+dbo.PADL('',10,'_'),'RJ'),
--(SPACE(5)+'SPECIAL INSTRUCTIONS: ','RK'),
--(SPACE(5)+dbo.PADL('',100,'_'),'RL'),
--(SPACE(5)+dbo.PADL('',100,'_'),'RM'),
--(SPACE(5)+dbo.PADR('ORIGINATOR:',20,' ')+SPACE(20)+dbo.PADL('',20,'_')+dbo.PADR('APPROVAL:',20,' ')+SPACE(20)+dbo.PADL('',20,'_')+dbo.PADR('ENTERED BY:',20,' ')+SPACE(20)+dbo.PADL('',25,'_'),'RN')
-- New code
(SPACE(5)+'PURCHASE HISTORY:'+SPACE(18)+dbo.PADR('TAXABLE '+SPACE(2)+dbo.PADL('',23,'_'),35,' ')+dbo.PADR('TERMS  '+SPACE(2)+dbo.PADL('',23,'_'),35,' '),'RA'),
(SPACE(5)+dbo.PADR('PO  '+SPACE(2)+dbo.PADL('',23,'_'),35,' ')+dbo.PADR('VERNDOR '+SPACE(2)+dbo.PADL('',23,'_'),35,' ')+dbo.PADR('FOB    '+SPACE(2)+dbo.PADL('',23,'_'),35,' '),'RB'),
(SPACE(5)+dbo.PADR('PROJ'+SPACE(2)+dbo.PADL('',23,'_'),35,' ')+dbo.PADR('CONFIRM '+SPACE(2)+dbo.PADL('',23,'_'),35,' ')+dbo.PADR('SHIPVIA'+SPACE(2)+dbo.PADL('',23,'_'),35,' '),'RD'),
(SPACE(5)+dbo.PADR('DATE'+SPACE(2)+dbo.PADL('',23,'_'),35,' ')+dbo.PADR('PROMISED'+SPACE(2)+dbo.PADL('',23,'_'),35,' ')+dbo.PADR('DEL. TO'+SPACE(2)+dbo.PADL('',23,'_'),35,' '),'RE'),
(SPACE(5)+'QUANTITY__'+SPACE(2)+dbo.PADL('DUE DATE__',10,' ')+SPACE(2)+dbo.PADR('UNIT COST_',10,' ')+SPACE(2)+dbo.PADR('MFGR/SOURC',10,' ')+SPACE(2)+dbo.PADR('___: :___',10,' ')+SPACE(2)
+dbo.PADR('QUANTITY__',10,' ')+SPACE(2)+dbo.PADL('DUE DATE__',10,' ')+SPACE(2)+dbo.PADR('UNIT COST_',10,' ')+SPACE(2)+dbo.PADR('MFGR/SOURC',10,' '),'RF'),
(SPACE(5)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)
+dbo.PADL('',10,' ')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_'),'RG'),
(SPACE(5)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)
+dbo.PADL('',10,' ')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_'),'RH'),
(SPACE(5)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)
+dbo.PADL('',10,' ')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_'),'RI'),
(SPACE(5)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)
+dbo.PADL('',10,' ')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_')+SPACE(2)+dbo.PADL('',10,'_'),'RJ'),
(SPACE(5)+'SPECIAL INSTRUCTIONS: ','RK'),
(SPACE(5)+dbo.PADL('',100,'_'),'RL'),
(SPACE(5)+dbo.PADL('',100,'_'),'RM'),
(SPACE(5)+dbo.PADR('ORIGINATOR:'+SPACE(2)+dbo.PADL('',23,'_'),35,' ')+dbo.PADR('APPROVAL:'+SPACE(2)+dbo.PADL('',23,'_'),35,' ')+dbo.PADR('ENTERED BY:'+SPACE(2)+dbo.PADL('',23,'_'),35,' '),'RN')

-- insert line separator
INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY, PrintFlag, RptType, RptLine )
SELECT	PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
		PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
		,UNIQ_KEY, 'S' AS PrintFlag, 'R0' AS RptType, dbo.PADL('',110,'_') AS RptLine
		FROM @header 

INSERT INTO @report	(PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
					PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT
					,UNIQ_KEY, PrintFlag,RptType, RptLine)
SELECT PART_NO,Revision,STDCOST,Buyer_Type,PART_CLASS,PART_TYPE,Descript,Part_sourc,Ord_policy, MRC,U_OF_MEAS, PUR_UOFM,
		PUR_LTIME ,PUR_LUNIT,KIT_LTIME ,KIT_LUNIT,PROD_LTIME,PROD_LUNIT, CompMATLTYPE, D_TO_S,ORDMULT ,MINORD,PULL_IN ,PUSH_OUT,
		UNIQ_KEY, 'S' AS PrintFlag, S.RptType AS RptType, S.RptLine AS RptLine
		FROM @header CROSS JOIN @SummaryLine S



UPDATE @Report set [Days] = DATEDIFF(Day,DtTakeAct,MpsSys.MrpDate) FROM MPSSYS WHERE DATEDIFF(Day,DtTakeAct,MpsSys.MrpDate)>=0 AND NOT DtTakeAct is null
UPDATE @report SET Inv_Note = H.Inv_Note FROM @header H WHERE [@report].UNIQ_KEY = H.Uniq_key


SELECT * from @report order by Uniq_key,PrintFlag,RptType,ReqDate
END