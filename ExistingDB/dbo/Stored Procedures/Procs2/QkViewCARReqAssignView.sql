
CREATE PROCEDURE [dbo].[QkViewCARReqAssignView]
@userid uniqueidentifier = null
AS
BEGIN

SET NOCOUNT ON;

SELECT LTRIM(RTRIM(Name))+', '+LTRIM(RTRIM(Firstname)) AS Name, Crac_det.Carno AS TmCarno, Craction.NewDue_dt, Craction.Descript 
	FROM Crac_det, Craction, Users 
	WHERE Crac_det.Carno = Craction.Carno 
	AND Crac_det.C_id = Users.UserID 
	AND Proj_Stat = 0 
	AND Craction.CompDate IS NULL
	ORDER BY Name
  
END
