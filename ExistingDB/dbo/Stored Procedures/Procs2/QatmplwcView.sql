CREATE PROC [dbo].[QatmplwcView] @lcTemplUniq AS char(10) = ' '
AS
	SELECT *, Dept_name
		FROM QATMPLWC, Depts
		WHERE QatmplWc.DEPT_ID = Depts.DEPT_ID
		AND TEMPLUNIQ = @lcTemplUniq
		ORDER BY QATMPLWC.Dept_id