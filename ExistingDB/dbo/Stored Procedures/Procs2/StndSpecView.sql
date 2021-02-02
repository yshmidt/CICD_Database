CREATE PROC [dbo].[StndSpecView]
AS
SELECT Spec_no, Stndspec.dept_id, Spec_desc, Spec_note, Specpict, ISNULL(Dept_name,SPACE(25)) AS Dept_name
	FROM Stndspec LEFT OUTER JOIN Depts
	ON Stndspec.Dept_id = Depts.Dept_id
	ORDER BY Spec_desc

	