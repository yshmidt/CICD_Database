CREATE PROC [dbo].[SoBillView] @lcLinkAdd char(10) = ''
AS
SELECT *
	FROM ShipBill
	WHERE RecordType = 'B'
	AND LinkAdd = @lcLinkAdd