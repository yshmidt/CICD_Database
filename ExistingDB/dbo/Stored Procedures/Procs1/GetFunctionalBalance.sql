-- =============================================
-- Author: Nitesh B
-- Create date: <09/24/2018>
-- Description:	Ge tFunctional Balance
-- =============================================
-- =============================================
-- Author: Nitesh B
-- Create date: <09/24/2018>
-- Description:	Ge tFunctional Balance
-- =============================================
CREATE PROCEDURE GetFunctionalBalance
(
@bankUniq CHAR(10)
)
AS
BEGIN
SET NOCOUNT ON
	  DECLARE @funcitonalCur CHAR(100) = (SELECT dbo.fn_GetFunctionalCurrency());
      IF(@funcitonalCur IS NULL OR @funcitonalCur = '')
		SELECT 0.0
	  ELSE 
		SELECT Bank_Bal *((SELECT TOP 1 Askprice FROM FcHistory WHERE Fcused_Uniq = @funcitonalCur ORDER BY FcDateTime DESC)/fcHist.Askprice) AS FunctionalBalance
		FROM FcUsed F INNER JOIN BANKS B ON F.Symbol = B.Currency 
		  OUTER APPLY(SELECT TOP 1 Askprice FROM FcHistory WHERE FcUsed_Uniq =  CASE WHEN B.Fcused_Uniq IS NULL OR B.Fcused_Uniq = '' 
					  THEN F.FcUsed_Uniq ELSE B.Fcused_Uniq END ORDER BY FcDateTime DESC) fcHist
		WHERE B.BK_UNIQ = @bankUniq
END