		-- =============================================
		-- Author:		<Debbie>
		-- Create date: <11/29/2012>
		-- Description:	<Was created and used on aragedet.rpt ~ aragesum.rpt>
		-- Modified:	11/29/2012 DRP:  This stored procedure repaces the rptArAgeView.  We needed to have the Customer Parameter added into the stored procedure itself and a view does not allow it. 
		--				12/20/2013 DRP:  Created version of the procedure for WebManex.
		--				05/27/2014 DRP:	 Changed how the Customer Listing was pulling data to make sure that it was working properly for the userid.
		--								 Also changed the CURRENT and OVER Formula so when it was a PrePay that it would always populate the balance into the Current Column.
		--				09/19/2014 DRP:  Found that the @lcIsReport parameter was not working as I had invisioned.  If I set the defaultValue to 0 then the Report would not display results, if I default Value was 1 then the QuickView would not be correct
		--								 I had to add Range1, Range2, Range3, Range4 to what I was using as QuickView results and set them to be hidden for the quickView. 	
		--				09/22/2014 DRP:  needed to add DATEDIFF to all of the Ranges.  in the case there were seconds recorded in the fields it would confuse the results and balance would not be populated into the correct aged field. 				
		--								 changed "getdate()-dbo.acctsrec.INVDATE" to "DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate())"  for each Range results
		--				09/30/2014 DRP:  found when I was coping my code changes into the [OVER] section . . I had accidentally left Due_date where I should have changed it to InvDate.  This was causing records to not properly display in the [Over] column
		--								 needed to add case when lPrepay = 1 to all of the Range Results, otherwise it was displaying prepay values in more than one column or not at all
		--								 also had to remove the "case when DATEDIFF(day,getdate(),getdate()) <=0" from the lPrePay Case within the Current calculation   
		--				10/03/2014 DRP:  added [GETDATE() as AsOfDate] to the select statement in order for it to work with the recent change to the tArAging Type.
		--				01/06/2015 DRP:  Added @customerStatus Filter 
		--				02/29/2016 VL:   Copied from [rptArAgeDetailWM] and added code for foreign currency, if @lLatestRate = 1, will update home value to show latest rate
		--				12/06/16 DRP:  Made modifications to account for the Func Currency system
-- 08/22/17 VL: decided to calculate latest rate by FC value/latest ask price, not use the dbo.fn_CalculateFCRateVariance() which calculate the ratio of changing which might cause $0.01 difference, also added fcused_uniq in tArAgingFC
-- 08/25/17 VL: found I should added round() to the latest rate calculation
-- 03/02/20 VL Fixed the CType = 'AP' to cType = 'AR' 
-- 04/22/20 VL comment out FC vaule <> 0 code for FC not installed
-- 06/16/20 VL Changed dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS <> 0 to > 0 to work the same as cube, zendesk#6369
		-- =============================================
		CREATE PROCEDURE [dbo].[rptArAgeDetailWMFC]
--declare
		@lcCustNo as varchar(max) = 'All'		--customer number selection  
		,@lcAgedOn as char(12) = 'Invoice Date'		-- 12/20/2013 DRP: (Invoice Date or Due Date)  Added to be used for the WebManex Reports and Quickviews.  CR is not using it at this time. 
		,@lcRptType as char(10) = 'Detailed'			--12/20/2013 DRP:  (Detailed or Summary)  Added for Quickview results so it knows to display detailed or summary results.
		--,@lcIsReport as bit = 1			--09/19/2014 removed this parameter --07/25/2013 DRP:  Found that the CR report does not handle the changing of the resulting fields/columns.  We will use the parameter to determine which results will be displayed
												--				   1 = Crystal or Stimulsoft Report . . .  0 =  WebManex QuickView results
		,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
		, @userId uniqueidentifier= null
		-- 02/29/16 VL added to show values in latest rate or not
		,@lLatestRate bit = 1 -- Penang always use latest rate to show


as
begin


/*CUSTOMER LIST*/		
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
/*05/27/2014 DRP:  Replaced by the above Customer List
----allow @lcCustNo to have multiple csv
--declare  @CustNo table (Custno char(10))
--	if @lcCustNo<>'All' and @lcCustNo<>'' and @lcCustNo is not null
--		insert into @Custno  select * from  dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
*/


-- 02/10/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()


