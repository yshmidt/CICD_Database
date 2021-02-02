CREATE PROC [dbo].[Dept_qty4WonoNumberView] @lcWono AS char(10) = ' ', @lnNumber AS numeric(4,0)
AS
SELECT Wono, DEPT_ID, CURR_QTY, NUMBER, DEPTKEY, UniqueRec
	FROM Dept_qty
	WHERE Wono = @lcWono
	AND Number = @lnNumber





