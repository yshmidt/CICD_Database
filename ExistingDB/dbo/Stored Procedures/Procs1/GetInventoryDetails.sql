-- =============================================  
-- Author:Satish B  
-- Create date:02/13/2018  
-- Description:  Get warehouse details based on inventor   
-- Modified : Satish B :03/15/2018 : Check null for EXPDATE  
--   : Satish B :5/29/2018 : Removed the code of checking EXPDATE ISNULL  
-- 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials
-- exec GetInventoryDetails '_01F0NBI4H',1,500,0  
-- =============================================  
CREATE PROCEDURE GetInventoryDetails  
-- Add the parameters for the stored procedure here  
 @uniqKey char(10)='' ,  
 @startRecord int=0,  
 @endRecord int=50,  
 @outTotalNumberOfRecord int OUTPUT  
AS  
DECLARE @SQL nvarchar(max)  
BEGIN  
   SET NOCOUNT ON;  
       SELECT COUNT(i.uniq_key) AS RowCnt -- Get total counts   
    INTO #tempWhDetail  
    FROM Invtmfgr m     
   INNER JOIN  Warehous w ON w.UNIQWH=m.UNIQWH  
   INNER JOIN invtMpnlink mpnLink ON m.UNIQMFGRHD =mpnLink.uniqmfgrhd  
   INNER JOIN inventor i ON i.UNIQ_KEY=m.UNIQ_KEY  
   INNER JOIN MfgrMaster mfMaster ON mfMaster.MfgrMasterId=mpnLink.MfgrMasterId  
   LEFT OUTER JOIN invtlot lot ON lot.W_KEY =m.W_KEY   
			LEFT OUTER  JOIN parttype p ON p.PART_TYPE=i.PART_TYPE and p.PART_CLASS=i.PART_CLASS	  			
   WHERE (mpnLink.Uniq_key IS NULL OR mpnLink.Uniq_key =@uniqKey)    
   AND w.Warehouse <> 'WIP'  
   AND w.Warehouse <> 'WO-WIP'  
   AND w.Warehouse <> 'MRB'  
   AND m.Netable = 1  
   AND m.Is_Deleted = 0  
   --AND m.Instore=0   -- 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials
   AND mpnLink.Is_deleted = 0   
   AND mfMaster.is_deleted=0  
   AND w.Is_deleted = 0   
   AND m.COUNTFLAG = ''  
   AND (CASE WHEN p.LOTDETAIL = 1 THEN ISNULL ((lot.LOTQTY - lot.LOTRESQTY),0) ELSE ISNULL( (m.QTY_OH - m.RESERVED),0) END) > 0  
  
       SELECT DISTINCT   
   mfMaster.Partmfgr AS Mfgr  
  ,mfMaster.mfgr_pt_no AS MfgrPtNumber  
  ,RTRIM(w.Warehouse) + CASE WHEN m.Location IS NULL OR m.Location='' THEN '' ELSE '/' END + m.Location AS WHLoc  
  ,ISNULL(lot.lotcode, Space(10)) AS LotCode   
  --Satish B :03/15/2018 : Check null for EXPDATE  
  --Satish B :5/29/2018 : Removed the code of checking EXPDATE ISNULL  
  ,lot.EXPDATE AS ExpDate  
  --,ISNULL(lot.EXPDATE,Space(10)) AS ExpDate  
  ,ISNULL(lot.Reference, Space(10)) AS Reference  
  ,ISNULL(lot.PONUM, Space(10)) AS PONum  
  ,ISNULL(lot.LOTRESQTY, 0) AS LotResQty  
  ,p.LOTDETAIL AS LotDetail  
		,CASE WHEN isnull(p.LOTDETAIL,0) = 1 THEN ISNULL ((lot.LOTQTY - lot.LOTRESQTY),0) ELSE ISNULL( (m.QTY_OH - m.RESERVED),0) END AS  Available
  ,0 AS Issue  
  ,m.W_KEY As WKey  
  ,mpnLink.Uniq_key AS UniqKey  
  ,ISNULL(lot.UNIQ_LOT, SPACE(10)) AS UniqLot   
  ,m.UniqMfgrhd  
  ,i.SERIALYES AS SerialYes    
  ,i.UseIpKey  
   
 FROM Invtmfgr m     
  INNER JOIN  Warehous w ON w.UNIQWH=m.UNIQWH  
  INNER JOIN invtMpnlink mpnLink ON m.UNIQMFGRHD =mpnLink.uniqmfgrhd  
  INNER JOIN inventor i ON i.UNIQ_KEY=m.UNIQ_KEY  
  INNER JOIN MfgrMaster mfMaster ON mfMaster.MfgrMasterId=mpnLink.MfgrMasterId  
  LEFT OUTER JOIN invtlot lot ON lot.W_KEY =m.W_KEY   
		LEFT OUTER  JOIN parttype p ON p.PART_TYPE=i.PART_TYPE and p.PART_CLASS=i.PART_CLASS	  			
 WHERE (mpnLink.Uniq_key IS NULL OR mpnLink.Uniq_key =@uniqKey)    
  AND w.Warehouse <> 'WIP'  
  AND w.Warehouse <> 'WO-WIP'  
  AND w.Warehouse <> 'MRB'  
  AND m.Netable = 1  
  AND m.Is_Deleted = 0  
  --AND m.Instore=0   -- 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials
  AND mpnLink.Is_deleted = 0   
  AND mfMaster.is_deleted=0  
  AND w.Is_deleted = 0   
  AND m.COUNTFLAG = ''  
		AND (CASE WHEN isnull(p.LOTDETAIL,0) = 1 THEN ISNULL ((lot.LOTQTY - lot.LOTRESQTY),0) ELSE ISNULL( (m.QTY_OH - m.RESERVED),0) END) > 0
  ORDER BY mfMaster.Partmfgr DESC   
  OFFSET(@startRecord-1) ROWS  
  FETCH NEXT @EndRecord ROWS ONLY  
    
  SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempWhDetail) -- Set total count to Out parameter   
END  
  