-- =============================================
-- Author: <Shripati>
-- Create date: <04/19/2018>
-- Description:	Get Billing address view
-- 03/26/2019 Shrikant B Added parameter @userId for getting customer of selected user 
-- 03/26/2019 Shrikant B Added join for getting customer of selected user 
-- 04/01/2019 Shrikant B handle restricted user and full access user
-- 01/16/2020 Sachin B Add's @isAdmin,@acctAdmin,@linkCustCount veriable to Show Customer List Conditionaly and Remove If Else Block
-- 05/20/2020 Satyawan H: Assign sort expression to customer Name ascending if it is empty
-- exec [dbo].[GetCompanyList] 'Active',0,150,'CustName asc','', 'A93090DB-58C8-4805-B4F0-26D816AF7770' 
--=============================================
CREATE PROCEDURE [dbo].[GetCompanyList]
	@status char(10)=NULL,
	@startRecord int = 0,
    @endRecord int = 150, 
    @sortExpression nvarchar(1000) = NULL,
	@filter nvarchar(1000) = NULL,
	-- 03/26/2019 Shrikant B Added parameter @userId for getting customer of selected user 
	@userId UNIQUEIDENTIFIER= NULL  
AS 
BEGIN
 SET NOCOUNT ON
  DECLARE @SQL nvarchar(max);
  DECLARE @tCustomer TABLE ( CustName CHAR(50), Status CHAR(8), CustNo CHAR (10))
  DECLARE @isAdmin BIT,@acctAdmin BIT, @linkCustCount INT,@tempId UNIQUEIDENTIFIER;

	-- 01/16/2020 Sachin B Add's @isAdmin,@acctAdmin,@linkCustCount veriable to Show Customer List Conditionaly
    SET  @isAdmin = (SELECT CompanyAdmin FROM aspnet_Profile WHERE UserId=@userId)
	SET  @acctAdmin = (SELECT AcctAdmin FROM aspnet_Profile WHERE UserId=@userId)
	SET  @linkCustCount = ((SELECT COUNT(*) FROM aspmnx_UserCustomers WHERE fkUserId=@userId))
	SET @tempId =NEWID()
    -- 04/01/2019 Shrikant B handle restricted user and full access user

	INSERT INTO @tCustomer
	SELECT  CUSTNAME AS CustName, cust.STATUS AS Status, cust.custno AS CustNo FROM CUSTOMER cust
     -- 03/26/2019 Shrikant B Added join for getting customer of selected user (restricted user)
	 LEFT JOIN aspmnx_UserCustomers aspmnxUserCust ON (cust.CUSTNO = aspmnxUserCust.fkCustno)	 
     WHERE 
	 cust.CUSTNO = CASE WHEN (@isAdmin = 1 OR @acctAdmin =1 OR @linkCustCount=0) THEN  cust.CUSTNO   ELSE  aspmnxUserCust.fkCustno  END 	 
	 AND ISNULL(aspmnxUserCust.fkUserId,@tempId) = CASE WHEN (@isAdmin = 1 OR @acctAdmin =1 OR @linkCustCount=0) 
														THEN ISNULL(aspmnxUserCust.fkUserId,@tempId)  
														ELSE @userId  END
	 AND cust.STATUS = @status AND custno <> '000000000~'   
	 GROUP BY  CustName, cust.STATUS, cust.custno 
  
  SELECT IDENTITY(INT,1,1) AS RowNumber,* INTO #TEMP FROM @tCustomer

	-- Satyawan H: 05/20/2020 - Assign sort expression to customer Name ascending if it is empty
	IF ISNULL(@sortExpression,'')= ''  
	SET @sortExpression = 'CustName asc'

   IF @filter <> '' AND @sortExpression <> ''
		BEGIN
		   SET @SQL=N'SELECT  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE '+@filter
			   +' ORDER BY '+ @SortExpression+''+ ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'
		END
   ELSE IF @filter = '' AND @sortExpression <> ''
		BEGIN
			SET @SQL=N'SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t '  
			+' ORDER BY '+ @sortExpression+'' + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;' 
		END
	ELSE 
	  BEGIN
	    IF @filter <> '' AND @sortExpression = ''
		  BEGIN
			  SET @SQL=N'SELECT  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE  '+@filter+'' 
			  + ' ORDER BY CustName DESC OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;' 
		  END
		ELSE
		  BEGIN
			  SET @SQL=N'SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t'
			   + ' ORDER BY CustName DESC OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'
		  END
      END
	EXEC SP_EXECUTESQL @SQL
END