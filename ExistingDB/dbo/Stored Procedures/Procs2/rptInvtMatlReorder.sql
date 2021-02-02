
		-- =============================================
		-- Author:		<Yelena and Debbie>
		-- Create date: <12/22/2010,>
		-- Description:	<Compiles the details for the Inventory Material Re-order List>
		-- Used On:     <Crystal Report {icrpt1.rpt}>
		-- Modifications:	04/26/2013 DRP:  We needed to add code so that if the item on the po was flagged as cancelled that the report would then properly not consider that cancelled item as fulfilling the re-order demands.
		--					06/08/2015 DRP:  Needed to add @lcType, @lcCustNo and @useId parameters to the procedure.  Added the /*CUSTOMER LIST*/ section.  Broke the Consigned section into its own.   Added the Customer Name to the Consigned results
		--					07/28/2015 DRP:  Added the CUSTNAME field to the Internal Results so I could get the report to work with both Consigned and Internal
-- 07/16/18 VL changed custname from char(35) to char(50)
		-- =============================================
		CREATE PROCEDURE [dbo].[rptInvtMatlReorder]

--declare
		@lcType as char (20) = 'Internal'			--where the user would specify Internal, Internal & In Store, In Store, Consigned
		,@lcCustNo as varchar(max) = 'All'
		,@userId uniqueidentifier = null

		AS
		begin 

		/*CUSTOMER LIST*/		
		DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'Active' ;
		--SELECT * FROM @tCustomer	
		
		IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)
		ELSE

		IF  @lcCustNo='All'	
		BEGIN
			INSERT INTO @Customer SELECT CustNo FROM @tCustomer
		END

		/*RECORD SELECTION SECTION*/
		
	if (@lcType <> 'Consigned')
		begin
		-- 07/16/18 VL changed custname from char(35) to char(50)
		Select	t1.part_no, t1.revision, t1.CUSTNO, t1.PART_SOURC, t1.PART_CLASS, t1.PART_TYPE, t1.DESCRIPT, t1.U_OF_MEAS, t1.PUR_UOFM, t1.STDCOST
				,t1.buyer, t1.ORDMULT, t1.REORDERQTY, t1.REORDPOINT, t1.UNIQ_KEY, t1.INSTORE, t1.TotQty_Oh, t1.TotQty_Res, t1.AvailQty, t1.OnOrder
				,cast ('' as char (50)) as CUSTNAME
		
		from (	SELECT INVENTOR.PART_NO as part_no,
				INVENTOR.Revision as revision ,INVENTOR.CUSTNO,
				Inventor.Part_sourc,Part_class,Part_type,Descript,U_of_meas,Pur_uofm ,StdCost, CAST (buyer_type as CHAR(20)) as buyer, 
				MinOrd,OrdMult,Inventor.ReorderQty,Inventor.ReordPoint,Inventor.Uniq_key,INVTMFGR.INSTORE,
				SUM(InvtMfgr.Qty_oh) as TotQty_Oh ,SUM(InvtMfgr.Reserved) as TotQty_Res,SUM(InvtMfgr.Qty_oh) - SUM(InvtMfgr.Reserved) as AvailQty,
				dbo.fn_ConverQtyUOM(Inventor.PUR_UOFM,INVENTOR.U_OF_MEAS, isnull(z.OnOrder,CAST(0.00 as numeric(12,2)))) as OnOrder
				FROM	Invtmfgr,Inventor
						LEFT OUTER JOIN (SELECT SUM(Poitschd.Balance) AS OnOrder,Uniq_key 
										FROM Poitschd, Poitems, Pomain 
										WHERE Pomain.Ponum=Poitems.Ponum
										AND Pomain.PoStatus='OPEN'
										AND Poitems.Uniqlnno = Poitschd.Uniqlnno 
										--04/26/2013 DRP:  added the below
										and poitems.LCANCEL <> 1
										GROUP BY UNIQ_KEY) as Z ON INVENTOR.UNIQ_KEY = Z.UNIQ_KEY 
				WHERE	INVENTOR.UNIQ_KEY=INVTMFGR.UNIQ_KEY 
						AND Invtmfgr.Is_Deleted=0
						and INVENTOR.STATUS <> 'Inactive'
						and INVENTOR.REORDERQTY > 0
						and INVENTOR.REORDPOINT > 0
						AND INSTORE = CASE WHEN @lcType = 'Internal' then 0 when @lcType = 'In Store' then 1 when @lctype = 'Internal & In Store' then instore end	--06/08/2015 DRP:  Added
						and PART_SOURC <> 'CONSG'	--06/08/2015 DRP:  Added
				GROUP BY	INVENTOR.PART_NO,INVENTOR.Revision,INVENTOR.CUSTNO,
							PART_SOURC,Part_class,Part_type,Descript,U_of_meas,Pur_uofm ,StdCost,MinOrd,OrdMult,Inventor.ReorderQty,Inventor.ReordPoint,Inventor.Uniq_key,BUYER_TYPE,invtmfgr.INSTORE,z.OnOrder 
	
		) t1
		where	t1.AvailQty+t1.OnOrder<=t1.REORDPOINT order by	buyer, PART_CLASS, PART_TYPE, part_no, revision, UNIQ_KEY
	END	-- Internal or Instore End

	else if (@lcType = 'Consigned') 
	
	Begin
	Select	t1.part_no, t1.revision, t1.CUSTNO, t1.PART_SOURC, t1.PART_CLASS, t1.PART_TYPE, t1.DESCRIPT, t1.U_OF_MEAS, t1.PUR_UOFM, t1.STDCOST
				,t1.buyer, t1.ORDMULT, t1.REORDERQTY, t1.REORDPOINT, t1.UNIQ_KEY, t1.INSTORE, t1.TotQty_Oh, t1.TotQty_Res, t1.AvailQty, t1.OnOrder,t1.CUSTNAME
		
		from (	SELECT	INVENTOR.CUSTPARTNO as part_no,INVENTOR.CustRev as revision,INVENTOR.CUSTNO,Inventor.Part_sourc,Part_class,Part_type,Descript,U_of_meas
						,Pur_uofm ,StdCost, CAST (buyer_type as CHAR(20)) as buyer
						,MinOrd,OrdMult,Inventor.ReorderQty,Inventor.ReordPoint,Inventor.Uniq_key,INVTMFGR.INSTORE,
						SUM(InvtMfgr.Qty_oh) as TotQty_Oh ,SUM(InvtMfgr.Reserved) as TotQty_Res,SUM(InvtMfgr.Qty_oh) - SUM(InvtMfgr.Reserved) as AvailQty,
						dbo.fn_ConverQtyUOM(Inventor.PUR_UOFM,INVENTOR.U_OF_MEAS, isnull(z.OnOrder,CAST(0.00 as numeric(12,2)))) as OnOrder,CustName
				FROM	Invtmfgr,CUSTOMER,Inventor LEFT OUTER JOIN (SELECT	SUM(Poitschd.Balance) AS OnOrder,Uniq_key
															FROM	Poitschd, Poitems, Pomain 
															WHERE	Pomain.Ponum=Poitems.Ponum
																	AND Pomain.PoStatus='OPEN'
																	AND Poitems.Uniqlnno = Poitschd.Uniqlnno 
														--04/26/2013 DRP:  added the below
																	and poitems.LCANCEL <> 1
															GROUP BY UNIQ_KEY) as Z ON INVENTOR.UNIQ_KEY = Z.UNIQ_KEY 
				WHERE	INVENTOR.UNIQ_KEY=INVTMFGR.UNIQ_KEY 
						and inventor.CUSTNO = customer.CUSTNO
						AND Invtmfgr.Is_Deleted=0
						and INVENTOR.STATUS <> 'Inactive'
						and INVENTOR.REORDERQTY > 0
						and INVENTOR.REORDPOINT > 0
						and PART_SOURC = 'CONSG'	--06/08/2015 DRP: Added
						and 1 = case when inventor.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end

				GROUP BY INVENTOR.CUSTPARTNO, INVENTOR.CustRev ,INVENTOR.CUSTNO,PART_SOURC,Part_class,Part_type,Descript,U_of_meas,Pur_uofm ,StdCost,MinOrd,OrdMult
						,Inventor.ReorderQty,Inventor.ReordPoint,Inventor.Uniq_key,BUYER_TYPE,invtmfgr.INSTORE,z.OnOrder,CUSTNAME 
	
		) t1
		where	t1.AvailQty+t1.OnOrder<=t1.REORDPOINT order by	buyer, PART_CLASS, PART_TYPE, part_no, revision, UNIQ_KEY
	END	-- Consigned End

end