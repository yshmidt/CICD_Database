-- =============================================
-- Author:		Debbie
-- Create date: 11/15/2015
-- Description:	Get list of all Projects that the user is allowed to see based on the Customers that the user is approved 
--				used as a source for 'Prj4User' sourcename in mnxParamSources  (QkViewOpenPObyPJView) 
-- Modified:	08/14/2014 DRP:  needed to add @paramFilter and @top in order to make sure that it will not cause JSON errors with larger datasets. 
--				01/06/2015 DRP:  Added @customerStatus Filter
--				11/13/15 DRP:	 Created this for Open only Projects
-- =============================================
create PROCEDURE [dbo].[GetPrj4UserOpen]
--declare
	@paramFilter varchar(200) = '',		--- first 3+ characters entered by the user
	@top int = null,					-- if not null return number of rows indicated
	@customerStatus varchar (20) = 'All',
	@userId uniqueidentifier = null		-- check the user's limitation
	

as
begin

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

/*GATHERS THE LIST OF CUSTOMER THE USER IS APPROVED TO SEE*/			
	SET NOCOUNT ON;
	DECLARE @tCustomers tCustomer ;
	DECLARE @tCustno tCustno ;
	-- get list of customers for @userid with access
	-- even if @lcCustomer is not empty we cannot assume that the user has rights to those customers. They might just know the codes of the customers that they have no rights to
	
	INSERT INTO @tCustomers EXEC [aspmnxSP_GetCustomers4User] @userid,null,@customerStatus ;
	
/*WILL THEN LIST THE PROJECTS BASED ON THE APPROVED CUSTOMER LIST*/	
  	if (@top is not null)
		select  top(@top) prjunique as Value, prjnumber AS Text 
		from	pjctmain
		WHERe	1 = case when @paramFilter is null then 1 else case when PRJNUMBER like @paramFilter+ '%' then 1 else 0 end end
				and prjstatus = 'Open'
				
		
	else
		select distinct	prjunique as Value, prjnumber AS Text 
		from	pjctmain
		WHERE   1 = case when @paramFilter is null then 1 else case when prjnumber like @paramFilter+ '%' then 1 else 0 end end
				and prjstatus = 'Open'
		
		
--08/14/2014 DRP:  replace with the above select statement
	--select distinct PRJUNIQUE,PRJNUMBER
	--from	pjctmain
	--where	CUSTNO in (select CUSTNO from @tCustomers)
end