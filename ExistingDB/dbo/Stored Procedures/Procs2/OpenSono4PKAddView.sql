CREATE PROCEDURE [dbo].[OpenSono4PKAddView] @lcCustno AS char(10) = ''
AS
	SELECT Sono, CustName, Pono, ' ' AS RMAFlag
		FROM Somain, Customer
		WHERE Somain.Custno = Customer.Custno
		AND Somain.Ord_type = 'Open'
		AND Somain.Poack = 1
		AND Somain.Is_Rma = 0
		AND Customer.Status = 'Active'
		AND Customer.Creditok = 'OK'
		AND 1 = 
			CASE @lcCustno 
				WHEN '' THEN 1 
				ELSE CASE WHEN (SOMAIN.CUSTNO = @lcCustno) THEN 1 ELSE 0 END
			END
	UNION 
		SELECT DISTINCT Somain.Sono, CustName, Pono, 'T' AS RMAFlag
		FROM Somain, Sodetail, Customer
		WHERE Somain.Custno = Customer.Custno
		AND Somain.Ord_type = 'Open'
		AND Somain.Poack = 1
		AND Somain.Is_Rma = 1 
		AND Sodetail.Ord_qty > 0 
		AND Customer.Status = 'Active'
		AND Customer.Creditok = 'OK'
		AND 1 = 
			CASE @lcCustno 
				WHEN '' THEN 1 
				ELSE CASE WHEN (SOMAIN.CUSTNO = @lcCustno) THEN 1 ELSE 0 END
			END		
		ORDER BY 1