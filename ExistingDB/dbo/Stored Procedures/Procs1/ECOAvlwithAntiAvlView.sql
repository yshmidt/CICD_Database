-- =============================================      
-- Author:  Sachin B    
-- Create date: 07/18/2018      
-- Description: GET ECO AVL Data with Anti AVL data  
-- Modified: 01/30/2020 Vijay G Added extra parameter to get avl data base uniqEcDet    
-- [ECOAvlwithAntiAvlView] 'VG9OLPZ1U1','_01F15SZ9D'  
-- =============================================      
    
CREATE PROCEDURE [dbo].[ECOAvlwithAntiAvlView]    
     
@UniqEcNo CHAR(10)=' '  , @Uniqkey CHAR(10)=' '   ,@uniqEcDet VARCHAR(10)=' '    
      
AS      
BEGIN      
    
-- SET NOCOUNT ON added to prevent extra result sets from      
-- interfering with SELECT statements.      
SET NOCOUNT ON;      
      
DECLARE @Avl_View TABLE (    
Orderpref NUMERIC(2,0), Mfgr_pt_no CHAR(30), Partmfgr CHAR(8), Uniq_key CHAR(10),      
Uniqmfgrhd CHAR(10), Matltype CHAR(10), lDisallowbuy BIT, lDisallowkit BIT);      
      
DECLARE @EcAntiAvlView TABLE (Uniqecanti CHAR(10), Uniqecno CHAR(10), Uniqecdet CHAR(10), Uniqbomno CHAR(10), Uniq_key CHAR(10), Partmfgr CHAR(8), Mfgr_pt_no CHAR(30));      
      
INSERT INTO @Avl_View EXEC [Avl_View] @Uniqkey;      
      
INSERT INTO @EcAntiAvlView EXEC [EcAntiAvlView] @UniqEcNo,@uniqEcDet;      
      
SELECT Avl.Partmfgr, Avl.Mfgr_pt_no, Avl.Orderpref, Avl.Uniq_key,       
AntiAvl.Uniqecanti, CheckUse = CAST(CASE WHEN AntiAvl.Uniqecanti IS NULL THEN 1 ELSE 0 END AS bit), Avl.Matltype,Avl.lDisallowbuy, Avl.lDisallowkit  
FROM @Avl_View Avl     
LEFT OUTER JOIN @EcAntiAvlView AntiAvl   
ON Avl.Uniq_key=AntiAvl.Uniq_key AND LTRIM(RTRIM( Avl.Partmfgr)) =LTRIM(RTRIM(AntiAvl.Partmfgr))   
AND LTRIM(RTRIM(Avl.Mfgr_pt_no)) = LTRIM(RTRIM(AntiAvl.Mfgr_pt_no))  
ORDER BY Avl.Orderpref, Avl.Partmfgr, Avl.Mfgr_pt_no      
END 