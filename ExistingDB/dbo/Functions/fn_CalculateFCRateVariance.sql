-- =============================================
-- Author:		<Vicky Lu>
-- Create date: <02/03/16>
-- Description:	Get the ratio of old rate/new rate for passed in Fchist_key, now use in AR/AP aging to show original rate or latest rate
--	@cType: Conversion FC to Home (F), Home to FC (H)
--	@cFcused_uniq: Foreign currency fcused_uniq
--	@nAmt home: currency amount to be converted
--	@cFCHist_Key: the FCHist_key
-- Modification:
--	06/28/16 VL Changed from return numeric(20,5) to (20,7) to make it more accurate
--  12/07/16 VL Added another paramemter for calculate for functional currency or for presentation currency @CurrencyType can have "F" for Functional and "P" for presentation currency
--  03/20/17 VL If the rate is presentation currency, will juse use 1 to calculate because no need to convert
-- =============================================
CREATE FUNCTION [dbo].[fn_CalculateFCRateVariance]
(
	-- Add the parameters for the function here
	@FCHist_key char(10), @CurrencyType char(10)
)
RETURNS numeric(20,7)
AS
BEGIN

DECLARE @OldPrice numeric(13,5), @NewPrice numeric(13,5), @Fcused_uniq char(10), @nReturn numeric(20,7)

-- 12/07/16 VL added CASE WHEN to get different functional or presentation currency price
SELECT @OldPrice = CASE WHEN @CurrencyType = 'P' THEN AskPricePR ELSE AskPrice END, @Fcused_uniq = Fcused_uniq	
	FROM FcHistory
	WHERE Fchist_key = @FCHist_key

-- 12/07/16 VL added CASE WHEN to get different functional or presentation currency price
SELECT TOP 1 @NewPrice = CASE WHEN @CurrencyType = 'P' THEN AskPricePR ELSE AskPrice END 
	FROM FcHistory
	WHERE Fcused_uniq = @Fcused_uniq 
	ORDER BY FcDateTime DESC

-- 03/20/17 VL added one more criteria to check if the currency is presentation currency, if yes, use 1 to calculate
--SELECT @nReturn = CASE WHEN @NewPrice <> 0 THEN @OldPrice/@NewPrice ELSE 1 END
SELECT @nReturn = CASE WHEN @NewPrice <> 0 AND @Fcused_uniq <> dbo.fn_GetPresentationCurrency() THEN @OldPrice/@NewPrice ELSE 1 END

	
RETURN @nReturn

END