

CREATE PROC [dbo].[OpenCM4CustView] @lcCustno AS char(10) = ' '
AS
	SELECT CMemono 
		FROM Cmmain 
		WHERE CStatus = 'OPEN' 
		AND Custno = @lcCustno






