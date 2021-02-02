﻿-- =============================================
-- Author:		Mahesh B
-- Create date: 1/24/2019
-- Description:	Get Auto kit manufatures with constraints
-- 3/25/2019 Mahesh b: - If user set the default ware house aginest the Wororder then get only from the that warehouse only
-- 7/19/2019 Mahesh b: - Added condition to select ware house which has Default Ware house no is null or empty
-- Exec GetAutoKitManufacture  '0000000321','3NNC3KQV9N', 0 
-- =============================================
CREATE PROCEDURE GetAutoKitManufacture
	-- Add the parameters for the stored procedure here
	@woNumber AS CHAR(10),
    @uniqKey AS CHAR(10),
	@isDefaultWH AS BIT
AS
BEGIN
	 -- SET NOCOUNT ON added to prevent extra result sets from
	 -- interfering with SELECT statements.
	 SET NOCOUNT ON;

	 IF OBJECT_ID(N'tempdb..#tempKitDetails') IS NOT NULL
     DROP TABLE #tempKitDetails;

     IF OBJECT_ID(N'tempdb..#tempWOSettings') IS NOT NULL
     DROP TABLE #tempWOSettings;

     IF OBJECT_ID(N'tempdb..#tempBomParent') IS NOT NULL
     DROP TABLE #tempBomParent;

	 DECLARE @mfgrDefault NVARCHAR(MAX),@nonNettable BIT,@bomParent CHAR(10),@woDefaultWH CHAR(6),@woDefaultWHNo CHAR(10);

	 SELECT SettingName, LTRIM(ISNULL(WM.SettingValue,MS.settingValue)) SettingValue INTO  #tempWOSettings 
	                               FROM MnxSettingsManagement MS LEFT JOIN WmSettingsManagement WM ON MS.settingId = WM.settingId    
                                   WHERE SettingName IN('manufacturersDefault','allowUseOfNonNettableWarehouseLocation')  

     SET @mfgrDefault = ISNULL((SELECT SettingValue FROM #tempWOSettings WHERE SettingName = 'manufacturersDefault'),'All MFGRS')  

	 SET @nonNettable = ISNULL((SELECT CONVERT(BIT, SettingValue) FROM #tempWOSettings WHERE SettingName = 'allowUseOfNonNettableWarehouseLocation'),0)  
    
	 SELECT UNIQ_KEY INTO #tempBomParent FROM WOENTRY W where W.WONO = @woNumber
	 
	 SELECT @woDefaultWHNo = WO.KitUniqwh  FROM WOENTRY WO  LEFT JOIN  Warehous WH ON WO.KitUniqwh = WH.UNIQWH WHERE WO.WONO = @woNumber
	 SELECT  W_key AS WKey, 
             m.Partmfgr,
		     m.mfgr_pt_no AS MfgrPartNo,
		     Warehouse,
	         Location, 
			 Instore,
			 (ISNULL(QTY_OH, 0)-ISNULL(RESERVED, 0)) AS AvailableQty,
			 l.orderpref
      FROM Inventor i,Invtmfgr, Warehous, InvtMpnLink L, MfgrMaster M  
               WHERE Invtmfgr.UNIQWH =CASE WHEN  @isDefaultWH = 1 AND (@woDefaultWHNo <> null or @woDefaultWHNo <> '') THEN  @woDefaultWHNo  -- 7/19/2019 Mahesh b: - Added condition to select ware house which has Default Ware house no is null or empty
										   ELSE  Invtmfgr.UNIQWH -- 3/25/2019 Mahesh b: - If user set the default ware house aginest the Wororder then get only from the that warehouse only
									   END
									   AND L.Uniq_key = @uniqKey AND i.UNIQ_KEY =l.uniq_key  
                                       AND Invtmfgr.UniqMfgrHd = L.UniqMfgrHd 
									   AND (@nonNettable = 1 OR NETABLE = 1) 
							 	       AND COUNTFLAG = ''     
                                       AND L.mfgrMasterid = m.MfgrMasterId  
									   AND Warehous.UniqWh = Invtmfgr.UniqWh  
                                       AND Warehouse NOT IN('WO-WIP','MRB','WIP') 
                                       AND LNOTAUTOKIT = 0 AND Invtmfgr.Is_Deleted = 0  
                                       AND l.Is_deleted = 0 AND  m.lDisallowKit = 0 AND m.IS_DELETED=0
									   AND (ISNULL(QTY_OH, 0)-ISNULL(RESERVED, 0)) > 0 
                                       AND(@mfgrDefault = 'All MFGRS'   
									   OR (NOT EXISTS (SELECT bomParent FROM ANTIAVL A INNER JOIN #tempBomParent TBP ON A.BOMPARENT = TBP.UNIQ_KEY  
									   WHERE A.UNIQ_KEY = I.UNIQ_KEY AND A.PARTMFGR = m.PARTMFGR AND A.MFGR_PT_NO = m.MFGR_PT_NO)))   
									   ORDER BY Instore,orderpref
END
