-- =============================================
-- Author:		Vicky Lu
-- Create date: ????
-- Description:	Cycle count module
-- Modified: 
-- 03/28/12 VL changed from Count_dt + @lnCc_Days =< GETDATE() to and 1 = CASE WHEN COUNT_DT IS NULL THEN 1 ELSE CASE WHEN COUNT_DT <= GETDATE() THEN 1 ELSE 0 END END
-- 10/08/14 YS replace invtmfhd table with 2 new tables
-- 04/20/16 VL found left outer join invtlot will create some records which is lot-coded part, but has no invtlot record, so those records can not find right records in invtlot to update later, will use union to union non-lot code and lot code parts
--- 05/02/16 YS removed case when checking for @lNotInstore in the final result set
-- 05/31/17 VL added functional currency code
-- -- YS 02/06/2018 Changed lotcode column length to 25 char
-- =============================================
CREATE PROCEDURE [dbo].[CycleCountUniq_key4ABCView] @lcAbc_Type AS char(1) = ' ', @lnCc_Days numeric(7,0) = 1
AS
BEGIN

SET NOCOUNT ON;


DECLARE @ZTempPart TABLE (Uniq_key char(10))	-- All records that are type @lcAbc_Type
DECLARE @ZRandomPart TABLE (Uniq_key char(10))	-- Insert only the number of daily count

DECLARE @lNotInstore bit, @lnCntPart int, @lnDailyCount int, @lnLower int,
		@lnUpper int, @lnCnt int, @lnRandNo int

SELECT @lNotInstore = NotInstore FROM Abcsetup

-- Based on @lcAbc_Type, will get all Uniq_key records that meet criteria first, then only get random number of records (based on 
-- calculated daily count) from the dataset, and return the 2nd dataset

-- All records that are type @lcAbc_Type
INSERT @ZTempPart
SELECT DISTINCT Inventor.Uniq_key
	FROM Inventor, InvtMfgr, Warehous
	WHERE Abc = @lcAbc_Type
		AND Inventor.Uniq_Key = InvtMfgr.Uniq_Key 
		AND Warehous.UniqWh = Invtmfgr.UniqWh 
		AND Warehous.Warehouse <> 'MRB'
		AND Warehous.Warehouse <> 'WO-WIP'
		AND Part_Sourc <> 'CONSG'
		AND Part_Sourc <> 'PHANTOM'
		AND 1 = CASE WHEN COUNT_DT IS NULL THEN 1 ELSE CASE WHEN COUNT_DT + @lnCc_Days <= GETDATE() THEN 1 ELSE 0 END END
        AND Inventor.Status = 'Active  '
		AND Inventor.Uniq_Key NOT IN (SELECT Uniq_Key FROM CcRecord WHERE CCrecncl = 0)
		AND Inventor.Uniq_Key NOT IN (SELECT Uniq_Key FROM InvtMfgr WHERE CountFlag <> '')
		AND Invtmfgr.Is_Deleted = 0
		AND 0 = (CASE WHEN @lNotInstore = 1 THEN Invtmfgr.INSTORE ELSE 0 END)

SET @lnCntPart = @@ROWCOUNT
-- 03/22/12 VL changed to prevent @lnCc_Days is 0 to be divisor
--SET @lnDailyCount = CEILING(@lnCntPart/dbo.fn_FindNumberOfWorkingDays(GETDATE(), GETDATE()+@lnCc_Days))
SET @lnDailyCount = CASE WHEN dbo.fn_FindNumberOfWorkingDays(GETDATE(), GETDATE()+@lnCc_Days) <> 0 THEN CEILING(@lnCntPart/dbo.fn_FindNumberOfWorkingDays(GETDATE(), GETDATE()+@lnCc_Days)) ELSE 0 END
SET @lnLower = 1
SET @lnUpper = @lnCntPart
SET @lnCnt = 1

