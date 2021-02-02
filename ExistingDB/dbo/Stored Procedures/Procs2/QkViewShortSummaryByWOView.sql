CREATE PROCEDURE [dbo].[QkViewShortSummaryByWOView]
AS
BEGIN

SET NOCOUNT ON;

SELECT DISTINCT Kamain.Wono, Part_no, Revision, Descript, Due_date, Bldqty, Complete, Balance 
	FROM Kamain, Woentry, Inventor 
	WHERE Woentry.Uniq_key = Inventor.Uniq_key 
	AND Kamain.Wono = Woentry.Wono 
	AND Woentry.Openclos <> 'Cancel'
	AND Woentry.OpenClos <> 'Closed'
	AND Woentry.Balance <> 0
	AND ShortQty > 0 
	AND Woentry.kit = 1
	AND Kamain.IgnoreKit = 0

END