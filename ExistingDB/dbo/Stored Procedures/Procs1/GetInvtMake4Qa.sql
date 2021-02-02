-- =============================================
-- Author:		Debbie
-- Create date: 05/13/2014
-- Description:	Get list of all customers that selected user allowed to see and that have existing records within the QAINSP tables
--				used as a source for 'invtMakePart4Qa' sourcename in mnxParamSources  (rptQaDefectLogHist - QAHIST) 
--- Modified	01/06/2015 DRP:  Added @customerStatus Filter
-- =============================================
CREATE PROCEDURE [dbo].[GetInvtMake4Qa]

	@lcCustomer varchar(max) = 'All' -- if null will select all products, @@lcCustomer could have a single value for a custno or a CSV
	,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
	,@UserId uniqueidentifier = null  -- check the user's limitation

as
begin
			
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

/*PULLING FROM View_InvtMale4QA -- in order to only get product that exists within the QAINSP tables*/
select	I.Uniq_key,I.[Part Number],I.Part_no,I.Revision
FROM	View_invtMake4QA I 
		iNNER JOIN @tCustno C ON I.CUSTNO=C.Custno
			
end