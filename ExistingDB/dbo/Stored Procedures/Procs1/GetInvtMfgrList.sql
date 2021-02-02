

CREATE PROCEDURE [dbo].[GetInvtMfgrList]     
 @uniq_key AS CHAR (10)=' '     
AS    
BEGIN    
     
 SET NOCOUNT ON;    
        
 SELECT l.Uniq_key AS UniqKey, Qty_oh AS QtyOh, Qty_oh AS Balance, W_key AS WKey, M.Partmfgr AS PartMfgr, M.Mfgr_pt_no AS PartMfgrNumber,    
  Warehouse, Location ,L.UniqMfgrHd AS UniqMfgrHd
   ,CAST(ISNULL(M.qtyPerPkg,ISNULL(i.ORDMULT,0)) AS decimal(14,2)) AS QtyPerPackages      
 FROM Invtmpnlink L 
 INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId    
 INNER JOIN Invtmfgr ON L.uniqmfgrhd=INVTMFGR.UNIQMFGRHD    
 INNER JOIN INVENTOR i ON i.UNIQ_KEY = INVTMFGR.UNIQ_KEY
 INNER JOIN Warehous ON Invtmfgr.Uniqwh= Warehous.UNIQWH    
 WHERE     
 L.Uniq_key = @uniq_key    
 AND     
 Qty_oh > 0.00     
 AND Invtmfgr.Is_deleted=0    
 AND L.Is_deleted=0 and M.IS_DELETED=0    
END