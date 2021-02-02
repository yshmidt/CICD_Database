

-- =============================================
-- Author:		<Yelena and Debbie>
-- Create date: <01/18/2012,>
-- Description:	<Compiles the details for the Inventory Valuation report>
-- Used On:     <Crystal Report {icrpt5.rpt}>
-- Modified:	09/13/2013 DRP:  per conversation with David/Yelena I went through and remove the '*' from the parameters   then added code how to handle null or '*'  should now work for both the CR and Stimulsoft reports
--				10/11/2013 DRP: Per discussion with Yelena we decided to create a separate procedure for WebManex(WM)so we could get the parameters to work properly on the WebManex without messing up the existing procedure for Crystal Reports. 
--  			07/16/2014 DRP:  in the situation where the user had the Weighted Po set to 0 within the Inventory Setup,I needed to make sure that it would then use 5 as the weighted Po value.
--				03/02/15 DRP: changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
--				05/20/2015 DRP:  removed the zQtyNotNet in order to not call the Inventor table a second time.    Also added @userId  Changed the @lcClass and @lcUniqWhse to be varchar(max).  Changed @lcUniqWhse to be @lcUniqWh
--				08/06/15 DRP:  reported that in some instances the Weighted Cost within the Inventory screen would be different from the Weighted Cost calculated for this report.  added <<ORDER BY Pomain.Verdate DESC,pomain.ponum desc>> to the zPoHist section
--				09/15/15 DRP:  Needed to add <<and inventor.PART_SOURC <> 'CONSG'>> to the zQtyNet section below.  Because in the case where they had  Consigned records with qty on hand, Part Number range it would display the Consigned info and be confusing to the users when they thought they were looking at the internal. 
--- 03/28/17 YS changed length of the part_no column from 25 to 35
---				08/01/17 YS attempt to speedup w/o much rewriting
-- 08/01/17 YS use temp tables in place of CTE. did not work on Paneng's data
-- 08/01/17 DPR:  Added the Presentational Currency columns to the results.
--08/01/17 YS moved part_class setup from "support" table to partClass table 
-- 11/15/17 VL changed QtyNet, QtyAlloc and QtyNotNet from numeric(12,5) to numeric(12,2) to avoid getting numerice overflow error
-- 04/29/19 VL added code to convert last paid and weighted to have correct unit cost, also added rount() to some fields
-- 07/12/19 VL changed from #LastPaid to zlastPaid, #Total to ztotal for PR fields, also changed from INNER JOIN to LEFT OUTER JOIN Fcused for non FUNC system 
--				10/10/19 YS: part number char(35)
-- ============================================
		CREATE PROCEDURE [dbo].[rptInvtValuationWM]
			-- Add the parameters for the stored procedure here
--declare
				@lcClass as varchar (max) = 'All'
				,@lcUniqWh as varchar (max) = 'All'
				,@lcUniq_keyStart char(10)=''
				--,@lcPartStart as varchar(25)=''		--03/02/15 DRP:  replaced by @lcUniq_keyStart
				--,@lcPartEnd as varchar(25)=''			--03/02/15 DRP:  replaced by @lcUniq_keyEnd
				,@lcUniq_keyEnd char(10)=''
				,@lcCostBy as char(16) = 'Standard Cost'		--Standard, Last Paid, 'Weighted Average,User Define (this control which cost is used to calculate the Wip and Inventory Value	--05/20/2015 DRP:  Added
				,@userId uniqueidentifier= null			--05/20/2015 DRP:  Added



		as
		begin


-- 08/01/17 DRP added to check if FC is installed or not
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

