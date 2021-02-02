CREATE PROC [dbo].[Crac_DetView] @lcCarno  AS char(10) = ' '
AS
BEGIN
	SELECT LTRIM(RTRIM(Users.name))+', '+LTRIM(RTRIM(Users.firstname)) AS Name, Proj_stat, Last_edit, Recdate, 
			[By] AS 'By', Carno, C_id, Start_dt, Estcomp_dt, Newdue_dt, Acomp_dt, UNIQUECRDET
		FROM Crac_det, Users
		WHERE C_id = Users.userid
		AND Carno = @lcCarno
END
