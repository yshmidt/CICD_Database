
-- =============================================  
-- Author:  <Shripati>  
-- Create date: <09/25/2018>  
-- Description: Get parent Exist for tax Id selected for billing and shipping  
-- FindParentExistforTaxId '_3TT0T5X0B'  
-- =============================================  
CREATE PROCEDURE [dbo].[FindParentExistforTaxId]  
  @taxUnique char(10) = ''  
AS  
BEGIN  

SET NOCOUNT ON;  
 ;WITH cte AS 
(
   SELECT TaxApplicableTo, TAX_ID,TAXUNIQUE,1 AS level
   FROM TAXTABL
   WHERE TaxApplicableTo =   @taxUnique 
   UNION ALL
   SELECT C.TaxApplicableTo, C.TAX_ID,c.TAXUNIQUE, level +1
   FROM TAXTABL c
   JOIN cte p ON C.TaxApplicableTo = P.TAXUNIQUE  
   AND C.TaxApplicableTo<>C.TAXUNIQUE 
) 

SELECT  TAX_ID, TaxApplicableTo, TAXUNIQUE,level  FROM cte WHERE TAX_ID IS NOT NULL 
ORDER BY TAX_ID; 

END  
  