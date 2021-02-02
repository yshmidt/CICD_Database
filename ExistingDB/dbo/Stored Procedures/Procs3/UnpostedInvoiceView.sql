
CREATE PROC [dbo].[UnpostedInvoiceView] 
@userId uniqueidentifier = null
AS 

SELECT Invoiceno, Packlistno, INVTOTAL
	FROM PLMAIN
	WHERE Printed = 1	-- PK is posted
	AND PRINT_INVO = 0  -- invoice is not posted yet
	ORDER BY Invoiceno