-- =============================================
-- Author:		Debbie
-- Create date:	11/04/15 
-- Description:	Get a list of product that shipped and was serialized. 
-- Modified		
-- =============================================
create PROCEDURE [dbo].[GetInvtSerialPnList4PL]

--declare
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

		
/*RECORD SELECT*/
select	distinct inventor.UNIQ_KEY,inventor.PART_NO+inventor.REVISION as Part_Number
from	Packlser
		inner join sodetail on PACKLSER.UNIQUELN = sodetail.UNIQUELN
		inner join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY

end