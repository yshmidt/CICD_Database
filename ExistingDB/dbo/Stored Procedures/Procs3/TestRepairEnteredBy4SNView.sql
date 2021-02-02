CREATE PROC [dbo].[TestRepairEnteredBy4SNView] @lcSerialUniq AS char(10) = ' ' 
AS
SELECT Inspby, Date, Qainsp.Qaseqmain
	FROM Qainsp, Qadef
	WHERE Qainsp.Qaseqmain = Qadef.Qaseqmain 
	AND Qadef.SerialUniq = @lcSerialUniq
	ORDER BY Date








