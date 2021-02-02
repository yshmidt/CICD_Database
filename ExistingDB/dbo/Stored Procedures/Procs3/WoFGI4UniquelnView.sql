CREATE PROC [dbo].[WoFGI4UniquelnView] @lcUniqueln AS char(10) = ''
AS
SELECT ISNULL(SUM(Dept_qty.Curr_qty),0) AS FGIQty
	FROM Dept_qty, Woentry
	WHERE Dept_qty.Wono = Woentry.Wono 
	AND Dept_qty.Dept_id = 'FGI '
	AND Woentry.Uniqueln = @lcUniqueln