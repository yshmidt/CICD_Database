CREATE PROC [dbo].[Cmprices4PlpricelnkView] @lcPlpricelnk AS char(10) = ''
AS
SELECT Plpricelnk 
	FROM Cmprices 
	WHERE Cmprices.Plpricelnk = @lcPlpricelnk


