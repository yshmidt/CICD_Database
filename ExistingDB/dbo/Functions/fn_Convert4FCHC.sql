-- =============================================
-- Author:		<Vicky Lu>
-- Create date: <12/19/14>
-- Description:	Conver currencies
/*
 Parameters and their use
 1. @ctype 
	H - convert from Presentation or Functional to Transactional
		dbo.fn_GetFunctionalCurrency() = @cBaseCurKey - from Functional (use AskPrice)
		fn_GetPresentationCurrency()   = @cBaseCurKey - from Presentational (use AskPricePr)
	F - convert from foreign currencies (transaction cusrrencies) to Functional or Presentational based on @cBaseCurKey provided
		dbo.fn_GetFunctionalCurrency()   = @cBaseCurKey - Functional
		dbo.fn_GetPresentationCurrency() = @cBaseCurKey - Presentation 
 2.  @cFcUsed_Uniq - Transactional Currency 
 3. nAmt  
     @ctype='H' and dbo.fn_GetFunctionalCurrency() = @cBaseCurKey then amount provided is in functional currencies
	 @ctype='H' and fn_GetPresentationCurrency() = @cBaseCurKey then amount provided is in presentation currencies
	 @ctype='F' amount in Transaction Currencies, which will be converted to Functional or Presentational
 4. @cBaseCurKey - currency conversion based could be Functional or presentation
	dbo.fn_GetFunctionalCurrency()   = @cBaseCurKey - Functional
	dbo.fn_GetPresentationCurrency() = @cBaseCurKey - Presentation 
 5. @fchist_key - conversion rate to use in calculation
*/

-- In this example, the rate is for converting "EUR" from/to funcional/presentation currencies
-- Fchist_key	Fcused_uniq Date				Fgncncy		AskPrice	AskPricePR	FuncFcused_uniq		PRFcused_uniq
-- _4TC0NXZPT	_3D20X0GAD	2017-01-02 00:00:00	EUR			0.94794		0.21177		_3D20X0GF8			_3D20X0GC8

-- Convert transaction currency (EUR) $100 to functional currency (USD)
--SELECT dbo.fn_Convert4FCHC('F','_3D20X0GAD',100,dbo.fn_GetFunctionalCurrency(),'_4TC0NXZPT')

-- Convert transaction currency (EUR) $100 to presentaion currency (MYR)
--SELECT dbo.fn_Convert4FCHC('F','_3D20X0GAD',100,dbo.fn_GetPresentationCurrency(),'_4TC0NXZPT')

-- Convert functional currency (USD) $200 to transaction currency (EUR)
--SELECT dbo.fn_Convert4FCHC('H','_3D20X0GAD',200,dbo.fn_GetFunctionalCurrency(),'_4TC0NXZPT')

-- Convert presentation currency (MYR) 200 to transaction currency (EUR)
--SELECT dbo.fn_Convert4FCHC('H','_3D20X0GAD',200,dbo.fn_GetPresentationCurrency(),'_4TC0NXZPT')

-- Convert functional currency (USD) 300 to presentation currency (MYR) -- has to convert to transaction currency then convert to presentation currency
--SELECT dbo.fn_Convert4FCHC('F','_3D20X0GAD',dbo.fn_Convert4FCHC('H','_3D20X0GAD',300,dbo.fn_GetFunctionalCurrency(),'_4TC0NXZPT'),dbo.fn_GetPresentationCurrency(),'_4TC0NXZPT')


-- 10/05/16 VL added @cBaseCurKey as 4th parameter and change @cFCHist_key as 5th parameter, 
---@cBaseCurKey = when Convert between transaction and functional currency (FuncFcused_uniq), when convert between transaction and presentation currency (PRFcused_uniq)
-- 10/11/16 VL changed the way how BaseCurKey is used in this function.  If this key is functional funcfcused_uniq, then get askprice, otherwise, get askpricePR for presentation currency
-- 03/20/17 VL IF the FROM and TO currencies are the same, just use 1 to calculate
-- 10/15/18 YS updated parameter description
-- =============================================
CREATE FUNCTION [dbo].[fn_Convert4FCHC]
(
	-- Add the parameters for the function here
	@cType char(1), @cFcUsed_Uniq char(10), @nAmt numeric(20,5), @cBaseCurKey char(10), @cFCHist_key char(10)
)
RETURNS numeric(20,5)
AS
BEGIN

