-- =============================================  
-- Author:  Debbie  
-- Create date: 02/23/2012  
-- Description: This Stored Procedure was created for the Invoice Register by Invoice Number  
-- Reports Using Stored Procedure:  inv_rep3.rpt, inv_rep6.rpt  
-- Modified: 01/15/2014 DRP:  added the @userid parameter for WebManex  
--    10/30/15 DRP:  changed the Date Range filter. added the @lcSort param so I could use the same procedure to two reports.   
-- 05/23/2020 Satayawn H: Added to get invoice By customerNo 
-- =============================================  
CREATE PROCEDURE [dbo].[rptInvoiceRegister]  
	 @lcDateStart AS SMALLDATETIME= NULL  
	,@lcDateEnd AS SMALLDATETIME = NULL  
	,@lcSort AS CHAR(10) = 'by Invoice' --By Invoice or By Date --10/30/15 DRP:  Added   
	,@lcCustNo AS VARCHAR (MAX) = 'All' -- 05/23/2020 Satayawn H: Added to get invoice By customerNo 
	,@userId UNIQUEIDENTIFIER = NULL  
AS 
BEGIN  
	IF @@version like '%2008%'  
		EXEC rptInvoiceRegister2008 @lcDateStart=@lcDateStart, @lcDateEnd=@lcDateEnd, 
									@lcSort=@lcSort, @userId=@userId, @lcCustNo=@lcCustNo
	else  
		EXEC rptInvoiceRegister2012 @lcDateStart=@lcDateStart, @lcDateEnd=@lcDateEnd, 
									@lcSort=@lcSort, @userId=@userId, @lcCustNo=@lcCustNo
END