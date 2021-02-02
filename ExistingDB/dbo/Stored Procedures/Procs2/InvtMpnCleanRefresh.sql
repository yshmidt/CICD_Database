-- =============================================
-- Author:		David Sharp
-- Create date: 10/23/2013
-- Description:	Refresh the InvtMpnClean data
-- Modified 10/09/14 YS removed invtmfhd table and replaced with 2 new tables
-- =============================================
CREATE PROCEDURE [dbo].[InvtMpnCleanRefresh] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    TRUNCATE TABLE InvtMpnClean
    ---10/09/14 YS removed invtmfhd table and replaced with 2 new tables
	-- no need distinct the combination of partmfgr and mfgr_pt_nmo is already distinct
    --INSERT INTO InvtMpnClean (partMfgr,Mfgr_pt_no)
    --SELECT DISTINCT partMfgr,Mfgr_pt_no FROM INVTMFHD
	
	INSERT INTO InvtMpnClean (partMfgr,Mfgr_pt_no)
    SELECT partMfgr,Mfgr_pt_no FROM MfgrMaster

	UPDATE InvtMpnClean SET cleanMpn = UPPER(dbo.fnKeepAlphaNumeric(Mfgr_Pt_No))
END