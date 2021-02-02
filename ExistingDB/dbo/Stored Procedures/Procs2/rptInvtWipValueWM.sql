

-- =============================================
-- Author:		<Debbie>
-- Create date: <01/20/2012,>
-- Description:	<Compiles the details for the Inventory and WIP Valuation reports>
-- Used On:     <Crystal Report {icrpt6.rpt}>
-- Modified:	09/25/2012 DRP:  added the micssys.lic_name within the Stored Procedure and removed it from the Crystal Report
-- 05/24/2013 DRP:  FOUND THAT IN SOME CASES THE USER COULD HAVE BLDQTY OF 0.00 AND YOU CAN NOT HAVE A DIVISOR OF 0.00. SO I HAD TO IMPLEMENT THE NULLIF(woentry.bldqty,0)
--	 09/13/2013 DRP:  per conversation with David/Yelena I went through and remove the '*' from the parameters   then added code how to handle null or '*'  should now work for both the CR and Stimulsoft reports
-- 	09/19/2013 DRP:  per request added the Part_Sourc and Buyer to the report results
-- 	10/11/2013 DRP:  Per discussion with Yelena we decided to create a separate procedure for WebManex(WM)so we could get the parameters to work properly on the WebManex without messing up the existing procedure for Crystal Reports. 
-- 	07/16/2014 DRP:  in the situation where the user had the Weighted Po set to 0 within the Inventory Setup,I needed to make sure that it would then use 5 as the weighted Po value.
-- 	09/26/2014 DRP:  Per Request we added the WipValue (WipQty * StdCost) and Total Value ((WipQty + QtyOh)*StdCost) to the end results. 
--  Also added the @userId Parameter
-- 	10/27/2014 DRP:  QtyShort,QtyInWip and rQtyInWip had a closing bracket in the incorrect location within the formula and it would cause these values to be extremly off. 
--  changed <<(sum(act_qty) + SUM(shortqty)/ nullif(woentry.bldqty,0))>> to be <<(sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0)>> 
-- 	01/27/2015 DRP:  Added @lcCostBy in order to control what cost is used when calculating the total values.  Added @lcRound in order to allow the user to control if they are rounded to the next integer or not
--  Needed to change the Part Class List to work properly
--  And changed the calculating fields a lot, They were not calculating properly before.
-- 	03/02/15 DRP: changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
-- 	06/05/2015 DRP:  Needed to change the @lcClass from varchar(8) to varchar(max)
-- 	06/11/2015 DRP:  Needed to filter out the CONSG parts from the results
-- 08/04/2015 YS:   Filter out records outside of given part range. Also chnaged the last SQL to check for wip qty as well as qty oh
-- if qtyoh =0 the reords were filtered out of the resulting set even though wip qty were present. 
-- Cleanup code. Removed some of the old comments
-- 12/14/15 DRP:	Needed to insert a new formula within the outer apply in the final select statement to make sure that it was calculating the Line shortage Qtys properly.  				
-- 12/27/15-01/01/16 YS try to optimize (vexos data could not finish running).  Now works faster for Vexos, but slower for other datasets. Will need more work
-- 02/18/16 DRP:	It was found that this version of the report was missing the line shortages from the QtyInWip fields.  
--  		within the last select section			--where zQtyInWip.QtyInWip <> 0.00		--02/18/2016 DRP:  REPLACED BY THE BELOW. 
--		     										WHERE	isnull(case when LINESHORT = 0 
--     												then case when QtyInWip < 0.00 then 0.00 else QtyInWip end 
--													else case when zqtyInWip.UNIQ_KEY = ParentUniq then ActQty + case when ShortQty < 0.00 then ShortQty else 0.00 end 
--													else ActQty+ case when ShortQty<0.00 then ShortQty else 0.00 end end end,0.00) <> 0.00
-- -- 05/18/16 -05/23/16	YS Modified code to eliminate extra calculations (need testing) and use #temp table to store 3 main results prior to link them, this seems solved speed issue 
-- 05/23/16 YS Fixed qtyInWip for the line shortage changed '-' to '+'
-- 02/22/17 DRP:  Found that I was including Non-Netable locations (example MRB locations) into the total Inventory Value	
-- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 05/01/17 DRP:  I should not have implemented the non-netable filter on 02/22/17.  I am removing it now 
-- 08/01/17 YS moved part_class setup from "support" table to partClass table 
-- 08/01/17 DRP:  Added the Presentational Currency columns to the results.
-- 11/15/17 VL:   Changed QtyOh from numeric(12,5) to numeric(12,2) @tResults, so won't get numeric overflow error
-- 07/12/19 VL changed from INNER JOIN to LEFT OUTER JOIN for non Func system
--				10/10/19 YS: part number char(35)
-- =============================================

