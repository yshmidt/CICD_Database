-- =============================================
-- Author:		Vicky Lu
-- Create date: ???
-- Description:	Cycle Count
-- Modified	: 10/08/14 YS replace invtmfhd with 2 new tables
-- Modified: 01/07/2015 DRP: the @userdid had a typo in it and would not work with Cloud. Change it to be @userId
-- =============================================
CREATE PROC [dbo].[CycleView]
@userid uniqueidentifier = null 
AS
BEGIN
SET NOCOUNT ON;
---10/08/14 YS replace invtmfhd with 2 new tables
SELECT Ccrecord.*, Part_no, Revision, Part_class, Part_type, Descript, U_of_meas, Part_sourc, Warehouse, Wh_gl_nbr,
	CAST(CASE WHEN 
		CASE WHEN Invtlot.LOTCODE IS NOT NULL THEN Invtlot.LOTRESQTY ELSE Invtmfgr.RESERVED END <> 0 
		THEN 1 ELSE 0 END AS bit) AS Is_Reserved, Inventor.Serialyes, Partmfgr, Mfgr_pt_no
 FROM Inventor INNER JOIN InvtMPNLink L ON Inventor.Uniq_key = L.UNIQ_KEY
 INNER JOIN Invtmfgr ON L.uniqmfgrhd=Invtmfgr.UNIQMFGRHD
 INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId 
 INNER JOIN CCRECORD ON Invtmfgr.W_key = Ccrecord.W_key
 INNER JOIN Warehous ON Ccrecord.UniqWh = Warehous.UniqWh
 LEFT OUTER JOIN INVTLOT
	ON Ccrecord.W_key = Invtlot.W_key
	AND Ccrecord.Lotcode = Invtlot.Lotcode 
	AND Ccrecord.Expdate = Invtlot.Expdate 
	AND Ccrecord.Reference = Invtlot.Reference 
	AND Ccrecord.Ponum = Invtlot.Ponum
WHERE Ccrecord.Is_Updated <> 1
ORDER BY Warehouse, Location, Reference, Part_no, Revision
END 