-- =============================================
-- Author: Vicky Lu
-- Create date:
-- Description: Physical inventory not update view
-- Modification:
-- 03/09/15 VL try to use CTE cursor to speed up the subselect from invtlot
--- 04/14/15 YS change "location" column length to 256
--- 03/28/17 YS changed length of the part_no column from 25 to 35
 --03/01/18 YS lotcode size change to 25
-- =============================================
CREATE PROCEDURE [dbo].[PhyInvtNotUpdView] @lcUniqPiHead char(10) = ' '
AS
BEGIN
SET NOCOUNT ON;
 --03/01/18 YS lotcode size change to 25
DECLARE @tUpdInvtLot TABLE (W_key char(10), LotCode char(25), Expdate smalldatetime, Reference char(12), Ponum char(15), Uniq_lot char(10), UniqPhyNo char(10))
--- 04/14/15 YS change "location" column length to 256
DECLARE @NegInvt TABLE (UniqMfgrhd char(10), Uniq_key char(10), W_key char(10), UniqWh char(10), Location varchar(256),
Adj_Qty numeric(12,2), IQty_oh numeric(12,2), PQty_oh numeric(12,2), PhyCount numeric(12,2), UniqPhyno char(10));
--- 03/28/17 YS changed length of the part_no column from 25 to 35
DECLARE @SerNoProb TABLE (Part_no char(35), Revision char(8), Serialno char(30), UniqCcno char(10), Description char(20))
DECLARE @lnInvtType numeric(1,0)
SELECT @lnInvtType = InvtType FROM PHYINVTH WHERE UNIQPIHEAD = @lcUniqPiHead
BEGIN TRANSACTION
BEGIN TRY
-- Prepare a table that Phinvt lot records can not find in invtlot, will be inserted into invtlot and update phyinvt(didn't have lot info because qty = 0)
-- 03/09/15 VL try to use CTE cursor to speed up the subselect from invtlot
--INSERT @tUpdInvtLot (W_KEY, LOTCODE, EXPDATE, REFERENCE, PONUM, UNIQ_LOT, UniqPhyNo)
-- SELECT W_Key, CASE WHEN Lotcode = '' THEN 'Sys Generated' ELSE Lotcode END AS LotCode,
-- CASE WHEN ExpDate IS NULL THEN GETDATE() ELSE Expdate END AS Expdate,
-- CASE WHEN Reference = '' THEN 'LOT'+RIGHT(dbo.fn_GenerateUniqueNumber(),9) ELSE Reference END AS Reference,
-- PoNum, CASE WHEN Uniq_lot = '' THEN dbo.fn_GenerateUniqueNumber() ELSE Uniq_lot END AS Uniq_lot, UniqPhyno
-- FROM PHYINVT, INVENTOR, PartType
-- WHERE PHYINVT.UNIQ_KEY = Inventor.UNIQ_KEY
-- AND Inventor.PART_CLASS = PartType.PART_CLASS
-- AND Inventor.PART_TYPE = PartType.PART_TYPE
-- AND PartType.LOTDETAIL = 1
-- AND InvRecncl = 1
-- AND UniqPiHead = @lcUniqPiHead
-- AND LOTCODE + CONVERT(char,Expdate,20)+REFERENCE+PONUM NOT IN
-- (SELECT LOTCODE + CONVERT(char,Expdate,20)+REFERENCE+PONUM
-- FROM INVTLOT)
;WITH Zlot1 AS (SELECT LOTCODE, Expdate, REFERENCE, PONUM
FROM INVTLOT
WHERE W_KEY IN
(SELECT W_key FROM Phyinvt
WHERE InvRecncl = 1
AND UniqPiHead = @lcUniqPiHead)
)
INSERT @tUpdInvtLot (W_KEY, LOTCODE, EXPDATE, REFERENCE, PONUM, UNIQ_LOT, UniqPhyNo)
SELECT W_Key, CASE WHEN Lotcode = '' THEN 'Sys Generated' ELSE Lotcode END AS LotCode,
CASE WHEN ExpDate IS NULL THEN GETDATE() ELSE Expdate END AS Expdate,
CASE WHEN Reference = '' THEN 'LOT'+RIGHT(dbo.fn_GenerateUniqueNumber(),9) ELSE Reference END AS Reference,
PoNum, CASE WHEN Uniq_lot = '' THEN dbo.fn_GenerateUniqueNumber() ELSE Uniq_lot END AS Uniq_lot, UniqPhyno
FROM PHYINVT, INVENTOR, PartType
WHERE PHYINVT.UNIQ_KEY = Inventor.UNIQ_KEY
AND Inventor.PART_CLASS = PartType.PART_CLASS
AND Inventor.PART_TYPE = PartType.PART_TYPE
AND PartType.LOTDETAIL = 1
AND InvRecncl = 1
AND UniqPiHead = @lcUniqPiHead
AND LOTCODE + CONVERT(char,Expdate,20)+REFERENCE+PONUM NOT IN
(SELECT LOTCODE + CONVERT(char,Expdate,20)+REFERENCE+PONUM
FROM Zlot1)
-- Now will insert record in Invtlot if those Phyinvt lot code info can not be found in Invtlot
INSERT INVTLOT (W_KEY, LOTCODE, EXPDATE, REFERENCE, PONUM, UNIQ_LOT)
SELECT W_KEY, LOTCODE, EXPDATE, REFERENCE, PONUM, UNIQ_LOT
FROM @tUpdInvtLot
IF @@ERROR<>0
BEGIN
-- raise an error
RAISERROR ('Insert into InvtLot table has failed.
Cannot proceed with Physical Inventory Posting'
,16 -- Severity.
,1 )-- State
ROLLBACK
RETURN
END
-- now, update Phinvt lotcode fields because before if the qty = 0, there might not have lot code info
UPDATE PHYINVT
SET LOTCODE = tUpdInvtLot.LotCode,
Expdate = tUpdInvtLot.Expdate,
REFERENCE = tUpdInvtLot.Reference,
PONUM = tUpdInvtLot.Ponum
FROM PHYINVT, @tUpdInvtLot tUpdInvtLot
WHERE PhyInvt.UNIQPHYNO = tUpdInvtLot.UniqPhyNo
IF @@ERROR<>0
BEGIN
-- raise an error
RAISERROR ('Updating physical invenotry lot code records has failed.
Cannot proceed with Physical Inventory Posting'
,16 -- Severity.
,1 )-- State
ROLLBACK
RETURN
END
-- 1. This SQL contains all those records even marked with reconciled, but now the Invtmfgr.Qty_oh got changed, and can not be
-- reconciled any more because now the adjust qty will make qty OH below 0
-- 05/14/12 VL changed original code to new one, don't understand the reason
--AND ABS(Invtmfgr.QTY_OH) < ABS(PhyInvt.QTY_OH - PhyInvt.PhyCOUNT)
--AND PhyInvt.Qty_Oh - PhyInvt.PhyCount < 0
--AND ABS(Invtlot.LOTQTY) < ABS(PhyInvt.Qty_Oh - PhyInvt.PhyCount)
--AND PhyInvt.Qty_Oh - PhyInvt.PhyCount < 0
INSERT @NegInvt
SELECT UniqPiHead, PhyInvt.Uniq_key, PhyInvt.W_Key, Invtmfgr.UniqWh, InvtMfgr.Location, PhyInvt.Qty_Oh - Phycount AS Adj_Qty,
InvtMfgr.Qty_Oh AS IQty_oh, PhyInvt.Qty_Oh AS PQty_oh, PhyCount, UniqPhyNo
FROM INVTMFGR, PhyInvt
WHERE Invtmfgr.W_KEY = PhyInvt.W_KEY
AND PhyInvt.Qty_oh > PhyInvt.PhyCount
AND PhyInvt.Qty_Oh - Phyinvt.PhyCount > Invtmfgr.Qty_oh
AND PhyInvt.UNIQPIHEAD = @lcUniqPiHead
AND PhyInvt.LOTCODE = ''
UNION
SELECT UniqPiHead, PhyInvt.Uniq_Key, PhyInvt.W_Key, Invtmfgr.UniqWh, InvtMfgr.Location, PhyInvt.Qty_Oh - Phycount AS Adj_Qty,
Invtlot.LOTQTY AS IQty_oh, PhyInvt.QTY_OH AS PQty_oh, PhyCount, UniqPhyNo
FROM INVTLOT, PhyInvt, Invtmfgr
WHERE Invtlot.W_key = PhyInvt.W_KEY
AND PhyInvt.W_KEY = Invtmfgr.W_key
AND Invtlot.LOTCODE = PhyInvt.LOTCODE
AND Invtlot.REFERENCE = PhyInvt.REFERENCE
AND ISNULL(Invtlot.EXPDATE,1) = ISNULL(PhyInvt.Expdate,1)
ANd Invtlot.PONUM = PhyInvt.PONUM
AND PhyInvt.Qty_oh > PhyInvt.PhyCount
AND PhyInvt.Qty_Oh - Phyinvt.PhyCount > Invtlot.LotQty
AND PhyInvt.UNIQPIHEAD = @lcUniqPiHead
AND PhyInvt.LOTCODE <> ''
-- Return SQL result -- all those new qty OH will belowe 0
SELECT CASE WHEN @lnInvtType = 2 THEN CustPartNo ELSE Part_no END AS Part_no, --@lnInvType = 2 - Consigned
CASE WHEN @lnInvtType = 2 THEN CustRev ELSE Revision END AS Revision,
Warehouse, Location, Part_Class, Part_Type, PQty_Oh, IQty_oh, PhyCount, Adj_Qty
FROM @NegInvt NegInvt, Inventor, Warehous
WHERE NegInvt.UNIQ_KEY = Inventor.Uniq_key
AND NegInvt.UniqWh = Warehous.UNIQWH
ORDER BY 3, 4, 1, 2
-- Update back to not reconciled yet
UPDATE PhyInvt
SET InvRecncl = 0
WHERE UniqPhyNo IN
(SELECT UniqPhyNo
FROM @NegInvt)
IF @@ERROR<>0
BEGIN
-- raise an error
RAISERROR ('Updating Physical Inventory records are failed.
Cannot proceed with Physcial Inventory Posting'
,16 -- Severity.
,1 )-- State
ROLLBACK
RETURN
END
-- 2. Now check if decrease too many, will affect reserved qty
DELETE FROM @NegInvt WHERE 1=1
-- 05/14/12 VL changed original code that didn't seem to make sense, use new code
--AND InvtMfgr.QTY_Oh - InvtMfgr.Reserved < PhyInvt.Qty_Oh - PhyCount ;
--AND PhyInvt.Qty_Oh - PhyCount < 0 ;
--AND PhyInvt.Qty_oh > PhyInvt.PhyCount
--AND PhyInvt.Qty_Oh - Phyinvt.PhyCount > Invtlot.LotQty
INSERT @NegInvt
SELECT UniqPiHead, PhyInvt.Uniq_key, PhyInvt.W_Key, Invtmfgr.UniqWh, InvtMfgr.Location, PhyInvt.Qty_Oh - Phycount AS Adj_Qty,
InvtMfgr.Qty_Oh AS IQty_oh, PhyInvt.Qty_Oh AS PQty_oh, PhyCount, UniqPhyNo
FROM INVTMFGR, PhyInvt
WHERE Invtmfgr.W_KEY = PhyInvt.W_KEY
AND PhyInvt.Qty_oh > PhyInvt.PhyCount
AND PhyInvt.Qty_Oh - Phyinvt.PhyCount > Invtmfgr.Qty_oh - Invtmfgr.Reserved
AND PhyInvt.UNIQPIHEAD = @lcUniqPiHead
AND PhyInvt.LOTCODE = ''
UNION
SELECT UniqPiHead, PhyInvt.Uniq_Key, PhyInvt.W_Key, Invtmfgr.UniqWh, InvtMfgr.Location, PhyInvt.Qty_Oh - Phycount AS Adj_Qty,
Invtlot.LOTQTY AS IQty_oh, PhyInvt.QTY_OH AS PQty_oh, PhyCount, UniqPhyNo
FROM INVTLOT, PhyInvt, Invtmfgr
WHERE Invtlot.W_key = PhyInvt.W_KEY
AND PhyInvt.W_KEY = Invtmfgr.W_key
AND Invtlot.LOTCODE = PhyInvt.LOTCODE
AND Invtlot.REFERENCE = PhyInvt.REFERENCE
AND ISNULL(Invtlot.EXPDATE,1) = ISNULL(PhyInvt.Expdate,1)
ANd Invtlot.PONUM = PhyInvt.PONUM
AND PhyInvt.Qty_oh > PhyInvt.PhyCount
AND PhyInvt.Qty_Oh - Phyinvt.PhyCount > Invtlot.LotQty - InvtLot.LotResQty
AND PhyInvt.UNIQPIHEAD = @lcUniqPiHead
AND PhyInvt.LOTCODE <> ''
-- Return SQL result 1 -- all those adjustment will affect reserved qty
SELECT CASE WHEN @lnInvtType = 2 THEN CustPartNo ELSE Part_no END AS Part_no, --@lnInvType = 2 - Consigned
CASE WHEN @lnInvtType = 2 THEN CustRev ELSE Revision END AS Revision,
Warehouse, Location, Part_Class, Part_Type, PQty_Oh, IQty_oh, PhyCount, Adj_Qty
FROM @NegInvt NegInvt, Inventor, Warehous
WHERE NegInvt.UNIQ_KEY = Inventor.Uniq_key
AND NegInvt.UniqWh = Warehous.UNIQWH
ORDER BY 3, 4, 1, 2
-- Update back to not reconciled yet
UPDATE PhyInvt
SET InvRecncl = 0
WHERE UniqPhyNo IN
(SELECT UniqPhyNo
FROM @NegInvt)
IF @@ERROR<>0
BEGIN
-- raise an error
RAISERROR ('Updating Physical Inventory records are failed.
Cannot proceed with Physcial Inventory Posting'
,16 -- Severity.
,1 )-- State
ROLLBACK
RETURN
END
-- 3. Check if the PhyInvtser.Serialno either not in inventory any more or become in different location
INSERT @SerNoProb
SELECT Part_no, Revision, PhyInvtser.Serialno, PhyInvtser.UniqPhyno,
CASE WHEN (Id_key= 'W_KEY' AND Id_Value <> PhyInvt.W_key) THEN 'Different Location ' ELSE
CASE WHEN Id_key <> 'W_KEY' THEN 'Not in the Inventory' ELSE SPACE(20) END END AS Description
FROM Inventor, PhyInvtser, PhyInvt, INVTSER
WHERE Inventor.UNIQ_KEY = InvtSer.UNIQ_KEY
AND InvtSer.UNIQ_KEY = PhyInvt.UNIQ_KEY
AND PhyInvt.Uniqphyno = PhyInvtser.UniqPhyno
AND Invtser.SERIALNO = PhyInvtser.SERIALNO
AND InvtSer.UNIQMFGRHD = PhyInvtser.UNIQMFGRHD
AND InvtSer.LOTCODE = PhyInvt.LotCode
AND InvtSer.REFERENCE = PhyInvt.REFERENCE
AND ISNULL(InvtSer.EXPDATE,1) = ISNULL(PhyInvt.Expdate,1)
ANd InvtSer.PONUM = PhyInvt.PONUM
AND Inventor.SerialYes = 1
AND PhyInvt.UNIQPIHEAD = @lcUniqPiHead
AND ((Id_key= 'W_KEY'
AND Id_Value <> PhyInvt.W_key)
OR Id_key <> 'W_KEY')
-- Return SQL result2 -- Those record whose SN have issues (not in inventory any more or in inventory but in different location)
SELECT *
FROM @SerNoProb
ORDER BY Part_no, Revision, Serialno
-- Update back to not reconciled yet
UPDATE PhyInvt
SET InvRecncl = 0
WHERE UniqPhyNo IN
(SELECT UniqPhyNo
FROM @SerNoProb)
IF @@ERROR<>0
BEGIN
-- raise an error
RAISERROR ('Updating Physical Inventory records are failed.
Cannot proceed with Physcial Inventory Posting'
,16 -- Severity.
,1 )-- State
ROLLBACK
RETURN
END
END TRY
BEGIN CATCH
RAISERROR('Error occurred in updating physical inventory records. This operation will be cancelled.',1,1)
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END