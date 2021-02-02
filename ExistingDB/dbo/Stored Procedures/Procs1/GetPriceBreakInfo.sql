-- ================================================================      
-- Author:  Kalpesh M         
-- Create date: 05/31/2019           
-- Description: Get the price break grid data  
-- Modify : Nitesh B : 11/1/2019 Added new REPLACE for PriceItemDescription column  
--			Nitesh B : 11/2/2019 Change the Join to left join to get empty Price Break
--          Nitesh B : 11/5/2019 Added RemoveSpecialChars to remove special characters from PriceItemDescription
-- ================================================================      
-- EXEC GetPriceBreakInfo '_1LR0NALBN','0000000001'      
CREATE PROC GetPriceBreakInfo      
 @uniq_key VARCHAR(10) = null,      
 @custNo VARCHAR(10) = null     
AS      
BEGIN      
 SET NOCOUNT ON;      
 DECLARE @PrItemizationSetup nvarchar(MAX)=''      
     ,@SQL nvarchar(MAX)='' 
  
 SELECT @PrItemizationSetup =        
   STUFF(        
  (																			-- Nitesh B : 11/5/2019 Added RemoveSpecialChars to remove special characters from PriceItemDescription
  SELECT  ',' + '['+REPLACE(dbo.RemoveSpecialChars(TRIM(PriceItemDescription)),' ','_')+']'    --Nitesh B : 11/1/2019 Added new REPLACE for PriceItemDescription column    
   FROM PriceItemizationSetup F														
  WHERE is_Deleted = 0      
  ORDER BY DisplaySeq asc          
   for xml path('')        
  ),        
  1,1,'')         
  print @PrItemizationSetup 
   
            
  SET @SQL =       
    'SELECT LTRIM(CONCAT(STR(Tab2.FromQty) + '' - '',Tab2.ToQty)) QtyBreak
	,'+@PrItemizationSetup+'
	,Tab2.Price
	,Tab2.QuoteNumber
	,Tab2.QuoteDate
	,Tab2.AmortAmount
	,Tab2.AmortQty
	,Tab2.uniqprhead
	,Tab2.custno 
	,tab2.UniqPrCustBrkId   
     FROM         
   (      
    SELECT       
    REPLACE(dbo.RemoveSpecialChars(TRIM(pis.PriceItemDescription)), '' '',  ''_'' ) AS PriceItemDescription,       
    CAST(pic.Amount as DECIMAL(9,2)) Amount,       
    CAST(pcb.FromQty as DECIMAL(9,0)) FromQty,      
    CAST(pcb.ToQty as DECIMAL(9,0)) ToQty,      
    CAST(pcb.Amount as DECIMAL(9,2)) Price ,      
    pc.quotenumber QuoteNumber, CAST(pc.quoteDate as date) QuoteDate,pc.AmortAmount,pc.AmortQty, pc.custno,      
    ph.uniqprhead,    
    pcb.uniqprcustbrkid  
    FROM priceheader ph       
    Join priceCustomer pc ON pc.uniqprhead = ph.uniqprhead      
    join priceCustbreak pcb ON pcb.uniqprhead = ph.uniqprhead AND pc.uniqprcustid = pcb.uniqprcustid      
    left join priceItemCust pic ON pic.uniqprcustbrkid = pcb.uniqprcustbrkid      
    left join PriceItemizationSetup pis on pis.PriceItemUK = pic.priceitemuk      
   WHERE pc.custno = '''+ @custNo +''' and uniq_key = '''+ @uniq_key +''') Tab1        
   PIVOT (SUM(Tab1.Amount) FOR Tab1.PriceItemDescription IN ('+@PrItemizationSetup+')) AS Tab2'        
      --Nitesh B : 11/2/2019 Change the Join to left join to get empty Price Break
        --Nitesh B : 11/5/2019 Added RemoveSpecialChars to remove special characters from PriceItemDescription  
  EXEC sp_executesql @SQL            
END