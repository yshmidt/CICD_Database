-- ======================================================================
-- Author:		Vicky Lu
-- Create date: 
-- Description:	Foreign Currency used currencies
---Modified:	10/10/14 VL Created the view
---				11/12/14 VL added FcHist_key to refer back to Fchistory if necessary
---				11/18/14 VL Remove UniqFcUsed field
---				09/26/16 VL added BaseCurKey, so the view include both functional and presentation currency rate
--				10/03/16 VL Changed BaseCurKey to have either SPACE(10) or user functional currency, otherwise in currency setup, the new added currency would not show
--				10/04/16 VL added one more criteria basecurkey in ZFCPrice
--				10/11/16 VL Removed BaseCurKey, but get AskPricePF
-- ======================================================================
CREATE PROC [dbo].[FcUsedView] 
AS
BEGIN

;WITH ZMaxDate AS
	-- 09/26/16 VL added BaseCurKey
	-- 10/11/16 VL removed BaseCurKey
	(SELECT MAX(Fcdatetime) AS Fcdatetime, FcUsed_Uniq
		FROM FcHistory 
		GROUP BY Fcused_Uniq),
ZFCPrice AS 
	(SELECT FcHistory.AskPrice, AskPricePR, FcHistory.FcUsed_Uniq, FcHist_key, FcHistory.Fcdatetime
		FROM FcHistory, ZMaxDate
		WHERE FcHistory.FcUsed_Uniq = ZMaxDate.FcUsed_Uniq
		AND FcHistory.Fcdatetime = ZMaxDate.Fcdatetime)
	
	SELECT FcUsed.FCUsed_Uniq, Country, CURRENCY, Symbol, Prefix, UNIT, Subunit, Thou_sep, Deci_Sep, Deci_no, 
		ISNULL(AskPrice,0) AS AskPrice, ISNULL(AskPricePR,0) AS AskPricePR, FcHist_key, FcdateTime
		FROM FCUsed LEFT OUTER JOIN ZFCPrice
		ON FcUsed.FcUsed_Uniq = ZFCPrice.FcUsed_Uniq
		ORDER BY Country
END