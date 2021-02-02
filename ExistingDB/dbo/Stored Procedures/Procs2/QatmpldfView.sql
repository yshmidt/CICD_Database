CREATE PROC [dbo].[QatmpldfView] @lcTemplUniq AS char(10) = ' '
AS
	SELECT *, LEFT(Support.Text3,20) AS Def_name
		FROM Qatmpldf, Support
		WHERE Qatmpldf.Def_code = LEFT(Support.Text2,10)
		AND Support.Fieldname = 'DEF_CODE'
		AND TEMPLUNIQ = @lcTemplUniq
		ORDER BY DEF_CODE
