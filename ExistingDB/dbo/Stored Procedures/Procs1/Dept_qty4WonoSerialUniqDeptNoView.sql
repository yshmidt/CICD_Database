
CREATE PROCEDURE [dbo].[Dept_qty4WonoSerialUniqDeptNoView]
(
  @SerialUniq VARCHAR(10),
	@Wono VARCHAR(10)
)
AS
BEGIN
		SELECT Dept_qty.dept_id,Dept_qty.deptkey,InvtSer.SerialUniq,Dept_qty.Number,Dept_qty.wono
		FROM InvtSer INNER JOIN Dept_qty ON InvtSer.wono = Dept_qty.wono
			 INNER JOIN Depts  ON Dept_qty.Dept_id = Depts.Dept_id  
			 INNER JOIN Woentry ON Dept_qty.wono = Woentry.wono	 
		WHERE InvtSer.SerialUniq = @SerialUniq
				and dept_qty.wono = @Wono 
				and ((InvtSer.ID_KEY = 'DEPTKEY' AND dept_qty.Deptkey <> InvtSer.ID_value) OR (InvtSer.ID_KEY <> 'DEPTKEY' AND dept_qty.Dept_id <> 'FGI'))		
END