CREATE PROC [dbo].[QuotdeptDept_id4Uniq_keyView] @gUniq_key AS char(10) = ''
AS
SELECT Quotdept.Dept_id, Dept_name 
	FROM Quotdept, Depts 
	WHERE Quotdept.Dept_id = Depts.Dept_id 
	AND Uniq_key = @gUniq_key
	ORDER BY Quotdept.Number






