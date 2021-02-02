-- =====================================================  
-- Author:  <Avinash>  
-- Create date: 06/24/2015  
-- Example : spMANUFACTURERPTNO  '_1EI0NK1ZM','In-Plant Supplier (IPS)'  
-- spMANUFACTURERPTNO  '_1LR0NALAS','Internal Inventory' ,'' 
-- Description: Created for the ICM for Manufacture   
-- 5/11/2016 Nitesh B: Modify the Supplier & customer invetory type  
-- 6/7/2016 Nitesh B: Added @uniqsupno parameter to check the supplier exists w r to mfgr  
-- 09/01/2016 Shivshankar P: Modify for merging 'Manufacturer Part No' and 'Internal Inventory' grid added three columns  
-- 027/04/2017 Shivshankar P: Row number generated for indentity and added column MfgrMasterId
-- 11/11/2017 Shivshankar P: Get records for 'CONSG Part No'
-- =====================================================  
CREATE PROCEDURE spMANUFACTURERPTNO    
(  
@UNIQKEY NVARCHAR(20),  
@InventorType CHAR(30) = null,  
@uniqsupno char(10) = null -- 6/7/2016 Added @uniqsupno parameter to check the supplier exists w r to mfgr  
)  
AS  
BEGIN  
IF(@InventorType = 'Internal Inventory' or @InventorType = 'In-Plant Customer (IPC)' or @InventorType= 'Manufacturer Part No' or @InventorType='Inactive' 
   OR @InventorType = 'CONSG Part No')    --  11/11/2017 Shivshankar P: Get records for 'CONSG Part No'
  BEGIN  
  SELECT  Number = ROW_NUMBER() OVER (ORDER BY M.MfgrMasterId) ,M.MfgrMasterId, L.ORDERPREF, M.MFGR_PT_NO, M.PARTMFGR, L.UNIQ_KEY, L.UNIQMFGRHD, M.MATLTYPE, M.LDISALLOWBUY, M.LDISALLOWKIT,M.AUTOLOCATION,  
    SUM(ISNULL(INM.QTY_OH,0.00)) AS TOTAL_QTY_OH,  
    -- 09/01/2016 Shivshankar P: Modify for merging 'Manufacturer Part No' and 'Internal Inventory' grid  
    W.WAREHOUSE +'/'+ INM.LOCATION as WarehouseLocation,ISNULL(P.NUMBEROFPKGS,0) AS NUMBEROFPKGS , INM.QTY_OH,INM.RESERVED,INM.QTY_OH-INM.RESERVED AS AVAILABLE,  
        INM.COUNT_DT AS LAST_COUNT,INM.NETABLE,INM.IS_VALIDATED,INM.W_KEY,INM.UNIQWH,W.WHNO ,  
   W.WAREHOUSE,INM.LOCATION,  --12/10/2016 Shivshankar P:  Added thise columns for displaying in grid and Binding corresponding Data  
    M.SFTYSTK
  FROM INVTMPNLINK L  
    INNER JOIN MFGRMASTER M ON L.MFGRMASTERID=M.MFGRMASTERID  
    LEFT OUTER JOIN INVTMFGR INM ON L.UNIQMFGRHD=INM.UNIQMFGRHD AND INM.IS_DELETED=0  
    INNER JOIN WAREHOUS W ON INM.UNIQWH=W.UNIQWH  
    OUTER APPLY (SELECT W_KEY,COUNT(*) AS NUMBEROFPKGS FROM IPKEY WHERE IPKEY.W_KEY=INM.W_KEY AND PKGBALANCE<>0.00 GROUP BY IPKEY.W_KEY) P  
  WHERE L.UNIQ_KEY = @UNIQKEY  
    AND L.IS_DELETED = 0  
    AND M.IS_DELETED = 0 AND  
    INM.IS_DELETED=0 AND INM.INSTORE=0   
  GROUP BY M.MfgrMasterId, L.ORDERPREF, M.MFGR_PT_NO, M.PARTMFGR, L.UNIQ_KEY, L.UNIQMFGRHD, M.MATLTYPE, M.LDISALLOWBUY, M.LDISALLOWKIT,M.AUTOLOCATION,  
           W.WAREHOUSE,INM.LOCATION,ISNULL(P.NUMBEROFPKGS,0) , INM.QTY_OH,INM.RESERVED,INM.QTY_OH-INM.RESERVED,  
         INM.COUNT_DT,INM.NETABLE,INM.IS_VALIDATED,INM.W_KEY,INM.UNIQMFGRHD,INM.UNIQWH,W.WHNO,M.SFTYSTK  --12/10/2016 Shivshankar P:  Added thise columns Binding corresponding Data  
  ORDER BY L.ORDERPREF, M.PARTMFGR, M.MFGR_PT_NO
  END  
