
CREATE procedure [dbo].[CustomerContactView] 
		@lcCustno AS char(10)= ''
AS
---08/26/2013 YS :  changed Name to varchar(200), increased length of the ccontact fields.
SELECT Ccontact.Lastname, Ccontact.Firstname, Ccontact.Title, Cid, CAST(RTRIM(LTRIM(Ccontact.Lastname))+', '+RTRIM(LTRIM(Ccontact.Firstname)) as varCHAR(200)) AS Name 
	FROM Ccontact 
	WHERE Ccontact.Custno = @lcCustno 
	AND Ccontact.Type = 'C'
	AND Status = 'Active'
	ORDER BY LASTNAME, FIRSTNAME