-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/14/2013
-- Description:	Get list of all active customers that selected user allowed to see and for which work orders are created
--- used as a source for 'custName4Wo' sourcename in mnxParamSources  (rptkplabl - label) 
--- 09/03/13 YS added distinct
--- 10/03/16 DRP:  needed to had the ability to enter the first 3 character and find the nearest match for users with larger customer listing. 	
-- =============================================
CREATE PROCEDURE [dbo].[GetCustomerList4UserWithWo]
	-- Add the parameters for the stored procedure here
	@UserId uniqueidentifier =NULL,  -- userid for security
	@OpenWo bit = 1  -- show customers with open work orders only by default, if 0 show all
	,@paramFilter varchar(200) = ''		--- first 3+ characters entered by the user		12/09/15 DRP:  Added
	,@top int = null					-- if not null return number of rows indicated	12/09/15 DRP: Added
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @tCustomers tCustomer ;
	INSERT INTO @tCustomers EXEC [aspmnxSP_GetCustomers4User] @userid ;
	-- 09/03/13 YS added distinct

if (@top is not null)
		select distinct top(@top) t.Custno,t.CustName
		FROM @tCustomers t INNER JOIN WOENTRY W ON t.Custno=W.Custno
		WHERE 1=CASE WHEN @OpenWo=0 OR (@OpenWo=1 AND OpenClos<>'Closed' and OpenClos<>'Cancel') THEN 1 ELSE 0 END 
				and 1 = case when @paramFilter is null then 1 else case when custname like '%'+@paramFilter+ '%' then 1 else 0 end end
else
		select distinct t.Custno,t.CustName
		FROM @tCustomers t INNER JOIN WOENTRY W ON t.Custno=W.Custno
		WHERE 1=CASE WHEN @OpenWo=0 OR (@OpenWo=1 AND OpenClos<>'Closed' and OpenClos<>'Cancel') THEN 1 ELSE 0 END 
			and 1 = case when @paramFilter is null then 1 else case when custname like '%'+@paramFilter+ '%' then 1 else 0 end end

END