CREATE PROCEDURE [dbo].[rptInvtWipValueWM]
--declare
	-- Add the parameters for the stored procedure here
		@lcClass as varchar (max) = 'All'
		,@lcUniq_keyStart char(10)=''
		--,@lcPartStart as varchar(25)=''		--03/02/15 DRP:  replaced by @lcUniq_keyStart
		--,@lcPartEnd as varchar(25)=''			--03/02/15 DRP:  replaced by @lcUniq_keyEnd
		,@lcUniq_keyEnd char(10)=''
		,@lcCostBy as char(16) = 'Standard'		--Standard, Last Paid, 'Weighted Average,User Define (this control which cost is used to calculate the Wip and Inventory Value	--01/27/2015 DRP:  Added
		,@lcRound as char(3) = 'No'				--Yes:  round QtyInWip to the nearest Interger No:  Don't round the QtyInWip	--01/27/2015 DRP: Added
		, @userId uniqueidentifier=null


as
begin

-- 08/01/17 DRP added to check if FC is installed or not
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

SET NOCOUNT ON;
-- 05/23/16 YS use local temp tables to save intermidiate results
	IF OBJECT_ID('tempdb..#tQtyOh') IS NOT NULL 
		drop table #tQtyOh;
	IF OBJECT_ID('tempdb..#tPoHist') IS NOT NULL 
	drop table #tPoHist;

	IF OBJECT_ID('tempdb..#tWipQty') IS NOT NULL 
	drop table #tWipQty;
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
	
	
/*PART CLASS LIST*/	--01/27/2015 DRP:  Added
	DECLARE @tPartClass TABLE (part_class char(8))
		Declare @Class table(part_class char(8))
		--08/01/17 YS moved part_class setup from "support" table to partClass table 
		insert into @tPartClass SELECT  PART_CLASS FROM partClass
	
		IF @lcClass is not null and @lcClass <>'' and @lcClass<>'All'
			insert into @Class select * from dbo.[fn_simpleVarcharlistToTable](@lcClass,',')
					where CAST (id as CHAR(10)) in (select part_class from @tPartClass)
		ELSE

		IF  @lcClass='All'	
		BEGIN
			INSERT INTO @Class SELECT Part_class FROM @tPartClass
		END

---05/18/16 YS declare @WipQty
--declare @wipQty table (uniq_key char(10),qtyInWip numeric(12,2))
--12/27/15 YS add a varaibale and assign ahead of time
declare @WEIGHTEDPO int = 5

select @WEIGHTEDPO=case when WEIGHTEDPO=0 or WEIGHTEDPO is null then 5 else WEIGHTEDPO end from INVTSETUP



--08/01/17 DRP:  added the tResults table
-- 11/15/17 VL changed QtyOh from numeric(12,5) to numeric(12,2) so won't get numeric overflow error
--				10/10/19 YS: part number char(35)
declare @tResults as table (uniq_key char(10),PART_NO Char(35),REVISION char(8),PART_CLASS char(8),PART_TYPE Char(8),DESCRIPT char(45),ABC char(1),PART_SOURC char (10),U_OF_MEAS char(4),stdcost numeric(12,5)
				,qtyoh numeric(12,2),QtyInWip numeric(12,5),FSymbol char(8),WipValue numeric(12,5),InvtValue numeric(12,5),TotalValue numeric(12,5),VerDate smalldatetime,LastPaid numeric(12,5),WghtAvg numeric(12,5)
				,UserDef numeric(12,5),buyer_type char(3),PSymbol char(8),stdcostPR numeric(12,5),WipValuePR numeric(12,5),InvtValuePR numeric(12,5),TotalValuePR numeric(12,5),LastPaidPR numeric(12,5),WghtAvgPR numeric(12,5)
				,UserDefPR numeric(12,5))


