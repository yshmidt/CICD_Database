--Sachin s:Return the list of Contact details for customer
CREATE procedure [dbo].[sp_CustomerContactView] 
		@lcCustno AS char(10)= ''
AS
SELECT Cid, CAST(RTRIM(LTRIM(Ccontact.Lastname))+', '+RTRIM(LTRIM(Ccontact.Firstname)) as varCHAR(200)) AS Name 
	FROM Ccontact 
	WHERE Ccontact.Custno = @lcCustno 
	AND Ccontact.Type = 'C'
	AND Status = 'Active'
	ORDER BY LASTNAME, FIRSTNAME