
		-- =============================================
		-- Author:		<Debbie>
		-- Create date: <06/09/2010>
		-- Description:	<one of the stored procedures used to gather the AR Credit amounts for each invoice record>
		-- Report:      <used on [arageasof.rpt]
		-- Modified		11/02/2012 DRP:  Found that the Crystal Report wants the AsOfDate field to be in smalldatetime format.  So I casted the field accordingly. 
		--				11/20/2012 DRP:  Found that the code below should link to custno and uniquear fields 
		--								 were possible to make sure that it was linking to the correct records in cases where they used the same invoice/prepayment number more than once. 
		--				01/16/2014 DRP:  found that if the users happen to process AR Check Returns that it was returning duplicate results from the ARRETCK table due to having a incorrect join.  
		--				01/16/2014 DRP:	 in the section of code that gathers the Ar Deposit I had to add the dep_no to the Credit_ref in order to make it unique in the scenario where they happen to 
		--								 record an invoice in an deposit (against incorrect bank)process an Return Check and the deposit against the invoice into the correct bank on the same day. 
		--				01/16/2014 DRP:	 also needed to add the aroffset.ctransaction to the credit_ref results.  In the situation where they might apply the same record within the same offset. 
		--				01/16/2014 DRP:  found that if the original deposit contained some discounts taken and then a Check return (NSF) was processed that I needed to make sure that added both the Rec_amount and Disc__taken when gathering the values for the Return Checks.
		--				01/24/2014 DRP:  I added  ";With tresults" to the procedure so that I could filter out at the end any results where the CreditAmt = 0.00
		--				02/18/2014 DRP:  Replaced the T1 where . . . statement below with "where  DATEDIFF(Day,t1.CreditDATE,@lcdate)>=0"  so that the results will be filtered off of the CreditDate field. 
		--				02/27/2014 DRP:  needed to make sure that the prepayments displayed in the current column in order to match the aging screen  The AgeDate formula has been changed where PrePayments are involved.  
		--								 also changed the DueDate where prepayments are involved.  instead of leaving it null I populated it with the invoice date. 
		--				10/02/2014 DRP:  Found that if the user left the @lcDate blank that it was not displaying any results.  Added to the procedure so if @lcDate is blank then it will take the current calendar date. 
		--								 also had to change the section that would get the desired @lcdate.  In the situation where the Fy and Period were entered before, the Stimulsoft was not seeing it and it would either error out or take the current date each time.
		--								 needed to add fields to the results to improve the results of the end report:  InvTotal,Phone,Terms and PoNo.  In order to get the PoNo in the results and not mess up the grouping I had to add the PLMAIN and the SOMAIN tables to multiple sections 
		--								 Added the /*CUSTOMER LIST*/ to make sure that only customer that the user is approved to view. 
		--								 Changed any code that referenced "CASE WHEN LEFT(ar1.invno, 4) = 'PPay'" and changed it to be "CASE WHEN lPrepay = 1"
		--								 Added script in order for the Ranges to display properly witin QuickView and Report. 
		--								 removed t1.uniquear from the results.  Changed the field name from CreditAmt to BalAmt and added creditlimit so it would work with the Type "tArAging
		--				11/20/2014 DRP:  when originally writing the section for the Ar Write-off I did not take into consideration that the users would be writing off Prepayments.  
		--								 I need to change the InvTotal to be 0.00 in the case that the write off was for a prepaymentcase when ar5.lprepay = 1 then cast(0.00 as numeric(20,2)) else ar5.invtotal end as InvTotal
		--				11/24/2014 DRP:	 needed to add union all  Found that some users would create offsets that were identical. 
		--				01/06/2015 DRP:  Added @customerStatus Filter
		--				01/31/2015 DRP:  Credit Memo's were being pulled in too many times, needed to remove the CMMAIN join and change some items within the section that gathers the CM info. 
		--				02/24/2015 DRP:  Added the @lcCustNo parameter to allow the users the ability to run the Ar Aging As Of Report per Single Customer if desired. 		
		--				02/29/2016 VL:   Added FC code, added one more parameter to show HC in original rate or latest rate, currently the Penang verion, only calcualte in code, but not show in report
		--				05/12/2016 VL:	 Added BalAmt <> 0.00 in addition to BalAmtFC <> 0.00 to avoid those balance = 0 records with 1 cent rounding issue appear in report
		--				05/13/2016 DRP:  Changed the @lLatestRate parameter from a bit to char(3) when I will use Yes or No for the Parameter selection options. 
		--				09/21/16 DRP:	found that the Return Check did not have the correct relation setup and was returning too many duplicate results.  
		--				01/06,11/17 VL:	added functional currency and add one more parameter for fn_CalculateFCRateVariance() which is the rate ratio calculated based on functional currency or presentation currency	
		--				02/07/17 DRP:	Changed the <<INNER JOIN  Fcused ON Fcused.Fcused_uniq = ar1.Fcused_uniq>> to be <<left outer JOIN  Fcused ON Fcused.Fcused_uniq = ar1.Fcused_uniq>>
		--								also changed <<where tresults.BalAmtFC <> 0.00 and BalAmt <> 0.00>> to be <<where tresults.BalAmtFC <> 0.00 or BalAmt <> 0.00>>
		-- 05/09/17 DRP:  replaced the code from BalAmtFC <> 0.00 or BalAmt <> 0.00 to BalAmt <> 0.00
		-- 08/22/17 VL: found we never saved fchist_key in @Results, so when re-calculating with new rate, never update correctly, added fchist_key
		-- 08/22/17 VL: Changed Range1PR... to be 1-30PR more meaningful column name
		-- 08/22/17 VL: decided to calculate latest rate by FC value/latest ask price, not use the dbo.fn_CalculateFCRateVariance() which calculate the ratio of changing which might cause $0.01 difference
