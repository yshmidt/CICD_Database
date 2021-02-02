
-- =============================================
-- Author:		<Debbie>
-- Create date: 08/27/2014
-- Description:	Compiles the data for the Physical Inventory Work Sheet
-- Used On:     phyws
-- Modified:	10/13/14 YS : replaced invtmfhd table with 2 new tables
-- Modified:	01/18/2016 Anuj K: Added missing parameters lcUniqSupNo and lcCustNo . . these params were needed in order to work with the passing of two parent params within a cascade start
--				01/18/16 DRP:  changed the left outer join to not have the "+" in it.  Also changed the Where clauses to not use the case when . . . 
--- 09/29/17 YS Location column
-- =============================================
CREATE procedure [dbo].[rptPhyInvtWorkSh]

-- 1/18/2016 Anuj K: Added missing parameters lcUniqSupNo and lcCustNo
	@lcUniqSupNo As char(10) = ''
	,@lcCustNo as char(10) = ''
	,@lcUniqPiHead AS char(10) = null
	,@lcLoc as int = 1		--1:All Locations, 0:Only Locations with qty > 0
	,@lcQtyOh as int = 1	--1:Print Qty OH, 0:Do Not Print Qty OH
	,@SortBy as int = 2		--1:Whse+Location+PN+Rev+LotCode, 2:PN+Rev+LotCode,3:Tag Number
	,@userId uniqueidentifier = null
	
as
begin	


/*CUSTOMER AND SUPPLIER LIST*/
DECLARE @LIST AS TABLE(UniqNum char(10),Name char(35))

		/*CUSTOMER LIST*/		
		DECLARE  @tCustomer as tCustomer
			--DECLARE @Customer TABLE (custno char(10))`--10/28/15 DRP:  we declared this but never really used it. 
			-- get list of customers for @userid with access
			INSERT INTO @tCustomer (Custno,CustName) 
		EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
				--SELECT * FROM @tCustomer	
		insert into @list select * from @tCustomer
		--select * from @list

		/*SUPPLIER LIST*/	
		-- get list of approved suppliers for this user
		DECLARE @tSupplier tSupplier

		INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, 'All';
		insert into @list select * from @tSupplier
		--select * from @list



/*RECORD SELECTION*/
	--- 09/29/17 YS Location column
SELECT	Part_no,Revision,inventor.Part_class,inventor.Part_type,Descript,inventor.U_of_meas,Part_sourc,case when @lcQtyOh = 1 then invtmfgr.QTY_OH else CAST (0.00 as numeric (12,2)) end as Qty_oh
		,Lotcode,Expdate,Reference,invtmfgr.Location,Warehouse,Partmfgr,Mfgr_pt_no,Sys_date as PhyInvtRunDate,Custpartno,Custrev,detailname,Tag_no,detailno,startno,endno,PHYINVTH.invttype,PARTTYPE.LOTDETAIL
FROM	Inventor 
		--  10/13/14 YS : replaced invtmfhd table with 2 new tables and use JOINS
		--left outer join PARTTYPE on inventor.PART_CLASS+inventor.PART_TYPE = PARTTYPE.PART_CLASS+PARTTYPE.PART_TYPE	--01/18/16 DRP:  replaced by the below
		left outer join parttype on inventor.part_class = parttype.PART_CLASS and inventor.part_type = parttype.part_type
		INNER JOIN Phyinvt ON Inventor.Uniq_key = Phyinvt.Uniq_key
		INNER JOIN PHYINVTH on phyinvt.uniqpihead = phyinvth.UNIQPIHEAD
		INNER JOIN Invtmfgr ON Phyinvt.W_key = Invtmfgr.W_key
		INNER JOIN warehous ON Invtmfgr.Uniqwh = Warehous.Uniqwh
		INNER JOIN Invtmpnlink L on Invtmfgr.Uniqmfgrhd = L.uniqmfgrhd
		inner join Mfgrmaster m on l.mfgrmasterid=m.mfgrmasterid 
WHERE	Phyinvt.Uniqpihead = @lcUniqPiHead
		and ((@lcloc= 0 and invtmfgr.Qty_oh <> 0) or (@lcloc = 1)) 
		and exists (select 1 from @list t where t.uniqnum = detailno)	
		--and 1 = case when CUSTNO in (select CUSTNO from @tCustomer) then 1 else 0 end		--01/18/16 DRP:  replaced by the above
order by	CASE @sortBy WHEN 1 THEN warehouse+invtmfgr.location+Part_no+Revision+Lotcode END,
			CASE  @sortBy WHEN 2 THEN Part_no+Revision+LotCode END, 
			CASE @sortBy WHEN 3  THEN Tag_No END
			
END