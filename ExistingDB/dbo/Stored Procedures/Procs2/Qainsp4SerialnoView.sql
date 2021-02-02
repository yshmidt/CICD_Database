CREATE PROC [dbo].[Qainsp4SerialnoView] @lcSerialno AS char(30) = ' '
AS
	SELECT Qainsp.Wono, Qainsp.Dept_id, Lotsize, Inspqty, Failqty, PassQty, Inspby, Date, Qainsp.Qaseqmain 
		FROM Qainsp, Qadef 
		WHERE Qainsp.Qaseqmain = Qadef.Qaseqmain 
		AND Serialno = @lcSerialno
		ORDER BY Date
	





