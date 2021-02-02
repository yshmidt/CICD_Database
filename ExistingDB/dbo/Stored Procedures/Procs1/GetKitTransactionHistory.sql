-- =============================================      
-- Author:  Rajendra K       
-- Create date: <02/15/2016>      
-- Modification       
   -- 10/31/2017 Rajendra K : Removed Alias for table InvtLot      
   -- 10/31/2017 Rajendra K : Parameter name renamed as per naming conventions      
   -- 11/02/2017 Rajendra K : Replace Left join by Inner join for table InvtRes to get only if transactions exists      
   -- 11/08/2017 Rajendra K : Added join condition 'IR.W_KEY = INVTMF.W_KEY' to get current W_Key transactions       
   -- 11/09/2017 Rajendra K : ORDER BY IR.DATETIME -- 11/09/2017 Rajendra K : Added order by IR.DATETIME      
   -- 11/23/2017 Rajendra K : Added DATETIME,Initial,SID in select list      
   -- 11/23/2017 Rajendra K : Added iReserveIpKey in join condition      
   -- 11/30/2017 Rajendra K : Added conditions for Join with InvtLot table      
   -- 11/30/2017 Rajendra K : Added Alias for InvtLot      
   -- 12/07/2017 Rajendra K : Used Replace instead of STUFF for DateTimeStr      
   -- 02/02/2018 Rajendra K : Added condition IR.W_KEY = INVTMF.W_KEY       
   -- 11/02/2018 Rajendra K : Changed select condition for LotResQty & LOTRESQTY     
   -- 07/02/2019 Rajendra K : Removed Overage column from selection list due to duplication of record    
   -- 04/29/2020 Rajendra K : Added join with aspnet_Users to get the username instade of initails  
   -- 06/08/2020 Rajendra K : Added condition to getting MTC Qty 
-- Description: Get Kit Transaction History      
-- [dbo].[GetKitTransactionHistory] 'HDZGTQ1IAA','0000001324'    
-- =============================================      
CREATE PROCEDURE [dbo].[GetKitTransactionHistory]      
(      
@uniqKey AS CHAR(10),      
@woNumber AS CHAR(10)      
)      
AS      
BEGIN      
  SET NOCOUNT ON;      
  SELECT DISTINCT  IL.LOTRESQTY      
      ,ISNULL(IR.QTYALLOC,IL.LOTRESQTY) AS LOTRESQTY      
      ,IR.QTYALLOC      
      ,MFG.PARTMFGR AS PartMfgr      
      ,MFG.MFGR_PT_NO AS MfgrPtNo      
      ,IR.LotCode       
      ,IL.Reference      
      ,IL.ExpDate      
      ,IL.PONUM AS PONumber      
      --,ISNULL(IL.LOTRESQTY,IR.QTYALLOC) AS LOTRESQTY -- Reserved       
	  -- 06/08/2020 Rajendra K : Added condition to getting MTC Qty
      ,CASE WHEN IRP.ipkeyunique IS NULL THEN ISNULL(IR.QTYALLOC,IL.LOTRESQTY) ELSE IRP.qtyAllocated END AS LotResQty -- Reserved       
      --,(ISNULL(IL.LOTRESQTY,IR.QTYALLOC) + KM.ACT_QTY )       
      --,(ISNULL(IR.QTYALLOC,IL.LOTRESQTY) + KM.ACT_QTY )  -- 07/02/2019  : Removed Overage column from selection list due to duplication of record     
      --- (KM.SHORTQTY+(KM.ACT_QTY+KM.allocatedQty))  AS Overage -- Allocated + Used - Required       
      -- 11/23/2017 Rajendra K : Added DATETIME,Initial,SID      
      ,IR.DATETIME      
      --,IR.SAVEINIT AS Initial -- 04/29/2020 Rajendra K : Added join with aspnet_Users to get the username instade of initails  
   ,ISNULL( us.UserName,'')  AS Initial  
      ,IRP.ipkeyunique AS SID            
  FROM MfgrMaster MFG INNER JOIN InvtMpnLink INVT ON MFG.MfgrMasterId = INVT.MfgrMasterId      
      INNER JOIN KAMAIN KM ON INVT.uniq_key = KM.UNIQ_KEY      
      INNER JOIN Invtmfgr INVTMF ON INVT.uniqmfgrhd = INVTMF.Uniqmfgrhd      
      INNER JOIN INVT_RES IR ON IR.WONO = KM.WONO AND IR.UNIQ_KEY = KM.UNIQ_KEY -- 11/02/2017 Rajendra : Replace Left join by Inner join to get only if transactions exists      
      AND IR.W_KEY = INVTMF.W_KEY -- 02/02/2018 Rajendra K : Added condition       
      LEFT JOIN InvtLot IL ON INVTMF.W_Key = IL.W_KEY -- 10/31/2017 Rajendra K : Removed Alias  -- 11/30/2017 Rajendra K : Added Alias       
      AND IR.LOTCODE = IL.LOTCODE AND IR.EXPDATE = IL.EXPDATE AND IR.PONUM = IL.PONUM AND IR.REFERENCE = IL.REFERENCE -- 11/30/2017 Rajendra K : Added conditions for Join with InvtLot table            
      LEFT JOIN iReserveIpKey IRP ON IR.INVTRES_NO = IRP.invtres_no -- 11/23/2017 Rajendra K : Added iReserveIpKey in join condition    
     LEFT JOIN aspnet_Users us ON IR.fk_userid = us.UserId-- 04/29/2020 Rajendra K : Added join with aspnet_Users to get the username instade of initails  
     WHERE invt.uniq_key = @uniqKey AND KM.WONO = @woNumber      
  ORDER BY IR.DATETIME -- 11/09/2017 Rajendra K : Added order by IR.DATETIME      
END 