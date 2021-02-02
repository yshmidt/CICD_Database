-- =============================================
-- Author:		???
-- Create date: ???
-- Description:	Show all current records in the Invtmfhd Table for a given uniq_key
-- Modified: 10/08/14 YS use new tables in place of invtmfhd
-- 11/11/14 YS move orderpref to invtmpnlink
-- =============================================

CREATE PROCEDURE [dbo].[Avl_View]
	-- Add the parameters for the stored procedure here
	@cUniq_key char(10)=' ' 
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
--10/08/14 YS use new tables in place of invtmfhd
-- 11/11/14 YS move orderpref to invtmpnlink
SELECT L.Orderpref, M.Mfgr_pt_no, M.Partmfgr, L.Uniq_key, L.Uniqmfgrhd, M.Matltype, M.lDisallowbuy, M.lDisallowkit
	--FROM Invtmfhd
	FROM InvtMPNLink L
	INNER JOIN MfgrMaster M on L.mfgrMasterId=M.mfgrmasterid
	WHERE L.Uniq_key = @cUniq_key
	AND L.Is_deleted = 0
	AND M.IS_DELETED = 0
	ORDER BY L.Orderpref, M.Partmfgr, M.Mfgr_pt_no

END