-- 08/25/17 VL found I should add round() to the calculation of latest rate
-- 09/21/17 VL changed to check BalAmtFC <> 0 for FC installed and check BalAmt <> for FC not installed
-- 10/06/17 VL removed 'Fchist_key', we don't need to use it go calculate the rate of new rate and old rate, it also caused the group by having issue that same invoice (one from plmain, one from CM) with different fchist_key became 2 records
-- 01/16/2020 YS added new column to plmain table pono for the manual invoice w/o sales order. Need to identify the table in the sql
-- 03/02/20 VL Fixed the CType = 'AP' to cType = 'AR' 
-- =============================================


		CREATE PROCEDURE [dbo].[rptArAgeAsOfFC]  
			-- Add the parameters for the stored procedure here
--declare
		@lcDate as date=  null
		,@lcFy as char(4)=' '
		,@lnPeriod as int =0 
		,@lcAgeBy as varchar(12)='Due Date'	--Invoice Date or Due Date
		,@lcSort as char(12) 
		,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
		,@lcCustNo varchar(max) = 'All'		--02/24/2015 DRP:  ADDED
		, @userId uniqueidentifier= null
		-- 02/29/16 VL added to show values in latest rate or not
		,@lLatestRate char(3) = 'Yes'	--Yes:  it will then use the latest rate to make its calculations.  No:  it will then use the original Exchange rate.	 
AS
BEGIN


/*CUSTOMER LIST*/ --10/02/2014 DRP:  Added  02/24/2015 DRP:  changed the Customer List selection to work with the @lcCustNo parameter
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,@customerStatus ;
		--SELECT * FROM @tCustomer	
		
		IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)
		ELSE

		IF  @lcCustNo='All'	
		BEGIN
			INSERT INTO @Customer SELECT CustNo FROM @tCustomer
		END


		if @lcFy<>'' and @lnPeriod<>''
		BEGIN
			-- look for the end of the given fiscal year period
			SELECT @lcDate=glfyrsdetl.ENDDATE 
					FROM glfyrsdetl inner join glfiscalyrs on glfiscalyrs.FY_UNIQ = glfyrsdetl.FK_FY_UNIQ 
					WHERE glfiscalyrs.FISCALYR =@lcFy and glfyrsdetl.PERIOD =@lnPeriod
			END	-- @lcDate IS NULL
		else	--09/29/2014 DRP:  Added
			begin
				select @lcDate = case when @lcDate is null then getdate() else @lcDate end
			end	--09/29/2014 DRP:  End Add
/*10/02/2014 DRP:  Replaced with the above
		IF @lcDate IS NULL
		BEGIN
			-- look for the end of the given fiscal year period
			if @lcFy<>' ' and @lnPeriod<>0
			BEGIN
				SELECT @lcDate=glfyrsdetl.ENDDATE 
					FROM glfyrsdetl inner join glfiscalyrs on glfiscalyrs.FY_UNIQ = glfyrsdetl.FK_FY_UNIQ 
					WHERE glfiscalyrs.FISCALYR =@lcFy and glfyrsdetl.PERIOD =@lnPeriod
			END -- @lcFy<>' ' and @lnPeriod<>0
		END	-- @lcDate IS NULL
10/02/2014 DRP: Replacement End*/


/*10/02/2014 DRP:*/ --needed to add the below in order for the Ranges to display both in Quick View and in report
-- string for the names of the columnsbased on the AgingRangeSetup
declare @cols as nvarchar(max)

