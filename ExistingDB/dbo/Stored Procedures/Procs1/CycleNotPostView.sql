-- =============================================
-- Author: Vicky Lu
-- Create date:
-- Description: Cycle count not post view
-- Modification:
-- 03/09/15 VL try to use CTE cursor to speed up the subselect from invtlot
--- 04/14/15 YS change "location" column length to 256
--02/08/16 YS remove Invtmfhd table and use invtmpnlink
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- =============================================
CREATE PROCEDURE [dbo].[CycleNotPostView]
AS
BEGIN
SET NOCOUNT ON;
--- 04/14/15 YS change "location" column length to 256
DECLARE @NegInvt TABLE (Uniq_key char(10), IQty_oh numeric(12,2), Adj_Qty numeric(12,2), PQty_oh numeric(12,2), PhyCount numeric(12,2),
UniqCcno char(10), UniqMfgrhd char(10), Location varchar(256), UniqWh char(10));
--- 03/28/17 YS changed length of the part_no column from 25 to 35
DECLARE @SerNoProb TABLE (Part_no char(35), Revision char(8), Serialno char(30), UniqCcno char(10), Description char(20))
-- 10/29/14 VL added plan to receive SN to check duplicates
DECLARE @ZPlanToReceive TABLE (Serialno char(30), Uniqmfgrhd char(10), Uniq_key char(10))
DECLARE @XxSNAssign char(1)
SELECT @XxSnAssign = XxSnAssign FROM Shopfset
BEGIN TRANSACTION
BEGIN TRY;
-- Now will insert record in Invtlot if those Ccrecord lot code info can not be found in Invtlot
-- 05/21/12 VL added ISNULL() to criteria for null value
-- 10/27/14 VL found need to add Is_updated = 0 criteria
-- 03/09/15 VL try to use CTE cursor to speed up the subselect from invtlot
--INSERT INVTLOT (W_KEY, LOTCODE, EXPDATE, REFERENCE, PONUM, UNIQ_LOT)
--SELECT W_Key, CASE WHEN Lotcode = '' THEN 'Unk' ELSE Lotcode END AS LotCode, Expdate,
-- CASE WHEN Reference = '' THEN 'LOT'+RIGHT(dbo.fn_GenerateUniqueNumber(),9) ELSE Reference END AS Reference,
-- PoNum, dbo.fn_GenerateUniqueNumber() AS Uniq_lot
-- FROM CCRECORD, INVENTOR, PartType
-- WHERE Ccrecord.UNIQ_KEY = Inventor.UNIQ_KEY
-- AND Inventor.PART_CLASS = PartType.PART_CLASS
-- AND Inventor.PART_TYPE = PartType.PART_TYPE
-- AND PartType.LOTDETAIL = 1
-- AND Ccrecord.CCRECNCL = 1
-- AND Ccrecord.POSTED = 0
-- AND Ccrecord.IS_UPDATED = 0
-- AND LOTCODE + CONVERT(char,ISNULL(Expdate,SPACE(20)),20)+REFERENCE+PONUM NOT IN
-- (SELECT LOTCODE + CONVERT(char,ISNULL(Expdate,SPACE(20)),20)+REFERENCE+PONUM
-- FROM INVTLOT)
;WITH Zlot1 AS (SELECT LOTCODE, Expdate, REFERENCE, PONUM
FROM INVTLOT
WHERE W_KEY IN
(SELECT W_key FROM Ccrecord
WHERE Ccrecord.CCRECNCL = 1
AND Ccrecord.POSTED = 0
AND Ccrecord.IS_UPDATED = 0)
)
INSERT INVTLOT (W_KEY, LOTCODE, EXPDATE, REFERENCE, PONUM, UNIQ_LOT)
SELECT W_Key, CASE WHEN Lotcode = '' THEN 'Unk' ELSE Lotcode END AS LotCode, Expdate,
CASE WHEN Reference = '' THEN 'LOT'+RIGHT(dbo.fn_GenerateUniqueNumber(),9) ELSE Reference END AS Reference,
PoNum, dbo.fn_GenerateUniqueNumber() AS Uniq_lot
FROM CCRECORD, INVENTOR, PartType
WHERE Ccrecord.UNIQ_KEY = Inventor.UNIQ_KEY
AND Inventor.PART_CLASS = PartType.PART_CLASS
AND Inventor.PART_TYPE = PartType.PART_TYPE
AND PartType.LOTDETAIL = 1
AND Ccrecord.CCRECNCL = 1
AND Ccrecord.POSTED = 0
AND Ccrecord.IS_UPDATED = 0
AND LOTCODE + CONVERT(char,ISNULL(Expdate,SPACE(20)),20)+REFERENCE+PONUM NOT IN
(SELECT LOTCODE + CONVERT(char,ISNULL(Expdate,SPACE(20)),20)+REFERENCE+PONUM
FROM Zlot1)
--04/03/2012 YS every time we insert a record we should check for the errors
IF @@ERROR<>0
BEGIN
-- raise an error
RAISERROR ('Insert into InvtLot table has failed.
Cannot proceed with Cycle Count Posting'
,16 -- Severity.
,1 )-- State
ROLLBACK
RETURN
END
-- This SQL contains all those records even marked with reconciled, but now the Invtmfgr.Qty_oh got changed, and can not be
-- reconciled any more because now the adjust qty will make qty OH below 0
-- 10/27/14 VL found need to add Is_updated = 0 criteria
INSERT @NegInvt
SELECT Ccrecord.Uniq_key, Invtmfgr.QTY_OH AS IQty_Oh, -Ccrecord.QTY_OH + Ccrecord.CCOUNT AS Adj_Qty, CcRecord.Qty_oh AS PQty_oh,
Ccount AS PhyCount, UniqCcno, CCRECORD.UniqMfgrhd, Ccrecord.Location, CCRECORD.UniqWh
FROM INVTMFGR, CCRECORD
WHERE Invtmfgr.W_KEY = Ccrecord.W_KEY
AND Invtmfgr.QTY_OH < Ccrecord.QTY_OH - Ccrecord.CCOUNT
AND Ccrecord.Qty_oh > Ccount
AND CCRECNCL = 1
AND Posted = 0
AND Ccrecord.IS_UPDATED = 0
AND Ccrecord.LOTCODE = ''
UNION
SELECT Ccrecord.Uniq_key, Invtlot.LOTQTY AS IQty_Oh, -Ccrecord.QTY_OH + Ccrecord.CCOUNT AS Adj_Qty, CcRecord.Qty_oh AS PQty_oh,
Ccount AS PhyCount, UniqCcno, Ccrecord.Uniqmfgrhd, Ccrecord.Location, CCRECORD.UniqWh
FROM INVTLOT, CCRECORD
WHERE Invtlot.W_key = Ccrecord.W_KEY
AND Invtlot.LOTCODE = Ccrecord.LOTCODE
AND Invtlot.REFERENCE = Ccrecord.REFERENCE
AND ISNULL(Invtlot.EXPDATE,1) = ISNULL(Ccrecord.Expdate,1)
ANd Invtlot.PONUM = Ccrecord.PONUM
AND LotQty < Ccrecord.Qty_Oh - Ccrecord.CCount
AND Ccrecord.Qty_oh > Ccount
AND CCRECNCL = 1
AND Posted = 0
AND Ccrecord.IS_UPDATED = 0
AND Ccrecord.LOTCODE <> ''
-- Return SQL result -- all those new qty OH will belowe 0
SELECT Part_no, Revision, Part_Class, Part_Type, Warehouse, Location, PQty_oh, IQty_Oh, PhyCount, Adj_Qty
FROM @NegInvt NegInvt, INVENTOR, WAREHOUS
WHERE NegInvt.UNIQ_KEY = Inventor.Uniq_key
AND NegInvt.UniqWh = Warehous.UNIQWH
ORDER BY 5,6,1,2
-- Update back to not reconciled yet
UPDATE CCRECORD
SET CcRecncl = 0
WHERE UNIQCCNO IN
(SELECT UNIQCCNO
FROM @NegInvt)
IF @@ERROR<>0
BEGIN
-- raise an error
RAISERROR ('Updating Cycle Count records are failed.
Cannot proceed with Cycle Count Posting'
,16 -- Severity.
,1 )-- State
ROLLBACK
RETURN
END
-- check if the Cyclser.Serialno either not in inventory any more or become in different location
INSERT @SerNoProb
SELECT Part_no, Revision, Cycleser.Serialno, CYCLESER.UniqCcno,
CASE WHEN (Id_key= 'W_KEY' AND Id_Value <> Ccrecord.W_key) THEN 'Different Location ' ELSE
CASE WHEN Id_key <> 'W_KEY' THEN 'Not in the Inventory' ELSE SPACE(20) END END AS Description
FROM Inventor, CYCLESER, Ccrecord, INVTSER
WHERE Inventor.UNIQ_KEY = InvtSer.UNIQ_KEY
AND InvtSer.UNIQ_KEY = Ccrecord.UNIQ_KEY
AND Ccrecord.UNIQCCNO = Cycleser.UNIQCCNO
AND Invtser.SERIALNO = CycleSer.SERIALNO
AND InvtSer.UNIQMFGRHD = CycleSer.UNIQMFGRHD
AND InvtSer.UNIQMFGRHD = Ccrecord.UniqMfgrHd
AND InvtSer.LOTCODE = Ccrecord.LotCode
AND InvtSer.REFERENCE = Ccrecord.REFERENCE
AND ISNULL(InvtSer.EXPDATE,1) = ISNULL(Ccrecord.Expdate,1)
ANd InvtSer.PONUM = Ccrecord.PONUM
AND Inventor.SerialYes = 1
AND CCRECNCL = 1
AND POSTED = 0
AND Ccrecord.IS_UPDATED = 0
AND ((Id_key= 'W_KEY'
AND Id_Value <> Ccrecord.W_key)
OR Id_key <> 'W_KEY')
-- 10/27/14 VL added to trap if duplicate SN belongs to same w_key but different lot code
INSERT @SerNoProb
SELECT Part_no, Revision, Cycleser.Serialno, CYCLESER.UniqCcno, 'Different Lot ' AS Description
FROM Inventor, CYCLESER, Ccrecord, INVTSER
WHERE Inventor.UNIQ_KEY = InvtSer.UNIQ_KEY
AND InvtSer.UNIQ_KEY = Ccrecord.UNIQ_KEY
AND Ccrecord.UNIQCCNO = Cycleser.UNIQCCNO
AND Invtser.SERIALNO = CycleSer.SERIALNO
AND InvtSer.UNIQMFGRHD = CycleSer.UNIQMFGRHD
AND InvtSer.UNIQMFGRHD = Ccrecord.UniqMfgrHd
AND (InvtSer.LOTCODE <> Ccrecord.LotCode
OR InvtSer.REFERENCE <> Ccrecord.REFERENCE
OR ISNULL(InvtSer.EXPDATE,1) <> ISNULL(Ccrecord.Expdate,1)
OR InvtSer.PONUM <> Ccrecord.PONUM)
AND Inventor.SerialYes = 1
AND CCRECNCL = 1
AND POSTED = 0
AND Ccrecord.IS_UPDATED = 0
AND Id_key= 'W_KEY'
AND Id_Value = Ccrecord.W_key
-- 10/29/14 VL get all SN that plans to receive and already in system, then check duplicate
INSERT @ZPlanToReceive (Serialno, Uniqmfgrhd)
SELECT Serialno, Uniqmfgrhd
FROM CycleSer
WHERE UniqCcno IN (SELECT UniqCcno FROM Ccrecord WHERE CCRECNCL = 1 AND POSTED = 0 AND Ccrecord.IS_UPDATED = 0)
AND Serialno NOT IN (SELECT Serialno
FROM Invtser, Ccrecord
WHERE Invtser.Uniq_key = Ccrecord.Uniq_key
AND Invtser.Uniqmfgrhd = Ccrecord.uniqmfgrhd
AND Invtser.Lotcode = Ccrecord.Lotcode
AND ISNULL(Invtser.Expdate,1) = ISNULL(Ccrecord.Expdate,1)
AND Invtser.Ponum = Ccrecord.Ponum
AND Invtser.Reference = Ccrecord.Reference
AND Invtser.Id_Value = Ccrecord.W_key
AND Invtser.Id_key = 'W_KEY'
AND CCRECNCL = 1
AND POSTED = 0
AND Ccrecord.IS_UPDATED = 0)
--02/08/16 YS remove Invtmfhd table and use invtmpnlink
--UPDATE @ZPlanToReceive SET Uniq_key = Invtmfhd.Uniq_key FROM @ZPlanToReceive ZPlanToReceive, Invtmfhd WHERE ZPlanToReceive.Uniqmfgrhd = Invtmfhd.UniqMfgrhd
UPDATE @ZPlanToReceive SET Uniq_key = Invtmpnlink.Uniq_key FROM @ZPlanToReceive ZPlanToReceive inner join Invtmpnlink on ZPlanToReceive.Uniqmfgrhd = Invtmpnlink.UniqMfgrhd
BEGIN
IF @XxSnAssign = 'P' -- Unique by part
BEGIN
INSERT @SerNoProb
SELECT Part_no, Revision, Serialno, SPACE(10) AS UniqCcno, 'Duplicate Serial NO ' AS Description
FROM InvtSer,Inventor
WHERE Invtser.Uniq_key = Inventor.Uniq_key
AND Serialno+Invtser.Uniq_key IN
(SELECT Serialno+Uniq_key FROM @ZPlanToReceive)
END
ELSE
-- Unique by system
BEGIN
INSERT @SerNoProb
SELECT Part_no, Revision, Serialno, SPACE(10) AS UniqCcno, 'Duplicate Serial NO ' AS Description
FROM InvtSer,Inventor
WHERE Invtser.Uniq_key = Inventor.Uniq_key
AND Serialno IN
(SELECT Serialno FROM @ZPlanToReceive)
END
END
-- 10/27/14 VL End}
-- Return SQL result1 -- Those record whose SN have issues (not in inventory any more or in inventory but in different location)
SELECT *
FROM @SerNoProb
ORDER BY Part_no, Revision, Serialno
-- Update back to not reconciled yet
UPDATE CCRECORD
SET CcRecncl = 0
WHERE UNIQCCNO IN
(SELECT UNIQCCNO
FROM @SerNoProb)
IF @@ERROR<>0
BEGIN
-- raise an error
RAISERROR ('Updating Cycle Count records are failed.
Cannot proceed with Cycle Count Posting'
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
IF @@ERROR<>0 OR @@TRANCOUNT=0 BEGIN IF @@TRANCOUNT>0 ROLLBACK SET NOEXEC ON END