-- 10/11/16 VL added @nAskPricePR and remove nBidPrice
DECLARE @lToday bit, @nAskPrice numeric(13,5)= 0.00000, @nAskPricePR numeric(13,5) = 0.00000, @nReturn numeric(20,5)
SELECT @lToday = CASE WHEN (@cFCHist_key = '' OR @cFCHist_key IS NULL OR @cFCHist_key = 'today') THEN 1 ELSE 0 END


BEGIN
IF @lToday = 0
	BEGIN
	SELECT @nAskPrice = AskPrice, @nAskPricePR = AskPricePR
		FROM FcHistory 
		WHERE FcHist_key = @cFCHist_key
		AND Fcused_Uniq = @cFcUsed_Uniq
		
	IF @@ROWCOUNT = 0
		-- If didn't find, get latest rate
		BEGIN
			SELECT TOP 1 @nAskPrice = AskPrice, @nAskPricePR = AskPricePR
			FROM FcHistory 
			WHERE Fcused_Uniq = @cFcUsed_Uniq
			ORDER BY FcDateTime DESC
		END
	END
ELSE
	-- If didn't find, get latest rate
	BEGIN
		SELECT TOP 1 @nAskPrice = AskPrice, @nAskPricePR = AskPricePR
		FROM FcHistory 
		WHERE Fcused_Uniq = @cFcUsed_Uniq
		ORDER BY FcDateTime DESC
	END	
END
	
IF @cType = 'H'	-- use HC to convert to FC
	-- 10/11/16 VL changed to use different rate based on @cBaseCurKey is functional or presentation key
	--SELECT @nReturn = @nAmt * @nAskPrice
	-- If FROM and TO currencies are the same, use 1 to calculate
	--SELECT @nReturn = @nAmt * CASE WHEN dbo.fn_GetFunctionalCurrency() = @cBaseCurKey THEN @nAskPrice ELSe @nAskPricePR END
	SELECT @nReturn = @nAmt * CASE WHEN @cFcUsed_Uniq = @cBaseCurKey THEN 1 ELSE CASE WHEN dbo.fn_GetFunctionalCurrency() = @cBaseCurKey THEN @nAskPrice ELSE @nAskPricePR END END
	
ELSE
	-- 10/11/16 VL changed to use different rate based on @cBaseCurKey is functional or presentation key
	--SELECT @nReturn = CASE WHEN @nAskPrice > 0 THEN @nAmt/@nAskPrice ELSE 0 END
	-- If FROM and TO currencies are the same, use 1 to calculate
	--SELECT @nReturn = CASE WHEN dbo.fn_GetFunctionalCurrency() = @cBaseCurKey THEN 
	--		CASE WHEN @nAskPrice > 0 THEN @nAmt/@nAskPrice ELSE 0 END 
	--	ELSE CASE WHEN @nAskPricePR > 0 THEN @nAmt/@nAskPricePR ELSE 0 END
	--	END
		SELECT @nReturn = 
		CASE WHEN @cFcUsed_Uniq = @cBaseCurKey THEN
			CASE WHEN dbo.fn_GetFunctionalCurrency() = @cBaseCurKey THEN 
				CASE WHEN @nAskPrice > 0 THEN @nAmt/1 ELSE 0 END 
			ELSE CASE WHEN @nAskPricePR > 0 THEN @nAmt/1 ELSE 0 END
			END
		ELSE
			CASE WHEN dbo.fn_GetFunctionalCurrency() = @cBaseCurKey THEN 
				CASE WHEN @nAskPrice > 0 THEN @nAmt/@nAskPrice ELSE 0 END 
			ELSE CASE WHEN @nAskPricePR > 0 THEN @nAmt/@nAskPricePR ELSE 0 END
			END
		END
	
RETURN @nReturn

END