-- Get @lnDailyCount number of parts from @ZTempPart order by NewID() to get radom records
INSERT @ZRandomPart 
	SELECT TOP (@lnDailyCount) Uniq_key
		FROM @ZTempPart
		ORDER BY NEWID()

-- 3/28/12 VL comment out following part, it's too slow		
---- the loop that will get lnDailyCount number of part records
--WHILE @lnCnt <= @lnDailyCount
--BEGIN
--	INSERT @ZRandomPart
--	SELECT TOP 1 Uniq_key 
--		FROM @ZTempPart
--		WHERE Uniq_key NOT IN 
--			(SELECT Uniq_key 
--				FROM @ZRandomPart)
--		ORDER BY NEWID()
		
--	SET @lnCnt = @lnCnt + 1
--END
-- Now will create a cursor which have all detail records for @ZRandomPart

-- 04/20/16 VL found left outer join invtlot will create some records which is lot-coded part, but has no invtlot record, so those records can not find right records in invtlot to update later
-- will use union to union non-lot code and lot code parts
--SELECT Invtmfgr.Uniq_key, Invtmfgr.W_key, Whno, Location, Partmfgr, Mfgr_pt_no, 
--	Part_no, Revision, Warehouse, Part_sourc, Part_class, Part_type, Descript, U_of_meas,
--	Invtmfgr.UniqSupNo, CASE WHEN Invtlot.LotCode IS NULL THEN Invtmfgr.QTY_OH ELSE Invtlot.LOTQTY END AS Qty_oh,
--	GETDATE() AS SYS_Date, @lcAbc_Type AS Abc, ISNULL(Invtlot.LotCode, SPACE(15)) AS LotCode, Invtlot.Expdate AS Expdate,
--	ISNULL(Invtlot.Reference, SPACE(12)) AS Reference, ISNULL(Invtlot.Ponum,SPACE(15)) AS Ponum, ISNULL(Invtlot.Uniq_lot,SPACE(10)) AS Uniq_lot, 
--	Wh_gl_nbr, Stdcost,dbo.fn_GenerateUniqueNumber() AS UniqCcno, Warehous.UniqWh, L.UniqMfgrhd
--FROM Inventor INNER JOIN InvtMPNLink L ON Inventor.Uniq_key = L.UNIQ_KEY
-- INNER JOIN Invtmfgr ON L.uniqmfgrhd=Invtmfgr.UNIQMFGRHD
-- INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId 
-- INNER JOIN Warehous ON Invtmfgr.UniqWh = Warehous.UniqWh
-- LEFT OUTER JOIN INVTLOT
-- ON Invtmfgr.W_key = Invtlot.W_key
-- 	ANd L.Is_Deleted = 0
--	AND M.Is_Deleted = 0
--	AND Invtmfgr.Is_Deleted = 0
--	AND Warehouse <> 'MRB'
--	AND Warehouse <> 'WO-WIP'
--	AND 0 = (CASE WHEN @lNotInstore = 1 THEN Invtmfgr.INSTORE ELSE 0 END)
--	AND Invtmfgr.Uniq_key IN 
--		(SELECT Uniq_key FROM @ZRandomPart)

