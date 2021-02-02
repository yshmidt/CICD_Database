CREATE PROC [dbo].[InvtSerDefectHistView] @gWono AS char(10) = '', @lcSerialno AS char(30) = ''
AS
SELECT Date, SUBSTRING(Inspby,1,8) AS Inspby, ChgDept_id, Def_code, Location, Partmfgr, 
	ISNULL(Part_no,SPACE(25)) AS Part_no, LocQty
	FROM Qadef, Qainsp, Qadefloc LEFT OUTER JOIN Inventor
	ON Qadefloc.Uniq_key = Inventor.Uniq_key 
	WHERE Qadef.Locseqno = Qadefloc.Locseqno
	AND Qainsp.Qaseqmain = Qadef.Qaseqmain
	AND Qadef.Serialno = @lcSerialno
	AND Qadef.Wono = @gWono
	ORDER BY Date