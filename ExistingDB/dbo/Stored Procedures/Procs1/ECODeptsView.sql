
CREATE PROC [dbo].[ECODeptsView] AS 
	SELECT Support.Text, Support.Uniqfield
		FROM Support
		WHERE Support.Fieldname = 'DEPT'
		AND LOGIC1 = 1
		ORDER BY Support.Text







