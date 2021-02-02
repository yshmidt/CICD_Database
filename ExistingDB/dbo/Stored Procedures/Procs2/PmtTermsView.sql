CREATE PROC [dbo].[PmtTermsView]
AS 
SELECT Descript, Pmt_Days, Disc_days, Disc_pct, Uniquenum FROM PmtTerms ORDER BY Number
