CREATE PROCEDURE [dbo].[QkViewCARFollowUpView]
@userid uniqueidentifier = null
AS
BEGIN

SET NOCOUNT ON;

SELECT LTRIM(RTRIM(Name))+', '+LTRIM(RTRIM(Firstname)) AS Name, Followupdt, Carno, Descript 
	FROM Craction, Users 
	WHERE Followupdt IS NOT NULL
	AND FollowUpby = Users.userID
	ORDER BY Name 
  
END
