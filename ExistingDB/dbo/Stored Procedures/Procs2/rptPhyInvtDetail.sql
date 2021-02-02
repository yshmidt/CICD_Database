
	-- =============================================
	-- Author:			Debbie
	-- Create date:		01/12/2016
	-- Description:		Created for the Physical Inventory Detail 
	-- Reports:			phydtl 
	-- Modified:		01/18/16 DRP:  changed the left outer join to not have the "+" in it.  Also changed the Where clauses to not use the case when . . . 
	--					1/18/2016 Anuj K: Added missing parameters lcUniqSupNo and lcCustNo . . these params were needed in order to work with the passing of two parent params within a cascade start
	--					02/08/16 YS removed invtmfhd table and replaced with 2 new tables 
	--					12/06/16 DRP:  found that it was incorrectly taking the invtmfgr.qty_oh instead of the Phyinvt.Qty_OH when calculating the countVariance
	--									needed to add the CountValue and BookValue to the results.  It appears that they were there sometime in the past but were now missing.
	-- 08/15/17 VL  Added functional currency code
	--- 09/29/17 YS Location column 
	 --03/01/18 YS lotcode size change to 25
	 -- 09/26/19 YS modified part number/customer part number char(25) to char(35)
	-- =============================================
	CREATE PROCEDURE  [dbo].[rptPhyInvtDetail]


--declare
	-- 1/18/2016 Anuj K: Added missing parameters lcUniqSupNo and lcCustNo
	@lcUniqSupNo As char(10) = '',
	@lcCustNo as char(10) = '',
	@lcUniqPiHead AS char(10) = ''
	,@lcLoc as int = 1		--1:All Locations, 0:Only Locations with qty > 0
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


 --03/01/18 YS lotcode size change to 25
 -- 09/26/19 YS modified part number/customer part number char(25) to char(35)
declare @PhyInvt as table (Tag_no char(6),WAREHOUSE char(6),location char(17),part_no char(35), Revision char (8),PARTMFGR char(8),MFGR_PT_NO char(30),PART_CLASS char(8),PART_TYPE char(8)
							,lotcode char (25), CountQty numeric (13,2),BookQty numeric (13,2), CountVariance numeric(12,2), DollarVariance numeric (13,2),InvType char (10)
							,StartTime smalldatetime, PiStatus char(10), DetailName char(30),STARTNO char (25),ENDNO char (25),STDCOST numeric (13,5),CountValue numeric (13,5)	
							,BookValue	numeric (13,5),DollarVarGTotal numeric(13,2),CountGTotal numeric (13,2),BookGTotal Numeric(13,2)
							,DollarVariancePR numeric (13,2), StdcostPR numeric(13,5), CountValuePR numeric (13,5)	
							,BookValuePR numeric (13,5), DollarVarGTotalPR numeric(13,2),CountGTotalPR numeric (13,2),BookGTotalPR Numeric(13,2)
							,FSymbol char(3), PSymbol char(3), Uniq_key char(10))	--12/06/16 DRP:  created to help with calculating the GTotal Fields

