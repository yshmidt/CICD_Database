-- =============================================
-- Author:		???
-- Create date: ???
-- Description:	???
-- Modified: 10/09/14 YS removed invtmfhd table and replaced with 2 new tables
-- =============================================

CREATE PROCEDURE [dbo].[InvtMfhd4UPMView] 
	-- Add the parameters for the stored procedure here
	@lcUniq_key as char(10) = ' ', @lcMfgr_pt_no as char(30) = ' ', @lcPartmfgr as char(8) = ' '
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- Insert statements for procedure here
-- 10/09/14 YS removed invtmfhd table and replaced with 2 new tables
SELECT l.Uniq_key, m.Partmfgr, m.Mfgr_pt_no
	FROM Invtmpnlink L INNER JOIN MfgrMaster M on l.mfgrmasterid=m.mfgrmasterid
	WHERE UNIQ_KEY = @lcUniq_key
	AND MFGR_PT_NO = @lcMfgr_pt_no
	AND PARTMFGR = @lcPartmfgr
	AND l.Is_deleted = 0 and m.IS_DELETED=0
END




