

CREATE PROCEDURE [dbo].[InventorytLotMfgrView]     
	-- Add the parameters for the stored procedure here    
	@lcUniq_key as char(10)=''     
AS    
BEGIN    
 -- SET NOCOUNT ON added to prevent extra result sets from    
 -- interfering with SELECT statements.    
 SET NOCOUNT ON;    
    -- Insert statements for procedure here    
	 SELECT l.Uniq_key, Qty_oh, Reserved, Invtmfgr.W_key, m.Partmfgr, m.Mfgr_pt_no,    
	  Warehouse, Location ,l.UniqMfgrHd ,    
	 Invtlot.Lotcode, InvtLot.Expdate, InvtLot.LotQty, InvtLot.Reference AS Reference,    
	  InvtLot.LotresQty, InvtLot.Ponum, InvtLot.Uniq_lot,InvtLot.LotQty AS NeedQty
	  ,CAST(ISNULL(M.qtyPerPkg,ISNULL(i.ORDMULT,0)) AS decimal(14,2)) AS QtyPerPackages     
	  ,InvtLot.LotQty AS QtyOh   ,InvtLot.LotQty AS Balance ,INVTMFGR.W_key AS WKey 
	 FROM Invtmpnlink L 
	 INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId  
	 INNER JOIN Invtmfgr ON L.uniqmfgrhd=INVTMFGR.UNIQMFGRHD   
	 INNER JOIN INVENTOR i ON i.UNIQ_KEY = INVTMFGR.UNIQ_KEY
	 INNER JOIN Warehous ON Invtmfgr.Uniqwh= Warehous.UNIQWH  
	 LEFT JOIN INVTLot  ON InvtLot.W_key=Invtmfgr.W_key   
	  WHERE Invtmfgr.UniqWh = Warehous.Uniqwh     
	  AND L.Uniq_key = @lcUniq_key
	  AND Invtmfgr.Is_deleted=0  AND l.Is_deleted=0   AND  m.is_deleted=0  
	  AND Qty_oh > 0.00     
END