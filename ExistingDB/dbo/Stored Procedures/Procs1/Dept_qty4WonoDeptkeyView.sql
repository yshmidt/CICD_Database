CREATE PROC [dbo].[Dept_qty4WonoDeptkeyView] @lcWono AS char(10) = ' ', @lcDeptkey AS char(10) = ' '
AS
SELECT Wono, DEPT_ID, CURR_QTY, NUMBER, DEPTKEY, UniqueRec
	FROM Dept_qty
	WHERE Wono = @lcWono
	AND DEPTKEY = @lcDeptkey





