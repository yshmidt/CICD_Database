CREATE PROC [dbo].[SosrepView] @lcSono AS char(10) = ''
AS
-- 08/26/13 YS   changed first name+last name to varchar(200), increased length of the ccontact fields.
SELECT Soprsrep.Cid, Sono, Uniqueln, Soprsrep.Custno, Commission, 
	CAST(RTRIM(LTRIM(Ccontact.Lastname))+', '+RTRIM(LTRIM(Ccontact.Firstname)) as varCHAR(200)) AS Name, Soprsrepuk
	FROM Soprsrep, Ccontact 
	WHERE Soprsrep.Cid = Ccontact.Cid
	AND Ccontact.Type = 'R'
	AND Soprsrep.Sono = @lcSono
	ORDER BY 6