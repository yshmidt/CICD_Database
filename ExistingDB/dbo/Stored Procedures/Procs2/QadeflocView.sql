-- =============================================
-- Author:		Vicky Lu
-- Create date: 
-- Description:	Defect entry
-- 02/08/16 YS removed invtmfhd table and replaced with invtmplink and mfgrmaster
-- =============================================
CREATE PROC [dbo].[QadeflocView] @lcQaseqmain AS char(10) = ''
AS
-- 09/04/15 VL added Mfgr_pt_no, Uniqmfgrhd, and get partmfgr and Mfgr_pt_no from invtmfhd
-- 02/08/16 YS removed invtmfhd table and replaced with invtmplink and mfgrmaster
SELECT Qadefloc.Location, ISNULL(m.Partmfgr,SPACE(8)) AS Partmfgr, Qadefloc.Locqty, Qadefloc.Def_code, Qadefloc.Uniq_key, Needreplac,
	Fixstatus, Chgdept_id, Uniq_loc, Qadefloc.Locseqno, [Check], Chk_note, Chk_date, Chk_time, Chk_id, Part_no, Revision,
	Reworkinit, Qadef.Qaseqmain, Qadefloc.Req_qty, LEFT(Support.text3,20) AS Def_name, Qadefloc.Userid,
	ISNULL(LTRIM(RTRIM(Users.firstname))+' '+LTRIM(RTRIM(Users.name)),SPACE(31)) AS Name, ISNULL(Users.Initials,SPACE(3)) AS Initials, 
	ISNULL(m.Mfgr_pt_no, SPACE(30)) AS Mfgr_pt_no, Qadefloc.Uniqmfgrhd
FROM Qadef, Support, Qadefloc 
LEFT OUTER JOIN Inventor ON Qadefloc.Uniq_key = Inventor.Uniq_key
LEFT OUTER JOIN Users ON Qadefloc.Userid = Users.userid
--LEFT OUTER JOIN Invtmfhd ON Qadefloc.Uniqmfgrhd = Invtmfhd.Uniqmfgrhd 
left outer JOIn Invtmpnlink L ON Qadefloc.Uniqmfgrhd = L.Uniqmfgrhd 
left outer join MfgrMaster M ON l.mfgrmasterid=m.mfgrmasterid
WHERE Qadefloc.Locseqno = Qadef.Locseqno
AND Qadefloc.Def_code = LEFT(Support.Text2,10)
AND Support.Fieldname = 'DEF_CODE'
AND Qadef.Qaseqmain = @lcQaseqmain






