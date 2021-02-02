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
		--				04/18/2016 VL:	 added dbo.ACCTSREC.INVTOTALFC - dbo.ACCTSREC.ARCREDITSFC <> 0 criteria in addition to dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS <> 0) , so like Penang they have 1 cent difference in HC won't show
		-- =============================================
		CREATE PROCEDURE [dbo].[rptArAgeDetailWM]
--declare
		@lcCustNo as varchar(max) = 'All'		--customer number selection  
		,@lcAgedOn as char(12) = 'Invoice Date'		-- 12/20/2013 DRP: (Invoice Date or Due Date)  Added to be used for the WebManex Reports and Quickviews.  CR is not using it at this time. 
		,@lcRptType as char(10) = 'Detailed'			--12/20/2013 DRP:  (Detailed or Summary)  Added for Quickview results so it knows to display detailed or summary results.
		--,@lcIsReport as bit = 1			--09/19/2014 removed this parameter --07/25/2013 DRP:  Found that the CR report does not handle the changing of the resulting fields/columns.  We will use the parameter to determine which results will be displayed
												--				   1 = Crystal or Stimulsoft Report . . .  0 =  WebManex QuickView results
		,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
		, @userId uniqueidentifier= null


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
		and (dbo.ACCTSREC.INVTOTAL - dbo.ACCTSREC.ARCREDITS <> 0) AND (a1.cType = 'AR') AND (a1.nRange = 1) AND (a2.cType = 'AR') AND (a2.nRange = 2) AND 
                      (a3.cType = 'AR') AND (a3.nRange = 3) AND (a4.cType = 'AR') AND (a4.nRange = 4)
		-- 04/18/16 VL added dbo.ACCTSREC.INVTOTALFC - dbo.ACCTSREC.ARCREDITSFC <> 0)
		AND (dbo.ACCTSREC.INVTOTALFC - dbo.ACCTSREC.ARCREDITSFC <> 0)


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
	

/* 09/18/2014 DRP***************************************************/
/*the below section of code was removed and replaced by the above. */
/*******************************************************************/
----use dynamic SQL to assign an actual range as a column name in place of 'Range1','Range2',... 'Range4'
--	declare @sql nvarchar(max)
--	if (@lcRptType = 'Detailed')
--	Begin
--		if(@lcIsReport = 1)
--			Begin
--				select * from @results
--			End
--		else if (@lcIsReport = 0)
--			Begin
--				set @sql= 	
--					'SELECT CustName ,InvNo,InvDate,Due_Date,PoNo
--					,InvTotal,BalAmt,[Current],'+@cols+ 
--										 ',[Over],R1Start,R1end,R2Start,R2End,R3Start,R3End,R4Start,R4End,CustNo,Phone,Terms FROM @results';
				
--					--sp_executesql procedure will take second parameter as User defined table type (UDTT) and we will pass @result table variable 
--					execute sp_executesql @sql,N'@results tArAging READONLY',@results
--				end
--	end
	
----These results will be used only for the WebManex QuickView results if the users selects to view the Summary version of the report.
--	else if (@lcRptType = 'Summary')
--	Begin
--		if(@lcIsReport = 1)
--			Begin
--				Select	custname,Custno,phone,SUM(InvTotal) as InvTotal,SUM(BalAmt) as BalAmt,SUM([Current]) as [Current],SUM(Range1) as Range1,SUM(Range2) as Range2,SUM(Range3) as Range3
--						,SUM(Range4) as Range4,sum([Over])as [Over],R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End,terms,credlimit
--				from	@results
--				group by CustName,Custno,Phone,R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End,terms,credlimit
--			End-- if(@lcIsReport = 1)
--		else if (@lcIsReport = 0)
--			Begin
--				set @Sql='
--				SELECT CustName,CustNo,phone,InvTotal,BalAmt,[Current],'+@cols+',[Over],terms,credlimit,R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End
--				FROM(
--				Select	CustName,CustNo,phone,SUM(InvTotal) as InvTotal,SUM(BalAmt) as BalAmt,SUM([Current]) as [Current],
--						SUM([Over]) as [Over],terms,Credlimit
--						,SUM(Range1) as Range1,SUM(Range2) as Range2,SUM(Range3) as Range3
--						,SUM(Range4) as Range4,R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End
--				from	@results
--				group by CustName,CustNo,Phone,terms,credlimit,R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End ) S ';
				
--				--sp_executesql procedure will take second parameter as User defined table type (UDTT) and we will pass @result table variable 
--				execute sp_executesql @sql,N'@results tArAging READONLY',@results
--			end--- else if (@lcIsReport = 0)
--	End -- if (@lcRptType = 'Summary')
	
end