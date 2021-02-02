

CREATE PROC [dbo].[OpenWorkOrdersNoFGI4Uniq_keyView] @gUniq_key AS char(10) =''    
AS
SELECT Wono, BldQty, Complete, Balance, Sono, Due_date, ReleDate, OpenClos, CustName
	FROM Woentry, Customer 
	WHERE Woentry.Custno = Customer.Custno
	AND (OpenClos<>'Closed' 
	AND OpenClos<>'Cancel'
	ANd OpenClos<>'ARCHIVED')
	AND Uniq_key = @gUniq_key 
	AND WONO NOT IN 
		(SELECT WONO 
			FROM DEPT_QTY 
			WHERE CURR_QTY > 0
			AND (DEPT_ID = 'FGI'
			OR DEPT_ID = 'SCRP'))
ORDER BY Wono