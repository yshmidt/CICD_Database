-- ===================================================================================
-- Author		: Satyawan H.
-- Description  : Get billing addresses of a customer by Customer number
-- Date			: 05/13/2020
-- EXEC getBillingAddressesByCustNo '0000001842,0000001206,0000001613,0000001829'
-- ====================================================================================
CREATE PROC getBillingAddressesByCustNo
	@CustNos VARCHAR(MAX)
AS
BEGIN
	-- Temporary table to create list of customer nombers passed as parameter
	SELECT id AS CustNo INTO #tempCustomerNumberList 
	FROM dbo.[fn_simpleVarcharlistToTable](@CustNos,',')  

	-- Distinct CustomerNo
	SELECT DISTINCT CUSTNO,
		STUFF((SELECT distinct ', ' + TRIM(sb.E_MAIL)
					FROM SHIPBILL sb
					WHERE sb.CUSTNO = sbo.CUSTNO AND recordtype = 'B' 
					  AND TRIM(ISNULL(sb.E_MAIL,'')) <> '' 
				FOR XML PATH(''), TYPE
			  ).value('.', 'NVARCHAR(MAX)') 
			,1,2,'') toAddress 
	FROM SHIPBILL sbo 
	WHERE sbo.CUSTNO IN (select CustNo from #tempCustomerNumberList)
END