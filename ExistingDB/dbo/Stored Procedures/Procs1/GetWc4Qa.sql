-- =============================================
-- Author:		Debbie
-- Create date: 05/13/2014
-- Description:	Get list of all customers that selected user allowed to see and that have existing records within the QAINSP tables
--				used as a source for 'workcenter4Qa' sourcename in mnxParamSources  (rptQaDefectLogHist - QAHIST) 
-- Modified:	08/14/2014 DRP:   needed to add @paramFilter and @top in order to prevent JSON error on BigData 
--				01/06/2015 DRP:  Added @customerStatus Filter
-- =============================================
CREATE PROCEDURE [dbo].[GetWc4Qa]

	@UserId uniqueidentifier = NULL   -- check the user's limitation
	,@lcCustomer varchar(max)  ='AlL'		-- if null will select all products, @@lcCustomer could have a single value for a custno or a CSV 
	--,@lcDeptId varchar(max) = 'All'
	,@paramFilter varchar(200) = ''			-- first 3+ characters entered by the user --08/14/2014 DRP Added
	,@customerStatus varchar (20) = 'All'
	,@top int = null						-- if not null return number of rows indicated --08/14/2014 DRP Added



as
begin

/*CUSTOMER SELECTION LIST*/
SET NOCOUNT ON;
	DECLARE @tCustomers tCustomer ;
	DECLARE @tCustno tCustno ;
	
	-- get list of customers for @userid with access
	-- even if @lcCustomer is not empty we cannot assume that the user has rights to those customers. They might just know the codes of the customers that they have no rights to
	INSERT INTO @tCustomers EXEC [aspmnxSP_GetCustomers4User] @userid,null,@customerStatus ;
	
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


/*SELECTION STATEMENT*/
/*PULL FROM View_Wc4Qa --in order to only get Work Centers exist within QAINSP tables that the user is approved to see associated to the Customer */

--08/14/2014 DRP NEEDED TO REPLACE THE BELOW WITH THE FOLLOWING SO THAT IT WOULD PREVENT JSON ERROR IN BIGDATA SITUATIONS. 
--SELECT distinct	w.DEPT_ID, W.dept_name,W.NUMBER 
--	FROM	View_Wc4Qa W
--			inner join @tCustno c on W.custno = c.custno
--order by NUMBER

	if (@top is not null)
		select  top(@top) dEPT_ID as Value, RTRIM(DEPT_NAME) AS Text, NUMBER
		from	View_Wc4Qa W
				inner join @tCustno c on W.custno = c.custno 
		WHERe	1 = case when @paramFilter is null then 1 else case when DEPT_NAME like @paramFilter+ '%' then 1 else 0 end end
		ORDER BY NUMBER
	else
		select distinct	dEPT_ID as Value, RTRIM(DEPT_NAME) AS Text,NUMBER 
		from	View_Wc4Qa W
				inner join @tCustno c on W.custno = c.custno 
		WHERe	1 = case when @paramFilter is null then 1 else case when DEPT_NAME like @paramFilter+ '%' then 1 else 0 end end
		ORDER BY NUMBER

end