/*RECORD SELECTION*/
-- 02/08/16 YS removed invtmfhd table and replaced with 2 new tables 
-- 08/15/17 VL added functional currency code
insert into @PhyInvt 
---09/29/17 YS specify table with location column
SELECT	Tag_no,WAREHOUSE,invtmfgr.location,case when part_sourc = 'CONSG' then CUSTPARTNO else part_no end as part_no,case when part_sourc = 'CONSG' then CUSTREV else Revision end as Revision
		,M.PARTMFGR,M.MFGR_PT_NO,inventor.PART_CLASS,inventor.PART_TYPE,lotcode	--12/06/16 DRP:  LotCode was missing from the results
		,PHYINVT.PHYCOUNT as CountQty,PHYINVT.qty_oh as BookQty,phyinvt.PHYCOUNT-PHYINVT.QTY_OH as CountVariance  --,phyinvt.phycount - invtmfgr.qty_oh as CountVariance --12/05/16 DRP:  found this error in the formula for CountVariance
		,case when PART_SOURC = 'CONSG' then 0.00 else cast(round((phycount-PHYINVT.qty_oh)*inventor.stdcost,2) as numeric (13,2)) end as DollarVariance
		,CASE WHEN PHYINVTH.InvtType = 1 THEN 'INTERNAL' ELSE CASE WHEN PHYINVTH.InvtType = 2 THEN 'CONSIGNED' ELSE 
			CASE WHEN PHYINVTH.InvtType = 3 THEN 'INSTORES' ELSE ' ' END END END AS InvType
		,PHYINVTH.StartTime, PHYINVTH.PiStatus, PHYINVTH.DetailName,PHYINVTH.STARTNO,PHYINVTH.ENDNO
		,INVENTOR.STDCOST
		,PHYINVT.PHYCOUNT * inventor.stdcost as CountValue	--12/06/16 DRP:  readded
		,PHYINVT.qty_oh * inventor.STDCOST as BookValue		--12/06/16 DRP:  Readded
		,cast(0.00 as numeric (13,5)) as DollarVarGTotal,cast(0.00 as numeric (13,5)) as CountGTotal, Cast (0.00 as numeric (13,5)) as BookGTotal	--12/06/16 DRP:  added the three Gtotal fields
		-- 08/15/17 VL added functional currency code
		,case when PART_SOURC = 'CONSG' then 0.00 else cast(round((phycount-PHYINVT.qty_oh)*inventor.stdcostPR,2) as numeric (13,2)) end as DollarVariancePR
		,INVENTOR.STDCOSTPR
		,PHYINVT.PHYCOUNT * inventor.stdcostPR as CountValuePR	--12/06/16 DRP:  readded
		,PHYINVT.qty_oh * inventor.STDCOSTPR as BookValuePR		--12/06/16 DRP:  Readded
		,cast(0.00 as numeric (13,5)) as DollarVarGTotalPR,cast(0.00 as numeric (13,5)) as CountGTotalPR, Cast (0.00 as numeric (13,5)) as BookGTotalPR
		,ISNULL(FF.Symbol,'') AS FSymbol, ISNULL(PF.Symbol,'') AS PSymbol, Inventor.Uniq_key
FROM	Inventor 
		--left outer join PARTTYPE on inventor.PART_CLASS+inventor.PART_TYPE = PARTTYPE.PART_CLASS+PARTTYPE.PART_TYPE	--01/18/16 DRP:  replaced by the below
		-- 02/08/16 YS removed invtmfhd table and replaced with 2 new tables  and usee INNER JOIN in place of WHERE
		INNER JOIN PHYINVT ON Inventor.Uniq_key = Phyinvt.Uniq_key
		INNER JOIN PhyInvth ON phyinvt.uniqpihead = phyinvth.UNIQPIHEAD
		INNER JOIN Invtmfgr On Phyinvt.W_key = Invtmfgr.W_key
		INNER JOIN Warehous ON Invtmfgr.Uniqwh = Warehous.Uniqwh
		INNER JOIN Invtmpnlink L On   Invtmfgr.Uniqmfgrhd=L.uniqmfgrhd
		INNER JOIN MfgrMaster M ON L.mfgrmasterid=M.mfgrmasterid
		left outer join parttype on inventor.part_class = parttype.PART_CLASS and inventor.part_type = parttype.part_type
		-- 08/15/17 VL added
		LEFT OUTER JOIN Fcused FF ON Inventor.FuncFcused_uniq = FF.Fcused_uniq
		LEFT OUTER JOIN Fcused PF ON Inventor.PrFcused_uniq = PF.Fcused_uniq	
