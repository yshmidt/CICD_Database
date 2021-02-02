-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <03/22/2010>
-- Description:	<Get information from Invtmfhd and Invtmfgr for a specific part and not is_deleted>
-- Modified:	10/09/14 YS removed invtmfhd table and replaced with 2 new
-- =============================================
CREATE PROCEDURE [dbo].[InvtMfhdDetView] 
	-- Add the parameters for the stored procedure here
	@lcUniq_key as char(10)=' ' 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--10/09/14 YS removed invtmfhd table and replaced with 2 new
	SELECT l.Uniq_key, Qty_oh, Reserved, W_key, M.Partmfgr, M.Mfgr_pt_no,
	 Warehouse, Location ,L.UniqMfgrHd 
	FROM Invtmpnlink L INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
	INNER JOIN Invtmfgr ON L.uniqmfgrhd=INVTMFGR.UNIQMFGRHD
	INNER JOIN Warehous ON Invtmfgr.Uniqwh= Warehous.UNIQWH
	WHERE L.Uniq_key = @lcUniq_key
	AND Qty_oh > 0.00 
	AND Invtmfgr.Is_deleted=0
	AND L.Is_deleted=0 and M.IS_DELETED=0
END