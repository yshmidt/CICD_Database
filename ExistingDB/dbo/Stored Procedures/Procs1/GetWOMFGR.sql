-- =============================================
-- Author: Rajendra K
-- Create date: 02/04/2017
-- Description:	Get MFGR records by WONO
-- Modification
   -- 06/08/2017 Rajendra K : Replaced using PATINDEX(To remove leading zeros) by existing function 'fremoveLeadingZeros'
   -- 10/31/2017 Rajendra K : Removed use of function fremoveLeadingZeros
   -- 10/31/2017 Rajendra K : Parameter name renamed as per naming conventions
-- =============================================
CREATE PROCEDURE [dbo].[GetWOMFGR]
(
@woNumber CHAR(10)
)
AS
BEGIN
	SET NOCOUNT ON;
		SELECT DISTINCT M.Partmfgr
						,M.mfgr_pt_no AS MfgrPartNo
						,Invtmfgr.UniqMfgrHd
		FROM Inventor I,Invtmfgr, Warehous, InvtMpnLink L, MfgrMaster M
		WHERE L.Uniq_key IN (
					 SELECT DISTINCT I.Uniq_Key
					 FROM INVENTOR I
						  INNER JOIN KAMAIN K ON K.UNIQ_KEY=I.UNIQ_KEY 
						  INNER JOIN WOENTRY W ON W.WONO=K.WONO
						  WHERE K.WONO = @woNumber  -- 10/31/2017 Rajendra K : Removed use of function fremoveLeadingZeros
						  -- 06/08/2017 Rajendra K  : Replaced using PATINDEX(To remove leading zeros) by existing function 'fremoveLeadingZeros'
					)
		AND I.UNIQ_KEY =L.uniq_key
		AND Invtmfgr.UniqMfgrHd = L.UniqMfgrHd
		AND L.mfgrMasterid=m.MfgrMasterId
		AND Warehous.UniqWh = Invtmfgr.UniqWh
		AND Warehouse <> 'WIP'
		AND Warehouse <> 'WO-WIP'
		AND Warehouse <> 'MRB'
		AND Netable = 1
		AND Invtmfgr.Is_Deleted = 0
		AND L.Is_deleted = 0 and m.IS_DELETED=0
		AND Invtmfgr.Instore = 0
END