WHERE	Phyinvt.Uniqpihead = @lcUniqPiHead
		and phyinvt.uniqpihead = phyinvth.UNIQPIHEAD
		and ((@lcloc= 0 and invtmfgr.Qty_oh <> 0) or (@lcloc = 1)) 
		and exists (select 1 from @list t where t.uniqnum = detailno)	
		--and 1 = case when CUSTNO in (select CUSTNO from @tCustomer) then 1 else 0 end		--01/18/16 DRP:  replaced by the above


/*CALCULATE THE GTOTALS*/
	-- 08/15/17 VL added functional currency code
	;with zTotal as (
	select sum(B.DollarVariance) as DollarVarGTotal, sum (B.countValue) as CountGTotal, sum(b.Bookvalue) as BookGTotal,
			sum(B.DollarVariancePR) as DollarVarGTotalPR, sum (B.countValuePR) as CountGTotalPR, sum(b.BookvaluePR) as BookGTotalPR from @phyInvt B)

	-- 08/15/17 VL added functional currency code
	update @phyInvt set DollarVarGTotal = z.DollarVarGTotal, CountGTotal = z.countGTotal, BookGTotal = z.BookGTotal,
						DollarVarGTotalPR = z.DollarVarGTotalPR, CountGTotalPR = z.countGTotalPR, BookGTotalPR = z.BookGTotalPR from ztotal as z

/*FINAL RESULTS SELECTION*/

-- 08/15/17 VL separate FC and non FC
/*----------------------
None FC installation
*/----------------------
IF dbo.fn_IsFCInstalled() = 0 
	BEGIN
		select Tag_no,WAREHOUSE,location,part_no, Revision,PARTMFGR,MFGR_PT_NO,PART_CLASS,PART_TYPE,lotcode, CountQty,BookQty, CountVariance, DollarVariance,InvType,StartTime, PiStatus, DetailName
				,STARTNO,ENDNO,STDCOST,CountValue,BookValue,DollarVarGTotal,CountGTotal,BookGTotal
				,case when F.BookGTotal <> 0.00 then cast (round(((f.DollarVarGTotal/F.BookGTotal) * 100),2) as numeric(5,2)) else  cast (0.00 as numeric(5,2)) end  as PerChange
		from	@phyinvt F
		order by	CASE @sortBy WHEN 1 THEN warehouse+location+Part_no+Revision+Lotcode END,
					CASE  @sortBy WHEN 2 THEN Part_no+Revision+LotCode END, 
					CASE @sortBy WHEN 3  THEN Tag_No END
	END
ELSE
/*-----------------
 FC installation
*/-----------------
	BEGIN
		select Tag_no,WAREHOUSE,location,part_no, Revision,PARTMFGR,MFGR_PT_NO,PART_CLASS,PART_TYPE,lotcode, CountQty,BookQty, CountVariance, DollarVariance,InvType,StartTime, PiStatus, DetailName
				,STARTNO,ENDNO,STDCOST,FSymbol,CountValue,BookValue,DollarVarGTotal,CountGTotal,BookGTotal,DollarVariancePR,StdcostPR,PSymbol,CountValuePR,BookValuePR, DollarVarGTotalPR,CountGTotalPR
				,BookGTotalPR
				,case when F.BookGTotal <> 0.00 then cast (round(((f.DollarVarGTotal/F.BookGTotal) * 100),2) as numeric(5,2)) else  cast (0.00 as numeric(5,2)) end  as PerChange
				,case when F.BookGTotalPR <> 0.00 then cast (round(((f.DollarVarGTotalPR/F.BookGTotalPR) * 100),2) as numeric(5,2)) else  cast (0.00 as numeric(5,2)) end  as PerChangePR
		from	@phyinvt F
		order by	CASE @sortBy WHEN 1 THEN warehouse+location+Part_no+Revision+Lotcode END,
					CASE  @sortBy WHEN 2 THEN Part_no+Revision+LotCode END, 
					CASE @sortBy WHEN 3  THEN Tag_No END
	END			

			
END