--declare @pohist table (uniq_key char(10),ord_qty numeric(10,2),COSTEACH NUMERIC (15,7),rn Int,TotQty numeric(12,2),TotExtended numeric (17,7),wAvgCost numeric(15,7),Verdate smalldatetime)

--declare @qtyOh table (uniq_key char(10),part_no char(25),revision char(8),part_class char(8),part_type char(8),descript char(45),abc char(1),
					--	PART_SOURC char(10),U_OF_MEAS char(8),STDCOST numeric(13,5),OTHER_COST numeric(13,5),
					--QtyOh numeric (13,2),QtyAlloc numeric(13,2),QtyNotNet numeric (12,2),BUYER_TYPE char(3))
--insert into @qtyOh
select inventor.uniq_key,part_no,revision,part_class,part_type,descript,abc,inventor.PART_SOURC,U_OF_MEAS,STDCOST,OTHER_COST
					,sum(mfgr1.qty_oh) as QtyOh,SUM(mfgr1.reserved) as QtyAlloc,CAST (0.00 as numeric (12,2)) as QtyNotNet,inventor.BUYER_TYPE
					,STDCOSTPR,OTHER_COSTPR ,FF.Symbol AS FSymbol, PF.Symbol AS PSymbol	--08/01/17 DRP:   Added	
					INTO #TqtyOh
					from	inventor 
							inner join INVTMFGR as mfgr1 on inventor.UNIQ_KEY = mfgr1.UNIQ_KEY
							-- 07/12/19 VL changed from INNER JOIN to LEFT OUTER JOIN for non Func system
							LEFT OUTER JOIN Fcused PF ON inventor.PrFcused_uniq = PF.Fcused_uniq	--08/01/17 DRP:  Added
							LEFT OUTER JOIN Fcused FF ON inventor.FuncFcused_uniq = FF.Fcused_uniq	--08/01/17 DRP:  Added
					where	inventor.STATUS = 'Active'
							-- 05/18/16 YS change <>1 to =0 for is_deleted and instrore
							and mfgr1.IS_DELETED = 0
							and mfgr1.INSTORE =0
							--- 05/18/16 change to avoid case
							--and PART_NO >= case when @lcPartStart = '' then PART_NO else @lcPartStart END
							--and PART_NO <= CASE WHEN @lcPartEnd = '' THEN PART_NO ELSE @lcPartEnd END
							and 
							(@lcPartStart='' OR PART_NO>=@lcPartStart)
							and (@lcPartEnd='' OR Part_no<=@lcPartEnd)
							--- 05/18/16 change to use =
							--AND PART_SOURC <> 'CONSG'	--06/10/2015 DRP:  Added
							and Part_sourc IN ('BUY','MAKE')
							--08/04/15 YS no need for the case here if we are using @class table just join or use exists
							--and 1 = case when Part_class in (select part_class from @class ) then 1 else 0 end
							and EXISTS (select 1 from @class c where inventor.PART_CLASS=c.part_class)
							--and mfgr1.netable = 1	--05/01/17 DRP:  removed --02/22/17 DRP:  Found that I was including Non-Netable locations							
					group by inventor.UNIQ_KEY,part_no,revision,part_class,part_type,descript,abc,
					PART_SOURC,U_OF_MEAS,STDCOST,OTHER_COST,BUYER_TYPE
					,STDCOSTPR,OTHER_COSTPR,ff.Symbol,pf.Symbol --08/01/17 DRP  Added PR fields
					
	--select * from #TqtyOh

	--- 8 seconds after modification, 40 seconds - before
	--select * from @qtyOh

			
	--,
	--08/04/15 YS get only records in the given part range and remove select * from ()
	
