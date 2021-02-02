

-- =============================================
-- Author:		<Debbie>
-- Create date: <04/05/2012>
-- Description:	Compiled for the Purchase Costs Against a Project/Work Order report
-- Reports:     used on po4woprj.rpt
-- Modified:  09/25/2014 DRP:  added @userId in order to properly filter out Suppliers the user is approved to view.
--							 Added the Supplier List 
--							 Changed the Fields that are displayed in the results to work with the QuickViews better. 
--			09/26/2014 DRP:  Added the CUSTOMER lIST to the procedure in order to make sure that we only display Customer Work ORders that the user is approved to see
--							 Then had to add WoEntry and CustNo to the ZWoPrj so I could later filter off of the Custno.  then added the Custno filter at the end of each section.
--			12/12/14 DS Added supplier status filter
--			01/06/2015 DRP:  Added @customerStatus Filter
--			02/20/17 DRP:	added part_class,part_type, Descript,costeach and requesttp per user request
-- =============================================
CREATE PROCEDURE [dbo].[rptPo4WoPrj] 

	@lcWoPrj varchar(10) = 'Work Order'			-- the user will either enter in Project or Work Order
	,@lcRecord as varchar (max) = 'All'	-- If Work Order is selected the user can either leave default '*' for all Work orders, or they can enter in the individual Work order #
										-- If Project is selected then the user can either leave default '*' for all Project, or they can enter in the individual Project #. 
	,@userId uniqueidentifier = null
	,@supplierStatus varchar(20) = 'All'
	,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
as
Begin

/*SUPPLIER LIST*/	
-- get list of approved suppliers for this user
DECLARE @tSupplier tSupplier
declare @tSupNo as table (Uniqsupno char (10))
	INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, @supplierStatus ;
	insert into @tSupno  select UniqSupno from @tSupplier

/*CUSTOMER LIST*/	--09/26/2014 DRP:  needed to add Customer List in order to make sure that the results are filtered off of approve customers for userid
	DECLARE  @tCustomer as tCustomer
			DECLARE @Customer TABLE (custno char(10))
		-- get list of Customers for @userid with access
		INSERT INTO @tCustomer EXEC aspmnxSP_Getcustomers4user @userid,null,@customerStatus ;
		--SELECT * FROM @tCustomer	
		INSERT INTO @Customer SELECT Custno FROM @tCustomer


/*RECORD LIST*/
--allow @lcRecord to have multiple csv
declare  @Record table (Record char(10))
	if @lcRecord<>'All' and @lcRecord<>'' and @lcRecord is not null
		insert into @Record  select * from  dbo.[fn_simpleVarcharlistToTable](@lcrecord,',')

/*SELECT STATEMENT*/
--Will go through and find all PO schedule items that are allocated to a Work Order

if (@lcWoPrj = 'Work Order')
	begin	--WorkOrder Begin
		;
		with ZWoPrj as 
			(
			select	poitschd.UNIQLNNO,requesttp,woprjnumber,custno,SUM(schd_qty) as SumSchdqty
			from	POITSCHD,woentry	--09/26/2014 DRP:  added woentry table and custno
			where	poitschd.WOPRJNUMBER = woentry.wono
					and REQUESTTP = 'WO Alloc'
			group by	poitschd.UNIQLNNO,REQUESTTP,WOPRJNUMBER,custno
			)

		select	ZWoPrj.WOPRJNUMBER as WorkOrder,CASE WHEN POITEMS.UNIQ_KEY = '' THEN POITEMS.PART_NO ELSE INVENTOR.PART_NO END AS Part_No
				,case when poitems.UNIQ_KEY = '' then CAST ('' as CHAR(8)) else inventor.REVISION end as Rev,poitems.ItemNo
				,POITEMS.PartMfgr,poitems.Mfgr_Pt_No,poitems.PoNum,pomain.PoDate,zwoprj.SumSchdqty as Ord_qty
				,ZWoPrj.SumSchdqty*COSTEACH as ExtCost	
				,inventor.part_class,inventor.part_type, inventor.descript,costeach,requesttp	--02/20/17 DRP:  added
		from	POMAIN
				inner join POITEMS on pomain.ponum = poitems.ponum
				left outer join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY
				inner join ZWoPrj on poitems.UNIQLNNO = ZWoPrj.UNIQLNNO	
		where	poitems.LCANCEL <> 1
				and 1= case WHEN UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
				and 1 = case when @lcRecord = 'All' then 1 when ZWoPrj.WOPRJNUMBER IN(select record from @Record) then 1 else 0 end
				and 1 = case when zwoprj.CUSTNO IN (select CUSTNO from @Customer) then 1 else 0 end	--09/26/2014 DRP:  Added to filter wo's user is approved to view customer
		order by REQUESTTP,WOPRJNUMBER,PONUM
	end		--WorkOrder End

