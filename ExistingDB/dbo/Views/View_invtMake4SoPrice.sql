
  -- 12/14/2018 Shrikant added rtrim condition for Part Number
  -- 12/05/19 VL changed to use new price tables for cube version

CREATE VIEW [dbo].[View_invtMake4SoPrice]  
AS  
-- 12/14/2018 Shrikant added rtrim condition for Part Number
-- 12/05/19 VL changed to use new price tables for cube version
--SELECT DISTINCT I.UNIQ_KEY, rtrim(I.PART_NO) + ' ' + RTRIM(I.REVISION) AS [Part Number], I.PART_NO, I.REVISION, dbo.PRICHEAD.CATEGORY AS CustNo  
--FROM         dbo.PRICHEAD INNER JOIN  
--                      dbo.PRICDETL ON dbo.PRICHEAD.UNIQ_KEY + dbo.PRICHEAD.CATEGORY = dbo.PRICDETL.UNIQ_KEY + dbo.PRICDETL.CATEGORY INNER JOIN  
--                      dbo.INVENTOR AS I ON dbo.PRICHEAD.UNIQ_KEY = I.UNIQ_KEY  
SELECT DISTINCT I.UNIQ_KEY, rtrim(I.PART_NO) + ' ' + RTRIM(I.REVISION) AS [Part Number], I.PART_NO, I.REVISION, PC.CustNo  
FROM        Priceheader PH INNER JOIN Inventor I ON PH.Uniq_key = I.Uniq_key
			INNER JOIN PriceCustomer pc ON pc.UniqPrHead = ph.UniqPrHead 
					    