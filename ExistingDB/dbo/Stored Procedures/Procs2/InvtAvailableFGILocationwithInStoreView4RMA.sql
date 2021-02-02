-- =============================================
-- Author:		Vicky	
-- Create date: 08/06/2010
-- Description:	Available FGI with Instore locations
-- Modification:
-- 03/21/18 VL:	remove the Netable = 1 restriction.  We didn't have this restriction in VFP, so remove this restriction in SQL, so user can ship from this location.  In Kit, we have code in different place (sp_GetNotInstoreLocation4Mfgrhd) that will use Kitdef.lKitAllowNonNettable
-- 03/18/20 VL: the InvtAvailableFGILocationwithInStoreView had been changed in cube, so need to re-create the one for RMA purpose that can be used in RMA receiver (desktop)
-- =============================================
CREATE PROCEDURE [dbo].[InvtAvailableFGILocationwithInStoreView4RMA]
	-- Add the parameters for the stored procedure here
	@gUniq_key char(10)=' ' 
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
SELECT Partmfgr, Warehouse, Location, Warehous.Whno, W_key, Wh_gl_nbr, Mfgr_pt_no, Invtmfgr.UniqMfgrHd, 
	QTY_OH, Reserved, Instore, UniqSupno, INVTMFGR.UniqWh
	FROM Invtmfgr
	INNER JOIN  Warehous Warehous ON Warehous.UNIQWH=Invtmfgr.UNIQWH
	INNER JOIN invtMpnlink invtMpnlink ON Invtmfgr.UNIQMFGRHD =invtMpnlink.uniqmfgrhd
	INNER JOIN MfgrMaster mfgrMaster ON mfgrMaster.MfgrMasterId=invtMpnlink.MfgrMasterId
	WHERE Invtmfgr.Uniq_key = @gUniq_key
	AND Warehouse <> 'WIP'
	AND Warehouse <> 'WO-WIP'
	AND Warehouse <> 'MRB'
	-- 03/21/18 VL removed the restriction
	--AND Netable = 1
	AND Invtmfgr.Is_Deleted = 0
	AND invtMpnlink.Is_deleted = 0 
	and mfgrMaster.is_deleted=0
	AND CountFlag = ''
END