/*PART RANGE*/		
	--03/02/15 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
	declare @lcPartStart char(35)='',@lcRevisionStart char(8)='',
	@lcPartEnd char(35)='',@lcRevisionEnd char(8)=''
		
	--03/02/15 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key	
	--09/13/2013 DRP: If null or '*' then pass ''
	IF  @lcUniq_keyStart IS NULL or  @lcUniq_keyStart ='' 
		SELECT @lcPartStart=' ', @lcRevisionStart=' '
	ELSE
	SELECT @lcPartStart = ISNULL(I.Part_no,' '), 
		@lcRevisionStart = ISNULL(I.Revision,' ') 
	FROM Inventor I where Uniq_key=@lcUniq_keyStart
		
	-- find ending part number
	IF  @lcUniq_keyEnd IS NULL or  @lcUniq_keyEnd =''
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
		SELECT @lcPartEnd = REPLICATE('Z',35), @lcRevisionEnd=REPLICATE('Z',8)
	ELSE
		SELECT @lcPartEnd =ISNULL(I.Part_no,' '), 
			@lcRevisionEnd = ISNULL(I.Revision,' ') 
		FROM Inventor I where Uniq_key=@lcUniq_keyEnd	

/*PART CLASS LIST*/			
DECLARE @PartClass TABLE (part_class char(8))
	IF @lcClass is not null and @lcClass <>'' and @lcClass <> 'All'
		INSERT INTO @PartClass SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcClass,',')
			
	else
	if @lcClass = 'All'
	begin
	--08/01/17 YS moved part_class setup from "support" table to partClass table
		insert into @PartClass SELECT PART_CLASS FROM partClass
	end	

/*WAREHOUSE LIST*/
		--09/13/2013 DRP:  added code to handle Warehouse List
			declare @Whse table(Uniqwh char(10))
			if @lcUniqWh is not null and @lcUniqWh <> '' AND @lcUniqWh <> 'All'
				insert into @Whse select * from dbo.[fn_simpleVarcharlistToTable](@lcUniqWh,',')

			else

			if @lcUniqWh = 'All'
			Begin
				insert into @Whse select uniqwh from WAREHOUS
			end


--08/01/17 DRP:  added the tResults table
-- 11/15/17 VL changed QtyNet, QtyAlloc and QtyNotNet from numeric(12,5) to numeric(12,2) to avoid getting numerice overflow error
--				10/10/19 YS: part number char(35)
declare @tResults as table (uniq_key char(10),PART_NO Char(35),REVISION char(8),PART_CLASS char(8),PART_TYPE Char(8),DESCRIPT char(45),ABC char(1),U_OF_MEAS char(4),uniqwh char(10),warehouse char(6),CostedBy numeric(12,5),QtyNet numeric(12,2)
				,QtyAlloc numeric(12,2),QtyNotNet numeric(12,2),NetValue numeric(12,5),NotNetValue numeric(12,5),VerDate smalldatetime,stdcost numeric(12,5),StdNet numeric(12,5),StdNotNet numeric(12,5)
				,LastPaid numeric(12,5),LPNet numeric(12,5),LPNotNet numeric(12,5),WAvg numeric(12,5),WNet numeric(12,5),WNotNet numeric(12,5),UserDef numeric(12,5),UDNet numeric(12,5),UDNotNet numeric(12,5)
				,CostedByPR numeric(12,5),NetValuePR numeric(12,5),NotNetValuePR numeric(12,5),stdcostPR numeric(12,5),StdNetPR numeric(12,5),StdNotNetPR numeric(12,5),LastPaidPR numeric(12,5),LPNetPR numeric(12,5)
				,LPNotNetPR numeric(12,5),WAvgPR numeric(12,5),WNetPR numeric(12,5),WNotNetPR numeric(12,5),UserDefPR numeric(12,5),UDNetPR numeric(12,5),UDNotNetPR numeric(12,5),FSymbol char(8),PSymbol char(8))



