-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/02/11
-- Description:	This view gets all the overissue records and available invtmfgr location for gWono, used in Kit form
-- Modified: 10/09/14 YS removed invtmfhd table and replaced with 2 new tables
--- 04/14/15 YS change "location" column length to 256
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- =============================================
CREATE PROCEDURE [dbo].[KitOverIssue_Location4WonoView] @gWono char(10) = ' '
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @ZOverIss TABLE (Kaseqnum char(10), Overw_key char(10), OverIssQty numeric(12,2), Lotcode char(15), 
		Expdate smalldatetime, Reference char(12), Ponum char(15), Uniq_key char(10), Partmfgr char(8), 
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
		Mfgr_pt_no char(30), Part_no char(35), Revision char(8), Descript char(45), U_of_meas char(8), 
		QtyStock numeric(12,2), CountFlag char(1), UniqKalocate char(10), SerialYes bit, UniqSupno char(10), 
		Instore bit, W_key char(10), UniqMfgrHD char(10))
--- 04/14/15 YS change "location" column length to 256
--- 03/28/17 YS changed length of the part_no column from 25 to 35
DECLARE @ZAllLoc TABLE (Kaseqnum char(10), Uniq_key char(10), W_key char(10), PartMfgr char(8), Part_no char(35),
		Revision char(8), Descript char(45), LotCode char(15), Expdate smalldatetime, Reference char(12), Ponum char(15),
		Warehouse char(6), LocW_key char(10), Location varchar(256), Mfgr_pt_no char(30), Instore bit, UniqSupno char(10),
		UniqMfgrHd char(10), UniqKalocate char(10), Is_Deleted bit) 
-- 10/09/14 YS removed invtmfhd table and replaced with 2 new tables		
INSERT @ZOverIss 
SELECT Kalocate.Kaseqnum, Kalocate.Overw_key, SUM(Kalocate.OverIssQty) AS OverIssQty,
	Kalocate.Lotcode, Kalocate.Expdate, Kalocate.Reference, Kalocate.Ponum,
	L.Uniq_key, M.Partmfgr, M.mfgr_pt_no,
	CASE WHEN Inventor.Part_Sourc = 'CONSG' THEN Inventor.CustPartNO ELSE Inventor.Part_no END AS Part_no,
	CASE WHEN Inventor.Part_Sourc = 'CONSG' THEN Inventor.CustRev ELSE Inventor.Revision END AS Revision,
	Inventor.Descript, Inventor.U_of_meas, SUM(Kalocate.OverIssQty) AS QtyStock, Invtmfgr.CountFlag, 
	UniqKalocate, SerialYes, Invtmfgr.UniqSupno, Invtmfgr.Instore, Kalocate.W_key, Kalocate.UniqMfgrHD
FROM Kalocate, Kamain, InvtMPNLink L,MfgrMaster M, Invtmfgr, Inventor
WHERE Kamain.Wono = @gWono
AND Kalocate.KaSeqNum = Kamain.KaSeqNum
AND Kalocate.UniqMfgrhd = L.UniqMfgrhd
AND L.mfgrMasterId=M.MfgrMasterId
AND Overw_key <> '' 
AND OverIssQty>0.00
AND Invtmfgr.W_key = Kalocate.Overw_key
AND Inventor.Uniq_key = L.Uniq_key
GROUP BY Kalocate.Overw_key,Lotcode,ExpDate,Reference,Ponum,Kalocate.Kaseqnum,
L.Uniq_key, M.Partmfgr,M.Mfgr_pt_no,
CASE WHEN Inventor.Part_Sourc = 'CONSG' THEN Inventor.CustPartNO ELSE Inventor.Part_no END,
CASE WHEN Inventor.Part_Sourc = 'CONSG' THEN Inventor.CustRev ELSE Inventor.Revision END,
Inventor.Descript,Inventor.U_of_meas,Invtmfgr.CountFlag,
Kalocate.UniqKalocate, Inventor.SerialYes, INVTMFGR.uniqsupno, Invtmfgr.Instore,
Kalocate.W_key, Kalocate.UniqMfgrhd 
ORDER BY 11,12,M.Partmfgr

-- SQL result 
SELECT * FROM @ZOverIss

-- Find location 
INSERT @ZAllLoc
SELECT DISTINCT ZOverIss.Kaseqnum, ZOverIss.Uniq_key, Invtmfgr.W_key, ZOverIss.PartMfgr,
	ZOverIss.Part_no, ZOverIss.Revision, ZOverIss.Descript, ZOverIss.Lotcode, ZOverIss.Expdate, 
	ZOverIss.Reference, ZOverIss.Ponum, Warehous.Warehouse, Invtmfgr.W_key AS LocW_key,
	Invtmfgr.Location, ZOverIss.Mfgr_pt_no, Invtmfgr.Instore, Invtmfgr.UniqSupno, ZOverIss.UniqMfgrHd, 
	ZOverIss.UniqKalocate, Invtmfgr.Is_Deleted
FROM @ZOverIss ZOverIss, Invtmfgr, Warehous
WHERE ZOverIss.UniqMfgrHd = Invtmfgr.UniqMfgrHd
AND Invtmfgr.UniqSupno = ZOverIss.UniqSupno
AND Invtmfgr.Instore = ZOverIss.Instore
AND Invtmfgr.CountFlag = SPACE(1)
AND Warehouse <> 'WIP   '
AND Warehouse <> 'WO-WIP'
AND Warehouse <> 'MRB   '
AND Warehous.UniqWh = Invtmfgr.UniqWh

DELETE FROM @ZAllLoc
	WHERE Kaseqnum IN 
		(SELECT Kaseqnum
			FROM @ZAllLoc
			WHERE Is_Deleted = 0
			GROUP BY Kaseqnum)
	AND Is_Deleted = 1

-- SQL result 1
SELECT * 
	FROM @ZAllLoc

END