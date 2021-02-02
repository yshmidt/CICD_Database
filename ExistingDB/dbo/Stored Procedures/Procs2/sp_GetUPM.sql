-- =============================================
-- Author:		Vicky Lu
-- Create date: 03/15/13
-- Description:	This procedure will get all Invtmfhd records for passed in Uniq_key, Mfgr_pt_no, Partmfgr
-- Modified: 10/10/14 YS replaced invtmfhd table with 2 new tables
-- =============================================
CREATE PROCEDURE [dbo].[sp_GetUPM] 
	@ltUPM AS tUPM READONLY
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

-- 05/02/13 VL added one more field: lDisallowbuy
SET NOCOUNT ON;
-- 10/10/14 YS replaced invtmfhd table with 2 new tables
	--SELECT UniqMfgrhd, UNIQ_KEY, MFGR_PT_NO, Partmfgr, lDisallowbuy
	--	FROM INVTMFHD
	--	WHERE UNIQ_KEY+MFGR_PT_NO+PARTMFGR IN 
	--		(SELECT UNIQ_KEY+MFGR_PT_NO+PARTMFGR 
	--			FROM @ltUPM)
	--	AND IS_DELETED = 0

SELECT UniqMfgrhd, UNIQ_KEY, MFGR_PT_NO, Partmfgr, lDisallowbuy
		FROM InvtMPNLink L INNER JOIN MfgrMaster M ON l.mfgrMasterId=M.MfgrMasterId
		WHERE EXISTS (SELECT 1 FROM @ltUPM Z where l.Uniq_key=z.Uniq_key and M.mfgr_pt_no=Z.Mfgr_pt_no and M.PartMfgr=Z.Partmfgr)
		AND L.IS_DELETED = 0 and m.IS_DELETED=0

END