--08/01/17 use temp table in place of CTE
		if OBJECT_ID('tempdb..#QtyNet') is not null
		drop table #qtyNet;
		--;
		--with	zQtyNet as (
		-- 11/15/17 VL changed QtyNet, QtyAlloc and QtyNotNet from numeric(12,5) to numeric(12,2) to avoid getting numerice overflow error
		select inventor.uniq_key,part_no,revision,part_class,part_type,descript,abc,U_OF_MEAS,w1.UNIQWH,w1.WAREHOUSE,STDCOST,OTHER_COST
							,case when mfgr1.NETABLE = 1 then sum(mfgr1.qty_oh) else cast (0.00 as numeric(12,2)) end as QtyNet
							,case when mfgr1.NETABLE = 1 then SUM(mfgr1.reserved) else cast (0.00 as numeric(12,2)) end as QtyAlloc
							,case when mfgr1.NETABLE = 1 then cast (0.00 as numeric (12,2)) else sum(mfgr1.QTY_OH) end as QtyNotNet
							--,IIF(mfgr1.NETABLE=1, sum(mfgr1.qty_oh), cast (0.00 as numeric (12,5)) ) as QtyNet	--05/20/2015 DRP: replaced by the above
							--,IIF(mfgr1.NETABLE=1,SUM(mfgr1.reserved), cast (0.00 as numeric (12,5)) ) as QtyAlloc	--05/20/2015 DRP: replaced by the above
							--,IIF(mfgr1.NETABLE=1,CAST (0.00 as numeric (12,5)), SUM(mfgr1.qty_oh))as QtyNotNet	--05/20/2015 DRP: replaced by the above
							,STDCOSTPR,OTHER_COSTPR,FF.Symbol AS FSymbol, PF.Symbol AS PSymbol	--08/01/17 DRP:   Added

							INTO #qtyNet
							from	inventor 
									inner join INVTMFGR as mfgr1 on inventor.UNIQ_KEY = mfgr1.UNIQ_KEY
									left outer join WAREHOUS as w1 on mfgr1.UNIQWH = w1.UNIQWH
									-- 07/12/19 VL changed from INNER JOIN to LEFT OUTER JOIN for non Func
									LEFT JOIN Fcused PF ON inventor.PrFcused_uniq = PF.Fcused_uniq	--08/01/17 DRP:  Added
									LEFT JOIN Fcused FF ON inventor.FuncFcused_uniq = FF.Fcused_uniq	--08/01/17 DRP:  Added																	
							where	
							--08/01/17 YS no need for neatble
							---mfgr1.NETABLE in(1,0)
									--mfgr1.NETABLE = 1		--05/20/2015 DRP:  replaced by the above
									 inventor.STATUS = 'Active'
									 ---08/01/17 YS change from <>1 to =0
									and mfgr1.IS_DELETED = 0
									and mfgr1.INSTORE = 0
									and mfgr1.QTY_OH <> 0.00
									---08/01/17 YS change to remove case
									--and 1 = case when @lcClass = '' then 1 when PART_CLASS IN(select PART_CLASS from @PartClass) then 1 else 0 end  
									--and 1 = case when @lcUniqWh = '' then 1 when w1.UNIQWH IN(select UNIQWH from @Whse) then 1 else 0 end 
									AND (@lcClass='' OR (PART_CLASS IN (select PART_CLASS from @PartClass)))
									AND ( @lcUniqWh = '' OR (w1.UNIQWH IN (select UNIQWH from @Whse)))
									AND ( @lcPartStart='' OR Part_no>=@lcPartStart)
									AND (@lcPartEnd='' OR Part_no<=@lcPartEnd)
									---08/01/17 YS change to remove case
									--and Part_no>= case when @lcPartStart='' then Part_no else @lcPartStart END
									--and PART_NO<= CASE WHEN @lcPartEnd='' THEN PART_NO ELSE @lcPartEnd END
									and inventor.PART_SOURC <> 'CONSG'	--09/15/15 DRP:  Added
							group by mfgr1.NETABLE,inventor.UNIQ_KEY,part_no,revision,part_class,part_type,descript,abc,U_OF_MEAS,w1.UNIQWH,w1.WAREHOUSE,STDCOST,OTHER_COST	--05/20/2015 DRP:  added mfgr1.netable to the group by
									,STDCOSTPR,OTHER_COSTPR,ff.Symbol,PF.Symbol --08/01/17 DRP:  added STDCOSTPR & OTHER_COSTPR
						--)
							--,
			---zPoHist as	(	
			if OBJECT_ID('tempdb..#PoHist') is not null
						drop table #PoHist;		
			
			--SELECT * FROM 
								SELECT	Pomain.Ponum,Pomain.VERDATE,Poitems.UNIQ_KEY ,Poitems.UNIQLNNO
											-- 04/29/19 VL added to convert to UOM
											--,poitems.ORD_QTY
											,dbo.fn_ConverQtyUOM(Poitems.PUR_UOFM, U_of_meas,Poitems.Ord_qty) AS Ord_qty		
											-- 04/29/19 VL added to convert costeach to uom, also added rount(,5)
											--,poitems.COSTEACH
											,ROUND(ISNULL(dbo.fn_convertPrice('Pur',Poitems.CostEach,Poitems.Pur_Uofm,U_OF_MEAS),CAST(0.00000 as numeric(12,5))),5) AS CostEach																	
											,ROW_NUMBER() OVER(PARTITION BY Uniq_key ORDER BY Pomain.Verdate DESC,pomain.ponum desc) AS rn		--08/06/15 DRP:  added pomain.ponum desc to the order by
											,COSTEACH*ORD_QTY as Extended
											,POITEMS.CostEachPR,POITEMS.CostEachPR*ORD_QTY AS ExtendedPR	--08/01/17 DRP:  added the PR fields
									INTO #PoHist
									FROM	POMAIN 
											inner join POITEMS on pomain.PONUM=poitems.ponum 
									where	(pomain.POSTATUS = 'OPEN' or pomain.POSTATUS = 'CLOSED')
											---08/01/17 YS change <>1 to =0
											--and poitems.lcancel <> 1 
											and poitems.lcancel = 0
											and poitems.UNIQ_KEY <>' ' 
											
											
						--	)
			--				,
			--zTotal as	(


						if OBJECT_ID('tempdb..#Total') is not null
						drop table #Total;	

							select uniq_key,sum (ord_qty) as TOrdQty,SUM(extended)as TExtended,sum(extendedPR) as TExtendedPR	--08/01/17 DRP:  added TExtendedPR
							INTO #Total
							from #PoHist,INVTSETUP
							--  where	rn <= WEIGHTEDPO	/*07/16/2014 DRP:  IN THE CASE WEIGHTEDPO WAS 0 IT NEEDED TO THEN DEFAULT 5 AS THE FALUE*/
							--08/01/17 YS remove case
							where  (INVTSETUP.WEIGHTEDPO=0 and rn<=5 ) OR (rn <=INVTSETUP.weightedpo)
							--rn <= case when WEIGHTEDPO = 0 then 5 else weightedpo end
							group by UNIQ_KEY,WEIGHTEDPO
										
			--zLastPaid as(

							if OBJECT_ID('tempdb..#LastPaid') is not null
						drop table #LastPaid;	

						select uniq_key, verdate,costeach,CostEachPR	--08/01/17 DRP:  added CostEachPR
						INTO #LastPaid	
							from #PoHist
							where rn = 1
							--)

	insert into @tResults
		-- 04/29/19 VL added ROUNT(,2) for cost values
		-- 07/12/19 VL changed from #LastPaid to zlastPaid, #Total to ztotal for PR fields 
		select	t1.uniq_key,t1.PART_NO,t1.REVISION,t1.PART_CLASS,t1.PART_TYPE,t1.DESCRIPT,t1.ABC,t1.U_OF_MEAS,t1.uniqwh,t1.warehouse
				,ROUND(case when @lcCostBy = 'Standard' then t1.STDCOST else
					case when @lcCostBy =  'Last Paid' then ISNULL(zlastpaid.costeach,0.00) else
						case when @lcCostBy = 'Weighted Average' then ISNULL(zTotal.TExtended/TOrdQty,CAST(0.00 as numeric(12,5))) else t1.OTHER_COST end end end,5) as CostedBy
				,SUM(t1.qtynet) as QtyNet,SUM(t1.qtyAlloc)as QtyAlloc, SUM(t1.QtyNotNet)as QtyNotNet 
				
				,ROUND(case when @lcCostBy = 'Standard' then cast (SUM(t1.QtyNet * t1.STDCOST) as numeric (12,5)) else
					case when @lcCostBy =  'Last Paid' then ISNULL(sum(t1.qtynet*zlastpaid.costeach),cast(0.00000 as numeric (12,5))) else
						case when @lcCostBy = 'Weighted Average' then ISNULL(zTotal.TExtended/TOrdQty,CAST(0.00000 as numeric(12,5))) else CAST(sum(t1.qtynet * t1.other_cost) as numeric (12,5)) end end end,2) as NetValue

				,ROUND(case when @lcCostBy = 'Standard' then cast (SUM(t1.QtyNotNet * t1.STDCOST) as numeric (12,5)) else
					case when @lcCostBy =  'Last Paid' then ISNULL(sum(t1.QtyNotNet*zlastpaid.costeach),cast(0.00000 as numeric (12,5))) else
						case when @lcCostBy = 'Weighted Average' then ISNULL(sum(t1.qtynotnet*(ztotal.textended/tordqty)),CAST(0.00 as numeric(12,5))) else CAST(sum(t1.QtyNotNet * t1.other_cost) as numeric (12,5)) end end end,2) as NotNetValue
				
				,zlastpaid.VerDate	
				,t1.stdcost,ROUND(cast (SUM(t1.QtyNet * t1.STDCOST) as numeric (12,2)),2) as StdNet, ROUND(CAST (sum(t1.qtynotnet * t1.stdcost) as numeric (12,2)),2) as StdNotNet
				,ISNULL(zlastpaid.costeach,0.00) as LastPaid,ISNULL(sum(t1.qtynet*zlastpaid.costeach),cast(0.00 as numeric (12,5)))as LPNet
				,ISNULL(sum(t1.qtynotnet * zLastPaid.costeach),CAST(0.00 as numeric (12,5)))as LPNotNet,ISNULL(zTotal.TExtended/TOrdQty,CAST(0.00 as numeric(12,5))) as WAvg
				,ISNULL(sum(t1.qtynet*(ztotal.textended/tordqty)),CAST(0.00 as numeric(12,5)))as WNet,ISNULL(sum(t1.qtynotnet*(ztotal.textended/tordqty)),CAST(0.00 as numeric(12,5))) as WNotNet
				,t1.OTHER_COST as UserDef,CAST(sum(t1.qtynet * t1.other_cost) as numeric (12,2)) as UDNet, CAST(sum(t1.qtynotnet * t1.OTHER_COST) as numeric(12,2)) as UDNotNet

				,case when @lcCostBy = 'Standard' then t1.STDCOSTPR else
					case when @lcCostBy =  'Last Paid' then ISNULL(zlastpaid.costeachPR,0.00) else
						case when @lcCostBy = 'Weighted Average' then ISNULL(zTotal.TExtendedPR/TOrdQty,CAST(0.00 as numeric(12,5))) else t1.OTHER_COSTPR end end end as CostedByPR
				,case when @lcCostBy = 'Standard' then cast (SUM(t1.QtyNet * t1.STDCOSTPR) as numeric (12,5)) else
					case when @lcCostBy =  'Last Paid' then ISNULL(sum(t1.qtynet*zlastpaid.CostEachPR),cast(0.00000 as numeric (12,5))) else
						case when @lcCostBy = 'Weighted Average' then ISNULL(zTotal.TExtendedPR/TOrdQty,CAST(0.00000 as numeric(12,5))) else CAST(sum(t1.qtynet * t1.other_costPR) as numeric (12,5)) end end end as NetValuePR
				,case when @lcCostBy = 'Standard' then cast (SUM(t1.QtyNotNet * t1.STDCOSTPR) as numeric (12,5)) else
					case when @lcCostBy =  'Last Paid' then ISNULL(sum(t1.QtyNotNet*zlastpaid.costeachPR),cast(0.00000 as numeric (12,5))) else
						case when @lcCostBy = 'Weighted Average' then ISNULL(sum(t1.qtynotnet*(zTotal.TExtendedPR/tordqty)),CAST(0.00 as numeric(12,5))) else CAST(sum(t1.QtyNotNet * t1.OTHER_COSTPR) as numeric (12,5)) end end end as NotNetValuePR
				,t1.stdcostPR,cast (SUM(t1.QtyNet * t1.STDCOSTPR) as numeric (12,2)) as StdNetPR,CAST (sum(t1.qtynotnet * t1.stdcostPR) as numeric (12,2)) as StdNotNetPR
				,ISNULL(zlastpaid.CostEachPR,0.00) as LastPaidPR,ISNULL(sum(t1.qtynet*zlastpaid.CostEachPR),cast(0.00 as numeric (12,5)))as LPNetPR
				,ISNULL(sum(t1.qtynotnet * zlastpaid.costeachPR),CAST(0.00 as numeric (12,5)))as LPNotNetPR,ISNULL(zTotal.TExtendedPR/TOrdQty,CAST(0.00 as numeric(12,5))) as WAvgPR
				,ISNULL(sum(t1.qtynet*(zTotal.TExtendedPR/tordqty)),CAST(0.00 as numeric(12,5)))as WNetPR,ISNULL(sum(t1.qtynotnet*(zTotal.textendedPR/tordqty)),CAST(0.00 as numeric(12,5))) as WNotNetPR
				,t1.OTHER_COSTPR as UserDefPR,CAST(sum(t1.qtynet * t1.other_costPR) as numeric (12,2)) as UDNetPR, CAST(sum(t1.qtynotnet * t1.OTHER_COSTPR) as numeric(12,2)) as UDNotNetPR,t1.FSymbol,t1.PSymbol	--08/01/17 DRP:  added all of the PR fields
				
		from 
			(
			select #QtyNet.* from #QtyNet
			--union all		--05/20/2015 DRP:  Removed and included in zQtyNet
			--select zQtyNotNet.* from zQtyNotNet	--05/20/2015 DRP:  Removed and included in zQtyNet
			) t1 LEFT OUTER JOIN #LastPaid as zLastPaid ON T1.UNIQ_KEY = zLastPaid.UNIQ_KEY 
				 left outer join #Total as zTotal on t1.UNIQ_KEY = zTotal.UNIQ_KEY
				 --cross join MICSSYS	--05/20/2015 DRP:  Removed

		group by t1.UNIQ_KEY, t1.PART_NO,t1.REVISION,t1.PART_CLASS,t1.PART_TYPE,t1.DESCRIPT,t1.abc,t1.U_OF_MEAS,UNIQWH,WAREHOUSE,t1.STDCOST,zlastpaid.VerDate
				,zLastPaid.COSTEACH,t1.OTHER_COST,zTotal.TExtended,TOrdQty
				,t1.STDCOSTPR,zlastpaid.CostEachPR,t1.other_costPR,zTotal.TExtendedPR/TOrdQty,FSymbol,PSymbol	--08/01/17 DRP:  added the PR fields to the group by

/******************************/
/*NON FOREIGN CURRENCY SECTION*/
/******************************/
Begin
IF @lFCInstalled = 0
	BEGIN
	select	uniq_key,PART_NO,REVISION,PART_CLASS,PART_TYPE,DESCRIPT,ABC,U_OF_MEAS,uniqwh,warehouse,CostedBy,QtyNet,QtyAlloc ,QtyNotNet ,NetValue ,NotNetValue ,VerDate,stdcost ,StdNet ,StdNotNet
			,LastPaid ,LPNet ,LPNotNet ,WAvg ,WNet ,WNotNet ,UserDef ,UDNet ,UDNotNet 
	from	@tresults
	END
/**************************/
/*FOREIGN CURRENCY SECTION*/
/**************************/
	Else
	BEGIN 
	select	uniq_key,PART_NO,REVISION,PART_CLASS,PART_TYPE,DESCRIPT,ABC,U_OF_MEAS,uniqwh,warehouse,CostedBy,QtyNet,QtyAlloc ,QtyNotNet ,NetValue ,NotNetValue ,VerDate,stdcost ,StdNet ,StdNotNet
			,LastPaid ,LPNet ,LPNotNet ,WAvg ,WNet ,WNotNet ,UserDef ,UDNet ,UDNotNet,CostedByPR ,NetValuePR ,NotNetValuePR ,stdcostPR ,StdNetPR ,StdNotNetPR ,LastPaidPR ,LPNetPR
			,LPNotNetPR ,WAvgPR ,WNetPR ,WNotNetPR ,UserDefPR ,UDNetPR ,UDNotNetPR ,FSymbol,PSymbol 
	from	@tresults
	END
end		

		end