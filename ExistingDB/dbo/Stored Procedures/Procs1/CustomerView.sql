-- 04/08/13 VL added Status field

CREATE PROC [dbo].[CustomerView] AS 
SELECT Custname,custno,Status
	FROM Customer
	WHERE Status<>'Inactive'
	ORDER BY 1