﻿CREATE VIEW [dbo].[rptCustViewActiveOnly]
AS
SELECT     TOP (100) PERCENT CUSTNO, CUSTNAME, STATUS
FROM         dbo.CUSTOMER
WHERE     (CUSTNO <> '000000000~') AND (STATUS = 'Active')
ORDER BY CUSTNAME