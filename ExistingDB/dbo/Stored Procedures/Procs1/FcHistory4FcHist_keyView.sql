-- ======================================================================
-- Author:		Vicky Lu
-- Create date: 
-- Description:	Foreign Currency Currencies Exchange Rates History for one Fchist_key
---Modified:	01/22/15 VL Created the view
--				11/14/16 VL Remove BidPrice and add AskPricePR
-- ======================================================================
CREATE PROC [dbo].[FcHistory4FcHist_keyView] @lcFcHist_key AS char(10) = ' '
AS
BEGIN
	SELECT FcHist_key, FcUsed_Uniq, FcDateTime, Fgncncy, AskPrice, AskPricePR 
		FROM FcHistory
		WHERE Fchist_key = @lcFcHist_key
		
END