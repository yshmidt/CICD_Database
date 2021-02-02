-----------------------------------
-- Shivshankar P 04/08/2020 : Change the columns name UniqKey to Uniq_Key and ProdnDays to ProdDays
-----------------------------------
CREATE VIEW [dbo].[View_MrpLeadDetail]    
AS    
SELECT        MrpUniqKey, Uniq_Key, QtyFrom, QtyTo, KitDays, ProdDays, CAST(row_number() OVER (partition BY uniq_key    
ORDER BY qtyfrom, qtyto)  as integer) AS seqn    
FROM            dbo.MRPLeadDetail 