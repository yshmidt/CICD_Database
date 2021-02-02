CREATE PROC [dbo].[Users4WCView]
AS
SELECT Initials, LTRIM(RTRIM(FirstName))+' '+LTRIM(RTRIM(Name)) AS Name, Dept_id, WorkCenter, Userid 
	FROM Users
	WHERE Dept_id<>''
	ORDER BY 1,2









