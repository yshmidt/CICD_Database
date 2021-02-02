-- =============================================
-- Author: Nitesh B
-- Create date: <09/24/2018>
-- Description:	Get Bank Exchange Rate
-- =============================================
CREATE PROCEDURE GetBankExchangeRate
(
@bankUniq CHAR(10)
)
AS
BEGIN
SET NOCOUNT ON
DECLARE @fcUniq CHAR(10)
SET @fcUniq = (SELECT CASE WHEN B.Fcused_Uniq IS NULL OR B.Fcused_Uniq = '' 
			  THEN F.FcUsed_Uniq ELSE B.Fcused_Uniq END FROM FcUsed F INNER JOIN BANKS B ON F.Symbol = B.Currency WHERE BK_UNIQ = @bankUniq)

SELECT TOP 1 Askprice FROM FcHistory WHERE FcUsed_Uniq =  @fcUniq ORDER BY FcDateTime DESC

END