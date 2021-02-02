-- =============================================
-- Author:		Vicky Lu
-- Create date: 2012/05/08
-- Description:	Create new Phyinvt records based on what user selected part class, warehouse
-- Modified:  10/10/14 YS replaced invtmfhd table with 2 new tables
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[sp_PhyinvtSetupNew] @lcUniqPiHead AS char(10) = ''
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

BEGIN TRANSACTION
BEGIN TRY;
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
DECLARE @lnInvtType numeric(1,0), @lcDetailNo char(10), @lcStartNo char(35), @lcEndNo char(35)

SELECT @lnInvtType = InvtType, @lcDetailNo = DetailNo, @lcStartNo = StartNo, @lcEndNo = EndNo FROM PHYINVTH WHERE UNIQPIHEAD = @lcUniqPiHead
-- 10/10/14 YS replaced invtmfhd table with 2 new tables
INSERT PhyInvt (UNIQ_KEY, UNIQPIHEAD, UNIQPHYNO, TAG_NO, W_KEY, LOTCODE, REFERENCE, QTY_OH, SYS_DATE, EXPDATE, PONUM, UNIQ_LOT)
-- 10/10/14 YS replaced invtmfhd table with 2 new tables
--SELECT DISTINCT Invtmfgr.Uniq_key, @lcUniqPiHead AS UniqPiHead, dbo.fn_GenerateUniqueNumber() AS UniqPhyNo, '' AS Tag_no,
--		Invtmfgr.W_key, ISNULL(LotCode,SPACE(15)) AS LotCode, ISNULL(Reference,SPACE(12)) AS Reference, 
--		ISNULL(LotQty,Qty_oh) AS Qty_Oh, GETDATE() AS Sys_Date, ISNULL(Expdate,NULL) AS Expdate, ISNULL(Ponum, SPACE(15)) AS Ponum, 
--		ISNULL(Uniq_lot,SPACE(10)) AS Uniq_lot
--	FROM Inventor, Invtmfhd, InvtMfgr LEFT OUTER JOIN InvtLot 
--	ON InvtMfgr.W_KEY = InvtLot.W_KEY
--	WHERE Inventor.Uniq_Key = InvtMfhd.Uniq_Key 
--	AND Invtmfgr.UniqMfgrHd = Invtmfhd.UniqMfgrHd 
--	AND InvtMfgr.UniqWh IN (SELECT UniqWh FROM PHYHDTL WHERE UNIQWH <> '' AND UNIQPIHEAD = @lcUniqPiHead) 
--	AND Part_Class IN (SELECT Part_Class FROM PHYHDTL WHERE Part_Class <> '' AND UNIQPIHEAD = @lcUniqPiHead) 
--	AND InvtMfgr.CountFlag = ''
--	AND Inventor.Status = 'Active'
--	AND Invtmfgr.Is_Deleted = 0
--	AND Invtmfhd.Is_Deleted = 0 
--	AND 1 = CASE WHEN @lnInvtType = 1 THEN CASE WHEN (PART_SOURC <> 'CONSG' AND Invtmfgr.INSTORE = 0) THEN 1 ELSE 0 END ELSE 1 END -- * Internal
--	AND 1 = CASE WHEN @lnInvtType = 2 THEN CASE WHEN (PART_SOURC =  'CONSG' AND Inventor.CUSTNO = @lcDetailNo) THEN 1 ELSE 0 END ELSE 1 END -- * Consigned
--	AND 1 = CASE WHEN @lnInvtType = 3 THEN CASE WHEN (PART_SOURC <> 'CONSG' AND Invtmfgr.INSTORE = 1 AND Invtmfgr.uniqsupno = @lcDetailNo) THEN 1 ELSE 0 END ELSE 1 END --* Instore
--	AND 1 = CASE WHEN @lcStartNo <> '' AND @lcEndNo <> '' AND @lnInvtType <> 2 THEN CASE WHEN (PART_NO BETWEEN @lcStartNo AND @lcEndNo) THEN 1 ELSE 0 END ELSE 1 END -- * Both Numbers Entered with not Consigned
--	AND 1 = CASE WHEN @lcStartNo <> '' AND @lcEndNo <> '' AND @lnInvtType =  2 THEN CASE WHEN (CUSTPARTNO BETWEEN @lcStartNo AND @lcEndNo) THEN 1 ELSE 0 END ELSE 1 END -- * Both Numbers Entered with Consigned
--	AND 1 = CASE WHEN @lcStartNo <> '' AND @lcEndNo =  '' AND @lnInvtType <> 2 THEN CASE WHEN (PART_NO >= @lcStartNo) THEN 1 ELSE 0 END ELSE 1 END -- * Only Beginning Number Entered with not Consigned
--	AND 1 = CASE WHEN @lcStartNo <> '' AND @lcEndNo =  '' AND @lnInvtType =  2 THEN CASE WHEN (CUSTPARTNO >= @lcStartNo) THEN 1 ELSE 0 END ELSE 1 END -- * Only Beginning Number Entered with Consigned
--	AND 1 = CASE WHEN @lcStartNo =  '' AND @lcEndNo <> '' AND @lnInvtType <> 2 THEN CASE WHEN (PART_NO <= @lcEndNo) THEN 1 ELSE 0 END ELSE 1 END -- * Only Ending Number Entered with not Consigned
--	AND 1 = CASE WHEN @lcStartNo =  '' AND @lcEndNo <> '' AND @lnInvtType =  2 THEN CASE WHEN (CUSTPARTNO <= @lcEndNo) THEN 1 ELSE 0 END ELSE 1 END -- * Only Ending Number Entered with Consigned
--- 10/10/14 YS no need to have invtmfhd table included (confirmed with Vicky) 
SELECT DISTINCT Invtmfgr.Uniq_key, @lcUniqPiHead AS UniqPiHead, dbo.fn_GenerateUniqueNumber() AS UniqPhyNo, '' AS Tag_no,
		Invtmfgr.W_key, ISNULL(LotCode,SPACE(15)) AS LotCode, ISNULL(Reference,SPACE(12)) AS Reference, 
		ISNULL(LotQty,Qty_oh) AS Qty_Oh, GETDATE() AS Sys_Date, ISNULL(Expdate,NULL) AS Expdate, ISNULL(Ponum, SPACE(15)) AS Ponum, 
		ISNULL(Uniq_lot,SPACE(10)) AS Uniq_lot
	FROM Inventor, InvtMfgr LEFT OUTER JOIN InvtLot 
	ON InvtMfgr.W_KEY = InvtLot.W_KEY
	WHERE Inventor.Uniq_Key = InvtMfgr.Uniq_Key 
	AND InvtMfgr.UniqWh IN (SELECT UniqWh FROM PHYHDTL WHERE UNIQWH <> '' AND UNIQPIHEAD = @lcUniqPiHead) 
	AND Part_Class IN (SELECT Part_Class FROM PHYHDTL WHERE Part_Class <> '' AND UNIQPIHEAD = @lcUniqPiHead) 
	AND InvtMfgr.CountFlag = ''
	AND Inventor.Status = 'Active'
	AND Invtmfgr.Is_Deleted = 0
	AND 1 = CASE WHEN @lnInvtType = 1 THEN CASE WHEN (PART_SOURC <> 'CONSG' AND Invtmfgr.INSTORE = 0) THEN 1 ELSE 0 END ELSE 1 END -- * Internal
	AND 1 = CASE WHEN @lnInvtType = 2 THEN CASE WHEN (PART_SOURC =  'CONSG' AND Inventor.CUSTNO = @lcDetailNo) THEN 1 ELSE 0 END ELSE 1 END -- * Consigned
	AND 1 = CASE WHEN @lnInvtType = 3 THEN CASE WHEN (PART_SOURC <> 'CONSG' AND Invtmfgr.INSTORE = 1 AND Invtmfgr.uniqsupno = @lcDetailNo) THEN 1 ELSE 0 END ELSE 1 END --* Instore
	AND 1 = CASE WHEN @lcStartNo <> '' AND @lcEndNo <> '' AND @lnInvtType <> 2 THEN CASE WHEN (PART_NO BETWEEN @lcStartNo AND @lcEndNo) THEN 1 ELSE 0 END ELSE 1 END -- * Both Numbers Entered with not Consigned
	AND 1 = CASE WHEN @lcStartNo <> '' AND @lcEndNo <> '' AND @lnInvtType =  2 THEN CASE WHEN (CUSTPARTNO BETWEEN @lcStartNo AND @lcEndNo) THEN 1 ELSE 0 END ELSE 1 END -- * Both Numbers Entered with Consigned
	AND 1 = CASE WHEN @lcStartNo <> '' AND @lcEndNo =  '' AND @lnInvtType <> 2 THEN CASE WHEN (PART_NO >= @lcStartNo) THEN 1 ELSE 0 END ELSE 1 END -- * Only Beginning Number Entered with not Consigned
	AND 1 = CASE WHEN @lcStartNo <> '' AND @lcEndNo =  '' AND @lnInvtType =  2 THEN CASE WHEN (CUSTPARTNO >= @lcStartNo) THEN 1 ELSE 0 END ELSE 1 END -- * Only Beginning Number Entered with Consigned
	AND 1 = CASE WHEN @lcStartNo =  '' AND @lcEndNo <> '' AND @lnInvtType <> 2 THEN CASE WHEN (PART_NO <= @lcEndNo) THEN 1 ELSE 0 END ELSE 1 END -- * Only Ending Number Entered with not Consigned
	AND 1 = CASE WHEN @lcStartNo =  '' AND @lcEndNo <> '' AND @lnInvtType =  2 THEN CASE WHEN (CUSTPARTNO <= @lcEndNo) THEN 1 ELSE 0 END ELSE 1 END -- * Only Ending Number Entered with Consigned

END TRY

BEGIN CATCH
	RAISERROR('Error occurred in creating new physical inventory records. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END	