--Will go through and find all po schedule items allocated to a Project	
else if (@lcWoPrj = 'Project') 
	begin	--Project Begin
		;
		with ZWoPrj as 
			(
			select	poitschd.UNIQLNNO,requesttp,woprjnumber,custno,SUM(schd_qty) as SumSchdqty
			from	POITSCHD,pjctmain
			where	poitschd.WOPRJNUMBER = PJCTMAIN.PRJNUMBER
					and REQUESTTP = 'Prj Alloc'
			group by	poitschd.UNIQLNNO,REQUESTTP,WOPRJNUMBER,custno
			)

		select	ZWoPrj.WOPRJNUMBER as Project,CASE WHEN POITEMS.UNIQ_KEY = '' THEN POITEMS.PART_NO ELSE INVENTOR.PART_NO END AS Part_No
				,case when poitems.UNIQ_KEY = '' then CAST ('' as CHAR(8)) else inventor.REVISION end as Revision,poitems.ItemNo
				,POITEMS.PartMfgr,poitems.Mfgr_Pt_No,poitems.PoNum,pomain.PoDate,zwoprj.SumSchdqty as Ord_qty
				,ZWoPrj.SumSchdqty*COSTEACH as ExtCost
				,inventor.part_class,inventor.part_type, inventor.descript,costeach,requesttp	--02/20/17 DRP:  added
		from	POMAIN
				inner join POITEMS on pomain.ponum = poitems.ponum
				left outer join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY
				inner join ZWoPrj on poitems.UNIQLNNO = ZWoPrj.UNIQLNNO	
		where	poitems.LCANCEL <> 1
				and 1= case WHEN UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
				and 1 = case when @lcRecord = 'All' then 1 when ZWoPrj.WOPRJNUMBER IN(select record from @Record) then 1 else 0 end
				and 1 = case when zwoprj.CUSTNO IN (select CUSTNO from @Customer) then 1 else 0 end	--09/26/2014 DRP:  Added to filter wo's user is approved to view customer
		order by REQUESTTP,WOPRJNUMBER,PONUM
	end		--Project End

/*****/
/*09/25/2014 DRP:  Removed the below statement to be replaced by the above.*/ 
--Will go through and find all PO schedule items that are allocated to a Work Order
--if (@lcWoPrj = 'Work Order')
--	begin
--	;
--	with
--	ZWoPrj as 
--			(
--	select	poitschd.UNIQLNNO,requesttp,woprjnumber,SUM(schd_qty) as SumSchdqty
--	from	POITSCHD
--	where	REQUESTTP = 'WO Alloc'
--	group by	poitschd.UNIQLNNO,REQUESTTP,WOPRJNUMBER
--			)
--	select	poitems.PONUM,pomain.CONUM,pomain.PODATE,poitems.ITEMNO,case when poitems.uniq_key = '' then cast ('' as char(8))else inventor.PART_CLASS end as Part_class
--				,case when poitems.uniq_key = '' then cast ('' as char(8)) else inventor.part_type end as PART_TYPE
--				,CASE WHEN POITEMS.UNIQ_KEY = '' THEN POITEMS.PART_NO ELSE INVENTOR.PART_NO END AS PART_NO
--				,case when poitems.UNIQ_KEY = '' then CAST ('' as CHAR(8)) else inventor.REVISION end as revision
--				,case when poitems.UNIQ_KEY = '' then poitems.DESCRIPT else inventor.DESCRIPT end as DESCRIPT
--				,zwoprj.SumSchdqty as Ord_qty,POITEMS.PARTMFGR,poitems.MFGR_PT_NO,poitems.COSTEACH,ZWoPrj.SumSchdqty*COSTEACH as ExtCost,ZWoPrj.REQUESTTP,ZWoPrj.WOPRJNUMBER
--	from	POMAIN
--			inner join POITEMS on pomain.ponum = poitems.ponum
--			left outer join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY
--			inner join ZWoPrj on poitems.UNIQLNNO = ZWoPrj.UNIQLNNO	
--	where	poitems.LCANCEL <> 1
--			and WOPRJNUMBER LIKE CASE WHEN @lcRecord='*' THEN '%' ELSE dbo.padl(@lcRecord,10,'0') END
--	order by REQUESTTP,WOPRJNUMBER,PONUM
--	end

----Will go through and find all po schedule items allocated to a Project	
--else if (@lcWoPrj = 'Project') 
--	begin
--	;
--	with
--	ZWoPrj as 
--			(
--	select	poitschd.UNIQLNNO,requesttp,woprjnumber,SUM(schd_qty) as SumSchdqty
--	from	POITSCHD
--	where	REQUESTTP = 'Prj Alloc'
--	group by	poitschd.UNIQLNNO,REQUESTTP,WOPRJNUMBER
--			)
--	select	poitems.PONUM,pomain.CONUM,pomain.PODATE,poitems.ITEMNO,case when poitems.uniq_key = '' then cast ('' as char(8))else inventor.PART_CLASS end as Part_class
--				,case when poitems.uniq_key = '' then cast ('' as char(8)) else inventor.part_type end as PART_TYPE
--				,CASE WHEN POITEMS.UNIQ_KEY = '' THEN POITEMS.PART_NO ELSE INVENTOR.PART_NO END AS PART_NO
--				,case when poitems.UNIQ_KEY = '' then CAST ('' as CHAR(8)) else inventor.REVISION end as revision
--				,case when poitems.UNIQ_KEY = '' then poitems.DESCRIPT else inventor.DESCRIPT end as DESCRIPT
--				,zwoprj.SumSchdqty as Ord_qty,POITEMS.PARTMFGR,poitems.MFGR_PT_NO,poitems.COSTEACH,ZWoPrj.SumSchdqty*COSTEACH as ExtCost,ZWoPrj.REQUESTTP,ZWoPrj.WOPRJNUMBER
--	from	POMAIN
--			inner join POITEMS on pomain.ponum = poitems.ponum
--			left outer join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY
--			inner join ZWoPrj on poitems.UNIQLNNO = ZWoPrj.UNIQLNNO	
--	where	poitems.LCANCEL <> 1
--			and WOPRJNUMBER LIKE CASE WHEN @lcRecord='*' THEN '%' ELSE @lcRecord+'%' END
--	order by REQUESTTP,WOPRJNUMBER,PONUM
--	end
/*09/25/2014 DRP End of Removal*/

end