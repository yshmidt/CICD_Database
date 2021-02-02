
CREATE PROC [dbo].[OpenSalesOrders4Uniq_keyView] @gUniq_key AS char(10) =' '    
AS
SELECT Sodetail.Sono, Uniqueln, Line_no, Balance, Is_Rma
	FROM Sodetail, Somain 
	WHERE Sodetail.Sono = Somain.Sono 
	AND Uniq_key = @gUniq_key 
	AND Uniq_key <> ''
	AND (Status <> 'Cancel'
	AND Status <> 'Closed')
	AND Balance > 0
	ORDER BY Sodetail.Sono, Line_no




