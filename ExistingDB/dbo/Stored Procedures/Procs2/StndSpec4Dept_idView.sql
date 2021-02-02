CREATE PROC [dbo].[StndSpec4Dept_idView] @lcDept_id AS char(4) = ''
AS
SELECT Spec_desc, Spec_no 
	FROM StndSpec 
	WHERE Dept_id = @lcDept_id 
	ORDER BY Dept_id



