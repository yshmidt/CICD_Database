CREATE PROCEDURE [dbo].[SupplierRolodexView]
@userid uniqueidentifier = null
AS
BEGIN

SET NOCOUNT ON;
-- 08/26/13 YS   changed first name+last name to varchar(100), increased length of the ccontact fields.
SELECT SupName, CAST(ISNULL(LTRIM(RTRIM(Lastname))+', '+LTRIM(RTRIM(Firstname)),'') as varchar(200)) AS Contact,
	CAST(ISNULL(Title,'') as varchar(100)) AS Title, CAST(ISNULL(WorkPhone,'') as varchar(50)) AS Phone, CAST(ISNULL(Email,'') as varchar(100)) AS Email, 
	cast(ISNULL(ContactFax,'') as varchar(50)) AS ContactFax, Supinfo.UniqSupno, 'C' AS FromWhere 
	FROM Supinfo LEFT OUTER JOIN Ccontact 
	ON Supinfo.SUPID = Ccontact.Custno 
	AND Ccontact.Type = 'S'
	AND Ccontact.Status = 'Active'
	ORDER BY 1,2
	
END