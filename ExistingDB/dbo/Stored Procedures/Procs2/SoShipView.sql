CREATE PROC [dbo].[SoShipView] @lcLinkAdd char(10) = ''
AS
SELECT *
	FROM ShipBill
	WHERE RecordType = 'S'
	AND LinkAdd = @lcLinkAdd