
		-- =============================================
		-- Author:			Debbie
		-- Create date:		01/12/16
		-- Description:		Gathers the UniqPiHead for the Physical Inventory Selections for Internal and Complete
		-- Used On:			created to be used for parameter selection on the [phyws] mnxparamsources [PhyInvtUniqSelect]
		-- Modifications:	
		-- =============================================
create procedure [dbo].[GetPhyInvt2]
--declare
	@top int = null							-- if not null return number of rows indicated --08/14/2014 DRP Added
	,@paramFilter varchar(200) = ''			-- first 3+ characters entered by the user --08/14/2014 DRP Added
	--,@phytype numeric = 0					--0=All,1=Internal,2=Consigned,3=Instore
	,@lcPiStatus char(10) = 'In process'
	,@userId uniqueidentifier = null


as
begin


	if (@top is not null)
		select  top(@top) uniqpihead,rtrim(cast(STARTTIME as varCHAR(20)))+ '     '+ rtrim(DETAILNAME)  AS PhyInvtHeader
		from	PHYINVTH 
		where	PISTATUS = @lcPiStatus
				and PHYINVTH.INVTTYPE = 1
		order by INVTTYPE,STARTTIME desc
	else
		select	distinct	uniqpihead,rtrim(cast(STARTTIME as varCHAR(20)))+ '     '+ rtrim(DETAILNAME)  AS PhyInvtHeader
				,invttype,starttime
		from	phyinvth  
		where	PISTATUS = @lcPiStatus
				and PHYINVTH.INVTTYPE = 1
		order by INVTTYPE,STARTTIME desc

end