/******FC NOT INSTALLED******/
	Begin	
	IF @lFCInstalled = 0 
	-- FC not installed		
		BEGIN
			-- string for the names of the columnsbased on the AgingRangeSetup
			declare @cols as nvarchar(max)

			select @cols = STUFF((
				SELECT ',' + C.Name  
					from (select nRange,'Range'+RTRIM(cast(nRange as int))+' as ['+cast(nStart as varchar(4))+'-'+cast(nEND as varchar(4))+']' name from AgingRangeSetup where AgingRangeSetup.cType='AR' ) C
				ORDER BY C.nRange
				FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'');

			--populating the @results with the system type tArAging 
			declare @results as tArAging
			insert into @results

			SELECT    dbo.ACCTSREC.CUSTNO,dbo.customer.custname,dbo.ACCTSREC.INVNO,somain.PONO,isnull(dbo.ACCTSREC.INVDATE,getdate()) as InvDate, dbo.ACCTSREC.DUE_DATE as Due_Date  
					  ,CASE WHEN LEFT(dbo.acctsrec.invno, 4) = 'PPay' THEN 000000000.00 ELSE dbo.ACCTSREC.INVTOTAL END AS InvTotal,dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS AS BalAmt
					  ,case when @lcAgedOn = 'Invoice Date' then
						 case when lPrepay = 1 then ACCTSREC.INVTOTAL - ACCTSREC.ARCREDITS else 
							case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())<=0 then dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS	else 000000000.00 end 
						 end 
					   else case when @lcAgedOn = 'Due Date' then
						 case when lprepay = 1 then ACCTSREC.INVTOTAL - ACCTSREC.ARCREDITS else
							case when DATEDIFF(Day,ISNULL(ACCTSREC.Due_Date,GETDATE()),GETDATE())<=0 then dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000.00 end 
						 end 
					   end
					   end as [Current]
					   ,case when @lcAgedOn = 'Invoice Date' then 
							case when lPrepay = 1 then 000000000.00 else
								case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())>= a1.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a1.nEnd then 
									dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000.00 end
							end
						 else case when @lcAgedOn = 'Due Date' then 
							case when lPrepay = 1 then 000000000.00 else
								case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a1.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a1.nEnd then 
									dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000-00 end end end end as Range1					
		  				,case when @lcAgedOn = 'Invoice Date' then
		  					case when lPrepay = 1 then 000000000.00 else
								case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())>= a2.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a2.nEnd then 
									dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000.00 end
							end
						 else case when @lcAgedOn = 'Due Date' then 
							case when lPrepay = 1 then 000000000.00 else
								case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a2.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a2.nEnd then
									dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000-00 end end end end as Range2		 					
						,case when @lcAgedOn = 'Invoice Date' then
							case when lPrepay = 1 then 000000000.00 else
								case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())>= a3.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a3.nEnd then 
									dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000.00 end
							end
						 else case when @lcAgedOn = 'Due Date' then 
							 case when lPrepay = 1 then 000000000.00 else
								case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a3.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a3.nEnd then
								dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000-00 end end end end as Range3	
						,case when @lcAgedOn = 'Invoice Date' then
							case when lPrepay = 1 then 000000000.00 else
								case when DATEDIFF(Day,ISNULL(ACCTSREC.INVDATE,GETDATE()),GETDATE())>= a4.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a4.nEnd then
									dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000.00 end
							end
						 else case when @lcAgedOn = 'Due Date' then
							case when lPrepay = 1 then 000000000.00 else 
								case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a4.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a4.nEnd then
									dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000.00 end end end end as Range4							
						,case when @lcAgedOn ='Invoice Date' then
							case when lPrepay = 1 then 000000000.00 else
								case when DATEDIFF(day,ISNULL(ACCTSREC.INVDATE,GETDATE()),GETDATE()) > a4.nend then	dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000.00 end
							end
						 else case when @lcAgedOn = 'Due Date' then
							case when lPrepay = 1 then 000000000.00 else
								case when DATEDIFF(Day,ISNULL(ACCTSREC.DUE_DATE,GETDATE()),GETDATE())> a4.nEnd then	dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000.00 end
							end else 000000000.00 end end as [Over] 
						 ,a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End, a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start,a4.nEnd as R4End
						,GETDATE() as AsOfDate ,Customer.phone,Customer.terms,Customer.credlimit 
					
			/*09/30/2014:replaced with the above, the value was not being displayed in the right columns for PrePays or sometimes there would be no totals when they were needed.
					--,case when @lcAgedOn = 'Invoice Date' then
					--	case when lPrepay = 1 then 
					--		case when DATEDIFF(day,getdate(),getdate()) <=0  then ACCTSREC.INVTOTAL - ACCTSREC.ARCREDITS else 
					--  			case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())<=0 then dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS	else 
					--  				000000000.00 
					--			end 
					--		end
					--	 else 00000000.00
					--	end
					--   else case when @lcAgedOn = 'Due Date' then
					--	case when lprepay = 1 then 
					--		case when DATEDIFF(day,getdate(),getdate()) <=0  then ACCTSREC.INVTOTAL - ACCTSREC.ARCREDITS else
					--			case when DATEDIFF(Day,ISNULL(ACCTSREC.Due_Date,GETDATE()),GETDATE())<=0 then dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 
					--				000000000.00 
					--			end 
					--		end 
					--	else 00000000.00 
					--   end 
					--   end
					--   end as [Current]	
			/*05/27/2014 DRP:  needed to replace with the above in order to get prepayment to display in the Current column					
					  --,case when @lcAgedOn = 'Invoice Date' then 
							--case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())<=0 then 
							--	dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
							--		else 000000000.00 end 
					  -- else case when @lcAgedOn = 'Due Date' then
							--case when DATEDIFF(Day,ISNULL(ACCTSREC.Due_Date,GETDATE()),GETDATE())<=0 then  
							--	dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000.00 end end end as [Current]
			05/27/2014 END*/	
					--,case when @lcAgedOn = 'Invoice Date' then 
					--				case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())>= a1.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a1.nEnd then 
					--				dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
					--					else 000000000.00 end
					--		 else case when @lcAgedOn = 'Due Date' then 
					--				case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a1.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a1.nEnd then 
					--				dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
					--					else 000000000-00 end end end as Range1					
					--  	,case when @lcAgedOn = 'Invoice Date' then
					--				case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())>= a2.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a2.nEnd then 
					--				dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
					--					else 000000000.00 end
					--		 else case when @lcAgedOn = 'Due Date' then 
					--				case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a2.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a2.nEnd then
					--				dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
					--					else 000000000-00 end end end as Range2		 					
					--	,case when @lcAgedOn = 'Invoice Date' then
					--			case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())>= a3.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a3.nEnd then 
					--				dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS 
					--					else 000000000.00 end
					--		 else case when @lcAgedOn = 'Due Date' then 
					--			case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a3.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a3.nEnd then
					--				dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
					--					else 000000000-00 end end end as Range3	
					--	,case when @lcAgedOn = 'Invoice Date' then
					--			case when DATEDIFF(Day,ISNULL(ACCTSREC.INVDATE,GETDATE()),GETDATE())>= a4.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a4.nEnd then
					--				dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
					--					else 000000000.00 end
					--		 else case when @lcAgedOn = 'Due Date' then 
					--			case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a4.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a4.nEnd then
					--				dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
					--					else 000000000.00 end end end as Range4							
					--	,case when @lcAgedOn ='Invoice Date' then
					--		case when lPrepay = 1 then 000000000.00 else
					--				case when DATEDIFF(day,ISNULL(ACCTSREC.Due_DATE,GETDATE()),GETDATE()) > a4.nend then	dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS 
					--				end
					--		end
				
					--	 else case when @lcAgedOn = 'Due Date' then
					--		case when lPrepay = 1 then 000000000.00 else
					--				case when DATEDIFF(Day,ISNULL(ACCTSREC.DUE_DATE,GETDATE()),GETDATE())> a4.nEnd then	dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS 
					--				end
					--		end
					--		else 000000000.00
					--	 end
					--	 end as [Over] 
			/*05/27/2014 DRP:  needed to replace with the above in order to get prepayment to display in the OVER column	
						--,case when @lcAgedOn ='Invoice Date' then	
						--		case when DATEDIFF(day,ISNULL(ACCTSREC.INVDATE,GETDATE()),GETDATE()) > a4.nend then 
						--			dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
						--				else 000000000.00 end 
						--	 else case when @lcAgedOn = 'Due Date' then 
						--		case when DATEDIFF(Day,ISNULL(ACCTSREC.DUE_DATE,GETDATE()),GETDATE())> a4.nEnd then
						--			dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
						--				else 000000000.00 end end end as [Over]
			05/27/2014 END*/
					--,a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End, a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start,a4.nEnd as R4End
					--	,Customer.phone,Customer.terms,Customer.credlimit 
			09/30/2014 DRP 	Replacement end*/	

  
			FROM         dbo.ACCTSREC INNER JOIN
								  dbo.CUSTOMER ON dbo.ACCTSREC.CUSTNO = dbo.CUSTOMER.CUSTNO left outer join 
								  plmain on dbo.ACCTSREC.CUSTNO = dbo.plmain.CUSTNO and dbo.acctsrec.INVNO = dbo.plmain.INVOICENO left outer join
								  somain on plmain.SONO = somain.sono  cross JOIN
								  dbo.AgingRangeSetup AS a2 CROSS JOIN
								  dbo.AgingRangeSetup AS a3 CROSS JOIN
								  dbo.AgingRangeSetup AS a4 CROSS JOIN
								  dbo.AgingRangeSetup AS a1 
                      
			WHERE	/*05/27/2014 DRP: --1= CASE WHEN @lcCustNo = 'All' then 1 WHEN Customer.CustNo IN (select CustNo from @custno ) then 1 ELSE 0 END*/
					1 = case when Customer.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
					-- 06/16/20 VL Changed dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS <> 0 to > 0 to work the same as cube
					-- and (dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS <> 0)
					and (dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS > 0)
					AND (a1.cType = 'AR') AND (a1.nRange = 1) AND (a2.cType = 'AR') AND (a2.nRange = 2) AND 
								  (a3.cType = 'AR') AND (a3.nRange = 3) AND (a4.cType = 'AR') AND (a4.nRange = 4)
					-- 04/22/20 VL comment out FC vaule <> 0 code for FC not installed
					-- 04/18/16 VL added dbo.ACCTSREC.INVTOTALFC - dbo.ACCTSREC.ARCREDITSFC <> 0)
					-- AND (dbo.ACCTSREC.INVTOTALFC - dbo.ACCTSREC.ARCREDITSFC <> 0)


			ORDER BY dbo.CUSTOMER.CUSTNAME
			--select * from @results

			--use dynamic SQL to assign an actual range as a column name in place of 'Range1','Range2',... 'Range4'
				declare @sql nvarchar(max)
				if (@lcRptType = 'Detailed')
				Begin
						Begin
							set @sql= 	
								'SELECT CustName ,InvNo,InvDate,Due_Date,PoNo,InvTotal,BalAmt,[Current],'+@cols+ '
								,[Over],R1Start,R1end,R2Start,R2End,R3Start,R3End,R4Start,R4End,CustNo,Phone,Terms,credlimit
								,Range1,Range2,Range3,Range4 FROM @results';
				
								--sp_executesql procedure will take second parameter as User defined table type (UDTT) and we will pass @result table variable 
								execute sp_executesql @sql,N'@results tArAging READONLY',@results
							end
				end
	
			--These results will be used only for the WebManex QuickView results if the users selects to view the Summary version of the report.
				else if (@lcRptType = 'Summary')
				Begin
						Begin
							set @Sql='
							SELECT CustName,CustNo,phone,InvTotal,BalAmt,[Current],'+@cols+',[Over],terms,credlimit,R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End
									,Range1,Range2,Range3,Range4
							FROM(
							Select	CustName,CustNo,phone,SUM(InvTotal) as InvTotal,SUM(BalAmt) as BalAmt,SUM([Current]) as [Current],
									SUM([Over]) as [Over],terms,Credlimit
									,SUM(Range1) as Range1,SUM(Range2) as Range2,SUM(Range3) as Range3
									,SUM(Range4) as Range4,R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End
							from	@results
							group by CustName,CustNo,Phone,terms,credlimit,R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End ) S ';
				
							--sp_executesql procedure will take second parameter as User defined table type (UDTT) and we will pass @result table variable 
							execute sp_executesql @sql,N'@results tArAging READONLY',@results
						end--- else if (@lcIsReport = 0)
				End -- if (@lcRptType = 'Summary')


	END


	ELSE
		
