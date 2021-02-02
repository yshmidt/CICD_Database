CREATE PROC [dbo].[WoentryView] @gWono AS char(10) = ''
AS
SELECT Woentry.Wono,Customer.CustName,Inventor.Part_no,Inventor.Revision,Woentry.BALANCE,Woentry.Due_date
		FROM Woentry INNER JOIN Customer on Woentry.Custno=Customer.CustNo
		INNER JOIN INVENTOR ON Woentry.UNIQ_KEY =Inventor.UNIQ_KEY 
	WHERE Wono = @gWono