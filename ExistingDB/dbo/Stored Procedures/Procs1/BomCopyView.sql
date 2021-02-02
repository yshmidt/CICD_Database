-- =============================================
-- Author : ??
-- Create date : ??
-- Description : Get BOM View Data
-- 12/21/2018 Shrikant change part_sourc to Part_Sourc
-- BomCopyView '_2AJ0JDG3I', 1
-- =============================================
CREATE PROCEDURE [dbo].[BomCopyView] 
@lcUniq_key AS char(10) = '',
@lIsSameCust AS bit = 1  

AS  

IF @lIsSameCust = 1  
	BEGIN
	  -- 12/21/2018 Shrikant change part_sourc to Part_Sourc
	 SELECT Bom_det.*,Inventor.Part_Sourc,Inventor.BomCustNo,SPACE(1) AS Extra  
	  FROM Bom_det, Inventor   
	  WHERE BomParent = @lcUniq_key  
	  AND Inventor.Uniq_key = Bom_Det.Uniq_key
	END   
ELSE 
	BEGIN 
		SELECT Bom_det.*,Inventor.Part_sourc,Inventor.BomCustNo,SPACE(1) AS Extra  
		FROM Bom_det, Inventor   
		WHERE BomParent = @lcUniq_key  
		AND Inventor.Uniq_key = Bom_Det.Uniq_key   
		AND Part_Sourc <> 'CONSG     '   
		AND 1 = CASE WHEN (Part_Sourc = 'MAKE      ' OR Part_Sourc = 'PHANTOM   ') AND (BOMCUSTNO = '' OR BOMCUSTNO = '000000000~')THEN 1  
				ELSE 
				  CASE WHEN (Part_Sourc <> 'MAKE      ' AND Part_Sourc <> 'PHANTOM   ') THEN 1  
				  ELSE 0  
				  END  
			  END  
	END
  
  
  
  