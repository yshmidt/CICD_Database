

-- =============================================
-- Author:		<Debbie>
-- Create date: <01/24/2012,>
-- Description:	<Compiles the details for the Inventory and WIP Valuation by work order reports>
-- Used On:     <Crystal Report [invtwipw.rpt]>
-- Modified:	05/24/2013 DRP:  FOUND THAT IN SOME CASES THE USER COULD HAVE BLDQTY OF 0.00 AND YOU CAN NOT HAVE A DIVISOR OF 0.00. SO I HAD TO IMPLEMENT THE NULLIF(woentry.bldqty,0)
-- 09/13/2013 DRP:  per conversation with David/Yelena I went through and remove the '*' from the parameters   then added code how to handle null or '*'  should now work for both the CR and Stimulsoft reports
-- 11/06/2013 DRP:  found in scenario where the part has not yet been picked in full(still has shortage), but the qty moved into FGI for the product is greater than short qty for that part that it would result in - values in the qtyinwip 
-- 11/08/2013 DRP:  needed to insert code so that it would populate 0.00 for wip qty if no WIP records were found. 
-- 11/20/2013 DRP:  It was found that CR had an issue for records that had qty in wip for both normal item and a line shortage.  The procedure results were correct
--   but for some reason CR was doubling up the Qty and inventory values.  To address the issue we added the LineShortage field to the final results. 
-- 12/05/2013 DRP: Per discussion with Yelena we decided to create a separate procedure for WebManex(WM)so we could get the parameters to work properly on the WebManex without messing up the existing procedure for Crystal Reports. 
-- 04/24/2014 DRP:  The QtyInWip values where incorrectly display the entire build qty instead of the Qty in WIP when it came to  Work Orders for RMA's  
-- 07/16/2014 DRP:  in the situation where the user had the Weighted Po set to 0 within the Inventory Setup,I needed to make sure that it would then use 5 as the weighted Po value.
-- 09/26/2014 DRP:  per request added the WipValue (WipQty * StdCost) to the results
-- 10/27/2014 DRP:  QtyShort,QtyInWip and rQtyInWip had a closing bracket in the incorrect location within the formula and it would cause these values to be extremly off. 
--   changed <<(sum(act_qty) + SUM(shortqty)/ nullif(woentry.bldqty,0))>> to be <<(sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0)>>
-- 12/08/2014 DRP:  user reported that there were three columns missing from the XLS output compared to VFP.  Act_qty,LineShort, ShortQty.  Made the modifications below to add them back into the results so they will be included in the QuickView results.  
-- 12/16/2014 DRP:  user reported that there were two columns missing from the XLS output compared to VFP.  BldQty and Balance.  Made the modifications below to add them back into the results so they will be included in the QuickView results.  
-- 03/02/15 DRP: changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
-- 09/11/15 DRP:  changed @lcClass from varchar(8) to varchar(max) . . . also needed to change <<and 1 = case when @lcWono = 'All' then 1 when woentry.WONO IN(WONO from @WoNo) then 1 else 0 end>>  TO BE <<and 1 = case when @lcWono = 'All' then 1 when woentry.WONO IN(select dbo.PADL(WONO,10,'0') from @WoNo) then 1 else 0 end>> because the cloud was not passing the leading zeros
-- 10/26/15 DRP:  was found that for some reason the StimulSoft report was having problems summing on the formula field within Stimulsoft.  So I did the formula Calculation here within the procedure instead.  
-- 			   Added CostBy field as reference within the QuickView so the users know what the WipValue is calculated off of.   
-- 			   Needed to add the @lcCostBy and @lcRound parameters to the procedure itself instead of them only controlled within the StimulSoft Report form. 
-- 12/14/15 DRP:  Found that there was a problem with how the WipValue was being calculated when it came to Line Shortages.  The QtyInWip for line shortages were showing the correct whole number, but the WIP Value was incorrectly taking the fraction of a number when calculating
-- 			   So I actually too the Ending Select statement and inserted it into zFinal and change the ending select statement to calculate the Wip Value using the already Calculated qty's within the ZFinal instead of having to repeat the formula used to get the QtyInWip over and over again within the WipValue formula. 
-- 05/20/15 DRP:  added the Custname to the results per request of the users.   Added /*CUSTOMER LIST*/
-- 08/04/16 DRP:  took the same type of changes that Yelena had made agains the rptInvtWipValueWM procedure back on 05/18/16 and implemented them on this procedure also.
--  Modified code to eliminate extra calculations (need testing) and use #temp table to store 3 main results prior to link them, this seems solved speed issue 
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 06/28/17 DRP:  found that we had the Part Number Range as a parameter,but we did not have the where statement to filter on that parameter
-- 08/09/17 DRP:  added the Presentational Currency to results --	Also noticed that the @lcWoNo Parameter filter was not working properly.  Needed to fix the /*WORK ORDER LIST*/ and /*PART CLASS LIST*/ then insert the correct filters in the lower sections
-- 07/12/19 VL added Fcused table that were not copied when the presentational currency code was added
--				10/10/19 YS: part number char(35)
-- 01/02/20 VL added back WO selection that was in old code, but not in new code
-- =============================================
		CREATE PROCEDURE [dbo].[rptInvtWipByWoWM]
			-- Add the parameters for the stored procedure here
--declare	
			@lcClass as varchar (max) = 'All'
				,@lcWoNo as varchar(max) = 'All'
				,@lcUniq_keyStart char(10)=''
				--,@lcPartStart as varchar(25)=''	--03/02/15 DRP:  replaced by @lcUniq_keyStart
				--,@lcPartEnd as varchar(25)=''		--03/02/15 DRP:  replaced by @lcUniq_keyEnd
				,@lcUniq_keyEnd char(10)=''
				,@lcCostBy char(20) = 'Standard'	--10/26/15 DRP:  added:  Standard, Last Paid, Weighted Average, User Define
				,@lcRound char(3) = 'Yes'			--10/26/15 DRP:  added Yes or No
				,@userId uniqueidentifier = null

		as
		begin

