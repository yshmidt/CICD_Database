-- ======================================================================
-- Author:		Vicky Lu
-- Create date: 
-- Description:	Foreign Currency Currencies Exchange Rates History
---Modified:
--	10/31/2014	VL	Created the view
--	09/30/16	VL	Added BaseCurKey		
--	10/11/16	VL	Removed BaseCurKey and added AskPricePR to save the presentation currency rate, AskPrice will save the functional currency rate, removed BidPrice
-- ======================================================================
CREATE PROC [dbo].[FcHistoryView] 
AS
BEGIN
	SELECT FcHist_key, FcUsed_Uniq, FcDateTime, Fgncncy, AskPrice, AskPricePR, FuncFcused_uniq, PRFcused_uniq
		FROM FcHistory ORDER BY FcDateTime
		
END