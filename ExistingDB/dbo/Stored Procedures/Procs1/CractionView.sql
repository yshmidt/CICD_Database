CREATE PROC [dbo].[CractionView] @lcCarno  AS char(10) = ' '
AS
BEGIN
SELECT Craction.*, CUSTNAME, SupName, Dept_name, IsoDesc, LTRIM(RTRIM(Name))+CASE WHEN (Name='' OR FIRSTNAME='') THEN '' ELSE ', ' END + LTRIM(RTRIM(FirstName)) AS Coordinator, Supid
	FROM CRACTION LEFT OUTER JOIN Customer
			ON Craction.Custno = Customer.Custno
		LEFT OUTER JOIN Supinfo
			ON Craction.UniqSupno = Supinfo.UniqSupno
		LEFT OUTER JOIN Depts
			ON Craction.Dept_id = Depts.Dept_id
		LEFT OUTER JOIN Iso9000
			ON Craction.Elem_id = Iso9000.Iso_id
		LEFT OUTER JOIN Users
			ON Craction.ORIGNATR = Users.UserId
	WHERE CARNO = @lcCarNo

END