    
-- =============================================    
-- Author:  <Yelena Shmidt>    
-- Create date: <03/22/2010>    
-- Description: <InvtLot4UniqKeyView>    
-- Modified: 10/09/14 YS replaced invtmfhd table with 2 new tables    
-- Modified: 21/09/18 SanjayB add three new columns to get data for lotted part  
-- =============================================    
CREATE PROCEDURE [dbo].[InvtLotMfgrView]     
 -- Add the parameters for the stored procedure here    
@lcUniq_key as char(10)=''     
AS    
BEGIN    
 -- SET NOCOUNT ON added to prevent extra result sets from    
 -- interfering with SELECT statements.    
 SET NOCOUNT ON;    
  -- 10/09/14 YS eplaced invtmfhd table with 2 new tables    
    -- Insert statements for procedure here    
 SELECT l.Uniq_key, Qty_oh, Reserved, Invtmfgr.W_key, m.Partmfgr, m.Mfgr_pt_no,    
  Warehouse, Location ,l.UniqMfgrHd ,    
 Invtlot.Lotcode, InvtLot.Expdate, InvtLot.LotQty, InvtLot.Reference AS Reference,    
  InvtLot.LotresQty, InvtLot.Ponum, InvtLot.Uniq_lot, CAST(1 as bit) AS LotStatus, InvtLot.LotQty AS NeedQty,InvtLot.LotQty AS QtyOh ,InvtLot.LotQty AS Balance ,INVTMFGR.W_key AS WKey -- Modified: 21/09/18 SanjayB add three new columns to get data for lotted part 
 FROM InvtmpnLink L,MfgrMaster M,Invtmfgr, Warehous,InvtLot     
  WHERE Invtmfgr.UniqWh = Warehous.Uniqwh     
  AND L.Uniq_key = @lcUniq_key    
  AND Invtmfgr.UniqMfgrHd=L.UniqMfgrhd     
  AND l.mfgrMasterid=M.MfgrMasterid    
  AND Qty_oh > 0.00     
  AND Invtmfgr.Is_deleted=0    
  AND l.Is_deleted=0 and m.is_deleted=0    
  AND InvtLot.W_key=Invtmfgr.W_key    
    
     
     
END