-- Non lot code parts
-- 05/31/17 VL added functional currency code
-- YS 02/06/2018 Changed lotcode column length
SELECT Invtmfgr.Uniq_key, Invtmfgr.W_key, Whno, Location, Partmfgr, Mfgr_pt_no, 
	Part_no, Revision, Warehouse, Part_sourc, Part_class, Part_type, Descript, U_of_meas,
	Invtmfgr.UniqSupNo, Invtmfgr.Qty_OH AS Qty_oh, GETDATE() AS SYS_Date, @lcAbc_Type AS Abc,
	SPACE(25) AS LotCode, NULL AS Expdate, SPACE(12) AS Reference, SPACE(15) AS Ponum, SPACE(10) AS Uniq_lot,
	Wh_gl_nbr, Stdcost,dbo.fn_GenerateUniqueNumber() AS UniqCcno, Warehous.UniqWh, L.UniqMfgrhd, StdCostPR  
	FROM Inventor INNER JOIN InvtMPNLink L ON Inventor.Uniq_key = L.UNIQ_KEY
	INNER JOIN Invtmfgr ON L.uniqmfgrhd=Invtmfgr.UNIQMFGRHD
	INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId 
	INNER JOIN Warehous ON Invtmfgr.UniqWh = Warehous.UniqWh	
	ANd L.Is_Deleted = 0
	AND M.IS_Deleted = 0
	AND Invtmfgr.Is_Deleted = 0
	AND Warehouse <> 'MRB'
	AND Warehouse <> 'WO-WIP'
	---
	--- 05/02/16 YS I think this way the "where" is better optimizable
	and ((@lNotInstore=1 and Invtmfgr.INSTORE=0) OR (@lNotInstore=0))
	--AND 0 = (CASE WHEN @lNotInstore = 1 THEN Invtmfgr.INSTORE ELSE 0 END)
	AND Invtmfgr.Uniq_key IN 
		(SELECT Uniq_key FROM @ZRandomPart)
	--AND Inventor.Part_class+Inventor.Part_type NOT IN (SELECT Part_class+Part_type FROM Parttype WHERE LotDetail = 1)
	AND NOT EXISTS (SELECT 1 FROM Parttype WHERE Lotdetail = 1 AND Part_class = Inventor.Part_class AND Part_type = Inventor.Part_type) 
UNION ALL 
-- Lot code parts
-- 05/31/17 VL added functional currency code
SELECT Invtmfgr.Uniq_key, Invtmfgr.W_key, Whno, Location, Partmfgr, Mfgr_pt_no, 
	Part_no, Revision, Warehouse, Part_sourc, Part_class, Part_type, Descript, U_of_meas,
	Invtmfgr.UniqSupNo, Invtlot.LOTQTY AS Qty_oh, GETDATE() AS SYS_Date, @lcAbc_Type AS Abc, 
	Invtlot.LotCode AS LotCode, Invtlot.Expdate AS Expdate,	Invtlot.Reference AS Reference, Invtlot.Ponum AS Ponum, Invtlot.Uniq_lot AS Uniq_lot, 
	Wh_gl_nbr, Stdcost,dbo.fn_GenerateUniqueNumber() AS UniqCcno, Warehous.UniqWh, L.UniqMfgrhd, StdCostPR 
	FROM Inventor INNER JOIN InvtMPNLink L ON Inventor.Uniq_key = L.UNIQ_KEY
	INNER JOIN Invtmfgr ON L.uniqmfgrhd=Invtmfgr.UNIQMFGRHD
	INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId 
	INNER JOIN Warehous ON Invtmfgr.UniqWh = Warehous.UniqWh	
	INNER JOIN Invtlot ON Invtmfgr.w_key = Invtlot.W_key
	ANd L.Is_Deleted = 0
	AND M.Is_Deleted = 0
	AND Invtmfgr.Is_Deleted = 0
	AND Warehouse <> 'MRB'
	AND Warehouse <> 'WO-WIP'
	--- 05/02/16 YS I think this way the "where" is better optimizable
	and ((@lNotInstore=1 and Invtmfgr.INSTORE=0) OR (@lNotInstore=0))
	--AND 0 = (CASE WHEN @lNotInstore = 1 THEN Invtmfgr.INSTORE ELSE 0 END)
	AND Invtmfgr.Uniq_key IN 
		(SELECT Uniq_key FROM @ZRandomPart)
	--AND Inventor.Part_class+Inventor.Part_type IN (SELECT Part_class+Part_type FROM Parttype WHERE LotDetail = 1)
	AND EXISTS (SELECT 1 FROM Parttype WHERE Lotdetail = 1 AND Part_class = Inventor.Part_class AND Part_type = Inventor.Part_type) 
END