-- 08/22/17 VL added for PR to show more meaningful column names
-- 03/02/20 VL Fixed the CType = 'AP' to cType = 'AR' 
select @cols = STUFF((
	SELECT ',' + C.Name  
		from (select nRange,'Range'+RTRIM(cast(nRange as int))+' as ['+cast(nStart as varchar(4))+'-'+cast(nEND as varchar(4))+']'+
			', Range'+RTRIM(cast(nRange as int))+'FC as ['+cast(nStart as varchar(4))+'-'+cast(nEND as varchar(4))+'FC]'+
			', Range'+RTRIM(cast(nRange as int))+'PR as ['+cast(nStart as varchar(4))+'-'+cast(nEND as varchar(4))+'PR]' name from AgingRangeSetup where AgingRangeSetup.cType='AR' ) C
	ORDER BY C.nRange
	FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'');

-- 09/21/17 VL added for FC installed or not
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

--populating the @results with the system type tArAging 
-- 02/29/16 VL Changed to use tArAgingFC
declare @results as tArAgingFC
/*10/02/2014 DRP:  end Add*/

-- 08/22/17 VL create a table variable to save FcUsedView, and use this table variable to update latest rate
DECLARE @tFcusedView TABLE (FCUsed_Uniq char(10), Country varchar(60), CURRENCY varchar(40), Symbol varchar(3), Prefix varchar(7), UNIT varchar(10), Subunit varchar(10), Thou_sep varchar(1), Deci_Sep varchar(1), 
		Deci_no numeric(2,0), AskPrice numeric(13,5), AskPricePR numeric(13,5), Fchist_key char(10), Fcdatetime smalldatetime)
INSERT @tFcusedView EXEC FcusedView

--01/24/2014 DRP:  Added the below :with tresults so I can filter out the CreditAmt = 0.00 at the end. 		
-- 08/22/17 VL: found we never saved fchist_key in @Results, so when re-calculating with new rate, never update correctly, added fchist_key, also added fcused_uniq
-- 10/06/17 VL removed 'Fchist_key', we don't need to use it go calculate the rate of new rate and old rate, it also caused the group by having issue that same invoice (one from plmain, one from CM) with different fchist_key became 2 records
;with tresults as ( 
		select	t1.CUSTNO,rtrim(t1.custname)as custname,/*t1.uniquear,*/ t1.INVNO,t1.PONO,t1.invdate, t1.due_date,t1.InvTotal,sum(t1.BalAmt) as BalAmt, 
				case when DATEDIFF(day,t1.agedate,@lcDate) <=0 then SUM(t1.BalAmt) else CAST(0.00 as numeric(12,2)) end as [Current],
				case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r1start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r1end then SUM(t1.BalAmt) else CAST(0.00 as numeric(12,2)) end as Range1,
				case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r2start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r2end then SUM(t1.BalAmt) else CAST(0.00 as numeric(12,2)) end as Range2,
				case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r3start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r3end then SUM(t1.BalAmt) else CAST(0.00 as numeric(12,2)) end as Range3,
				case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r4start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r4end then SUM(t1.BalAmt) else CAST(0.00 as numeric(12,2)) end as Range4,
				case when DATEDIFF(day,t1.agedate,@lcDate) > t1.r4end then SUM(t1.BalAmt) else CAST(0.00 as numeric(12,2)) end as [Over], t1.R1Start, t1.R1End, t1.R2Start, t1.R2End
				,t1.R3Start, t1.R3End, t1.R4Start, t1.R4End, cast (@lcdate as smalldatetime) as AsOfDate,t1.PHONE,t1.TERMS,t1.credLimit	
				-- 02/29/16 VL added FC fields
				,t1.InvTotalFC,sum(t1.BalAmtFC) as BalAmtFC,
				case when DATEDIFF(day,t1.agedate,@lcDate) <=0 then SUM(t1.BalAmtFC) else CAST(0.00 as numeric(12,2)) end as [CurrentFC],
				case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r1start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r1end then SUM(t1.BalAmtFC) else CAST(0.00 as numeric(12,2)) end as Range1FC,
				case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r2start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r2end then SUM(t1.BalAmtFC) else CAST(0.00 as numeric(12,2)) end as Range2FC,
				case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r3start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r3end then SUM(t1.BalAmtFC) else CAST(0.00 as numeric(12,2)) end as Range3FC,
				case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r4start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r4end then SUM(t1.BalAmtFC) else CAST(0.00 as numeric(12,2)) end as Range4FC,
				case when DATEDIFF(day,t1.agedate,@lcDate) > t1.r4end then SUM(t1.BalAmtFC) else CAST(0.00 as numeric(12,2)) end as [OverFC], TSymbol
				-- 01/06/17 VL added functional currency fields
				,t1.InvTotalPR,sum(t1.BalAmtPR) as BalAmtPR,
				case when DATEDIFF(day,t1.agedate,@lcDate) <=0 then SUM(t1.BalAmtPR) else CAST(0.00 as numeric(12,2)) end as [CurrentPR],
				case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r1start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r1end then SUM(t1.BalAmtPR) else CAST(0.00 as numeric(12,2)) end as Range1PR,
				case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r2start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r2end then SUM(t1.BalAmtPR) else CAST(0.00 as numeric(12,2)) end as Range2PR,
				case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r3start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r3end then SUM(t1.BalAmtPR) else CAST(0.00 as numeric(12,2)) end as Range3PR,
				case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r4start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r4end then SUM(t1.BalAmtPR) else CAST(0.00 as numeric(12,2)) end as Range4PR,
				case when DATEDIFF(day,t1.agedate,@lcDate) > t1.r4end then SUM(t1.BalAmtPR) else CAST(0.00 as numeric(12,2)) end as [OverPR], PSymbol, FSymbol, Fcused_uniq	
		from(
		--THE BELOW WILL SELECT THE MAIN RECORD FROM THE ACCTSREC AND ALSO PULL FWD IN THE SYSTEM SETUP AGING RANGES

		SELECT     TOP (100) PERCENT c1.CUSTNAME,c1.CUSTNO,ar1.UNIQUEAR,ar1.INVNO, ar1.INVDATE  /*02/27/2014 DRP:	--, ar1.DUE_DATE*/
		-- 01/16/2020 YS added new column to plmain table pono for the manual invoice w/o sales order. Need to identify the table in the sql					
					,CASE WHEN AR1.lPrepay = 1 then aR1.INVDATE else aR1.due_date end as Due_date, ISNULL(so1.pono,pl1.pono) as PONO
					--, CASE WHEN LEFT(ar1.invno, 4) = 'PPay' THEN CAST(0.00 AS Numeric(20,2)) ELSE ar1.INVTOTAL END AS InvTotal	--10/02/2014 DRP:  replaced with the "case when lprepay = 1"
					, CASE WHEN ar1.lPrepay = 1 THEN CAST(0.00 AS Numeric(20,2)) ELSE ar1.INVTOTAL END AS InvTotal
					, ar1.INVDATE AS CreditDate, CAST('' AS char(25)) AS Credit_Ref,ar1.INVTOTAL AS BalAmt, a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start
					, a2.nEnd AS R2End, a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start, a4.nEnd AS R4End,
/*02/27/2014 DRP:			  --CASE WHEN @lcAgeBy ='Due Date' THEN ar1.Due_Date ELSE ar1.InvDate END AS AgeDate */
							  case when @lcAgeBy = 'Due Date' and ar1.lPrepay = 0 then ar1.DUE_DATE else 
								case when @lcAgeBy = 'Due Date' and  ar1.lprepay = 1 then @lcdate else 
									case when @lcAgeBy = 'Invoice Date' and ar1.lprepay = 0 then ar1.InvDate else
										case when @lcAgeBy = 'Invoice date' and ar1.lprepay = 1 then @lcDate end end end end as AgeDate ,c1.phone,c1.Terms,c1.credLimit		
					-- 02/29/16 VL added FC Fields
					,CASE WHEN ar1.lPrepay = 1 THEN CAST(0.00 AS Numeric(20,2)) ELSE ar1.INVTOTALFC END AS InvTotalFC,ar1.INVTOTALFC AS BalAmtFC, TF.Symbol AS TSymbol
					-- 01/06/17 VL added functional currency Fields
					,CASE WHEN ar1.lPrepay = 1 THEN CAST(0.00 AS Numeric(20,2)) ELSE ar1.INVTOTALPR END AS InvTotalPR,ar1.INVTOTALPR AS BalAmtPR, PF.Symbol AS PSymbol, 
					FF.Symbol AS FSymbol, ar1.FCUSED_UNIQ
		FROM         dbo.SOMAIN as so1 
					RIGHT OUTER JOIN dbo.PLMAIN as pl1 ON so1.SONO = pl1.SONO 
					RIGHT OUTER JOIN dbo.ACCTSREC AS ar1 
						-- 01/06/17 VL added to show currency symbol
						left outer JOIN Fcused PF ON ar1.PrFcused_uniq = PF.Fcused_uniq
						left outer JOIN Fcused FF ON ar1.FuncFcused_uniq = FF.Fcused_uniq			
						left outer JOIN Fcused TF ON ar1.Fcused_uniq = TF.Fcused_uniq					
					INNER JOIN dbo.CUSTOMER AS c1 ON ar1.CUSTNO = c1.CUSTNO ON pl1.INVOICENO = ar1.INVNO 
					CROSS JOIN dbo.AgingRangeSetup AS a4 
					CROSS JOIN dbo.AgingRangeSetup AS a1 
					CROSS JOIN dbo.AgingRangeSetup AS a2 
					CROSS JOIN dbo.AgingRangeSetup AS a3
		WHERE     (ar1.INVTOTAL <> 0.00) AND (LEFT(ar1.INVNO, 4) <> 'PPay') AND (a1.cType = 'AR') AND (a1.nRange = 1) AND (a2.cType = 'AR') AND (a2.nRange = 2) 
							  AND (a3.cType = 'AR') AND (a3.nRange = 3) AND (a4.cType = 'AR') AND (a4.nRange = 4)
							

		union all		--11/24/2014 DRP:  changed from union to union all
		-- THE BELOW WILL PULL THE INFORMATION FROM THE ARCREDIT TABLE WHICH SHOULD INCLUDE both GENERAL & INVOICE CREDIT MEMOS AND AR DEPOSITS APPLIED AGAINST INVOICE RECORDS
		SELECT     C2.CUSTNAME,c2.CUSTNO,ar2.uniquear, ar2.INVNO, ar2.INVDATE
/*02/27/2014 DRP:	, ar2.DUE_DATE*/
-- 01/16/2020 YS added new column to plmain table pono for the manual invoice w/o sales order. Need to identify the table in the sql
					,CASE WHEN AR2.lPrepay = 1 then aR2.INVDATE else aR2.due_date end as Due_date /*10/02/2014 DRP:,cast(''as char(25)) as pono*/,isnull(somain.pono,plmain.pono) as pono
					/*10/02/2014 DRP:  --,case when ar2.INVTOTAL = 0.00 and arc2.rec_type = 'Credit Memo' then cast (0.00 as Numeric(20,2)) when left(ar2.invno,4) = 'PPay' then cast (0.00 as numeric (12)) else ar2.invtotal end as invtotal,*/
					,case when ar2.INVTOTAL = 0.00 and arc2.rec_type = 'Credit Memo' then cast (0.00 as Numeric(20,2)) when ar2.lPrepay = 1 then cast (0.00 as numeric(20,2)) else ar2.invtotal end as InvTotal
					,arc2.REC_dATE as CreditDate
--01/16/2014 DRP	,case when arc2.rec_type = 'Invoice A/R' then 'chk: ' + arc2.rec_advice else ARC2.REC_ADVICE end as Credit_Ref
					,case when arc2.rec_type = 'Invoice A/R' then 'chk: ' +LTRIM(arc2.rec_advice)+'     '+LTRIM(ARC2.DEP_NO) else ARC2.REC_ADVICE end as Credit_Ref 
--01/31/2015 DRP:	,case when arc2.rec_type = 'Credit Memo' and cm2.cmtype = 'M' then -arc2.rec_amount else -(ARC2.REC_AMOUNT+ARC2.DISC_TAKEN) end as BalAmt,
					,case when arc2.rec_type = 'Credit Memo' and arc2.INVNO = arc2.REC_ADVICE then -arc2.rec_amount else -(ARC2.REC_AMOUNT+ARC2.DISC_TAKEN) end as BalAmt,    
					a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End,a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start, a4.nEnd AS R4End,
/*02/27/2014 DRP:	--CASE WHEN @lcAgeBy ='Due Date' THEN ar2.Due_Date ELSE ar2.InvDate END AS AgeDate */		  
					  case when @lcAgeBy = 'Due Date' and ar2.lPrepay = 0 then ar2.DUE_DATE else 
						case when @lcAgeBy = 'Due Date' and  ar2.lprepay = 1 then @lcdate else 
							case when @lcAgeBy = 'Invoice Date' and ar2.lprepay = 0 then ar2.InvDate else
								case when @lcAgeBy = 'Invoice date' and ar2.lprepay = 1 then @lcDate end end end end as AgeDate ,c2.phone,c2.Terms,c2.credLimit	
					-- 02/29/16 VL added FC fields
					,case when ar2.INVTOTALFC = 0.00 and arc2.rec_type = 'Credit Memo' then cast (0.00 as Numeric(20,2)) when ar2.lPrepay = 1 then cast (0.00 as numeric(20,2)) else ar2.invtotalFC end as InvTotalFC				
					,case when arc2.rec_type = 'Credit Memo' and arc2.INVNO = arc2.REC_ADVICE then -arc2.rec_amountFC else -(ARC2.REC_AMOUNTFC+ARC2.DISC_TAKENFC) end as BalAmtFC    
					,TF.Symbol AS TSymbol
					-- 01/06/17 VL added functional currency fields
					,case when ar2.INVTOTALPR = 0.00 and arc2.rec_type = 'Credit Memo' then cast (0.00 as Numeric(20,2)) when ar2.lPrepay = 1 then cast (0.00 as numeric(20,2)) else ar2.invtotalPR end as InvTotalPR				
					,case when arc2.rec_type = 'Credit Memo' and arc2.INVNO = arc2.REC_ADVICE then -arc2.rec_amountPR else -(ARC2.REC_AMOUNTPR+ARC2.DISC_TAKENPR) end as BalAmtPR   
					,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol, arc2.FCUSED_UNIQ
		FROM        dbo.ARCREDIT AS arc2 
						-- 01/06/17 VL added to show currency symbol
						left outer JOIN Fcused PF ON arc2.PrFcused_uniq = PF.Fcused_uniq
						left outer JOIN Fcused FF ON arc2.FuncFcused_uniq = FF.Fcused_uniq			
						left outer JOIN Fcused TF ON arc2.Fcused_uniq = TF.Fcused_uniq					
					INNER JOIN dbo.CUSTOMER AS c2 ON arc2.CUSTNO = c2.CUSTNO 
					INNER JOIN dbo.ACCTSREC AS ar2 ON arc2.INVNO = ar2.INVNO  and arc2.CUSTNO = ar2.CUSTNO and arc2.uniquear = ar2.UNIQUEAR 
--01/31/2015 DRP:	--LEFT OUTER JOIN dbo.CMMAIN AS cm2 ON ar2.INVNO = cm2.INVOICENO 
					left outer join plmain on arc2.invno = plmain.invoiceno
					left outer join somain on plmain.sono = somain.sono
					CROSS JOIN
		--11/20/2012 DRP:	  Dbo.ACCTSREC AS ar2 ON arc2.INVNO = ar2.INVNO  and arc2.CUSTNO = ar2.CUSTNO LEFT OUTER JOIN
							  dbo.AgingRangeSetup AS a2 CROSS JOIN
							  dbo.AgingRangeSetup AS a3 CROSS JOIN
							  dbo.AgingRangeSetup AS a4 CROSS JOIN
							  dbo.AgingRangeSetup AS a1
		WHERE     (a1.cType = 'AR') and (a1.nRange = 1) AND (a2.cType = 'AR') AND (a2.nRange = 2) 
							  AND (a3.cType = 'AR') AND (a3.nRange = 3) AND (a4.cType = 'AR') AND (a4.nRange = 4) 
							                     
		 union all		--11/24/2014 DRP:  changed from union to union all
		--THE BELOW WILL PULL THE INFORMATION FROM THE AROFFSET TABLE
		SELECT     c3.CUSTNAME,c3.CUSTNO,ar3.uniquear, ar3.INVNO, ar3.INVDATE  /*02/27/2014 DRP:  ,ar3.DUE_DATE*/,CASE WHEN AR3.lPrepay = 1 then aR3.INVDATE else aR3.due_date end as Due_date
				  -- 01/16/2020 YS added new column to plmain table pono for the manual invoice w/o sales order. Need to identify the table in the sql
				   /*10/02/2014 DRP: cast(''as char(25)) as pono,*/,isnull(somain.pono,plmain.pono) as pono,case when ar3.lprepay = 1 then cast (0.00 as numeric(20,2)) else ar3.INVTOTAL end as InvTotal, aro3.date as CreditDate,
					'Offset: ' + aro3.invno+'     '+ aro3.CTRANSACTION  as Credit_ref, aro3.amount as BalAmt,
--01/16/2014 DRP:	'Offset: ' + aro3.invno as Credit_ref, aro3.amount as CreditAmt,  
					a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End,a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start, a4.nEnd AS R4End,
/*02/27/2014 DRP:  --CASE WHEN @lcAgeBy ='Due Date' THEN ar3.Due_Date ELSE ar3.InvDate END AS AgeDate */
					  case when @lcAgeBy = 'Due Date' and ar3.lPrepay = 0 then ar3.DUE_DATE else 
						case when @lcAgeBy = 'Due Date' and  ar3.lprepay = 1 then @lcdate else 
							case when @lcAgeBy = 'Invoice Date' and ar3.lprepay = 0 then ar3.InvDate else
								case when @lcAgeBy = 'Invoice date' and ar3.lprepay = 1 then @lcDate end end end end as AgeDate ,c3.phone,c3.Terms,c3.credLimit		  
					-- 02/29/16 VL added FC fields
					,case when ar3.lprepay = 1 then cast (0.00 as numeric(20,2)) else ar3.INVTOTALFC end as InvTotalFC, aro3.amountFC as BalAmtFC
					,TF.Symbol AS TSymbol
					-- 01/06/17 VL added Functional currency fields
					,case when ar3.lprepay = 1 then cast (0.00 as numeric(20,2)) else ar3.INVTOTALPR end as InvTotalPT, aro3.amountPR as BalAmtPR
					,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol, ar3.FCUSED_UNIQ
		FROM        dbo.ACCTSREC as ar3 
						-- 01/06/17 VL added to show currency symbol
						left outer JOIN Fcused PF ON ar3.PrFcused_uniq = PF.Fcused_uniq
						left outer JOIN Fcused FF ON ar3.FuncFcused_uniq = FF.Fcused_uniq			
						left outer JOIN Fcused TF ON ar3.Fcused_uniq = TF.Fcused_uniq			  
					INNER JOIN dbo.CUSTOMER as c3 ON ar3.CUSTNO = c3.CUSTNO INNER JOIN
							  dbo.AROFFSET as aro3 ON ar3.INVNO = aro3.INVNO and ar3.UNIQUEAR = aro3.uniquear 
		--11/20/2012 DRP:	  dbo.AROFFSET as aro3 ON ar3.INVNO = aro3.INVNO CROSS JOIN
							  left outer join plmain on ar3.invno = plmain.invoiceno
							  left outer join somain on plmain.sono = somain.sono CROSS JOIN
							  dbo.AgingRangeSetup AS a2 CROSS JOIN
							  dbo.AgingRangeSetup AS a3 CROSS JOIN
							  dbo.AgingRangeSetup AS a4 CROSS JOIN
							  dbo.AgingRangeSetup AS a1
		WHERE     (a1.cType = 'AR') and (a1.nRange = 1) AND (a2.cType = 'AR') AND (a2.nRange = 2) 
							  AND (a3.cType = 'AR') AND (a3.nRange = 3) AND (a4.cType = 'AR') AND (a4.nRange = 4)
							  
		union all		--11/24/2014 DRP:  changed from union to union all
		--THE BELOW WILL PULL THE INFORMATION FROM THE AR CHECK RETURNS
		SELECT		C4.CUSTNAME,c4.CUSTNO,ar4.UNIQUEAR, AR4.INVNO, AR4.INVDATE /*02/27/2014 DRP:	,AR4.DUE_DATE*/
					,CASE WHEN AR4.lPrepay = 1 then aR4.INVDATE else aR4.due_date end as Due_date
					-- 01/16/2020 YS added new column to plmain table pono for the manual invoice w/o sales order. Need to identify the table in the sql
					/*10/02/2014 DRP: cast(''as char(25)) as pono*/,isnull(somain.pono,plmain.pono) as pono, case when ar4.lPrepay = 1 then cast (0.00 as numeric(20,2)) else AR4.INVTOTAL end as InvTotal, ARC4.RET_DATE AS CreditDAte,'chk rtn: ' + ard4.invno as Credit_ref
					, ard4.rec_amount+ard4.disc_taken as BalAmt ,/*01/16/2014 DRP:, ard4.rec_amount as CreditAmt,*/  
					a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End,a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start, a4.nEnd AS R4End,
/*02/27/2014 DRP:	  --CASE WHEN @lcAgeBy ='Due Date' THEN ar4.Due_Date ELSE ar4.InvDate END AS AgeDate*/   
					  case when @lcAgeBy = 'Due Date' and ar4.lPrepay = 0 then ar4.DUE_DATE else 
						case when @lcAgeBy = 'Due Date' and  ar4.lprepay = 1 then @lcdate else 
							case when @lcAgeBy = 'Invoice Date' and ar4.lprepay = 0 then ar4.InvDate else
								case when @lcAgeBy = 'Invoice date' and ar4.lprepay = 1 then @lcDate end end end end as AgeDate ,c4.phone,c4.Terms,c4.credLimit					
					-- 02/29/16 VL added FC fields
					, case when ar4.lPrepay = 1 then cast (0.00 as numeric(20,2)) else AR4.INVTOTALFC end as InvTotalFC, ard4.rec_amountFC+ard4.disc_takenFC as BalAmtFC 
					,TF.Symbol AS TSymbol
					-- 01/06/17 VL added Functional currency fields
					, case when ar4.lPrepay = 1 then cast (0.00 as numeric(20,2)) else AR4.INVTOTALPR end as InvTotalPR, ard4.rec_amountPR+ard4.disc_takenPR as BalAmtPR
					,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol, ar4.FCUSED_UNIQ
		FROM		DBO.ACCTSREC AS AR4
						-- 01/06/17 VL added to show currency symbol
						left outer JOIN Fcused PF ON AR4.PrFcused_uniq = PF.Fcused_uniq
						left outer JOIN Fcused FF ON AR4.FuncFcused_uniq = FF.Fcused_uniq			
						left outer JOIN Fcused TF ON AR4.Fcused_uniq = TF.Fcused_uniq					
						INNER JOIN DBO.CUSTOMER AS C4 ON AR4.CUSTNO = C4.CUSTNO INNER JOIN
						DBO.ARRETDET AS ARD4 ON ARD4.INVNO = AR4.INVNO and ard4.CUSTNO = ar4.CUSTNO INNER JOIN
	--11/20/2012 DRP:   DBO.ARRETDET AS ARD4 ON ARD4.INVNO = AR4.INVNO INNER JOIN
	--01/16/2014 DRP:	DBO.ARRETCK AS ARC4 ON ARC4.DEP_NO = ARD4.DEP_NO CROSS JOIN
						DBO.ARRETCK AS ARC4 ON ARC4.DEP_NO = ARD4.DEP_NO and arc4.UNIQLNNO = ard4.UNIQLNNO and arc4.uniqretno = ard4.UNIQRETNO	--09/21/16 DRP:  added this arc4.uniqretno = ard4.UNIQRETNO
						left outer join plmain on ar4.invno = plmain.invoiceno
						left outer join somain on plmain.sono = somain.sono
						cross join
							  dbo.AgingRangeSetup AS a2 CROSS JOIN
							  dbo.AgingRangeSetup AS a3 CROSS JOIN
							  dbo.AgingRangeSetup AS a4 CROSS JOIN
							  dbo.AgingRangeSetup AS a1
		WHERE     (a1.cType = 'AR') and (a1.nRange = 1)AND (a2.cType = 'AR') AND (a2.nRange = 2) 
							  AND (a3.cType = 'AR') AND (a3.nRange = 3) AND (a4.cType = 'AR') AND (a4.nRange = 4)
	
		union all		--11/24/2014 DRP:  changed from union to union all

		--THE BELOW WILL PULL THE INFORMATION FROM THE AR WRITE OFF
		select		C5.CUSTNAME,c5.CUSTNO,ar5.UNIQUEAR, AR5.INVNO, AR5.INVDATE/*02/27/2014 DRP:	, AR5.DUE_DATE*/
					,CASE WHEN AR5.lPrepay = 1 then aR5.INVDATE else aR5.due_date end as Due_date /*10/02/2014 DRP:,cast(''as char(25)) as pono*/
					-- 01/16/2020 YS added new column to plmain table pono for the manual invoice w/o sales order. Need to identify the table in the sql
					,isnull(somain.pono,plmain.pono) as pono
					,case when ar5.lprepay = 1 then cast(0.00 as numeric(20,2)) else ar5.invtotal end as InvTotal/*11/20/2014 DRP: AR5.INVTOTAL*/
					, ARWO5.WODATE AS CREDITDATE, 'Write-off:  ' + ARWO5.arwounique as credit_Ref, -arwo5.wo_amt as BalAmt, 
					a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End,a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start, a4.nEnd AS R4End,
/*02/27/2014 DRP:  --CASE WHEN @lcAgeBy ='Due Date' THEN ar5.Due_Date ELSE ar5.InvDate END AS AgeDate*/
				  case when @lcAgeBy = 'Due Date' and ar5.lPrepay = 0 then ar5.DUE_DATE else 
					case when @lcAgeBy = 'Due Date' and  ar5.lprepay = 1 then @lcdate else 
						case when @lcAgeBy = 'Invoice Date' and ar5.lprepay = 0 then ar5.InvDate else
							case when @lcAgeBy = 'Invoice date' and ar5.lprepay = 1 then @lcDate end end end end as AgeDate ,c5.phone,c5.Terms,c5.credLimit		   
					-- 02/29/16 VL added FC fields
					,case when ar5.lprepay = 1 then cast(0.00 as numeric(20,2)) else ar5.invtotalFC end as InvTotalFC, -arwo5.wo_amtFC as BalAmtFC
					,TF.Symbol AS TSymbol
					-- 01/06/17 VL added Functional currency fields
					,case when ar5.lprepay = 1 then cast(0.00 as numeric(20,2)) else ar5.invtotalPR end as InvTotalPR, -arwo5.wo_amtPR as BalAmtPR
					,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol, ar5.FCUSED_UNIQ
		from		DBO.ACCTSREC AS AR5 
						-- 01/06/17 VL added to show currency symbol
						left outer JOIN Fcused PF ON AR5.PrFcused_uniq = PF.Fcused_uniq
						left outer JOIN Fcused FF ON AR5.FuncFcused_uniq = FF.Fcused_uniq			
						left outer JOIN Fcused TF ON AR5.Fcused_uniq = TF.Fcused_uniq					
						INNER JOIN DBO.CUSTOMER AS C5 ON AR5.CUSTNO = C5.CUSTNO INNER JOIN
						DBO.AR_WO AS ARWO5 ON ARWO5.UniqueAr = AR5.UniqueAr 
						left outer join plmain on ar5.invno = plmain.invoiceno
						left outer join somain on plmain.sono = somain.sono
						CROSS JOIN
							  dbo.AgingRangeSetup AS a2 CROSS JOIN
							  dbo.AgingRangeSetup AS a3 CROSS JOIN
							  dbo.AgingRangeSetup AS a4 CROSS JOIN
							  dbo.AgingRangeSetup AS a1
		WHERE     (a1.cType = 'AR') and (a1.nRange = 1) AND (a2.cType = 'AR') AND (a2.nRange = 2) 
							  AND (a3.cType = 'AR') AND (a3.nRange = 3) AND (a4.cType = 'AR') AND (a4.nRange = 4)
							 
		) t1
/*02/18/2014 DRP:   it was not correct to filter off of the Trans_dt
		where (DATEPART(Year,t1.CreditDate)<DatePart(Year,@lcDate)) 
			OR (DATEPART(Year,t1.CreditDate)=DatePart(Year,@lcDate) and DATEPART(Month,t1.CreditDate)<DatePart(Month,@lcDate))
			OR (DATEPART(Year,t1.CreditDate)=DatePart(Year,@lcDate) and DATEPART(Month,t1.CreditDate)=DatePart(Month,@lcDate) AND DatePart(Day,t1.CreditDate)<=DatePart(Day,@lcDate)) 
*/	
		where  DATEDIFF(Day,t1.CreditDate,@lcdate)>=0 
			   and 1= case WHEN t1.custNO IN (SELECT custno FROM @CUSTOMER) THEN 1 ELSE 0  END 
		-- 01/06/17 VL added invtotlPR
		group by t1.FSymbol,t1.PSymbol,t1.TSymbol,t1.CUSTNO,t1.custname,/*t1.UNIQUEAR,*/t1.INVNO,t1.pono,t1.invdate, t1.due_date,t1.invtotal, t1.invtotalFC,t1.invtotalPR,t1.R1Start, t1.R1End, t1.R2Start, t1.R2End
		, t1.R3Start, t1.R3End, t1.R4Start, t1.R4End,t1.AgeDate,t1.phone,t1.terms,t1.CredLimit,t1.FCUSED_UNIQ
		--order by custname, invno
		)
		-- 02/29/16 VL list the detail of fields
		-- 08/22/17 VL: found we never saved fchist_key in @Results, so when re-calculating with new rate, never update correctly, added fchist_key, also added fcused_uniq
		-- 10/06/17 VL removed fchist_key
		--insert into @results select * from tresults where BalAmtFC <> 0.00 
		INSERT INTO @results (Custno, Custname,Invno, Pono, Invdate, due_date, Invtotal, Balamt, [Current], range1, range2, range3, range4,[over],R1Start, R1End
					,R2Start,R2End,R3Start,R3End,R4Start,R4End,AsOfDate,PHONE,TERMS,credLimit,InvTotalFC,BalAmtFC,CurrentFC,range1FC, range2FC, range3FC, range4FC,OverFC, 
					-- 01/06/17 VL added functional currency fields
					InvTotalPR,BalAmtPR,CurrentPR,range1PR, range2PR, range3PR, range4PR,OverPR, TSymbol, FSymbol, PSymbol, Fcused_uniq)
			SELECT Custno, Custname,Invno, Pono, Invdate, due_date, Invtotal, Balamt, [Current], range1, range2, range3, range4,[over],R1Start, R1End
					,R2Start,R2End,R3Start,R3End,R4Start,R4End,AsOfDate,PHONE,TERMS,credLimit,InvTotalFC,BalAmtFC,CurrentFC,range1FC, range2FC, range3FC, range4FC,OverFC, 
					-- 01/06/17 VL added functional currency fields
					InvTotalPR,BalAmtPR,CurrentPR,range1PR, range2PR, range3PR, range4PR,OverPR, TSymbol, FSymbol, PSymbol, Fcused_uniq
				--	05/12/2016 VL:	 Added BalAmt <> 0.00 in addition to BalAmtFC <> 0.00 to avoid those balance = 0 records with 1 cent rounding issue appear in report
				FROM  tresults 
				--where BalAmtFC <> 0.00 or BalAmt <> 0.00 --02/07/17 DRP:  change to be or instead of and
				-- 09/21/17 VL changed to check different fields based on if FC is installed or not
				--where BalAmt <> 0.00 --05/09/17 DRP:  replaced the above
				WHERE 1 = CASE WHEN @lFCInstalled = 1 AND BalAmtFC <> 0 THEN 1
							   WHEN @lFCInstalled = 0 AND BalAmt <> 0 THEN 1 ELSE 0 END
	

	-- 02/29/16 VL added code to update values with latest rate if @llLatestRate = 1, in current 962 Penang, they always use latest rate to calculate
	IF @lLatestRate = 'Yes'
		BEGIN
		-- 08/22/17 VL comment out the code that use dbo.fn_CalculateFCRateVariance() function to calculate latest rate, it used the ratio of rate changes, sometimes caused $0.01 difference
		-- changed to use FC value/latest rate to get the new func or pr values
		---- 01/06/17 VL added one more parameter which is the rate ratio calculated based on functional currency or presentation currency
		--UPDATE @Results SET Old2NewRate = dbo.fn_CalculateFCRateVariance(FcHist_key,'F')
		--UPDATE @results SET InvTotal = Old2NewRate*INVTOTAL,
		--					BalAmt = Old2NewRate*BalAmt,
		--					[Current] = Old2NewRate*[Current],
		--					Range1 = Old2NewRate*Range1,
		--					Range2 = Old2NewRate*Range2,
		--					Range3 = Old2NewRate*Range3,
		--					Range4 = Old2NewRate*Range4,
		--					[Over] = Old2NewRate*[Over]
		---- 01/06/17 VL added to update presentation currency fields
		--UPDATE @Results SET Old2NewRate = dbo.fn_CalculateFCRateVariance(FcHist_key,'P')
		--UPDATE @results SET InvTotalPR = Old2NewRate*INVTOTALPR,
		--					BalAmtPR = Old2NewRate*BalAmtPR,
		--					[CurrentPR] = Old2NewRate*[CurrentPR],
		--					Range1PR = Old2NewRate*Range1PR,
		--					Range2PR = Old2NewRate*Range2PR,
		--					Range3PR = Old2NewRate*Range3PR,
		--					Range4PR = Old2NewRate*Range4PR,
		--					[OverPR] = Old2NewRate*[OverPR]
		-- 08/22/17 VL start new code
		-- 08/25/17 VL added ROUND()
		UPDATE @results SET InvTotal = ROUND(InvTotalFC/F.AskPrice,2),
							BalAmt = ROUND(BalAmtFC/F.AskPrice,2),
							[Current] = ROUND([CurrentFC]/F.AskPrice,2),
							Range1 = ROUND(Range1FC/F.AskPrice,2),
							Range2 = ROUND(Range2FC/F.AskPrice,2),
							Range3 = ROUND(Range3FC/F.AskPrice,2),
							Range4 = ROUND(Range4FC/F.AskPrice,2),
							[Over] = ROUND([OverFC]/F.AskPrice,2), 
							InvTotalPR = ROUND(InvTotalFC/F.AskPricePR,2),
							BalAmtPR = ROUND(BalAmtFC/F.AskPricePR,2),
							[CurrentPR] = ROUND([CurrentFC]/F.AskPricePR,2),
							Range1PR = ROUND(Range1FC/F.AskPricePR,2),
							Range2PR = ROUND(Range2FC/F.AskPricePR,2),
							Range3PR = ROUND(Range3FC/F.AskPricePR,2),
							Range4PR = ROUND(Range4FC/F.AskPricePR,2),
							[OverPR] = ROUND([OverFC]/F.AskPricePR,2)
				FROM @results R, @tFcusedView F
				WHERE R.Fcused_uniq = F.FCUsed_Uniq
		-- 08/22/17 VL End}

	END