-- 08/09/17 DRP added to check if FC is installed or not
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

SET NOCOUNT ON;
-- 08/04/16 DRP use local temp tables to save intermidiate results (copied YS change from rptInvtWipValueWM)
	IF OBJECT_ID('tempdb..#tPoHist') IS NOT NULL 
	drop table #tPoHist;
	IF OBJECT_ID('tempdb..#tWipQty') IS NOT NULL 
	drop table #tWipQty;


/*PART RANGE*/		
	--03/02/15 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
	--				10/10/19 YS: part number char(35)
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
		SELECT @lcPartEnd = REPLICATE('Z',25), @lcRevisionEnd=REPLICATE('Z',8)
	ELSE
		SELECT @lcPartEnd =ISNULL(I.Part_no,' '), 
			@lcRevisionEnd = ISNULL(I.Revision,' ') 
		FROM Inventor I where Uniq_key=@lcUniq_keyEnd	
			
--/*PART CLASS LIST*/	--08/09/17 DRP:  replaced with the below list		
--		-- 09/13/2013 YS/DRP added code to handle class list
--			DECLARE @PartClass TABLE (part_class char(8))
--			IF @lcClass is not null and @lcClass <>'' and @lcClass <>'All'
--				INSERT INTO @PartClass SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcClass,',')
				
--				select * from @partClass	

/*PART CLASS LIST*/
DECLARE @PartClass TABLE (part_class char(8))
	IF @lcClass is not null and @lcClass <>'' and @lcClass <> 'All'
		INSERT INTO @PartClass SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcClass,',')
			
	else
	if @lcClass = 'All'
	begin
		insert into @PartClass SELECT TEXT2 AS PART_CLASS FROM SUPPORT WHERE FIELDNAME = 'PART_CLASS'
	end	
--select * from @PartClass



