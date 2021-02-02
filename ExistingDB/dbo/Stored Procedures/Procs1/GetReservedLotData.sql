    
-- =============================================    
-- Author:  Rajendra K     
-- Create date: <03/23/2020>    
-- Description: Get lotted resered manufacturers data for over reserved grid    
-- Modification     
-- 06/15/2020 : Rajendra k : Added condition for antiavls    
-- 06/16/2020 : Rajendra k : Added join with WOENTRY table and added condition for OPENCLOS     
-- 06/18/2020 Rajendra K : Added SET statement for @CosignUniqKey if part is CONSG and @custNo parameter and join with ManufactList    
-- 06/23/2020 Rajendra K : Added DoNotKit field in selection list   
-- 12/17/2020 Rajendra K : Added condition to skip issued Qty 
-- EXEC GetReservedLotData '0000001025','GLWBO9KR4K','','','','WoNoDept desc',''    
-- =============================================    
CREATE PROCEDURE GetReservedLotData    
(    
@wono AS CHAR(10)='',    
@uniqKey AS CHAR(10)='',     
@uniqWHKey AS CHAR(10)='',    
@wKey AS CHAR(10)='',    
@location AS NVARCHAR(200)='',    
@sortExpression char(1000) = NULL,    
@filter NVARCHAR(MAX) = NULL,    
@custNo CHAR(10) = ''     
)    
AS      
BEGIN    
 SET NOCOUNT ON;    
    SET @location = LTRIM(RTRIM(@location))    
     
 DECLARE @nonNettable BIT,@CosignUniqKey CHAR(10);    
 DECLARE @sqlQuery NVARCHAR(MAX);     
    
 IF OBJECT_ID(N'tempdb..#TempData') IS NOT NULL    
     DROP TABLE #TempData ;    
    
     -- 06/18/2020 Rajendra K : Added SET statement for @CosignUniqKey if part is CONSG and @custNo parameter and join with ManufactList        
 SET @CosignUniqKey = ISNULL((SELECT UNIQ_KEY FROM INVENTOR WHERE INT_UNIQ = @uniqKey AND CUSTNO = @custNo),@uniqKey);    
     
 SELECT @nonNettable = ISNULL(CONVERT(Bit, WM.SettingValue),0)     
 FROM MnxSettingsManagement MS LEFT JOIN WmSettingsManagement WM ON MS.settingId = WM.settingId      
 WHERE SettingName = 'allowUseOfNonNettableWarehouseLocation'    
    
 SET @sortExpression = CASE WHEN @sortExpression IS NULL OR @sortExpression = '' THEN 'Reserved,WoNoDept' ELSE @sortExpression END     
    
  ;WITH ManufactList AS(     
       SELECT DISTINCT mf.MfgrMasterId    
    FROM INVTMFGR im     
       INNER JOIN InvtMPNLink m ON im.uniqmfgrhd = m.UNIQMFGRHD    
       INNER JOIN  MfgrMaster mf ON mf.MfgrMasterId = m.MfgrMasterId     
   WHERE im.UNIQ_KEY = @CosignUniqKey AND m.is_deleted = 0    
    )    
 ,  InvtResCte AS     
  (    
   SELECT SUM(QTYALLOC) AS Allocated    
     ,K.WONO    
     ,K.UNIQ_KEY     
     ,W_KEY    
     ,DEPT_ID    
     ,LOTCODE    
     ,Reference    
     ,ExpDate    
     ,PONUM    
     ,k.KASEQNUM    
   FROM INVT_RES IR     
   INNER JOIN KAMAIN k ON k.WONO = IR.WONO AND IR.KaSeqnum = k.KASEQNUM     
   INNER JOIN WOENTRY WO ON WO.WONO = K.WONO-- 06/16/2020 : Rajendra k : Added join with WOENTRY table and added condition for OPENCLOS     
   WHERE k.SHORTQTY < 0 AND allocatedQty > 0 AND K.UNIQ_KEY = @uniqKey AND k.WONO != @wono AND OPENCLOS NOT LIKE 'C%'     
   GROUP BY W_KEY    
     ,K.WONO    
     ,K.UNIQ_KEY    
     ,DEPT_ID    
     ,LOTCODE    
     ,Reference    
     ,ExpDate    
     ,PONUM    
     ,k.KASEQNUM    
  )     
 SELECT DISTINCT identity(int, 1, 1) as Number,INVT.uniqmfgrhd AS UniqMfgrHd    
    ,IL.UNIQ_LOT AS UniqLot             
          ,IL.LOTCODE AS LotCode     
       ,IL.REFERENCE AS Reference     
          ,IL.EXPDATE AS ExpDate    
          ,IL.PONUM AS PONumber     
    ,MFG.mfgr_pt_no AS MfgrPtNo    
    ,MFG.PartMfgr AS PartMfgr    
    ,IM.W_Key AS WKey    
    ,COALESCE(IR.Allocated,0) AS AllReserved    
    ,CAST(0 AS NUMERIC) AS Allocated    
    ,COALESCE(IL.LOTQTY,0)-COALESCE(IL.LOTRESQTY,0)  AS QtyOh    
    ,RTRIM(w.Warehouse)+ (CASE WHEN IM.Location IS NULL OR IM.Location =''  THEN RTRIM(IM.Location) ELSE ' / '+RTRIM(IM.Location) END) AS ToWarehouse    
    ,I.U_OF_MEAS AS Unit     
    ,I.UNIQ_KEY AS UniqKey    
    ,IR.WONO    
    ,IR.DEPT_ID    
    ,CAST(dbo.fremoveLeadingZeros(IR.WONO) AS VARCHAR(MAX))+' / '+IR.DEPT_ID AS WoNoDept    
    ,k.KASEQNUM    
	-- 12/17/2020 Rajendra K : Added condition to skip issued Qty
    ,CASE WHEN k.ACT_QTY > 0 AND -k.SHORTQTY > k.ACT_QTY THEN -k.SHORTQTY-k.ACT_QTY ELSE 0 END AS Reserved     
    ,CAST(0 AS NUMERIC) AS OriginalAllocated    
    ,W.UNIQWH AS UniqWH    
    ,IM.LOCATION AS Location    
    ,mfg.LDISALLOWKIT AS DoNotKit-- 06/23/2020 Rajendra K : Added DoNotKit field in selection list    
    INTO #TempData    
    FROM MfgrMaster mfg     
         INNER JOIN InvtMpnLink INVT  ON MFG.MfgrMasterId = INVT.MfgrMasterId    
         INNER JOIN Invtmfgr IM ON INVT.uniqmfgrhd = IM.Uniqmfgrhd     
    AND IM.Is_deleted = 0  AND INVT.Is_Deleted = 0     
    AND ((@nonNettable =1 AND IM.SFBL =0) OR Netable = 1)     
   INNER JOIN INVENTOR I ON IM.UNIQ_KEY = I.UNIQ_KEY    
   INNER JOIN KAMAIN K ON K.UNIQ_KEY = IM.UNIQ_KEY     
   INNER JOIN INVTLOT IL ON IM.W_Key = IL.W_KEY    
   INNER JOIN InvtResCte IR ON IL.W_KEY = IR.W_KEY AND IM.W_KEY= IR.W_KEY AND  K.KASEQNUM = IR.KASEQNUM    
       AND IL.LOTCODE = IR.LOTCODE    
       AND IL.REFERENCE = IR.REFERENCE    
       AND COALESCE(IL.EXPDATE,GETDATE()) = COALESCE(IR.EXPDATE,GETDATE())    
       AND IL.PONUM = IR.PONUM     
   INNER JOIN WAREHOUS W  ON IM.Uniqwh = W.UNIQWH    
   INNER JOIN ManufactList ML ON mfg.MfgrMasterId = ML.MfgrMasterId-- 06/18/2020 Rajendra K : Added SET statement for @CosignUniqKey if part is CONSG and @custNo parameter and join with ManufactList    
 WHERE (@uniqKey IS NULL OR @uniqKey = '' OR IM.UNIQ_KEY = @uniqKey)    
    AND (@wKey IS NULL OR @wKey = '' OR IM.W_KEY = @wKey) AND IR.Allocated > 0    
    AND (NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A     
     WHERE A.BOMPARENT = K.bomParent AND A.UNIQ_KEY = @CosignUniqKey AND A.PARTMFGR = mfg.PARTMFGR     
     AND A.MFGR_PT_NO = mfg.MFGR_PT_NO))-- 06/15/2020 : Rajendra k : Added condition for antiavls    
  AND -k.SHORTQTY > k.ACT_QTY   
   ORDER BY MfgrPtNo,PartMfgr     
       
   SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #TempData',@filter,@sortExpression,N'Reserved,WoNoDept','',1,3000))     
   EXEC sp_executesql @sqlQuery    
END