/*10/02/2014 DRP:*/ --added below so results would work for both QuickView and Reports		
--use dynamic SQL to assign an actual range as a column name in place of 'Range1','Range2',... 'Range4'
	declare @sql nvarchar(max)
			Begin
				set @sql= 	
					-- 01/06/17 VL added functional currency fields
					'SELECT CustName ,InvNo,InvDate,Due_Date,PoNo,InvTotal,BalAmt,[Current],'+@cols+ '
					,[Over],R1Start,R1end,R2Start,R2End,R3Start,R3End,R4Start,R4End,CustNo,Phone,Terms,credlimit
					,Range1,Range2,Range3,Range4,AsOfDate,InvTotalFC,BalAmtFC,CurrentFC,OverFC,Range1FC,Range2FC,Range3FC,Range4FC,
					InvTotalPR,BalAmtPR,CurrentPR,OverPR,Range1PR,Range2PR,Range3PR,Range4PR,TSymbol,FSymbol,PSymbol
					FROM @results ORDER BY TSymbol,Custname, Invno';

					--sp_executesql procedure will take second parameter as User defined table type (UDTT) and we will pass @result table variable 
					execute sp_executesql @sql,N'@results tArAgingFC READONLY',@results
			end
/*10/02/2014 DRP:  End Add*/
END