CREATE PROCEDURE [dbo].[QkViewShortSummaryByPartNoView]
@userid uniqueidentifier = null
AS
BEGIN

SET NOCOUNT ON;

SELECT DISTINCT CASE WHEN Part_Sourc = 'CONSG' THEN CustPartno ELSE Part_no END  AS Part_no,
	CASE WHEN Part_Sourc = 'CONSG' THEN CustRev ELSE Revision END AS Revision, 
	Part_class, Part_type, Descript, Kamain.Uniq_key 
	FROM Inventor, Kamain, Woentry 
	WHERE Kamain.Uniq_key  = Inventor.Uniq_key
	AND Kamain.Wono = Woentry.Wono 
	AND Woentry.Openclos <> 'Cancel'
	AND Woentry.OpenClos <> 'Closed'
	AND Woentry.Balance <> 0 
	AND Woentry.KIT = 1
	AND ShortQty > 0 
	AND IgnoreKit = 0
	
END