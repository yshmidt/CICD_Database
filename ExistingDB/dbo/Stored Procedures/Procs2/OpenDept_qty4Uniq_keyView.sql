

CREATE PROC [dbo].[OpenDept_qty4Uniq_keyView] @gUniq_key AS char(10) =' '    
AS
SELECT Wono, Dept_id, Curr_qty, Number, Deptkey
	FROM Dept_qty
	WHERE Wono IN 
		(SELECT Wono 
			FROM Woentry
			WHERE OpenClos<>'Closed' 
			AND OpenClos<>'Cancel'
			ANd OpenClos<>'ARCHIVED'
		AND Uniq_key = @gUniq_key )
ORDER BY Wono

















