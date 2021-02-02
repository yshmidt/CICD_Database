
CREATE PROCEDURE [dbo].[SupplierContactView] 
		@lcSupId AS char(10)= ''
AS
SELECT RTRIM(LTRIM(Ccontact.Firstname))+ ' '+RTRIM(LTRIM(Ccontact.Lastname)) AS Name, Title, WorkPhone, ContactFax, Email, Cid, Custno
	FROM Ccontact 
	WHERE Ccontact.Custno =@lcSupId AND Ccontact.Type = 'S' AND Status = 'Active' ORDER BY Name