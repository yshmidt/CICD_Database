-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 06/10/10
-- Description:	Invtmfgr view for selected uniqmfgrhd
-- 07/12/2018 YS supname column increased from 30 to 50
-- =============================================
CREATE PROCEDURE [dbo].[InvtMfgr4UniqMfgrhdView] 
	@lcUniqMfgrHD char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT DISTINCT Warehous.whno,Invtmfgr.UniqWH,Warehous.Warehouse,InvtMfgr.Qty_oh,InvtMfgr.Reserved,
		INVTMFGR.LOCATION,INVTMFGR.W_key,WAREHOUS.wh_gl_nbr, Invtmfgr.inStore,INVTMFGR.uniqsupno,INVTMFGR.COUNTFLAG,
		-- 07/12/2018 YS supname column increased from 30 to 50
		 ISNULL(SUPINFO.SUPID,SPACE(10)) as Supid,ISNULL(SUPINFO.Supname,SPACE(50)) as Supname 
		 FROM Invtmfgr INNER JOIN Warehous 
			ON  Warehous.Uniqwh=Invtmfgr.Uniqwh
			LEFT OUTER JOIN SUPINFO 
			ON INVTMFGR.uniqsupno=SUPINFO.UNIQSUPNO   
		WHERE Uniqmfgrhd = @lcUniqMfgrHD
		AND Invtmfgr.IS_Deleted =0
END