--insert into @PoHist
select Uniq_key, ord_qty ,COSTEACH ,rn,
sum(ORD_QTY) over (partition by uniq_key) as TotQty,
Sum(ORD_QTY*COSTEACH) over (partition by uniq_key) as TotExtended,
isnull(Sum(ORD_QTY*COSTEACH) over (partition by uniq_key)/nullif(sum(ORD_QTY) over (partition by uniq_key),0),0.00) as wAvgCost,
	Verdate
	,COSTEACHPR,Sum(ORD_QTY*COSTEACHPR) over (partition by uniq_key) as TotExtendedPR,
	isnull(Sum(ORD_QTY*COSTEACHPR) over (partition by uniq_key)/nullif(sum(ORD_QTY) over (partition by uniq_key),0),0.00) as wAvgCostPR	--08/01/17 DRP:  Added
	into #tPoHIst
	FROM
		(SELECT Pomain.Ponum,Pomain.VERDATE,Poitems.UNIQ_KEY ,Poitems.UNIQLNNO,poitems.ORD_QTY
						,poitems.COSTEACH,ROW_NUMBER() OVER(PARTITION BY Uniq_key ORDER BY Pomain.Verdate DESC) AS rn
						--,COSTEACH*ORD_QTY as Extended
						,POITEMS.COSTEACHPR	--08/01/17 DRP: Added
			FROM POMAIN 
			inner join POITEMS on pomain.PONUM=poitems.ponum 
			where	(pomain.POSTATUS = 'OPEN' or pomain.POSTATUS = 'CLOSED')
			and poitems.lcancel =0  and poitems.UNIQ_KEY <>' ' 
			and exists (select 1 from #TqtyOh Q where Q.UNIQ_KEY=poitems.UNIQ_KEY) ) P
			where p.rn <=  @WEIGHTEDPO 
---select * from #tPoHIst


			--select * from @qtyOh
		--- 44 seconds first run, 11 seconds second
		--select * from @pohist


	;
	with			
	zQtyInWip 
		
		as(
			select 	UNIQ_KEY,ActQty,LINESHORT,ShortQty,wono,balance
			,ParentUniq,bldqty,ReqPerBld,ReqPerEach,ReqPerBal,
			CASE WHEN ShortQty>0 and shortQty<ReqPerBal THEN ShortQty
			WHEN ShortQty<=0.00 THEN 0.00 ELSE ReqPerBal END QtyShort,
			--ReqPerBal-QtyShort as QtyInWip
			CAST(
			Case when @lcRound='No' THEN
				CASE WHEN LINESHORT=0 
				THEN
					ReqPerBal-
					CASE WHEN ShortQty>0 and shortQty<ReqPerBal THEN ShortQty
					WHEN ShortQty<=0.00 THEN 0.00 ELSE ReqPerBal END 
				WHEN LINESHORT=1 and UNIQ_KEY=ParentUniq and ShortQty<0  
					THEN
					-- pick min value between ActQty+ShortQty and Balance
					CASE WHEN ActQty+ShortQty<Balance THEN ActQty+ShortQty ELSE Balance END
				WHEN LINESHORT=1 and UNIQ_KEY=ParentUniq and ShortQty>=0  
					THEN
						-- pick min value between ActQty+ShortQty and Balance
						CASE WHEN ActQty<Balance THEN ActQty ELSE Balance END
				WHEN LINESHORT=1 and UNIQ_KEY<>ParentUniq and ShortQty<0
					-- 05/23/16 YS changed '-' to '+'
					THEN ActQty+ShortQty
				WHEN LINESHORT=1 and UNIQ_KEY<>ParentUniq and ShortQty>=0
					THEN ActQty
				END 
			
			ELSE  --- Case when @lcRound='No'
				--- @lcRound='Yes'
				CEILING(
				CASE WHEN LINESHORT=0 
				THEN
					ReqPerBal-
					CASE WHEN ShortQty>0 and shortQty<ReqPerBal THEN ShortQty
					WHEN ShortQty<=0.00 THEN 0.00 ELSE ReqPerBal END 
				WHEN LINESHORT=1 and UNIQ_KEY=ParentUniq and ShortQty<0  
					THEN
					-- pick min value between ActQty+ShortQty and Balance
					CASE WHEN ActQty+ShortQty<Balance THEN ActQty+ShortQty ELSE Balance END
				WHEN LINESHORT=1 and UNIQ_KEY=ParentUniq and ShortQty>=0  
					THEN
						-- pick min value between ActQty+ShortQty and Balance
						CASE WHEN ActQty<Balance THEN ActQty ELSE Balance END
				WHEN LINESHORT=1 and UNIQ_KEY<>ParentUniq and ShortQty<0
					-- 05/23/16 YS changed '-' to '+'
					THEN ActQty+ShortQty
				WHEN LINESHORT=1 and UNIQ_KEY<>ParentUniq and ShortQty>=0
					THEN ActQty	END)
			END as Numeric(12,2)) 
			as QtyInWip
			FROM(
					select	kamain.UNIQ_KEY,
					cast(SUM(act_qty) as numeric(12,2)) as ActQty,LINESHORT,
					cast(SUM(shortqty) as numeric(12,2)) as ShortQty,Woentry.wono,woentry.balance
					,woentry.UNIQ_KEY as ParentUniq,woentry.bldqty
					--- ReqPerBld=Act_qty+ShortQty
					,cast(SUM(act_qty) + SUM(shortqty) as numeric(12,2)) as ReqPerBld
					-- 05/18/16 YS added isnull()
					--- ReqPerEach=ReqPerBld/woentry.bldqty
					,cast(ISNULL((SUM(act_qty) + SUM(shortqty)) /nullif(woentry.bldqty,0),0.00) as numeric(25,13)) as ReqPerEach
					--05/18/16 YS this is wrong, the ReqPerEach has to be multiplied by the balance, not devided 
					--,(sum(act_qty) + SUM(shortqty))/nullif(woentry.bldqty * woentry.balance,0) as ReqPerBalD
					--- ReqPerBal=ReqPerBld*Woentry.Balance
					,cast(isnull(((sum(act_qty) + SUM(shortqty))/nullif(woentry.bldqty,0)) * woentry.balance,0.00) as numeric(25,13)) as ReqPerBal
					From	kamain
						inner join WOENTRY on KAMAIN.wono = woentry.WONO
						inner join #TqtyOh I on kamain.UNIQ_KEY = I.UNIQ_KEY
					where	woentry.openclos <> 'Closed' and woentry.openclos <>'Cancel'
					group by	kamain.uniq_key,lineshort,woentry.WONO,woentry.balance,woentry.UNIQ_KEY,woentry.BLDQTY
					) CalcWip
			)
			--select * from zQtyInWip
				select uniq_key,SUM(QtyInWip) as QtyInWip 
				INTO #tWipQty 
				from zQtyInWip group by UNIQ_KEY

--select * from #TqtyOh
--select * from #tPoHIst
--select * from #tWipQty
--select * from @qtyOh
--select * from @pohist
--select * from @wipQty

insert into @tResults			

				Select	t1.uniq_key,t1.PART_NO,t1.REVISION,t1.PART_CLASS,t1.PART_TYPE,t1.DESCRIPT,t1.ABC,t1.PART_SOURC,
				t1.U_OF_MEAS,
				t1.stdcost,
				t1.qtyoh,isnull(w1.QtyInWip,0.00) as QtyInWip,t1.FSymbol,
				case when @lcCostBy = 'Standard' then isnull(W1.QtyInWip,0.00)*t1.stdcost 
				when @lcCostBy = 'Last Paid' then isnull(W1.QtyInWip,0.00)*lastpaid.costeach 
				when @lcCostBy = 'Weighted Average' then isnull(w1.qtyinWip,0.00)* ISNULL(lastPaid.wAvgCost,CAST(0.00 as numeric(12,5)))
				else isnull(W1.QtyInWip,0.00)*t1.OTHER_COST end as WipValue	
				,ISNULL(case when @lcCostBy = 'Standard' then t1.qtyoh *t1.stdcost 
				when @lcCostBy = 'Last Paid' then  t1.qtyoh*lastpaid.costeach 
				when @lcCostBy = 'Weighted Average' then t1.qtyoh*ISNULL(lastPaid.wAvgCost,CAST(0.00 as numeric(12,5)))
				else t1.qtyoh*t1.OTHER_COST end,0.00) as InvtValue	--01/27/2015 DRP:  added InvtValue
				,case when @lcCostBy = 'Standard' then t1.qtyoh*t1.stdcost+isnull(W1.QtyInWip,0.00) *t1.stdcost 
				when @lcCostBy = 'Last Paid' then  t1.qtyoh*isnull(lastpaid.costeach,0.00) +isnull(W1.QtyInWip,0.00)*lastpaid.costeach 
				when @lcCostBy = 'Weighted Average' 
				then t1.qtyoh* ISNULL(lastPaid.wAvgCost,0.0)+isnull(W1.QtyInWip,0.00) * ISNULL(lastPaid.wAvgCost,0.00)
				else t1.qtyoh*t1.OTHER_COST+isnull(W1.QtyInWip,0.00)*t1.OTHER_COST end as TotalValue	
				,lastpaid.VerDate,ISNULL(lastpaid.costeach,0.00) as LastPaid,
				ISNULL(lastPaid.wAvgCost,CAST(0.00 as numeric(12,5))) as WghtAvg,
				t1.OTHER_COST as UserDef,t1.buyer_type
				,t1.PSymbol,t1.stdcostPR
				,case when @lcCostBy = 'Standard' then isnull(W1.QtyInWip,0.00)*t1.STDCOSTPR 
					when @lcCostBy = 'Last Paid' then isnull(W1.QtyInWip,0.00)*lastpaid.CostEachPR 
						when @lcCostBy = 'Weighted Average' then isnull(w1.qtyinWip,0.00)* ISNULL(lastPaid.wAvgCostPR,CAST(0.00 as numeric(12,5)))
							else isnull(W1.QtyInWip,0.00)*t1.OTHER_COSTPR end as WipValuePR	
				,ISNULL(case when @lcCostBy = 'Standard' then t1.qtyoh *t1.stdcostPR 
					when @lcCostBy = 'Last Paid' then  t1.qtyoh*lastpaid.CostEachPR 
						when @lcCostBy = 'Weighted Average' then t1.qtyoh*ISNULL(lastPaid.wAvgCostPR,CAST(0.00 as numeric(12,5)))
							else t1.qtyoh*t1.OTHER_COSTPR end,0.00) as InvtValuePR	
				,case when @lcCostBy = 'Standard' then t1.qtyoh*t1.STDCOSTPR+isnull(W1.QtyInWip,0.00) *t1.stdcostPR 
					when @lcCostBy = 'Last Paid' then  t1.qtyoh*isnull(lastpaid.costeachPR,0.00) +isnull(W1.QtyInWip,0.00)*lastpaid.costeachPR 
						when @lcCostBy = 'Weighted Average' 
							then t1.qtyoh* ISNULL(lastPaid.wAvgCostPR,0.0)+isnull(W1.QtyInWip,0.00) * ISNULL(lastPaid.wAvgCostPR,0.00)
								else t1.qtyoh*t1.OTHER_COSTPR+isnull(W1.QtyInWip,0.00)*t1.OTHER_COSTPR end as TotalValuePR	
				,ISNULL(lastpaid.costeachPR,0.00) as LastPaidPR,ISNULL(lastPaid.wAvgCostPR,CAST(0.00 as numeric(12,5))) as WghtAvgPR,t1.OTHER_COSTPR as UserDefPR	--08/01/2017 DRP: Added PR Fields
				from #tQtyOh t1
					LEFT OUTER JOIN #tPoHIst lastPaid ON T1.UNIQ_KEY = LastPaid.UNIQ_KEY and lastPaid.rn=1
				   LEFT OUTER JOIN #twipQty W1 ON t1.UNIQ_KEY = w1.UNIQ_KEY 
			where	t1.qtyoh <> 0.00 OR (W1.QtyInWip<>0.00 and W1.QtyInWip  IS NOT NULL)
				

/******************************/
/*NON FOREIGN CURRENCY SECTION*/
/******************************/
Begin
IF @lFCInstalled = 0
	BEGIN
	select	uniq_key,PART_NO,REVISION,PART_CLASS,PART_TYPE,DESCRIPT,ABC,PART_SOURC,U_OF_MEAS,stdcost
				,qtyoh,QtyInWip,WipValue,InvtValue,TotalValue,VerDate,LastPaid,WghtAvg
				,UserDef,buyer_type
	from	@tresults
	END
/**************************/
/*FOREIGN CURRENCY SECTION*/
/**************************/
	Else
	BEGIN 
	select	uniq_key,PART_NO,REVISION,PART_CLASS,PART_TYPE,DESCRIPT,ABC,PART_SOURC,U_OF_MEAS,stdcost
				,qtyoh,QtyInWip,FSymbol,WipValue,InvtValue,TotalValue,VerDate,LastPaid,WghtAvg
				,UserDef,buyer_type,PSymbol,stdcostPR,WipValuePR,InvtValuePR,TotalValuePR,LastPaidPR,WghtAvgPR
				,UserDefPR
	from	@tresults
	END

	end
	
	

end