CREATE PROC [dbo].[CudefdetView] @lcDept_id AS char(4) = ' '
AS
	SELECT Cudefdet.Def_code, LEFT(Support.Text3,20) AS Def_name
		FROM Cudefdet, Support 
		WHERE Cudefdet.Def_code = LEFT(Support.Text2,10)
		AND Support.Fieldname = 'DEF_CODE'
		AND CUDEFDET.DEPT_ID = @lcDept_id
		ORDER BY Support.Number






