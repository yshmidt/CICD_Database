-- =============================================        
-- Author:  Vijay G    
-- Create date: 07/18/2018        
-- Description: GET ECO AVL Data with Anti AVL data    
-- Modified: 01/30/2020 Vijay G Added extra parameter to get avl data base uniqEcDet      
-- [EcAntiAvlView] 'VG9OLPZ1U1','_01F15SZ9D'    
-- =============================================     
CREATE PROC [dbo].[EcAntiAvlView] @gUniqEcNo AS char(10) = ' '  ,@uniqEcDet VARCHAR(10)=' '  
AS    
SELECT Uniqecanti, Uniqecno, Uniqecdet,Uniqbomno, Uniq_key, Partmfgr, Mfgr_pt_no    
 FROM Ecantiavl    
 WHERE Uniqecno = @gUniqEcNo  and UNIQECDET=@uniqEcDet  
  
   
    
    
    
    
    