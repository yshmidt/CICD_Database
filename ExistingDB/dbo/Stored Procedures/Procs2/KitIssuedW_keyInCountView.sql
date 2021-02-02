CREATE PROC [dbo].[KitIssuedW_keyInCountView] @gWono AS char(10) = ' '
AS
SELECT DISTINCT Kamain.Uniq_key,Inventor.Part_no,Inventor.Revision 
	FROM Kamain,Kalocate,Invtmfgr,Inventor
	WHERE Kamain.Wono = @gWono
	AND Kamain.Kaseqnum = Kalocate.Kaseqnum
	AND Kamain.Uniq_key = Inventor.Uniq_key
	AND Kalocate.W_key = Invtmfgr.W_key
	AND Invtmfgr.CountFlag <> SPACE(1)