-- 5/11/2016 Nitesh B: Modify the Supplier & customer inventory type  
ELSE IF(@InventorType = 'In-Plant Supplier (IPS)')  
  BEGIN   
  SELECT  Number = ROW_NUMBER() OVER (ORDER BY M.MfgrMasterId),M.MfgrMasterId, L.ORDERPREF, M.MFGR_PT_NO, M.PARTMFGR, L.UNIQ_KEY, L.UNIQMFGRHD, M.MATLTYPE, M.LDISALLOWBUY, M.LDISALLOWKIT,M.AUTOLOCATION,  
  SUM(ISNULL(INM.QTY_OH,0.00)) AS TOTAL_QTY_OH,INM.W_KEY, --12/10/2016 Shivshankar P:  Added thise columns Binding corresponding Data  
  M.SFTYSTK
  FROM INVTMPNLINK L  
  INNER JOIN MFGRMASTER M ON L.MFGRMASTERID=M.MFGRMASTERID  
  LEFT OUTER JOIN INVTMFGR INM ON L.UNIQMFGRHD=INM.UNIQMFGRHD AND INM.IS_DELETED=0  
  INNER JOIN SUPINFO S ON INM.UNIQSUPNO=S.UNIQSUPNO  
  WHERE L.UNIQ_KEY = @UNIQKEY   
  AND S.uniqsupno= @uniqsupno -- 6/7/2016 Nitesh B: Added @uniqsupno parameter to check the supplier exists w r to mfgr  
  AND L.IS_DELETED = 0  
  AND M.IS_DELETED = 0  
  GROUP BY M.MfgrMasterId,L.ORDERPREF, M.MFGR_PT_NO, M.PARTMFGR, L.UNIQ_KEY, L.UNIQMFGRHD, M.MATLTYPE, M.LDISALLOWBUY, M.LDISALLOWKIT,M.AUTOLOCATION,INM.W_KEY ,M.SFTYSTK
  ORDER BY L.ORDERPREF, M.PARTMFGR, M.MFGR_PT_NO  
  END  
-- 5/11/2016 Nitesh B: Modify the Supplier & customer inventory type 'Internal Inventory'  
-- 6/9/2016 Nitesh B : Duplicate Code Handle with 'or' with inventory type   
/*  
ELSE IF(@InventorType = 'In-Plant Customer (IPC)')  
  BEGIN   
  SELECT L.ORDERPREF, M.MFGR_PT_NO, M.PARTMFGR, L.UNIQ_KEY,L.UNIQMFGRHD, M.MATLTYPE, M.LDISALLOWBUY, M.LDISALLOWKIT,M.AUTOLOCATION,  
  SUM(ISNULL(W.QTY_OH,0.00)) AS TOTAL_QTY_OH  
  FROM INVTMPNLINK L  
  INNER JOIN MFGRMASTER M ON L.MFGRMASTERID=M.MFGRMASTERID  
  LEFT OUTER JOIN INVTMFGR W ON L.UNIQMFGRHD=W.UNIQMFGRHD AND W.IS_DELETED=0  
  WHERE L.UNIQ_KEY = @UNIQKEY  
  AND L.IS_DELETED = 0  
  AND M.IS_DELETED = 0  
  GROUP BY L.ORDERPREF, M.MFGR_PT_NO, M.PARTMFGR, L.UNIQ_KEY, L.UNIQMFGRHD, M.MATLTYPE, M.LDISALLOWBUY, M.LDISALLOWKIT,M.AUTOLOCATION--,I.INT_UNIQ  
  ORDER BY L.ORDERPREF, M.PARTMFGR, M.MFGR_PT_NO  
  END  
*/  
END  
  

  