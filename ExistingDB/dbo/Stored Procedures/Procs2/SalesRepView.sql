
CREATE PROC [dbo].[SalesRepView] AS 

-- Modified: 08/26/13 YS   changed first name+last name to varchar(200), increased length of the ccontact fields.
SELECT Ccontact.*, CAST(RTRIM(LTRIM(Ccontact.Lastname))+', '+RTRIM(LTRIM(Ccontact.Firstname)) as VARCHAR(200)) AS Name
	FROM Ccontact
	WHERE Type = 'R'
	AND Status<>'Inactive'
	ORDER BY LastName, FirstName