/*CUSTOMER LIST*/	--05/20/2016 DRP:  Added 	
	DECLARE  @tCustomer as tCustomer
		--DECLARE @Customer TABLE (custno char(10))`--10/28/15 DRP:  we declared this but never really used it. 
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer


--/*WORK ORDER LIST*/	--08/09/17 DRP:  replaced with the below work order list
--		--09/13/2013 DRP:  added code to handle Wo List
--			declare @WoNo table(WoNo char(10))
--			if @lcWoNo is not null and @lcWoNo <> ''
--				insert into @WoNo select * from dbo.[fn_simpleVarcharlistToTable] (@lcWoNo,',')
--		select * from @WoNo

/*WORK ORDER LIST*/
declare @tWono as tWono
	declare @Wono table(wono char(10),custno char(10),openclos char(10))
	insert into @Wono select distinct wono, custno,openclos from View_Wo4Qa W where w.custno in (select custno from @tCustomer)
	--select * from @Wono
	--Get list of work order the user is approved to view based off of the approved Customer listing
	if @lcwono is not null and @lcWoNo <> '' and @lcWoNo <> 'All'
		insert into @tWono select * from dbo.[fn_simpleVarcharlistToTable](@lcwono,',')
	else
	if @lcWoNo = 'All'
		Begin 
			insert into @tWono select wono from @Wono
		end
--select * from @tWono order by wono

--08/04/16 DRP:  added 
declare @WEIGHTEDPO int = 5
select @WEIGHTEDPO=case when WEIGHTEDPO=0 or WEIGHTEDPO is null then 5 else WEIGHTEDPO end from INVTSETUP

--08/09/17 DRP:  added the tResults table
--				10/10/19 YS: part number char(35)
declare @tResults as table (uniq_key char(10),PART_NO Char(35),REVISION char(8),PART_CLASS char(8),PART_TYPE Char(8),DESCRIPT char(45),U_OF_MEAS char(4),LINESHORT BIT,WONO CHAR(10)
							,QtyInWip numeric(12,5),WipValue numeric(12,5),VerDate smalldatetime,FSymbol char(8),stdcost numeric(12,5),LastPaid numeric(12,5),WghtAvg numeric (12,5)
							,UserDef numeric(12,5),Actqty numeric(12,5),Shortqty numeric(12,5),Bldqty numeric(12,5),balance numeric(12,5),CostBy char(15),CUSTNAME char(35)
							,PSymbol char(8),WipValuePR numeric(12,5),stdcostPR numeric(12,5),LastPaidPR numeric(12,5),WghtAvgPR numeric(12,5),UserDefPR numeric(12,5),CostedByValue numeric(12,5),CostedByValuePR numeric(12,5))

		--;
		--with	

--insert into @PoHist	--08/04/16 DRP:  replaced the zPoHist
select	Uniq_key, ord_qty ,COSTEACH ,rn,
		sum(ORD_QTY) over (partition by uniq_key) as TotQty,
		Sum(ORD_QTY*COSTEACH) over (partition by uniq_key) as TotExtended,
		isnull(Sum(ORD_QTY*COSTEACH) over (partition by uniq_key)/nullif(sum(ORD_QTY) over (partition by uniq_key),0),0.00) as wAvgCost,Verdate
		,COSTEACHPR,Sum(ORD_QTY*COSTEACHPR) over (partition by uniq_key) as TotExtendedPR
		,isnull(Sum(ORD_QTY*COSTEACHPR) over (partition by uniq_key)/nullif(sum(ORD_QTY) over (partition by uniq_key),0),0.00) as wAvgCostPR
into #tPoHIst
FROM
		(SELECT	Pomain.Ponum,Pomain.VERDATE,Poitems.UNIQ_KEY ,Poitems.UNIQLNNO,poitems.ORD_QTY
				,poitems.COSTEACH,ROW_NUMBER() OVER(PARTITION BY Uniq_key ORDER BY Pomain.Verdate DESC) AS rn
				,poitems.CostEachPR
		 FROM	POMAIN
				inner join POITEMS on pomain.PONUM=poitems.ponum 
		 where	(pomain.POSTATUS = 'OPEN' or pomain.POSTATUS = 'CLOSED')
				and poitems.lcancel <> 1 and poitems.UNIQ_KEY <>' ' 
		 ) P where p.rn <=  @WEIGHTEDPO
		  
/*08/04/16 DRP:  replaced with the above		
			--;
			--with	
			--zPoHist as	(	SELECT * FROM 
			--					(	SELECT	Pomain.Ponum,Pomain.VERDATE,Poitems.UNIQ_KEY ,Poitems.UNIQLNNO,poitems.ORD_QTY
			--								,poitems.COSTEACH,ROW_NUMBER() OVER(PARTITION BY Uniq_key ORDER BY Pomain.Verdate DESC) AS rn
			--								,COSTEACH*ORD_QTY as Extended
			--						FROM	POMAIN 
			--								inner join POITEMS on pomain.PONUM=poitems.ponum 
			--						where	(pomain.POSTATUS = 'OPEN' or pomain.POSTATUS = 'CLOSED')
			--								and poitems.lcancel <> 1 and poitems.UNIQ_KEY <>' ' ) AS t   
											
			--				)
End 08/04/16 replacement*/

;With 
			zTotal as	(
							select distinct uniq_key,Totqty as TOrdQty,TotExtended as TExtended,TotExtendedPR as TExtendedPR
							from #tPoHist,INVTSETUP
							where	rn <= case when WEIGHTEDPO = 0 then 5 else weightedpo end
						)
 
/*08/04/16 DRP:  Replaced with the above zTotal
			zTotal as	(
							select uniq_key,sum (ord_qty) as TOrdQty,SUM(extended)as TExtended
							from zPoHist,INVTSETUP
							--  where	rn <= WEIGHTEDPO	/*07/16/2014 DRP:  IN THE CASE WEIGHTEDPO WAS 0 IT NEEDED TO THEN DEFAULT 5 AS THE FALUE*/
							where	rn <= case when WEIGHTEDPO = 0 then 5 else weightedpo end
							group by UNIQ_KEY,WEIGHTEDPO
						)
08/04/16 Replacement end*/
						,
										
			zLastPaid as(
							select uniq_key, verdate,costeach,CostEachPR
							from #tPoHist
							where rn = 1
							)

						,

			zQtyInWip as(
							select	UNIQ_KEY,ActQty,LINESHORT,ShortQty,wono,balance,ParentUniq,bldqty,ReqPerBld,ReqPerEach,ReqPerBal,
									CASE WHEN ShortQty>0 and shortQty<ReqPerBal THEN ShortQty WHEN ShortQty<=0.00 THEN 0.00 ELSE ReqPerBal END QtyShort,
									CAST(Case when @lcRound='No' THEN
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
								as QtyInWip,Custname
							FROM(
									select	kamain.UNIQ_KEY,
									cast(SUM(act_qty) as numeric(12,2)) as ActQty,LINESHORT,
									cast(SUM(shortqty) as numeric(12,2)) as ShortQty,Woentry.wono,woentry.balance
									,woentry.UNIQ_KEY as ParentUniq,woentry.bldqty
									,cast(SUM(act_qty) + SUM(shortqty) as numeric(12,2)) as ReqPerBld
									,cast(ISNULL((SUM(act_qty) + SUM(shortqty)) /nullif(woentry.bldqty,0),0.00) as numeric(25,13)) as ReqPerEach
									,cast(isnull(((sum(act_qty) + SUM(shortqty))/nullif(woentry.bldqty,0)) * woentry.balance,0.00) as numeric(25,13)) as ReqPerBal
									,custname
									From	kamain
										inner join WOENTRY on KAMAIN.wono = woentry.WONO
										inner join customer on woentry.CUSTNO = customer.CUSTNO
									where	woentry.openclos <> 'Closed' and woentry.openclos <>'Cancel'
									-- 01/02/20 VL added back WO selection that was in old code, but not in new code
									and 1 = case when @lcWono = 'All' then 1 when woentry.WONO IN(select dbo.PADL(WONO,10,'0') from @tWono) then 1 else 0 end
									group by	kamain.uniq_key,lineshort,woentry.WONO,woentry.balance,woentry.UNIQ_KEY,woentry.BLDQTY,custname
									) CalcWip
			)
			--select * from zQtyInWip
				select uniq_key,SUM(QtyInWip) as QtyInWip,wono,LINESHORT,ParentUniq,ActQty,ShortQty,BLDQTY,BALANCE,CUSTNAME
				INTO #tWipQty 
				from zQtyInWip group by UNIQ_KEY,wono,lineshort,ParentUniq,ActQty,ShortQty,BLDQTY,BALANCE,CUSTNAME
				--select * from #tWipQty
	

/*08/04/16 DRP:  Replaced with the above zQtyInWIP
--						,
--			zQtyInWip as(
--							select	kamain.UNIQ_KEY,PART_NO,REVISION,part_class,Part_type,descript,u_of_meas,stdcost,other_cost,SUM(act_qty) as ActQty,LINESHORT,SUM(shortqty) as ShortQty,Woentry.wono,woentry.balance
--								,woentry.UNIQ_KEY as ParentUniq,woentry.bldqty
--								,SUM(act_qty) + SUM(shortqty) as ReqPerBld
--								,(SUM(act_qty) + SUM(shortqty)) / nullif(woentry.bldqty,0) as ReqPerEach
--								,(sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance as ReqPerBal
--								,case when SUM(shortqty)>0.00 and SUM(shortqty) <= (sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance then SUM(shortqty) else
--									case when SUM(shortqty)<=0.00 then 0.00 else (sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance end end as QtyShort 
--								,(sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance - case when SUM(shortqty)>0.00 and SUM(shortqty) <= (sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance then SUM(shortqty) else
--									case when SUM(shortqty)<=0.00 then 0.00 else (sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance end end as QtyInWip
--								,ceiling((sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance - case when SUM(shortqty)>0.00 and SUM(shortqty) <= (sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance then SUM(shortqty) else
--									case when SUM(shortqty)<=0.00 then 0.00 else (sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance end end) as rQtyInWip		
--								,CUSTNAME					
--/*10/27/2014 DRP:				,case when SUM(shortqty)>0.00 and SUM(shortqty) <= (sum(act_qty) + SUM(shortqty)/ nullif(woentry.bldqty,0)) * woentry.balance then SUM(shortqty) else
--									case when SUM(shortqty)<=0.00 then 0.00 else (sum(act_qty) + SUM(shortqty)/ nullif(woentry.bldqty,0)) * woentry.balance end end as QtyShort 
--								,(sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance - case when SUM(shortqty)>0.00 and SUM(shortqty) <= (sum(act_qty) + SUM(shortqty)/ nullif(woentry.bldqty,0)) * woentry.balance then SUM(shortqty) else
--									case when SUM(shortqty)<=0.00 then 0.00 else (sum(act_qty) + SUM(shortqty)/ nullif(woentry.bldqty,0)) * woentry.balance end end as QtyInWip
--								,ceiling((sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance - case when SUM(shortqty)>0.00 and SUM(shortqty) <= (sum(act_qty) + SUM(shortqty)/ nullif(woentry.bldqty,0)) * woentry.balance then SUM(shortqty) else
--									case when SUM(shortqty)<=0.00 then 0.00 else (sum(act_qty) + SUM(shortqty)/ nullif(woentry.bldqty,0)) * woentry.balance end end) as rQtyInWip	--10/27/2014 DRP:  END*/			--05/24/2013 DRP:  FOUND THAT IN SOME CASES THE USER COULD HAVE BLDQTY OF 0.00 AND YOU CAN NOT HAVE A DIVISOR OF 0.00. SO I HAD TO IMPLEMENT THE NULLIF(woentry.bldqty,0) above
--								--,(SUM(act_qty) + SUM(shortqty)) / woentry.bldqty as ReqPerEach
--								--,(sum(act_qty) + SUM(shortqty))/ woentry.bldqty * woentry.balance as ReqPerBal
--								--,case when SUM(shortqty)>0.00 and SUM(shortqty) <= (sum(act_qty) + SUM(shortqty)/ woentry.bldqty) * woentry.balance then SUM(shortqty) else
--								--	case when SUM(shortqty)<=0.00 then 0.00 else (sum(act_qty) + SUM(shortqty)/ woentry.bldqty) * woentry.balance end end as QtyShort 
--								--,(sum(act_qty) + SUM(shortqty))/ woentry.bldqty * woentry.balance - case when SUM(shortqty)>0.00 and SUM(shortqty) <= (sum(act_qty) + SUM(shortqty)/ woentry.bldqty) * woentry.balance then SUM(shortqty) else
--								--	case when SUM(shortqty)<=0.00 then 0.00 else (sum(act_qty) + SUM(shortqty)/ woentry.bldqty) * woentry.balance end end as QtyInWip
--								--,ceiling((sum(act_qty) + SUM(shortqty))/ woentry.bldqty * woentry.balance - case when SUM(shortqty)>0.00 and SUM(shortqty) <= (sum(act_qty) + SUM(shortqty)/ woentry.bldqty) * woentry.balance then SUM(shortqty) else
--								--	case when SUM(shortqty)<=0.00 then 0.00 else (sum(act_qty) + SUM(shortqty)/ woentry.bldqty) * woentry.balance end end) as rQtyInWip
--						from	kamain
--								inner join WOENTRY on KAMAIN.wono = woentry.WONO
--								inner join INVENTOR on kamain.UNIQ_KEY = inventor.UNIQ_KEY
--								INNER JOIN CUSTOMER ON WOENTRY.CUSTNO = CUSTOMER.CUSTNO		--05/20/16 DRP: ADDED
--		--09/13/2013 DRP--where	woentry.openclos <> 'Closed' and woentry.openclos <>'Cancel'
--						--		and woentry.WONO like case when @lcWoNo = '*' then '%' else dbo.PADL(@lcwono,10,'0')+'%' end
--						--		and PART_CLASS LIKE CASE WHEN @lcclass='*' THEN '%' ELSE @lcclass+'%' END
--						--		and Part_no>= case when @lcPartStart='*' then PART_NO else @lcPartStart END
--						--		and PART_NO<= CASE WHEN @lcPartEnd='*' THEN PART_NO ELSE @lcPartEnd END
--						where	woentry.openclos <> 'Closed' and woentry.openclos <>'Cancel'
--		--12/05/2013 DRP:		--and 1 = case when woentry.WONO like case when @lcWoNo = '*' then '%' else dbo.PADL(@lcwono,10,'0')+'%' end then 1
--								--	when @lcWoNo IS null OR @lcWoNo = '' then 1 else 0 end 
--								and 1 = case when @lcWono = 'All' then 1 when woentry.WONO IN(select dbo.PADL(WONO,10,'0') from @WoNo) then 1 else 0 end
--		--12/05/2013 DRP:		--and 1 = case when PART_CLASS like Case when @lcClass = '*' then '%' else @lcClass+'%' end then 1 
--								--	when @lcClass IS Null OR @lcClass='' THEN 1 else 0 end 
--								and 1 = case when @lcClass = 'All' then 1 when PART_CLASS IN(select PART_CLASS from @PartClass) then 1 else 0 end  
--								and Part_no>= case when @lcPartStart=''  then Part_no else @lcPartStart END
--								and PART_NO<= CASE WHEN @lcPartEnd='' THEN PART_NO ELSE @lcPartEnd END
--								and exists (select 1 from @tCustomer t inner join customer c on t.custno=c.custno where c.custno=woentry.custno)		--05/20/16 DRP:  ADDED
--					group by	kamain.uniq_key,part_no,Revision,part_class,Part_type,DESCRIPT,u_of_meas,stdcost,other_cost,lineshort,woentry.WONO,woentry.balance,woentry.UNIQ_KEY,woentry.BLDQTY,kamain.ACT_QTY-kamain.ACT_QTY,CUSTNAME

--						)
08/04/16 DRP zQtyInWip Replacement end*/

insert into @tResults
Select	t1.uniq_key,t1.PART_NO,t1.REVISION,t1.PART_CLASS,t1.PART_TYPE,t1.DESCRIPT,U_OF_MEAS,W1.LINESHORT,W1.WONO,
		isnull(w1.QtyInWip,0.00) as QtyInWip,
		case when @lcCostBy = 'Standard' then isnull(W1.QtyInWip,0.00)*t1.stdcost 
			when @lcCostBy = 'Last Paid' then isnull(W1.QtyInWip,0.00)*lastpaid.costeach 
				when @lcCostBy = 'Weighted Average' then isnull(w1.qtyinWip,0.00)* ISNULL(lastPaid.wAvgCost,CAST(0.00 as numeric(12,5)))
					else isnull(W1.QtyInWip,0.00)*t1.OTHER_COST end as WipValue,
		lastpaid.VerDate,FF.Symbol AS FSymbol,t1.stdcost,ISNULL(lastpaid.costeach,0.00) as LastPaid,
		ISNULL(lastPaid.wAvgCost,CAST(0.00 as numeric(12,5))) as WghtAvg,
		t1.OTHER_COST as UserDef,w1.Actqty,w1.Shortqty,w1.Bldqty,w1.balance,@lcCostBy as CostBy,W1.CUSTNAME
		,PF.Symbol AS PSymbol
		,case when @lcCostBy = 'Standard' then isnull(W1.QtyInWip,0.00)*t1.stdcostPR 
			when @lcCostBy = 'Last Paid' then isnull(W1.QtyInWip,0.00)*lastpaid.costeachPR 
				when @lcCostBy = 'Weighted Average' then isnull(w1.qtyinWip,0.00)* ISNULL(lastPaid.wAvgCostPR,CAST(0.00 as numeric(12,5)))
					else isnull(W1.QtyInWip,0.00)*t1.OTHER_COSTPR end as WipValuePR
		,t1.stdcostPR,ISNULL(lastpaid.costeachPR,0.00) as LastPaidPR,
		ISNULL(lastPaid.wAvgCostPR,CAST(0.00 as numeric(12,5))) as WghtAvgPr,
		t1.OTHER_COSTPR as UserDefPR
		,case when @lcCostBy = 'Standard' then t1.stdcost 
			when @lcCostBy = 'Last Paid' then lastpaid.costeach 
				when @lcCostBy = 'Weighted Average' then lastPaid.wAvgCost
					else t1.OTHER_COST end as CostedByValue
		,case when @lcCostBy = 'Standard' then t1.stdcostPR 
			when @lcCostBy = 'Last Paid' then lastpaid.costeachPR 
				when @lcCostBy = 'Weighted Average' then lastPaid.wAvgCostPR
					else t1.OTHER_COSTPR end as CostedByValuePR		 	--08/09/17 DRP:   Added	
				
from	inventor t1
		LEFT OUTER join #tPoHIst lastPaid ON T1.UNIQ_KEY = LastPaid.UNIQ_KEY and lastPaid.rn=1
		LEFT OUTER JOIN #twipQty W1 ON t1.UNIQ_KEY = w1.UNIQ_KEY 
		-- 07/12/19 VL added Fcused that were not added before
		LEFT OUTER JOIN Fcused FF ON t1.FuncFcused_uniq = FF.Fcused_uniq
		LEFT OUTER JOIN Fcused PF ON t1.PrFcused_uniq = PF.Fcused_uniq	
where	isnull(case when LINESHORT = 0 
					then case when QtyInWip < 0.00 then 0.00 else QtyInWip end 
						else case when W1.UNIQ_KEY = ParentUniq then ActQty + case when w1.ShortQty < 0.00 then w1.ShortQty else 0.00 end 
							else ActQty+ case when w1.ShortQty<0.00 then w1.ShortQty else 0.00 end end end,0.00) <> 0.00
		AND (part_no+revision BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)	--06/28/17 DRP:  Added
		AND (@lcClass = '' OR exists (SELECT 1 FROM @PartClass pc WHERE PC.PART_CLASS=t1.PART_CLASS))	--08/09/17 DRP:  Added
--order by wono	-08/09/17 drp:  comment out the sort order can be used in the below 


/******************************/
/*NON FOREIGN CURRENCY SECTION*/
/******************************/
Begin
IF @lFCInstalled = 0
	BEGIN
	select	uniq_key,PART_NO,REVISION,PART_CLASS,PART_TYPE,DESCRIPT,U_OF_MEAS,LINESHORT,WONO
			,QtyInWip,WipValue,VerDate ,stdcost,LastPaid,WghtAvg,UserDef,Actqty,Shortqty,Bldqty,balance,CostBy,CUSTNAME
			,CostedByValue
	from	@tresults
	ORDER BY WONO,part_no,revision
	END
/**************************/
/*FOREIGN CURRENCY SECTION*/
/**************************/
	Else
	BEGIN 
	select	uniq_key,PART_NO,REVISION,PART_CLASS,PART_TYPE,DESCRIPT,U_OF_MEAS,LINESHORT,WONO
			,QtyInWip,WipValue,VerDate,FSymbol ,stdcost,LastPaid,WghtAvg,UserDef,Actqty,Shortqty,Bldqty,balance,CostBy,CUSTNAME	
			,CostedByValue,PSymbol,WipValuePR,stdcostPR,LastPaidPR,WghtAvgPR,UserDefPR,CostedByValuePR
	from	@tresults
	order by wono,part_no,revision
	END

	end	
/*08/04/16 DRP:  replaced with the above 
--	--12/14/15 DRP:  added the zFinal Brackets and pulled the ending results from the zFinal
--/*	,
--	zFinal as (					
--		--11/08/2013 DRP:  Added isnull to the following fields WONO,QtyInWip,rQtyInWip							
--		select	zQtyInWip.uniq_key,zQtyInWip.PART_NO,zQtyInWip.REVISION,zQtyInWip.PART_CLASS,zQtyInWip.PART_TYPE,zQtyInWip.DESCRIPT,zQtyInWip.U_OF_MEAS
--				--11/20/2013 DRP:  LINESHORT added belo
--				,LINESHORT,ISNULL(zQtyInWip.WONO,'')AS WONO 
--				--11/06/2013 DRP:,isnull(zQtyInWip.QtyInWip,0.00)as QtyInWip
--				--11/06/2013 DRP:,isnull(zqtyinwip.rQtyInWip,0.00) as RQtyInWip
--/*04/24/2014 DRP:,isnull(case when LINESHORT = 0 
--							then case when QtyInWip < 0.00 then 0.00 else QtyInWip end 
--								else case when zqtyInWip.UNIQ_KEY = ParentUniq then ActQty + case when ShortQty < 0.00 then ShortQty else 0.00 end 
--									else ActQty+ case when ShortQty<0.00 then ShortQty else 0.00 end end end,0.00) as QtyInWip
--				,isnull(case when LINESHORT = 0 
--							then case when rQtyInWip < 0.00 then 0.00 else rQtyInWip end 
--								else case when zqtyInWip.UNIQ_KEY = ParentUniq then ActQty + case when ShortQty < 0.00 then ShortQty else 0.00 end 
--									else ActQty+ case when ShortQty<0.00 then ShortQty else 0.00 end end end,0.00) as rQtyInWip	
--04/24/2014 END*/
--				,isnull(case when LINESHORT = 0 
--							then case when QtyInWip < 0.00 then 0.00 else QtyInWip end 
--								else case when zqtyInWip.UNIQ_KEY = ParentUniq 
--									then CASE WHEN ActQty + case when ShortQty < 0.00 then ShortQty else 0.00 end > BALANCE -- compare actqty+shortqty and balance, pick the smaller one
--											THEN BALANCE ELSE ActQty + case when ShortQty < 0.00 then ShortQty else 0.00 end END
--									else ActQty + case when ShortQty < 0.00 then ShortQty else 0.00 end end end,0.00) as QtyInWip
--				,isnull(case when LINESHORT = 0 
--							then case when rQtyInWip < 0.00 then 0.00 else rQtyInWip end 
--								else case when zqtyInWip.UNIQ_KEY = ParentUniq 
--									then CASE WHEN ActQty + case when ShortQty < 0.00 then ShortQty else 0.00 end > BALANCE -- compare actqty+shortqty and balance, pick the smaller one
--											THEN BALANCE ELSE ActQty + case when ShortQty < 0.00 then ShortQty else 0.00 end END
--									else ActQty + case when ShortQty < 0.00 then ShortQty else 0.00 end end end,0.00) as rQtyInWip									
--				--,ISNULL(zqtyInWip.QtyInWip*zQtyInWip.stdcost,0.00) as WipValue	--09/26/2014 DRP:  added WipValue per request (WipQty * StdCost) --10/26/15 DRP  replaced with the below
--				,ISNULL(case when @lcCostBy = 'Standard' and @lcRound = 'No' then 
--								zqtyInWip.QtyInWip*zQtyInWip.stdcost
--							else case when @lcCostBy = 'Standard' and @lcRound = 'Yes' then zqtyInWip.rQtyInWip*zQtyInWip.stdcost 
--								else case when @lcCostBy = 'Last Paid' and @lcRound = 'No' then zqtyInWip.QtyInWip*zLastPaid.COSTEACH
--									else case when @lcCostBy = 'Last Paid' and @lcRound = 'Yes' then zqtyInWip.rQtyInWip*zLastPaid.COSTEACH
--										else case when @lcCostBy = 'Weighted Average' and @lcRound = 'No' then zqtyInWip.QtyInWip*zTotal.TExtended/TOrdQty
--											else case when @lcCostBy = 'Weighted Average' and @lcRound = 'Yes' then zqtyInWip.rQtyInWip*zTotal.TExtended/TOrdQty
--												else case when @lcCostBy = 'User Define' and @lcRound = 'No' then zqtyInWip.QtyInWip*zQtyInWip.OTHER_COST
--													else case when @lcCostBy = 'User Define' and @lcRound = 'Yes' then zqtyInWip.rQtyInWip*zQtyInWip.OTHER_COST
--							else 0.00 end end end end end end end end,0.00) as WipValue	

--				--,ISNULL(case when @lcCostBy = 'Standard' and @lcRound = 'No' then *zQtyInWip.stdcost
--				--			else case when @lcCostBy = 'Standard' and @lcRound = 'Yes' then zqtyInWip.rQtyInWip*zQtyInWip.stdcost 
--				--				else case when @lcCostBy = 'Last Paid' and @lcRound = 'No' then zqtyInWip.QtyInWip*zLastPaid.COSTEACH
--				--					else case when @lcCostBy = 'Last Paid' and @lcRound = 'Yes' then zqtyInWip.rQtyInWip*zLastPaid.COSTEACH
--				--						else case when @lcCostBy = 'Weighted Average' and @lcRound = 'No' then zqtyInWip.QtyInWip*zTotal.TExtended/TOrdQty
--				--							else case when @lcCostBy = 'Weighted Average' and @lcRound = 'Yes' then zqtyInWip.rQtyInWip*zTotal.TExtended/TOrdQty
--				--								else case when @lcCostBy = 'User Define' and @lcRound = 'No' then zqtyInWip.QtyInWip*zQtyInWip.OTHER_COST
--				--									else case when @lcCostBy = 'User Define' and @lcRound = 'Yes' then zqtyInWip.rQtyInWip*zQtyInWip.OTHER_COST
--				--			else 0.00 end end end end end end end end,0.00) as WipValue2


--				,zlastpaid.VerDate,zQtyInWip.stdcost,ISNULL(zlastpaid.costeach,0.00) as LastPaid,ISNULL(zTotal.TExtended/TOrdQty,CAST(0.00 as numeric(12,5))) as WghtAvg,zQtyInWip.OTHER_COST as UserDef
--				,zQtyInWip.Actqty
--				--,zQtyInWip.Lineshort
--				,zQtyInWip.Shortqty	--12/08/2014 DRP:  Added per request
--				,zQtyInWip.Bldqty,zQtyInWip.balance	--12/16/2014 DRP:  added per request
--				,@lcCostBy as CostBy	--10/26/15 DRP:  added for reference within quickview
--				,CUSTNAME
				 
--		from	 zQtyInWip
--				left outer join zTotal on zQtyInWip.UNIQ_KEY = zTotal.UNIQ_KEY
--				LEFT outer join zLastPaid on zQtyInWip.UNIQ_KEY = zLastPaid.UNIQ_KEY
			

--		--11/20/2013 DRP:  NEED TO REPLACE [where  zQtyInWip.QtyInWip <> 0.00] with the below otherwise some records were being incorrect dropped from the results. 
--		WHERE	isnull(case when LINESHORT = 0 
--							then case when QtyInWip < 0.00 then 0.00 else QtyInWip end 
--								else case when zqtyInWip.UNIQ_KEY = ParentUniq then ActQty + case when ShortQty < 0.00 then ShortQty else 0.00 end 
--									else ActQty+ case when ShortQty<0.00 then ShortQty else 0.00 end end end,0.00) <> 0.00


----11/06/2013 DRP:  had to add the new formula's for the QtyInWip and rQtyInWip change into the below Group by. 
--		group by zqtyinwip.UNIQ_KEY, zqtyinwip.PART_NO,zqtyinwip.REVISION,zqtyinwip.PART_CLASS,zqtyinwip.PART_TYPE,zqtyinwip.DESCRIPT,zqtyinwip.U_OF_MEAS,LINESHORT,zQtyInWip.wono
--/*04/24/2014 DRP:,isnull(case when LINESHORT = 0 
--							then case when QtyInWip < 0.00 then 0.00 else QtyInWip end 
--								else case when zqtyInWip.UNIQ_KEY = ParentUniq then ActQty + case when ShortQty < 0.00 then ShortQty else 0.00 end 
--									else ActQty+ case when ShortQty<0.00 then ShortQty else 0.00 end end end,0.00)
--		,isnull(case when LINESHORT = 0 
--					then case when rQtyInWip < 0.00 then 0.00 else rQtyInWip end 
--						else case when zqtyInWip.UNIQ_KEY = ParentUniq then ActQty + case when ShortQty < 0.00 then ShortQty else 0.00 end 
--							else ActQty+ case when ShortQty<0.00 then ShortQty else 0.00 end end end,0.00)
--04/24/2014 END*/
--		,isnull(case when LINESHORT = 0 
--							then case when QtyInWip < 0.00 then 0.00 else QtyInWip end 
--								else case when zqtyInWip.UNIQ_KEY = ParentUniq 
--									then CASE WHEN ActQty + case when ShortQty < 0.00 then ShortQty else 0.00 end > BALANCE -- compare actqty+shortqty and balance, pick the smaller one
--											THEN BALANCE ELSE ActQty + case when ShortQty < 0.00 then ShortQty else 0.00 end END
--									else ActQty + case when ShortQty < 0.00 then ShortQty else 0.00 end end end,0.00) 
--				,isnull(case when LINESHORT = 0 
--							then case when rQtyInWip < 0.00 then 0.00 else rQtyInWip end 
--								else case when zqtyInWip.UNIQ_KEY = ParentUniq 
--									then CASE WHEN ActQty + case when ShortQty < 0.00 then ShortQty else 0.00 end > BALANCE -- compare actqty+shortqty and balance, pick the smaller one
--											THEN BALANCE ELSE ActQty + case when ShortQty < 0.00 then ShortQty else 0.00 end END
--									else ActQty + case when ShortQty < 0.00 then ShortQty else 0.00 end end end,0.00) 						
--		,ISNULL(case when @lcCostBy = 'Standard' and @lcRound = 'No' then zqtyInWip.QtyInWip*zQtyInWip.stdcost
--							else case when @lcCostBy = 'Standard' and @lcRound = 'Yes' then zqtyInWip.rQtyInWip*zQtyInWip.stdcost 
--								else case when @lcCostBy = 'Last Paid' and @lcRound = 'No' then zqtyInWip.QtyInWip*zLastPaid.COSTEACH
--									else case when @lcCostBy = 'Last Paid' and @lcRound = 'Yes' then zqtyInWip.rQtyInWip*zLastPaid.COSTEACH
--										else case when @lcCostBy = 'Weighted Average' and @lcRound = 'No' then zqtyInWip.QtyInWip*zTotal.TExtended/TOrdQty
--											else case when @lcCostBy = 'Weighted Average' and @lcRound = 'Yes' then zqtyInWip.rQtyInWip*zTotal.TExtended/TOrdQty
--												else case when @lcCostBy = 'User Define' and @lcRound = 'No' then zqtyInWip.QtyInWip*zQtyInWip.OTHER_COST
--													else case when @lcCostBy = 'User Define' and @lcRound = 'Yes' then zqtyInWip.rQtyInWip*zQtyInWip.OTHER_COST
--							else 0.00 end end end end end end end end,0.00)
--		,zlastpaid.VerDate,zqtyinwip.STDCOST,zLastPaid.COSTEACH,zqtyinwip.OTHER_COST,zTotal.TExtended/TOrdQty
--		,zQtyInWip.Actqty,zQtyInWip.Lineshort,zQtyInWip.Shortqty	--12/08/2014 DRP:  Added per request
--		,zQtyInWip.Bldqty,zQtyInWip.balance	--12/16/2014 DRP:  added per request
--		,CUSTNAME
--		)
--		--select * from zFinal

--	--12/14/15 DRP:  Added this new ending selection statement using the already calculated QtyInWip from the zFinal.
--		select	uniq_key,PART_NO,REVISION,PART_CLASS,PART_TYPE,DESCRIPT,U_OF_MEAS,LINESHORT,WONO,QtyInWip,rQtyInWip
--				,ISNULL(case when @lcCostBy = 'Standard' and @lcRound = 'No' then QtyInWip*stdcost
--							else case when @lcCostBy = 'Standard' and @lcRound = 'Yes' then rQtyInWip*stdcost 
--								else case when @lcCostBy = 'Last Paid' and @lcRound = 'No' then QtyInWip*LastPaid
--									else case when @lcCostBy = 'Last Paid' and @lcRound = 'Yes' then rQtyInWip*LastPaid
--										else case when @lcCostBy = 'Weighted Average' and @lcRound = 'No' then QtyInWip*WghtAvg
--											else case when @lcCostBy = 'Weighted Average' and @lcRound = 'Yes' then rQtyInWip*WghtAvg
--												else case when @lcCostBy = 'User Define' and @lcRound = 'No' then QtyInWip*UserDef
--													else case when @lcCostBy = 'User Define' and @lcRound = 'Yes' then rQtyInWip*UserDef
--							else 0.00 end end end end end end end end,0.00) as WipValue
--							,VerDate,stdcost,LastPaid,WghtAvg,UserDef,Actqty,Shortqty,Bldqty,balance,CostBy,CUSTNAME
--		 from zFinal
--		order by wono
--		*/

--	Select	t1.uniq_key,t1.PART_NO,t1.REVISION,t1.PART_CLASS,t1.PART_TYPE,t1.DESCRIPT,U_OF_MEAS,W1.LINESHORT,W1.WONO,
--				isnull(w1.QtyInWip,0.00) as QtyInWip,
--				case when @lcCostBy = 'Standard' then isnull(W1.QtyInWip,0.00)*t1.stdcost 
--				when @lcCostBy = 'Last Paid' then isnull(W1.QtyInWip,0.00)*lastpaid.costeach 
--				when @lcCostBy = 'Weighted Average' then isnull(w1.qtyinWip,0.00)* ISNULL(lastPaid.wAvgCost,CAST(0.00 as numeric(12,5)))
--				else isnull(W1.QtyInWip,0.00)*t1.OTHER_COST end as WipValue,
--				lastpaid.VerDate,t1.stdcost,ISNULL(lastpaid.costeach,0.00) as LastPaid,
--				ISNULL(lastPaid.wAvgCost,CAST(0.00 as numeric(12,5))) as WghtAvg,
--				t1.OTHER_COST as UserDef,w1.Actqty,w1.Shortqty,w1.Bldqty,w1.balance,@lcCostBy as CostBy
--				,W1.CUSTNAME
					
				
				
--				from  inventor t1
--						LEFT OUTER join #tPoHIst lastPaid ON T1.UNIQ_KEY = LastPaid.UNIQ_KEY and lastPaid.rn=1
--				   LEFT OUTER JOIN #twipQty W1 ON t1.UNIQ_KEY = w1.UNIQ_KEY 
--			where	isnull(case when LINESHORT = 0 
--							then case when QtyInWip < 0.00 then 0.00 else QtyInWip end 
--								else case when W1.UNIQ_KEY = ParentUniq then ActQty + case when w1.ShortQty < 0.00 then w1.ShortQty else 0.00 end 
--									else ActQty+ case when w1.ShortQty<0.00 then w1.ShortQty else 0.00 end end end,0.00) <> 0.00
--			order by wono
08/04/16 DRP:  zFinal Replacement end*/
end