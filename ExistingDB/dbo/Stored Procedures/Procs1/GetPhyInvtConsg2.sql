
		-- =============================================
		-- Author:			Debbie
		-- Create date:		01/13/16
		-- Description:		Gathers the UniqPiHead for the Physical Inventory Selections for Consigned and completed 
		-- Used On:			created to be used for parameter selection on the [phyws] mnxparamsources [PhyInvtUniqSelect]
		-- Modified:		   
		-- =============================================
create procedure [dbo].[GetPhyInvtConsg2]
--declare
	@top int = null						-- if not null return number of rows indicated --08/14/2014 DRP Added
	,@paramFilter varchar(200) = ''			-- first 3+ characters entered by the user --08/14/2014 DRP Added
	--,@phytype numeric = 0					--0=All,1=Internal,2=Consigned,3=Instore
	,@lcPiStatus char(10) = 'In process'
	,@lcCustno char(10) = 'All'
	,@userId uniqueidentifier = null

as
begin

	
/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	
		
		IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)
		ELSE

		IF  @lcCustNo='All'	
		BEGIN
			INSERT INTO @Customer SELECT CustNo FROM @tCustomer
		END



if (@top is not null)
	select	top(@top) uniqpihead,rtrim(cast(STARTTIME as varCHAR(20)))+ '     '+ rtrim(DETAILNAME)  AS PhyInvtHeader
	from	PHYINVTH 
	where	PISTATUS = @lcPiStatus
			and PHYINVTH.INVTTYPE = 2
			and exists (select 1 from @Customer t where t.custno = detailno)	
	 order by INVTTYPE,STARTTIME desc
 
 else
		select	distinct uniqpihead,rtrim(cast(STARTTIME as varCHAR(20)))+ '     '+ rtrim(DETAILNAME)  AS PhyInvtHeader
				,invttype,starttime 
	from	PHYINVTH 
	where	PISTATUS = @lcPiStatus
			and PHYINVTH.INVTTYPE = 2
			and exists (select 1 from @Customer t where t.custno = detailno)	
 order by INVTTYPE,STARTTIME desc

end