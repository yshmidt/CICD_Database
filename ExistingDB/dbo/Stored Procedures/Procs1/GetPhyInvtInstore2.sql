
		-- =============================================
		-- Author:			Debbie
		-- Create date:		01/13/16
		-- Description:		Gathers the UniqPiHead for the Physical Inventory Selections for Instore and Complete
		-- Used On:			created to be used for parameter selection on the [phyws] mnxparamsources [PhyInvtUniqSelect]
		-- Modifications:	
		-- =============================================
create procedure [dbo].[GetPhyInvtInstore2]

--declare
	@top int = null						-- if not null return number of rows indicated --08/14/2014 DRP Added
	,@paramFilter varchar(200) = ''			-- first 3+ characters entered by the user --08/14/2014 DRP Added
	--,@phytype numeric = 0					--0=All,1=Internal,2=Consigned,3=Instore
	,@lcPiStatus char(10) = 'In process'
	,@lcUniqSupNo char(10) = 'All'
	,@userId uniqueidentifier = null

as
begin

/*SUPPLIER LIST*/
	---- SET NOCOUNT ON added to prevent extra result sets from
	---- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE  @tSupplier tSupplier
	declare @tSupNo as table (Uniqsupno char (10))
	-- get list of Suppliers for @userid with access
	INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, 'All';
	
	--- have to check for all suppliers @lcUniqSupNo for all no need to run [fn_simpleVarcharlistToTable], no data will be retuned
	IF @lcUniqSupNo is not null and @lcUniqSupNo <>'' and @lcUniqSupNo<>'All'
		insert into @tSupNo select * from dbo.[fn_simpleVarcharlistToTable](@lcUniqSupNo,',')
			where CAST (id as CHAR(10)) in (select Uniqsupno from @tSupplier)
	ELSE
	--- empty or null customer or part number means no selection were made
	IF  @lcUniqSupNo='All'	
	BEGIN
		INSERT INTO @tSupNo SELECT UniqSupno FROM @tSupplier	
	end


if (@top is not null)
	select	top(@top) uniqpihead,rtrim(cast(STARTTIME as varCHAR(20)))+ '     '+ rtrim(DETAILNAME)  AS PhyInvtHeader
	from	PHYINVTH 
	where	PISTATUS = @lcPiStatus
			and PHYINVTH.INVTTYPE = 3
			and exists (select 1 from @tSupNo t where t.Uniqsupno = detailno)
 order by INVTTYPE,STARTTIME desc
 
 else
		select	distinct uniqpihead,rtrim(cast(STARTTIME as varCHAR(20)))+ '     '+ rtrim(DETAILNAME)  AS PhyInvtHeader
				,invttype,starttime
		from	PHYINVTH 
		where	PISTATUS = @lcPiStatus
				and PHYINVTH.INVTTYPE = 3
				and exists (select 1 from @tSupNo t where t.Uniqsupno = detailno)
 order by INVTTYPE,STARTTIME desc
end