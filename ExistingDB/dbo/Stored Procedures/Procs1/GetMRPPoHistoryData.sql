  
-- =============================================  
-- Author: Shivshankar P  
-- Create date: 08/17/2018  
-- Description: Get MRP History   
-- exec GetMRPPoHistoryData 'X3G6ZRKMFM',0,1,10,4000 
-- Shivshankar P 01/11/18: Filtered data based upon the quantity  
-- Shivshankar P 05/08/20: Get UniqSupNo from Supinfo table  
-- Shivshnakar P 06/02/20: Apply ORDER BY t.podate DESC to get MRP History records 
-- Shivshankar P 06/16/20: Remove where condition to show all PO history without @quantity filter
-- =============================================  
CREATE PROC [dbo].[GetMRPPoHistoryData]   
 @uniq_key char(10) = null,  
 --@lcDateOrder char(10)='PODATE',  
 @lnNumberOfPOsIncluded int=10,   
 @startRecord INT=1,  
 @endRecord INT=10,  
 @quantity INT = 0  
AS  
BEGIN  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
     
   SELECT * FROM (  
   SELECT  Pomain.PoDate, PoMain.PoStatus,Supinfo.SupName, Supinfo.UniqSupNo, -- Shivshankar P 05/08/20: Get UniqSupNo from Supinfo table
    Pomain.PoNum,Poitems.Itemno,Poitems.partmfgr +' / ' + Poitems.mfgr_pt_no AS PartMfg,  
    ISNULL(LAG(Poitems.Ord_Qty) OVER (ORDER BY Poitems.Ord_Qty),0) AS  StartQty,  
          Poitems.Ord_Qty,  
    ISNULL(LEAD(Poitems.Ord_Qty) OVER (ORDER BY Poitems.Ord_Qty),0) AS EndQty,  
    Poitems.CostEach  
     FROM pomain, supinfo,poitems   
     WHERE Pomain.ponum = Poitems.ponum   
       AND Supinfo.uniqsupno = Pomain.uniqsupno   
       AND Poitems.uniq_key = @uniq_key   
       AND POSTATUS  <> 'CANCEL'  AND Poitems.lcancel=0   
    ) t
	-- Shivshankar P 06/16/20: Remove where condition to show all PO history without @quantity filter
    -- WHERE  StartQty <=  @quantity AND Ord_Qty >= @quantity   -- Shivshankar P 01/11/18: Filtered data based upon the quantity  
    ORDER BY t.podate DESC  -- Shivshnakar P 06/02/20: Apply ORDER BY t.podate DESC to get MRP History records
END  