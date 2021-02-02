-- =============================================
-- Author:		<Vicky Lu>
-- Create date: <2013/11/04>
-- Description:	<Function to return a product price from price module/by customer, qty>
-- =============================================
CREATE FUNCTION [dbo].[fn_GetPartPricePrice] 
(	
	@lcUniq_key char(10)=' ', @lcCustno char(10) = ' ', @lnBldQty numeric(7,0)
)
RETURNS numeric(15,5)
AS
BEGIN
DECLARE @lnPrice numeric(15,5) = 0.00, @lcUniqPrHead char(10)

-- 11/25/13 VL changed to use YS less code and fix if qty is not in the pricdetl range
--;WITH ZPricHead
--AS
--(
--	SELECT UniqPrHead, Category 
--		FROM PricHead 
--		WHERE Uniq_key = @lcUniq_key
--		AND (Category = @lcCustno 
--		OR Category = '000000000~')
--)	
--SELECT @lcUniqPrHead = ISNULL(UniqPrHead,SPACE(10)) FROM ZPricHead
--IF @lcUniqPrHead<>''
--	BEGIN
--	;WITH ZPrice 
--	AS
--	(
--		SELECT TOP 1 TotalPrice, FromQty, ToQty
--			FROM PricDetl 
--			WHERE PricDetl.UniqPrHead = @lcUniqPrHead
--			AND ((@lnBldQty BETWEEN Pricdetl.Fromqty AND Pricdetl.Toqty) 
--			--OR (ToQty = (SELECT MAX(ToQty) AS ToQty FROM PricDetl
--			--	 		WHERE UniqPrHead=@lcUniqPrHead))
--			OR (1 = CASE WHEN @lnBldQty < (SELECT MIN(FromQty) FROM PRICDETL WHERE UNIQPRHEAD=@lcUniqPrHead) THEN CASE WHEN 
--				FromQty = (SELECT MIN(FROMQty) AS FromQty FROM PricDetl WHERE UniqPrHead=@lcUniqPrHead) THEN 1 ELSE 0 END ELSE 0 END )
--			OR (1 = CASE WHEN @lnBldQty > (SELECT MAX(ToQty) FROM PricDetl WHERE UniqPrHead=@lcUniqPrHead) THEN CASE WHEN
--				TOQty = (SELECT MAX(ToQty) AS ToQty FROM PricDetl WHERE UniqPrHead=@lcUniqPrHead) THEN 1 ELSE 0 END ELSE 0 END))
--			ORDER BY FromQty
--	)
--	SELECT @lnPrice = ISNULL(TotalPrice,0)*@lnBldQty
--		FROM ZPrice

--END

SELECT TOP 1 @lnPrice=TotalPrice*@lnBldQty
                  FROM PricDetl D INNER JOIN PRICHEAD H on H.UNIQPRHEAD =D.UNIQPRHEAD 
                  WHERE H.Uniq_key = @lcUniq_key
                  AND (H.Category = @lcCustno 
                  OR H.Category = '000000000~')
                  AND ((@lnBldQty BETWEEN D.Fromqty AND D.Toqty) 
                  --OR (ToQty = (SELECT MAX(ToQty) AS ToQty FROM PricDetl
                  --                 WHERE UniqPrHead=H.UniqPrHead)))
					OR (1 = CASE WHEN @lnBldQty < (SELECT MIN(FromQty) FROM PRICDETL WHERE UNIQPRHEAD=H.UniqPrHead) THEN CASE WHEN 
						FromQty = (SELECT MIN(FROMQty) AS FromQty FROM PricDetl WHERE UniqPrHead=H.UniqPrHead) THEN 1 ELSE 0 END ELSE 0 END )
					OR (1 = CASE WHEN @lnBldQty > (SELECT MAX(ToQty) FROM PricDetl WHERE UniqPrHead=H.UniqPrHead) THEN CASE WHEN
						TOQty = (SELECT MAX(ToQty) AS ToQty FROM PricDetl WHERE UniqPrHead=H.UniqPrHead) THEN 1 ELSE 0 END ELSE 0 END))                  
                  ORDER BY FromQty

RETURN @lnPrice

END
