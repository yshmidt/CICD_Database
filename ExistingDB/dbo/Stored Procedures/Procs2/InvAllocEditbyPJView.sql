-- =============================================
-- Author:		Vicky Lu
-- Create date: ???
-- Description:	???
-- Modified: - 08/29/14 VL 
---			10/09/14 YS replace invtmfhd table with 2 new tables
--- 04/14/15 YS change "location" column length to 256
-- 03/28/16 YS removed serial number from invt_res table . Whne working on the allocation we may need to dump this procedure or modify it 
--02/09/18 YS changed size of the lotcode column to 25 char
-- =============================================
CREATE PROCEDURE [dbo].[InvAllocEditbyPJView] @lcPrjUnique AS char(10) = ' '
AS
BEGIN
-- 08/29/14 VL Changed @ZInvAllocD from  TO ON Invt_res.W_key+Invt_res.Lotcode+CONVERT(char,Invt_res.expdate,20)+Invt_res.reference+Invt_res.Ponum = Invtlot.W_key+Invtlot.lotcode+CONVERT(char,Invtlot.expdate,20)+Invtlot.reference+Invtlot.Ponum 
--  TO ON Invt_res.W_key = Invtlot.W_key
--	AND Invt_res.Lotcode = Invtlot.lotcode
--	AND ISNULL(Invt_res.Expdate,1) = ISNULL(Invtlot.Expdate,1)
--	AND Invt_res.Reference = Invtlot.Reference
--	AND Invt_res.Ponum = Invtlot.Ponum 
	
SET NOCOUNT ON;
--- 04/14/15 YS change "location" column length to 256
--03/28/16 YS removed serial number
--02/09/18 YS changed size of the lotcode column to 25 char
DECLARE	@ZInvAllocD TABLE (QtyAlloc numeric(12,2), Uniq_key char(10), DateTime smalldatetime, SaveInit char(8), Invtres_no char(10), 
		Partmfgr char(8), Mfgr_pt_no char(30), UniqWh char(10), Location varchar(256), W_key char(10), AvailQty numeric(12,2), 
		AvailBalance numeric(12,2), Lotcode nvarchar(25), Expdate smalldatetime, 
		Ponum char(15), Reference char(12), LotResQty numeric(12,2), Warehouse char(6), Refinvtres char(10), 
		OldQtyAlloc numeric(12,2), Fk_PrjUnique char(10), Wono char(10), PrjUnique chAr(10))
		
		
-- Prepare detail
-------------------------------------------------------------------------------------
-- 08/29/14 VL changed LEFT OUTER JOIN
-- 10/09/14 YS replace invtmfhd table with 2 new tables
--03/28/16 YS removed serial number
--02/09/18 YS changed size of the lotcode column to 25 char
INSERT @ZInvAllocD
SELECT Qtyalloc, Invt_Res.Uniq_Key, Invt_res.DateTime, Invt_res.Saveinit, Invt_res.Invtres_no, 
		m.Partmfgr, m.Mfgr_pt_no, Invtmfgr.UniqWh, Invtmfgr.Location, Invtmfgr.W_key,
		CASE WHEN (Invtlot.Lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN Invtmfgr.Qty_oh-Invtmfgr.Reserved ELSE Invtlot.Lotqty-Invtlot.Lotresqty END AS AvailQty,
		CASE WHEN (Invtlot.Lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN Invtmfgr.Qty_oh-Invtmfgr.Reserved ELSE Invtlot.Lotqty-Invtlot.Lotresqty END AS AvailBalance,
		ISNULL(Invtlot.Lotcode, SPACE(25)) AS LotCode, Invtlot.Expdate, ISNULL(Invtlot.Ponum,SPACE(15)) AS Ponum, 
		ISNULL(Invtlot.Reference,SPACE(12)) AS Reference,
		CASE WHEN (Invtlot.Lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN 0 ELSE Invtlot.Lotresqty END AS Lotresqty, 
		Warehous.warehouse, Invt_Res.RefInvtRes,  Invt_Res.QtyAlloc AS OldQtyAlloc,
		Invt_Res.Fk_PrjUnique,Invt_res.wono, Invt_Res.Fk_PrjUnique AS PrjUnique
FROM Warehous, InvtMPNLink L, MfgrMaster M, Invtmfgr, Invt_res LEFT OUTER JOIN Invtlot
	ON Invt_res.W_key = Invtlot.W_key
	AND Invt_res.Lotcode = Invtlot.lotcode
	AND ISNULL(Invt_res.Expdate,1) = ISNULL(Invtlot.Expdate,1)
	AND Invt_res.Reference = Invtlot.Reference
	AND Invt_res.Ponum = Invtlot.Ponum 
WHERE  Invtmfgr.UniqWh = Warehous.UniqWh
	AND Invt_res.Fk_PrjUnique = @lcPrjUnique
	AND Invtmfgr.w_key = Invt_res.w_key
	AND L.UniqMfgrHd=Invtmfgr.UniqMfgrHd
	AND L.mfgrMasterId=M.MfgrMasterId				
-- Detail
-- Also filter out if it has unallocated records or is unallocated records of others
SELECT * 
	FROM @ZInvAllocD
	WHERE InvtRes_No NOT IN (SELECT RefInvtRes FROM @ZinvAllocD) 
			AND RefInvtRes NOT IN (SELECT InvtRes_No FROM @ZinvAllocD);

WITH ZAllocDetail AS
(
SELECT * 
	FROM @ZInvAllocD
	WHERE InvtRes_No NOT IN (SELECT RefInvtRes FROM @ZinvAllocD) 
			AND RefInvtRes NOT IN (SELECT InvtRes_No FROM @ZinvAllocD)
)
		SELECT DISTINCT Inventor.Part_No, Inventor.Revision, Inventor.Descript, Part_Sourc, 
			Inventor.Part_Class, Inventor.Part_Type, ZAllocDetail.Uniq_key, Inventor.U_of_meas AS U_of_meas, 
			PjctMain.PrjNumber, ZAllocDetail.Fk_PrjUnique AS PrjUnique, CustName
			FROM ZAllocDetail, PjctMain, Inventor, Customer
			WHERE ZAllocDetail.Fk_PrjUnique = @lcPrjUnique
			AND PjctMain.PrjUnique = ZAllocDetail.Fk_PrjUnique 
			AND Inventor.Uniq_Key = ZAllocDetail.Uniq_Key 
			AND PjctMain.CUSTNO = CUSTomer.Custno
		ORDER BY Inventor.Part_No, Inventor.Revision
		
END			