-- =============================================
-- Author:		???
-- Create date: ???
-- Description:	
--- Modified: 10/08/14 YS replace invtmfhd table with 2 new tables
-- =============================================

CREATE PROCEDURE [dbo].[ContractAddMfgrView] @lcUniq_key char(10) = ' ', @gUniqSupno as Char(10)=' '
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
-- 10/08/14 YS replace invtmfhd table with 2 new tables
--SELECT DISTINCT Partmfgr, Mfgr_pt_no
--	FROM Invtmfgr, Invtmfhd 
--	WHERE Invtmfgr.Uniq_key = @lcUniq_key
--	AND 1 = CASE Invtmfgr.INSTORE 
--				WHEN 0 THEN 1
--				ELSE CASE WHEN (UniqSupno = @gUniqSupno) THEN 1 ELSE 0 END
--			END
--	AND Invtmfhd.UniqMfgrHd = Invtmfgr.UniqMfgrHd
--	AND Invtmfgr.Is_Deleted = 0
--	AND Invtmfhd.Is_deleted = 0
--	ORDER BY 1,2

	SELECT DISTINCT M.Partmfgr, M.Mfgr_pt_no
	FROM Invtmfgr INNER JOIN InvtMPNLink L on  Invtmfgr.UniqMfgrHd = L.UniqMfgrHd
	INNER JOIN MfgrMaster M ON l.mfgrMasterId=M.MfgrMasterId
	WHERE Invtmfgr.Uniq_key = @lcUniq_key
	AND 1 = CASE Invtmfgr.INSTORE 
				WHEN 0 THEN 1
				ELSE CASE WHEN (UniqSupno = @gUniqSupno) THEN 1 ELSE 0 END
			END
	AND Invtmfgr.Is_Deleted = 0
	AND L.Is_deleted = 0 AND M.IS_DELETED=0
	ORDER BY M.Partmfgr, M.Mfgr_pt_no

END