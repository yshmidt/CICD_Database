create procedure [dbo].[InvtTopBom4CustomerView] @lcCustNo as CHAR(10) ='' 
AS
SELECT Inventor.uniq_key, Inventor.BomCustNo,Bom_status
 FROM 
     inventor
 WHERE  Inventor.BomCustNo = @lcCustNo