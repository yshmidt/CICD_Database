CREATE PROC [dbo].[TestRepairPartRequestView] @lcQaseqmain AS char(10) = ' ' 
AS
SELECT Qainsp.Wono, Dept_name, Part_no, Revision, Partmfgr, Part_class, Part_type, Descript, Part_sourc, Req_qty, Serialno, Location
	FROM Qadef, Qadefloc, Qainsp, Depts, Inventor
	WHERE Qainsp.Qaseqmain = Qadef.Qaseqmain
	AND Qadef.Locseqno = Qadefloc.Locseqno
	AND Qadefloc.Uniq_key = Inventor.Uniq_key
	AND QAINSP.DEPT_ID = Depts.DEPT_ID 
	AND Qadefloc.NeedReplac = 1
	AND Qadef.Qaseqmain = @lcQaseqmain
	ORDER BY PART_NO, Revision
	






