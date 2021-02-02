-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/14/2013
-- Description:	Get list of all make parts with work order created
--- used as a source for 'custName4Wo' sourcename in mnxParamSources  (rptkplabl - label) 
--- 09/03/2013 YS added distinct to the end result
-- 11/25/13 YS modified default value from @lcCustomer to be 'All'
-- 12/03/13 YS if customer is empty or null it doesn't mean all
-- 01/06/2015 DRP:  Added @customerStatus Filter
-- 09/08/16 DRP:  added the @paramFilter and @top so we could get the parameters to work properly for larger datasets.  Then added the if (@top is not null) . . . section 
-- =============================================
CREATE PROCEDURE [dbo].[GetInvtMake4Wo] 
--declare
	-- Add the parameters for the stored procedure here
	
	@paramFilter varchar(200) = '',		--- first 3+ characters entered by the user
	@top int = null,							-- if not null return number of rows indicated
	@UserId uniqueidentifier = null ,  -- check the user's limitation
	@lcCustomer varchar(max) = 'All', -- if null will select all products, @@lcCustomer could have a single value for a custno or a CSV
	@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
	,@openWo bit = 1  -- default to select make parts with open jobs only, if 0 select parts with any job status

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @tCustomers tCustomer ;
	DECLARE @tCustno tCustno ;
	-- get list of customers for @userid with access
	-- even if @lcCustomer is not empty we cannot assume that the user has rights to those customers. They might just know the codes of the customers that they have no rights to
	INSERT INTO @tCustomers EXEC [aspmnxSP_GetCustomers4User] @userid,null,@customerStatus ;
	--11/25/2013 YS change default 'ALL' for all customers instead of empty
	IF @lcCustomer is not null and @lcCustomer <>'' and @lcCustomer <>'All'
		-- from the given list select only those that @userid has an access
		INSERT INTO @tCustno SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcCustomer,',')
			WHERE cast(ID as char(10)) IN (SELECT Custno from @tCustomers)
	ELSE
	IF @lcCustomer ='All'
	BEGIN
		-- get all the customers to which @userid has accees
		-- selct from the list of all customers for which @userid has acceess
		INSERT INTO @tCustno SELECT Custno FROM @tCustomers
	END

if (@top is not null)
	SELECT DISTINCT I.Uniq_key,I.Part_no+' '+I.Revision as [Part Number],I.Part_no,I.Revision
		FROM INVENTOR I INNER JOIN Woentry W on I.Uniq_key=W.UNIQ_KEY 
		INNER JOIN @tCustno C ON W.CUSTNO=C.Custno
		WHERE 1 = case when @paramFilter is null then 1 else case when part_no like @paramFilter+ '%' then 1 else 0 end end
		and 1=CASE WHEN @OpenWo=0 OR (@OpenWo=1 AND OpenClos<>'Closed' and OpenClos<>'Cancel') THEN 1 ELSE 0 END 
else
	SELECT DISTINCT I.Uniq_key,I.Part_no+' '+I.Revision as [Part Number],I.Part_no,I.Revision
		FROM INVENTOR I INNER JOIN Woentry W on I.Uniq_key=W.UNIQ_KEY 
		INNER JOIN @tCustno C ON W.CUSTNO=C.Custno
		WHERE 1 = case when @paramFilter is null then 1 else case when part_no like @paramFilter+ '%' then 1 else 0 end end
		and 1=CASE WHEN @OpenWo=0 OR (@OpenWo=1 AND OpenClos<>'Closed' and OpenClos<>'Cancel') THEN 1 ELSE 0 END 

/*
/*09/08/16 DRP: below is the code that I replaced with the above to work with the Parameters*/		
	----09/03/13 YS added distinct
 --   SELECT DISTINCT I.Uniq_key,I.Part_no+' '+I.Revision as [Part Number],I.Part_no,I.Revision
	--	FROM INVENTOR I INNER JOIN Woentry W on I.Uniq_key=W.UNIQ_KEY 
	--	INNER JOIN @tCustno C ON W.CUSTNO=C.Custno
	--	WHERE 1=CASE WHEN @OpenWo=0 OR (@OpenWo=1 AND OpenClos<>'Closed' and OpenClos<>'Cancel') THEN 1 ELSE 0 END 
*/	
END