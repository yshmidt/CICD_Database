
CREATE PROCEDURE [dbo].[DeptsDetView] @pShftDept_id AS char(4) = ' '
AS 

BEGIN
SET NOCOUNT ON;
SELECT Deptsdet.Activ_id, Activ_name, Captotal, Std_rate
	FROM Deptsdet, Activity 
	WHERE Deptsdet.Activ_id = Activity.activ_id 
	AND Dept_id = @pShftDept_id
	ORDER BY Deptsdet.Number

END

