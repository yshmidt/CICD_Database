-- 12/05/19 VL changed to use new price tables for cube version
CREATE view [dbo].[rptPricListView] AS 
select distinct TOP 100 PERCENT Inventor.Uniq_key,Inventor.Part_no,Inventor.Revision FROM Inventor INNER JOIN priceheader on Inventor.uniq_key=priceheader.uniq_key order by Part_no,Revision