-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- Modified: 10/09/14 YS removed invtmfhd table and replaced with 2 new tables
--- 10/09/14 YS combine 2 sql into 1
-- 10/29/14    move orderpref to invtmpnlink
-- =============================================
CREATE PROC [dbo].[Kalocate4KaseqnumView] @lcKaseqnum AS char(10) ='' 
AS
--10/09/14 YS removed invtmfhd table and replaced with 2 new tables
-- 10/09/14 YS per conversation with Vicky use inner join, see commented code, 
--- all outer join records will be removed in the second sql
-- 10/29/14    move orderpref to invtmpnlink
SELECT Kaseqnum, Kalocate.W_key, Pick_qty, Lotcode, Expdate, Reference, Ponum,
	L.Uniq_key, M.Partmfgr,	M.Mfgr_pt_no , OverIssQty, Overw_key, '1' AS UpdFlg,
	l.OrderPref, UniqKalocate, Kalocate.UniqMfgrhd,
	Invtmfgr.Instore, Invtmfgr.UniqSupno, Invtmfgr.CountFlag, Inventor.StdCost, Inventor.U_of_meas 
	FROM Kalocate INNER JOIN InvtMPNLink L ON Kalocate.UNIQMFGRHD=L.uniqmfgrhd 
	INNER JOIN MfgrMaster M ON l.mfgrMasterId=M.MfgrMasterId
	INNER JOIN InvtMfgr ON KALOCATE.w_key=Invtmfgr.W_key
	INNER JOIN Inventor ON Invtmfgr.uniq_key=Inventor.Uniq_key 
	WHERE Kalocate.KaseqNum = @lcKaseqnum

--WITH ZKalocate4KaseqnumView AS 
--(
--SELECT Kaseqnum, W_key, Pick_qty, Lotcode, Expdate, Reference, Ponum,
--	ISNULL(Invtmfhd.Uniq_key,SPACE(10)) AS Uniq_key, ISNULL(Partmfgr,'Deleted') AS Partmfgr,
--	ISNULL(Mfgr_pt_no,SPACE(30)) AS Mfgr_pt_no, OverIssQty, Overw_key, '1' AS UpdFlg,
--	ISNULL(OrderPref,00) AS OrderPref, UniqKalocate, Kalocate.UniqMfgrhd 
--	FROM Kalocate LEFT OUTER JOIN Invtmfhd 
--	ON Kalocate.Uniqmfgrhd = Invtmfhd.UniqMfgrhd
--	WHERE Kalocate.KaseqNum = @lcKaseqnum
--)

--SELECT ZKalocate4KaseqnumView.*, Instore, UniqSupno, CountFlag, StdCost, U_of_meas
--	FROM ZKalocate4KaseqnumView, INVTMFGR, Inventor
--	WHERE ZKalocate4KaseqnumView.W_KEY = INVTMFGR.W_key
--	AND INVTMFGR.UNIQ_KEY = INVENTOR.Uniq_key
--	ORDER BY KASEQNUM, W_KEY, LOTCODE, EXPDATE, Reference