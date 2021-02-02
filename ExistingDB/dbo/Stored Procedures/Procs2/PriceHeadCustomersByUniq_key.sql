-- =============================================  
-- Author:  Rajendra K
-- Create date: 11/22/2019
-- Description: Get Customers from priceheader,priceCustomer of sales price Module
-- Modified:   
-- EXEC PriceHeadCustomersByUniq_key '_1LR0NALBN' 
-- =============================================  
CREATE PROC [dbo].[PriceHeadCustomersByUniq_key] 
@gUniq_key AS char(10) = ''  
AS  
 BEGIN  
	SELECT pc.custno AS CATEGORY,CustName
	FROM priceheader ph
	INNER JOIN priceCustomer pc ON ph.uniqprhead = pc.uniqprhead
	INNER JOIN CUSTOMER C ON pc.custno = C.CUSTNO
	WHERE uniq_key = @gUniq_key
 END  