/******FC INSTALLED******/		   
	BEGIN
			-- string for the names of the columnsbased on the AgingRangeSetup
			declare @colsFC as nvarchar(max)
			-- 03/02/20 VL Fixed the CType = 'AP' to cType = 'AR' 
			select @colsFC = STUFF((
				SELECT ',' + C.Name  
					from (select nRange,'Range'+RTRIM(cast(nRange as int))+' as ['+cast(nStart as varchar(4))+'-'+cast(nEND as varchar(4))+']'+
						', Range'+RTRIM(cast(nRange as int))+'FC as ['+cast(nStart as varchar(4))+'-'+cast(nEND as varchar(4))+'FC]'+ 
						', Range'+RTRIM(cast(nRange as int))+'PR as ['+cast(nStart as varchar(4))+'-'+cast(nEND as varchar(4))+'PR]'
						name from AgingRangeSetup where AgingRangeSetup.cType='AR' ) C
				ORDER BY C.nRange
				FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'');

		-- 08/22/17 VL create a table variable to save FcUsedView, and use this table variable to update latest rate
		DECLARE @tFcusedView TABLE (FCUsed_Uniq char(10), Country varchar(60), CURRENCY varchar(40), Symbol varchar(3), Prefix varchar(7), UNIT varchar(10), Subunit varchar(10), Thou_sep varchar(1), Deci_Sep varchar(1), 
				Deci_no numeric(2,0), AskPrice numeric(13,5), AskPricePR numeric(13,5), Fchist_key char(10), Fcdatetime smalldatetime)
		INSERT @tFcusedView EXEC FcusedView

		declare @resultsFC as tArAgingFC


				insert into @resultsFC

				SELECT    dbo.ACCTSREC.CUSTNO,dbo.customer.custname,dbo.ACCTSREC.INVNO,somain.PONO,isnull(dbo.ACCTSREC.INVDATE,getdate()) as InvDate, dbo.ACCTSREC.DUE_DATE as Due_Date  
						  ,CASE WHEN LEFT(dbo.acctsrec.invno, 4) = 'PPay' THEN 000000000.00 ELSE dbo.ACCTSREC.INVTOTAL END AS InvTotal,dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS AS BalAmt
						  ,case when @lcAgedOn = 'Invoice Date' then
							 case when lPrepay = 1 then ACCTSREC.INVTOTAL - ACCTSREC.ARCREDITS else 
								case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())<=0 then dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS	else 000000000.00 end 
							 end 
						   else case when @lcAgedOn = 'Due Date' then
							 case when lprepay = 1 then ACCTSREC.INVTOTAL - ACCTSREC.ARCREDITS else
								case when DATEDIFF(Day,ISNULL(ACCTSREC.Due_Date,GETDATE()),GETDATE())<=0 then dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000.00 end 
							 end 
						   end
						   end as [Current]
						   ,case when @lcAgedOn = 'Invoice Date' then 
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())>= a1.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a1.nEnd then 
										dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000.00 end
								end
							 else case when @lcAgedOn = 'Due Date' then 
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a1.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a1.nEnd then 
										dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000-00 end end end end as Range1					
		  					,case when @lcAgedOn = 'Invoice Date' then
		  						case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())>= a2.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a2.nEnd then 
										dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000.00 end
								end
							 else case when @lcAgedOn = 'Due Date' then 
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a2.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a2.nEnd then
										dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000-00 end end end end as Range2		 					
							,case when @lcAgedOn = 'Invoice Date' then
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())>= a3.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a3.nEnd then 
										dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000.00 end
								end
							 else case when @lcAgedOn = 'Due Date' then 
								 case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a3.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a3.nEnd then
									dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000-00 end end end end as Range3	
							,case when @lcAgedOn = 'Invoice Date' then
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(ACCTSREC.INVDATE,GETDATE()),GETDATE())>= a4.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a4.nEnd then
										dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000.00 end
								end
							 else case when @lcAgedOn = 'Due Date' then
								case when lPrepay = 1 then 000000000.00 else 
									case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a4.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a4.nEnd then
										dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000.00 end end end end as Range4							
							,case when @lcAgedOn ='Invoice Date' then
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(day,ISNULL(ACCTSREC.INVDATE,GETDATE()),GETDATE()) > a4.nend then	dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000.00 end
								end
							 else case when @lcAgedOn = 'Due Date' then
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(ACCTSREC.DUE_DATE,GETDATE()),GETDATE())> a4.nEnd then	dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000.00 end
								end else 000000000.00 end end as [Over] 
							 ,a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End, a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start,a4.nEnd as R4End
							,GETDATE() as AsOfDate ,Customer.phone,Customer.terms,Customer.credlimit 
				-- 02/29/16 VL added FC fields
							,CASE WHEN LEFT(dbo.acctsrec.invno, 4) = 'PPay' THEN 000000000.00 ELSE dbo.ACCTSREC.INVTOTALFC END AS InvTotalFC,dbo.ACCTSREC.INVTOTALFC - dbo.ACCTSREC.ARCREDITSFC AS BalAmtFC
						  ,case when @lcAgedOn = 'Invoice Date' then
							 case when lPrepay = 1 then ACCTSREC.INVTOTALFC - ACCTSREC.ARCREDITSFC else 
								case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())<=0 then dbo.ACCTSREC.INVTOTALFC - dbo.ACCTSREC.ARCREDITSFC	else 000000000.00 end 
							 end 
						   else case when @lcAgedOn = 'Due Date' then
							 case when lprepay = 1 then ACCTSREC.INVTOTALFC - ACCTSREC.ARCREDITSFC else
								case when DATEDIFF(Day,ISNULL(ACCTSREC.Due_Date,GETDATE()),GETDATE())<=0 then dbo.ACCTSREC.INVTOTALFC - dbo.ACCTSREC.ARCREDITSFC else 000000000.00 end 
							 end 
						   end
						   end as [CurrentFC]
						   ,case when @lcAgedOn = 'Invoice Date' then 
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())>= a1.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a1.nEnd then 
										dbo.ACCTSREC.INVTOTALFC - dbo.ACCTSREC.ARCREDITSFC else 000000000.00 end
								end
							 else case when @lcAgedOn = 'Due Date' then 
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a1.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a1.nEnd then 
										dbo.ACCTSREC.INVTOTALFC- dbo.ACCTSREC.ARCREDITSFC else 000000000-00 end end end end as Range1FC					
		  					,case when @lcAgedOn = 'Invoice Date' then
		  						case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())>= a2.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a2.nEnd then 
										dbo.ACCTSREC.INVTOTALFC - dbo.ACCTSREC.ARCREDITSFC else 000000000.00 end
								end
							 else case when @lcAgedOn = 'Due Date' then 
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a2.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a2.nEnd then
										dbo.ACCTSREC.INVTOTALFC - dbo.ACCTSREC.ARCREDITSFC else 000000000-00 end end end end as Range2FC		 					
							,case when @lcAgedOn = 'Invoice Date' then
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())>= a3.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a3.nEnd then 
										dbo.ACCTSREC.INVTOTALFC - dbo.ACCTSREC.ARCREDITSFC else 000000000.00 end
								end
							 else case when @lcAgedOn = 'Due Date' then 
								 case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a3.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a3.nEnd then
									dbo.ACCTSREC.INVTOTALFC - dbo.ACCTSREC.ARCREDITSFC else 000000000-00 end end end end as Range3FC	
							,case when @lcAgedOn = 'Invoice Date' then
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(ACCTSREC.INVDATE,GETDATE()),GETDATE())>= a4.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a4.nEnd then
										dbo.ACCTSREC.INVTOTALFC - dbo.ACCTSREC.ARCREDITSFC else 000000000.00 end
								end
							 else case when @lcAgedOn = 'Due Date' then
								case when lPrepay = 1 then 000000000.00 else 
									case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a4.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a4.nEnd then
										dbo.ACCTSREC.INVTOTALFC - dbo.ACCTSREC.ARCREDITSFC else 000000000.00 end end end end as Range4FC							
							,case when @lcAgedOn ='Invoice Date' then
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(day,ISNULL(ACCTSREC.INVDATE,GETDATE()),GETDATE()) > a4.nend then	dbo.ACCTSREC.INVTOTALFC - dbo.ACCTSREC.ARCREDITSFC else 000000000.00 end
								end
							 else case when @lcAgedOn = 'Due Date' then
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(ACCTSREC.DUE_DATE,GETDATE()),GETDATE())> a4.nEnd then	dbo.ACCTSREC.INVTOTALFC - dbo.ACCTSREC.ARCREDITSFC else 000000000.00 end
								end else 000000000.00 end end as [OverFC] 
							--, Acctsrec.Fcused_uniq AS Fcused_uniq, Fcused.Symbol AS Currency	--12/07/16 DRP:  replaced with the TSymbol,FSymbol,PSymbol
							, Acctsrec.Fchist_key AS Fchist_key, 00.000 AS Old2NewRate
				/*************************************/
							,CASE WHEN LEFT(dbo.acctsrec.invno, 4) = 'PPay' THEN 000000000.00 ELSE dbo.ACCTSREC.INVTOTALPR END AS InvTotalFC,dbo.ACCTSREC.INVTOTALPR - dbo.ACCTSREC.ARCREDITSPR AS BalAmtPR
						  ,case when @lcAgedOn = 'Invoice Date' then
							 case when lPrepay = 1 then ACCTSREC.INVTOTALPR - ACCTSREC.ARCREDITSPR else 
								case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())<=0 then dbo.ACCTSREC.INVTOTALPR - dbo.ACCTSREC.ARCREDITSPR	else 000000000.00 end 
							 end 
						   else case when @lcAgedOn = 'Due Date' then
							 case when lprepay = 1 then ACCTSREC.INVTOTALPR - ACCTSREC.ARCREDITSPR else
								case when DATEDIFF(Day,ISNULL(ACCTSREC.Due_Date,GETDATE()),GETDATE())<=0 then dbo.ACCTSREC.INVTOTALPR - dbo.ACCTSREC.ARCREDITSPR else 000000000.00 end 
							 end 
						   end
						   end as [CurrentPR]
						   ,case when @lcAgedOn = 'Invoice Date' then 
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())>= a1.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a1.nEnd then 
										dbo.ACCTSREC.INVTOTALPR - dbo.ACCTSREC.ARCREDITSPR else 000000000.00 end
								end
							 else case when @lcAgedOn = 'Due Date' then 
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a1.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a1.nEnd then 
										dbo.ACCTSREC.INVTOTALPR- dbo.ACCTSREC.ARCREDITSPR else 000000000-00 end end end end as Range1PR					
		  					,case when @lcAgedOn = 'Invoice Date' then
		  						case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())>= a2.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a2.nEnd then 
										dbo.ACCTSREC.INVTOTALPR - dbo.ACCTSREC.ARCREDITSPR else 000000000.00 end
								end
							 else case when @lcAgedOn = 'Due Date' then 
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a2.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a2.nEnd then
										dbo.ACCTSREC.INVTOTALPR - dbo.ACCTSREC.ARCREDITSPR else 000000000-00 end end end end as Range2PR		 					
							,case when @lcAgedOn = 'Invoice Date' then
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())>= a3.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a3.nEnd then 
										dbo.ACCTSREC.INVTOTALPR - dbo.ACCTSREC.ARCREDITSPR else 000000000.00 end
								end
							 else case when @lcAgedOn = 'Due Date' then 
								 case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a3.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a3.nEnd then
									dbo.ACCTSREC.INVTOTALPR - dbo.ACCTSREC.ARCREDITSPR else 000000000-00 end end end end as Range3PR	
							,case when @lcAgedOn = 'Invoice Date' then
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(ACCTSREC.INVDATE,GETDATE()),GETDATE())>= a4.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a4.nEnd then
										dbo.ACCTSREC.INVTOTALPR - dbo.ACCTSREC.ARCREDITSPR else 000000000.00 end
								end
							 else case when @lcAgedOn = 'Due Date' then
								case when lPrepay = 1 then 000000000.00 else 
									case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a4.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a4.nEnd then
										dbo.ACCTSREC.INVTOTALPR - dbo.ACCTSREC.ARCREDITSPR else 000000000.00 end end end end as Range4PR							
							,case when @lcAgedOn ='Invoice Date' then
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(day,ISNULL(ACCTSREC.INVDATE,GETDATE()),GETDATE()) > a4.nend then	dbo.ACCTSREC.INVTOTALPR - dbo.ACCTSREC.ARCREDITSPR else 000000000.00 end
								end
							 else case when @lcAgedOn = 'Due Date' then
								case when lPrepay = 1 then 000000000.00 else
									case when DATEDIFF(Day,ISNULL(ACCTSREC.DUE_DATE,GETDATE()),GETDATE())> a4.nEnd then	dbo.ACCTSREC.INVTOTALPR - dbo.ACCTSREC.ARCREDITSPR else 000000000.00 end
								end else 000000000.00 end end as [OverPR] 
							,00.000 AS Old2NewRatePR


							,TF.Symbol AS TSymbol, FF.Symbol AS FSymbol, PF.Symbol AS PSymbol	--12/07/16 DRP:  added
							-- 08/22/17 VL added Fcused_uniq
							,Acctsrec.FcUsed_Uniq
				/*09/30/2014:replaced with the above, the value was not being displayed in the right columns for PrePays or sometimes there would be no totals when they were needed.
						--,case when @lcAgedOn = 'Invoice Date' then
						--	case when lPrepay = 1 then 
						--		case when DATEDIFF(day,getdate(),getdate()) <=0  then ACCTSREC.INVTOTAL - ACCTSREC.ARCREDITS else 
						--  			case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())<=0 then dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS	else 
						--  				000000000.00 
						--			end 
						--		end
						--	 else 00000000.00
						--	end
						--   else case when @lcAgedOn = 'Due Date' then
						--	case when lprepay = 1 then 
						--		case when DATEDIFF(day,getdate(),getdate()) <=0  then ACCTSREC.INVTOTAL - ACCTSREC.ARCREDITS else
						--			case when DATEDIFF(Day,ISNULL(ACCTSREC.Due_Date,GETDATE()),GETDATE())<=0 then dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 
						--				000000000.00 
						--			end 
						--		end 
						--	else 00000000.00 
						--   end 
						--   end
						--   end as [Current]	
				/*05/27/2014 DRP:  needed to replace with the above in order to get prepayment to display in the Current column					
						  --,case when @lcAgedOn = 'Invoice Date' then 
								--case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())<=0 then 
								--	dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
								--		else 000000000.00 end 
						  -- else case when @lcAgedOn = 'Due Date' then
								--case when DATEDIFF(Day,ISNULL(ACCTSREC.Due_Date,GETDATE()),GETDATE())<=0 then  
								--	dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS else 000000000.00 end end end as [Current]
				05/27/2014 END*/	
						--,case when @lcAgedOn = 'Invoice Date' then 
						--				case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())>= a1.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a1.nEnd then 
						--				dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
						--					else 000000000.00 end
						--		 else case when @lcAgedOn = 'Due Date' then 
						--				case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a1.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a1.nEnd then 
						--				dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
						--					else 000000000-00 end end end as Range1					
						--  	,case when @lcAgedOn = 'Invoice Date' then
						--				case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())>= a2.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a2.nEnd then 
						--				dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
						--					else 000000000.00 end
						--		 else case when @lcAgedOn = 'Due Date' then 
						--				case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a2.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a2.nEnd then
						--				dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
						--					else 000000000-00 end end end as Range2		 					
						--	,case when @lcAgedOn = 'Invoice Date' then
						--			case when DATEDIFF(Day,ISNULL(acctsrec.INVDATE,GETDATE()),GETDATE())>= a3.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a3.nEnd then 
						--				dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS 
						--					else 000000000.00 end
						--		 else case when @lcAgedOn = 'Due Date' then 
						--			case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a3.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a3.nEnd then
						--				dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
						--					else 000000000-00 end end end as Range3	
						--	,case when @lcAgedOn = 'Invoice Date' then
						--			case when DATEDIFF(Day,ISNULL(ACCTSREC.INVDATE,GETDATE()),GETDATE())>= a4.nStart and DateDiff(day,isnull(dbo.acctsrec.INVDATE ,getdate()),getdate()) <= a4.nEnd then
						--				dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
						--					else 000000000.00 end
						--		 else case when @lcAgedOn = 'Due Date' then 
						--			case when DATEDIFF(Day,ISNULL(acctsrec.DUE_DATE,GETDATE()),GETDATE())>= a4.nStart and DateDiff(day,isnull(dbo.acctsrec.DUE_DATE ,getdate()),getdate()) <= a4.nEnd then
						--				dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
						--					else 000000000.00 end end end as Range4							
						--	,case when @lcAgedOn ='Invoice Date' then
						--		case when lPrepay = 1 then 000000000.00 else
						--				case when DATEDIFF(day,ISNULL(ACCTSREC.Due_DATE,GETDATE()),GETDATE()) > a4.nend then	dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS 
						--				end
						--		end
				
						--	 else case when @lcAgedOn = 'Due Date' then
						--		case when lPrepay = 1 then 000000000.00 else
						--				case when DATEDIFF(Day,ISNULL(ACCTSREC.DUE_DATE,GETDATE()),GETDATE())> a4.nEnd then	dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS 
						--				end
						--		end
						--		else 000000000.00
						--	 end
						--	 end as [Over] 
				/*05/27/2014 DRP:  needed to replace with the above in order to get prepayment to display in the OVER column	
							--,case when @lcAgedOn ='Invoice Date' then	
							--		case when DATEDIFF(day,ISNULL(ACCTSREC.INVDATE,GETDATE()),GETDATE()) > a4.nend then 
							--			dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
							--				else 000000000.00 end 
							--	 else case when @lcAgedOn = 'Due Date' then 
							--		case when DATEDIFF(Day,ISNULL(ACCTSREC.DUE_DATE,GETDATE()),GETDATE())> a4.nEnd then
							--			dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS
							--				else 000000000.00 end end end as [Over]
				05/27/2014 END*/
						--,a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End, a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start,a4.nEnd as R4End
						--	,Customer.phone,Customer.terms,Customer.credlimit 
				09/30/2014 DRP 	Replacement end*/	

  
				FROM    Acctsrec inner join      
						-- 12/07/16  DRP added Fcused 3 times to get 3 currencies
											  dbo.Fcused TF ON Acctsrec.Fcused_uniq = TF.Fcused_uniq INNER JOIN
											  dbo.Fcused FF ON Acctsrec.FUNCFCUSED_UNIQ = FF.Fcused_uniq INNER JOIN
											  dbo.Fcused PF ON Acctsrec.PRFcused_uniq = PF.Fcused_uniq INNER JOIN
									  dbo.CUSTOMER ON dbo.ACCTSREC.CUSTNO = dbo.CUSTOMER.CUSTNO left outer join 
									  plmain on dbo.ACCTSREC.CUSTNO = dbo.plmain.CUSTNO and dbo.acctsrec.INVNO = dbo.plmain.INVOICENO left outer join
									  somain on plmain.SONO = somain.sono  cross JOIN
									  dbo.AgingRangeSetup AS a2 CROSS JOIN
									  dbo.AgingRangeSetup AS a3 CROSS JOIN
									  dbo.AgingRangeSetup AS a4 CROSS JOIN
									  dbo.AgingRangeSetup AS a1 
                      
				WHERE	/*05/27/2014 DRP: --1= CASE WHEN @lcCustNo = 'All' then 1 WHEN Customer.CustNo IN (select CustNo from @custno ) then 1 ELSE 0 END*/
						1 = case when Customer.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
						-- 06/16/20 VL Changed dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS <> 0 to > 0 to work the same as cube
						--and (dbo.ACCTSREC.INVTOTALFC - dbo.ACCTSREC.ARCREDITSFC <> 0) 
						and (dbo.ACCTSREC.INVTOTALFC - dbo.ACCTSREC.ARCREDITSFC > 0) 
						AND (a1.cType = 'AR') AND (a1.nRange = 1) AND (a2.cType = 'AR') AND (a2.nRange = 2) AND 
									  (a3.cType = 'AR') AND (a3.nRange = 3) AND (a4.cType = 'AR') AND (a4.nRange = 4)

				ORDER BY FSymbol,TSymbol,PSymbol, dbo.CUSTOMER.CUSTNAME
				--select * from @results order by custname,invno


			-- 02/29/16 VL added code to update values with latest rate if @llLatestRate = 1, in current 962 Penang, they always use latest rate to calculate
			-- 12/07/16 VL/DRP need to account for both the Functional and Presentational Currency

			IF @lLatestRate = 1
				BEGIN
				-- 08/22/17 VL comment out the code that use dbo.fn_CalculateFCRateVariance() function to calculate latest rate, it used the ratio of rate changes, sometimes caused $0.01 difference
				-- changed to use FC value/latest rate to get the new func or pr values
				--UPDATE @ResultsFC SET Old2NewRate = dbo.fn_CalculateFCRateVariance(FcHist_key, 'F'),
				--			Old2NewRatePR = dbo.fn_CalculateFCRateVariance(FcHist_key, 'P')

				---- You need to create InvTotalPR, BalamtPR, Range1PR for all presentation currency fields
				--UPDATE @resultsFC SET InvTotal = Old2NewRate*INVTOTAL,
				--					BalAmt = Old2NewRate*BalAmt,
				--					[Current] = Old2NewRate*[Current],
				--					Range1 = Old2NewRate*Range1,
				--					Range2 = Old2NewRate*Range2,
				--					Range3 = Old2NewRate*Range3,
				--					Range4 = Old2NewRate*Range4,
				--					[Over] = Old2NewRate*[Over],
				--					-- update presentation currency fields
				--					InvTotalPR = Old2NewRatePR*INVTOTALPR,
				--					BalAmtPR = Old2NewRatePR*BalAmtPR,
				--					[CurrentPR] = Old2NewRatePR*[CurrentPR],
				--					Range1PR = Old2NewRatePR*Range1PR,
				--					Range2PR = Old2NewRatePR*Range2PR,
				--					Range3PR = Old2NewRatePR*Range3PR,
				--					Range4PR = Old2NewRatePR*Range4PR,
				--					[OverPR] = Old2NewRatePR*[OverPR]

				-- 08/22/17 VL start new code

				-- 08/25/17 VL added ROUND()
				UPDATE @resultsFC SET InvTotal = ROUND(InvTotalFC/F.AskPrice,5),
									BalAmt = ROUND(BalAmtFC/F.AskPrice,5),
									[Current] = ROUND([CurrentFC]/F.AskPrice,5),
									Range1 = ROUND(Range1FC/F.AskPrice,5),
									Range2 = ROUND(Range2FC/F.AskPrice,5),
									Range3 = ROUND(Range3FC/F.AskPrice,5),
									Range4 = ROUND(Range4FC/F.AskPrice,5),
									[Over] = ROUND([OverFC]/F.AskPrice,5), 
									InvTotalPR = ROUND(InvTotalFC/F.AskPricePR,5),
									BalAmtPR = ROUND(BalAmtFC/F.AskPricePR,5),
									[CurrentPR] = ROUND([CurrentFC]/F.AskPricePR,5),
									Range1PR = ROUND(Range1FC/F.AskPricePR,5),
									Range2PR = ROUND(Range2FC/F.AskPricePR,5),
									Range3PR = ROUND(Range3FC/F.AskPricePR,5),
									Range4PR = ROUND(Range4FC/F.AskPricePR,5),
									[OverPR] = ROUND([OverFC]/F.AskPricePR,5)
						FROM @resultsFC R, @tFcusedView F
						WHERE R.Fcused_uniq = F.FCUsed_Uniq
				-- 08/22/17 VL End}

				/*	--12/07/16 DRP:  replaced with the above 
				--UPDATE @ResultsFC SET Old2NewRate = dbo.fn_CalculateFCRateVariance(FcHist_key)
				--UPDATE @resultsFC SET InvTotal = Old2NewRate*INVTOTAL,
				--					BalAmt = Old2NewRate*BalAmt,
				--					[Current] = Old2NewRate*[Current],
				--					Range1 = Old2NewRate*Range1,
				--					Range2 = Old2NewRate*Range2,
				--					Range3 = Old2NewRate*Range3,
				--					Range4 = Old2NewRate*Range4,
				--					[Over] = Old2NewRate*[Over]
				*/

				END

		--use dynamic SQL to assign an actual range as a column name in place of 'Range1','Range2',... 'Range4'
			declare @sqlFC nvarchar(max)
			if (@lcRptType = 'Detailed')
			Begin
					Begin
						set @sqlFC= 	
							'SELECT CustName ,InvNo,InvDate,Due_Date,PoNo,InvTotal,BalAmt,[Current],'+@colsFC+ '
							,[Over],R1Start,R1end,R2Start,R2End,R3Start,R3End,R4Start,R4End,CustNo,Phone,Terms,credlimit
							,Range1,Range2,Range3,Range4,FSymbol
							,InvTotalFC,BalAmtFC,[CurrentFC],[OverFC],Range1FC,Range2FC,Range3FC,Range4FC,TSymbol
							,InvTotalPR,BalAmtPR,[CurrentPR],[OverPR],Range1PR,Range2PR,Range3PR,Range4PR,PSymbol
							 FROM @resultsFC ORDER BY FSymbol,TSymbol,PSymbol,Custname,Invno';
				
							--sp_executesql procedure will take second parameter as User defined table type (UDTT) and we will pass @result table variable 
							execute sp_executesql @sqlFC,N'@resultsFC tArAgingFC READONLY',@resultsFC
						end
			end
	
		--These results will be used only for the WebManex QuickView results if the users selects to view the Summary version of the report.
			else if (@lcRptType = 'Summary')
			Begin
					Begin
						set @SqlFC='
						SELECT CustName,CustNo,phone,InvTotal,BalAmt,[Current],'+@colsFC+',[Over],terms,credlimit,R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End
								,Range1,Range2,Range3,Range4,FSymbol,InvTotalFC,BalAmtFC,CurrentFC,OverFC,Range1FC,Range2FC,Range3FC,Range4FC,TSymbol
								,InvTotalPR,BalAmtPR,CurrentPR,OverPR,Range1PR,Range2PR,Range3PR,Range4PR,PSymbol
						FROM(
						Select	CustName,CustNo,phone,SUM(InvTotal) as InvTotal,SUM(BalAmt) as BalAmt,SUM([Current]) as [Current],
								SUM([Over]) as [Over],terms,Credlimit
								,SUM(Range1) as Range1,SUM(Range2) as Range2,SUM(Range3) as Range3
								,SUM(Range4) as Range4,R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End,FSymbol
								,SUM(InvTotalFC) as InvTotalFC,SUM(BalAmtFC) as BalAmtFC,SUM(CurrentFC) AS CurrentFC,SUM(OverFC) AS OverFC,SUM(Range1FC) AS Range1FC
								,SUM(Range2FC) AS Range2FC,SUM(Range3FC) AS Range3FC,SUM(Range4FC) AS Range4FC,TSymbol
								,SUM(InvTotalPR) as InvTotalPR,SUM(BalAmtPR) as BalAmtPR,SUM(CurrentPR) AS CurrentPR,SUM(OverPR) AS OverPR,SUM(Range1PR) AS Range1PR
								,SUM(Range2PR) AS Range2PR,SUM(Range3PR) AS Range3PR,SUM(Range4PR) AS Range4PR,PSymbol
						from	@resultsFC
						group by TSymbol,FSymbol,Psymbol,CustName,CustNo,Phone,terms,credlimit,R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End) S ORDER BY TSymbol,FSymbol,PSymbol, Custname';
				
						--sp_executesql procedure will take second parameter as User defined table type (UDTT) and we will pass @result table variable 
						execute sp_executesql @sqlFC,N'@resultsFC tArAgingFC READONLY',@resultsFC
					end--- else if (@lcIsReport = 0)
			End -- if (@lcRptType = 'Summary')

	END
	end
		
end