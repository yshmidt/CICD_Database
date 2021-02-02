
CREATE PROC [dbo].[AggregateWIP4Uniq_keyView] @gUniq_key AS char(10) =''    
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT SUM(Curr_qty) AS WCQty, Dept_qty.Dept_id, Dept_name, Depts.number
	FROM Dept_qty, Depts
	WHERE Dept_qty.Dept_id = Depts.Dept_id
	AND Wono IN
		(SELECT Wono 
			FROM Woentry
			WHERE (OpenClos<>'Closed' 
			AND OpenClos<>'Cancel'
			ANd OpenClos<>'ARCHIVED')
			AND Uniq_key = @gUniq_key)
	GROUP BY Dept_qty.Dept_id, Dept_name, Depts.Number
	ORDER BY Depts.number

END