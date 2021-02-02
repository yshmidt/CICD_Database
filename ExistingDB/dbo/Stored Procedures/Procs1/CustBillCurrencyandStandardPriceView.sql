-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/06/2016
-- Description:	Get all customers with different currency (set up in shipbill recordtype = 'B') and get 'Standard Price' as well
-- =============================================
CREATE PROCEDURE [dbo].[CustBillCurrencyandStandardPriceView]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
SELECT DISTINCT Custname, Customer.Custno, Fcused.symbol, shipbill.fcused_uniq
	FROM Customer, shipbill, fcused
	WHERE Customer.custno = shipbill.custno 
	AND shipbill.recordtype = 'B'
	AND shipbill.fcused_uniq = fcused.fcused_uniq
	UNION ALL 
	SELECT 'Standard Price' AS Custname, '000000000~' AS Custno, SPACE(3) AS Symbol, SPACE(10) AS Fcused_Uniq
	ORDER BY CustName          

END