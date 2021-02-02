-- =============================================
-- Author: Nitesh B
-- Create date: <09/24/2018>
-- Description:	Get Bank details
-- =============================================
CREATE PROCEDURE GetBankDetails
AS
BEGIN
SET NOCOUNT ON
SELECT B.*,fcHist.Askprice AS ExchangeRate,fcHist.Askprice * BANK_BAL AS FunctionalBalance
FROM FcUsed F INNER JOIN BANKS B ON F.Symbol = B.Currency 
			  OUTER APPLY( SELECT TOP 1 Askprice FROM FcHistory WHERE FcUsed_Uniq =  CASE WHEN B.Fcused_Uniq IS NULL OR B.Fcused_Uniq = '' 
			  THEN F.FcUsed_Uniq ELSE B.Fcused_Uniq END ORDER BY FcDateTime DESC) fcHist
END