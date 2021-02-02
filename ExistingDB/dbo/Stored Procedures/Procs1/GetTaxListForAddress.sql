
-- =============================================  
-- Author:  <Shripati>  
-- Create date: <09/19/2018>  
-- Description: Get tax list for billing and shipping  
-- exec [dbo].[GetTaxForShipBill] ''  
-- GetTaxListForAddress '_3TT0T5X0A'  
-- select * from TAXTABL
-- =============================================  
CREATE PROCEDURE [dbo].[GetTaxListForAddress]  
  @taxUnique char(10) = ''  
AS  
BEGIN  

SET NOCOUNT ON;  

WITH cte 
 AS  
(  
	SELECT null TAX_ID, @taxUnique TaxApplicableTo, 0 as level, null TAXUNIQUE
  UNION  
	SELECT  a.TAX_ID, a.TaxApplicableTo , 1 as level, a.TAXUNIQUE  FROM TAXTABL a  WHERE a.TAXUNIQUE = @taxUnique
  UNION ALL  
	SELECT a.TAX_ID, a.TaxApplicableTo , c.level +1, a.TAXUNIQUE 
    FROM TAXTABL a JOIN cte c ON a.TAXUNIQUE = c.TaxApplicableTo  
)  
SELECT DISTINCT TAX_ID, TaxApplicableTo, TAXUNIQUE,level  FROM cte WHERE TAX_ID IS NOT NULL AND TaxApplicableTo<>''
ORDER BY TAX_ID; 
 
END  
  