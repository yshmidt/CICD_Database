-- =============================================
-- Author:		<Debbie>
-- Create date: <11/27/2012>
-- Description:	<Was created and used on apagedet.rpt ~  apagesum.rpt>
-- Modified:	11/27/2012 DRP:  This stored procedure repaces the rptApAgeView.  We needed to have the Supplier Parameter added into the stored procedure itself and a view does not allow it. 
--  07/18/2013 YS:   allow @lcuniqsup have multiple csv
--  07/25/2013 YS:   change Range1,Range2,... columns to show an actual range , i.e Range1 as [1-30],Range2 as [31-60],... where [1-30] comes from AgingRangeSetup table
--  07/25/2013 DRP:  added the @lcIsReport parameter so that we could indicate what type of results to provide.  They had to be different for the CR and the quickview.  CR did not like when the field changed for the Ranges
--  09/20/2013 DRP:  the @lcUniqSup was not working properly for the WebReports.  I removed the * from the parameter default and any place that was calling this parameter
--  12/03/2013  YS:  changed lcUniqSup to take 'All' instead of '' 
--  09/11/2014 DRP:  The Supplier Selection was not properly filtering out per the User Id.   Also removed the micssys from the final results because MRT and QuickView do not require it. 			
--  09/18/2014 DRP:  needed to add Terms to the Summary results. 
--     Found that the @lcIsReport parameter was not working as I had invisioned.  If I set the defaultValue to 0 then the Report would not display results, if I default Value was 1 then the QuickView would not be correct
--     I had to add Range1, Range2, Range3, Range4 to what I was using as QuickView results and set them to be hidden for the quickView. 
--  09/22/2014 DRP:  needed to add DATEDIFF to all of the Ranges.  in the case there were seconds recorded in the fields it would confuse the results and balance would not be populated into the correct aged field.   
--     changed "getdate()-dbo.apmaster.INVDATE" to "DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate())"  for each Range results
--  10/03/2014 DRP:  removed the micssys.lic_name from the results and added AsOfDate to work with the recent changes to the tApAging Type. 
--  12/12/14 DS Added supplier status filter
--  02/03/2016 VL:	 Copied from [rptApAgeDetailWM] and added code for foreign currency, if @lLatestRate = 1, will update home value to show latest rate
--  05/19/2016 DRP:  Changed the @lLatestRate parameter from a bit to char(3) when I will use Yes or No for the Parameter selection options. 
--  07/07/2016 VL:	 Update Appmts with original rate again no matter using latest or original rate, if multiple changes are made to this field with different rate, this field might not be accurate, Barbara did the fix in VFP 10/8/15 for ticket #8232
--  11/21/2016 DRP:	 Needed to make changes for the results to work with both types of systems (Non-FC and FC) Had to insert the two sections. 
--  11/21/2016 VL:	 We added one more (4th) parameter to fn_Convert4FCHC() that's used to convert for functional or presentation currency
--  01/11/2017 VL:	 added one more parameter for fn_CalculateFCRateVariance() which is the rate ratio calculated based on functional currency or presentation currency
--  01/27/2017 VL:	 added functional currency, also changed the non-FC part to work as before, I left the FC fields there that we probably still have the fields on report form, but remove the code that times the rate 
--  01/30/2017 VL:	 Confirmed with Debbie, that we don't need FC fields in non-FC part, so I will remove those FC fields in non-FC part
--  05/24/17 DRP:	under the Foreign Currency section the Where clause <<(dbo.APMASTER.INVAMOUNTFC - dbo.APMASTER.APPMTSFC - dbo.APMASTER.DISC_TKNFC <> 0) or (dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN <> 0) >> was causing 
--		the results to pull all history and it to time out on the Web Screen.  I have changed it to be <<(dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN <> 0)>>
--		there were multiple locations within the Foreign Currency section that it was forgotten to point to the "FC" declared tables, etc. . .
-- 05/25/17 YS check for the balance using FC amount 
-- 09/11/17 VL Added to show proper header for PR values, and change the way to calculate latest rate values 
-- =============================================
create PROCEDURE [dbo].[rptApAgeDetailWMFC]
--declare

 --@lcSup as varchar (35) = '*'			--09/11/2014 DRP:  Removed because it was only used for the CR version of the report
@lcUniqSup as varchar(max) = 'All'		--this was added for the WebManex Version of the report only    --12/03/13  YS    changed lcUniqSup to take 'All' instead of '' 
,@lcAgedOn as char(12) = 'Invoice Date'	-- 07/23/2013 DRP: (Invoice Date or Due Date)  Added to be used for the WebManex Reports and Quickviews.  CR is not using it at this time. 
,@lcRptType as char(10) = 'Detailed'	--07/24/2013 DRP:  (Detailed or Summary)  Added for Quickview results so it knows to display detailed or summary results. 
--,@lcIsReport as bit = 1				--09/18/2014 DRP:  removed this parameter	--07/25/2013 DRP:  Found that the CR report does not handle the changing of the resulting fields/columns.  We will use the parameter to determine which results will be displayed
										--				   1 = Crystal or Stimulsoft Report . . .  0 =  WebManex QuickView results
, @userId uniqueidentifier= null
,@supplierStatus varchar(20) = 'All'
-- 02/03/16 VL added to show values in latest rate or not
,@lLatestRate char(3) = 'No'	--Yes:  it will then use the latest rate to make its calculations.  No:  it will then use the original Exchange rate.	 

as
begin
	--07/25/13 YS need to use user defined table type 
	-- the UDTT should be create prior to this procedure
	-- this code for quick drop and re-create if needed.
	-- do not run it as part of the procedure
--	IF TYPE_ID('tApAging') IS NOT NULL
--	BEGIN
--		 DROP TYPE tApAging
--	END
  
--	CREATE TYPE tApAging AS TABLE
--(SupName CHAR (30),InvNo CHAR(20),InvDate SMALLDATETIME,Due_Date SMALLDATETIME,Trans_Dt SMALLDATETIME,PoNum CHAR (15),InvAmount NUMERIC(12,2)
--							   ,BalAmt NUMERIC(12,2),ApStatus char(15),[Current] numeric(12,2),Range1 numeric(12,2),Range2 numeric(12,2),Range3 numeric(12,2),Range4 numeric(12,2)
--							   ,[Over] numeric(12,2),R1Start numeric(3),R1end numeric(3),R2Start numeric(3),R2End numeric(3),R3Start numeric(3),R3End numeric(3),R4Start numeric(3)
--							   ,R4End numeric(3),UniqSupno char(10),Phone char(19),Terms char(15),Lic_name char(40));

/*SUPPLIER LIST*/	
	----07/18/2013 YS allow @lcuniqsup have multiple csv
	--declare  @unisupno table (uniqsupno char(10))
	----12/03/13  YS    changed lcUniqSup to take 'All' instead of '' 
	--if @lcUniqSup<>'All' and @lcUniqSup<>'' and @lcUniqSup is not null
	--	insert into @unisupno  select * from  dbo.[fn_simpleVarcharlistToTable](@lcUniqSup,',') --09/11/2014 DRP:  This section had to be commented out and replaced with the below to work properly with the User Id


-- get list of approved suppliers for this user
DECLARE @tSupplier tSupplier
declare @tSupNo as table (Uniqsupno char (10))

INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, @supplierStatus;

IF @lcUniqSup<>'All' and @lcUniqSup<>'' and @lcUniqSup is not null
	insert into @tSupNo  select * from  dbo.[fn_simpleVarcharlistToTable](@lcUniqSup,',') WHERE cast(ID as char(10)) IN (SELECT UniqSupno from @tSupplier)
ELSE
	BEGIN
		IF @lcUniqSup='All'
		insert into @tSupno  select UniqSupno from @tSupplier
	END				



-- 11/21/2016 DRPVL added for FC installed or not
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
		
--07/25/13 YS create string for the names of the columnsbased on the AgingRangeSetup
declare @cols as nvarchar(max)
	
--07/25/13 YS use new UDTT tApAging
declare @results as tApAging
	
-- 02/03/16 VL use new tApAgingFC type, try to avoid changing tApAging type
-- 01/30/17 VL renamed @results to resultsFC
DECLARE @resultsFC as tApAgingFC

/**********NON FC BEGIN**********/	--11/21/2016 DRP:  Added
IF @lFCInstalled = 0
	BEGIN

	select @cols = STUFF((
	SELECT ',' + C.Name  
		from (select nRange,'Range'+RTRIM(cast(nRange as int))+' as ['+cast(nStart as varchar(4))+'-'+cast(nEND as varchar(4))+']' name from AgingRangeSetup where AgingRangeSetup.cType='AP' ) C
	ORDER BY C.nRange
	FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'');
			
	-- 07/07/16 VL re-calculate appmts with original rate
	-- replace dbo.APMASTER.APPMTS to ROUND(dbo.fn_Convert4FCHC('F',APMASTER.Fcused_uniq, APMASTER.AppmtsFC, APMASTER.Fchist_key),2)
	-- 11/21/2016 VL We added one more (4th) parameter to fn_Convert4FCHC() that's used to convert for functional or presentation currency
	-- 01/27/17 VL removed the fn_Convert4FCHC() part only used in FC part and use the original appmts in the SQL statement
	-- 01/30/17 VL removed FC fields
	insert into @results
	SELECT      dbo.SUPINFO.SUPNAME, dbo.APMASTER.INVNO, isnull(dbo.APMASTER.INVDATE ,getdate()) as InvDate
				,isnull(dbo.APMASTER.DUE_DATE,getdate())as Due_Date, dbo.APMASTER.TRANS_DT as Trans_Dt, 
				dbo.APMASTER.PONUM, dbo.APMASTER.INVAMOUNT, dbo.APMASTER.INVAMOUNT - APMASTER.Appmts - dbo.APMASTER.DISC_TKN AS BalAmt,dbo.APMASTER.APSTATUS
	--07/23/2013 DRP:  ALL OF THE RANGE RESULTS HAVE BEEN ADDED TO THE PROCEDURE, THEY USED TO ONLY BE CALCULATED WITHIN THE CR ITSELF, BUT NEEDED TO BE ADDED HERE FOR THE QUICKVIEW RESULTS			
				,case when @lcAgedOn = 'Invoice Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())<=0 then 
						dbo.APMASTER.INVAMOUNT - APMASTER.Appmts - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.Due_Date,GETDATE()),GETDATE())<=0 then 
						dbo.APMASTER.INVAMOUNT - APMASTER.Appmts - dbo.APMASTER.DISC_TKN else 000000000.00 end end end as [Current]
				,case when @lcAgedOn = 'Invoice Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a1.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate())<= a1.nEnd then 
						dbo.APMASTER.INVAMOUNT - APMASTER.Appmts - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a1.nStart and datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate())<= a1.nEnd then 
						dbo.APMASTER.INVAMOUNT - APMASTER.Appmts - dbo.APMASTER.DISC_TKN 
							else 000000000-00 end end end as Range1		
				,case when @lcAgedOn = 'Invoice Date' then
						case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a2.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate()) <= a2.nEnd then 
						dbo.APMASTER.INVAMOUNT - APMASTER.Appmts - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a2.nStart and Datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate()) <= a2.nEnd then
						dbo.APMASTER.INVAMOUNT - APMASTER.Appmts - dbo.APMASTER.DISC_TKN 
							else 000000000-00 end end end as Range2		
				,case when @lcAgedOn = 'Invoice Date' then
					case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a3.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate()) <= a3.nEnd then 
						dbo.APMASTER.INVAMOUNT - APMASTER.Appmts - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
					case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a3.nStart and Datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate()) <= a3.nEnd then
						dbo.APMASTER.INVAMOUNT - APMASTER.Appmts - dbo.APMASTER.DISC_TKN 
							else 000000000-00 end end end as Range3	
				,case when @lcAgedOn = 'Invoice Date' then
					case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a4.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate()) <= a4.nEnd then
						dbo.APMASTER.INVAMOUNT - APMASTER.Appmts - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
					case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a4.nStart and Datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate()) <= a4.nEnd then
						dbo.APMASTER.INVAMOUNT - APMASTER.Appmts - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end end end as Range4			
				,case when @lcAgedOn ='Invoice Date' then	
					case when DATEDIFF(day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE()) > a4.nend then 
						dbo.APMASTER.INVAMOUNT - APMASTER.Appmts - dbo.APMASTER.DISC_TKN
							else 000000000.00 end 
				 else case when @lcAgedOn = 'Due Date' then 
					case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())> a4.nEnd then
						dbo.APMASTER.INVAMOUNT - APMASTER.Appmts - dbo.APMASTER.DISC_TKN 		
							else 000000000.00 end end end as [Over]
				, a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End, a3.nStart AS R3Start, a3.nEnd AS R3End, 
				a4.nStart AS R4Start, a4.nEnd AS R4End, dbo.APMASTER.UNIQSUPNO,SUPINFO.PHONE,SUPINFO.TERMS,getdate() as AsOfDate
			
	FROM         dbo.APMASTER INNER JOIN
						  dbo.SUPINFO ON dbo.APMASTER.UNIQSUPNO = dbo.SUPINFO.UNIQSUPNO
						  -- 01/27/17 VL comment out Fcused code in non-FC part
						  --left outer JOIN Fcused ON Apmaster.FcUsed_uniq = Fcused.FcUsed_Uniq --11/21/2016 dRP:  changed to left outer join 
						  CROSS JOIN
						  dbo.AgingRangeSetup AS a2 CROSS JOIN
						  dbo.AgingRangeSetup AS a3 CROSS JOIN
						  dbo.AgingRangeSetup AS a4 CROSS JOIN
						  dbo.AgingRangeSetup AS a1 
						  --cross join MICSSYS
	WHERE		(dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN <> 0) 
				--and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end	--09/11/2014 DRP:  removed was only needed for CR version of reports
				AND (a1.cType = 'AP') AND (a1.nRange = 1) AND (a2.cType = 'AP') AND (a2.nRange = 2) 
					AND (a3.cType = 'AP') AND (a3.nRange = 3) AND (a4.cType = 'AP') AND (a4.nRange = 4) AND (dbo.APMASTER.APSTATUS <> 'Deleted')
				-- the below was added for the WebManex Version report only
				--07/18/2013 YS allow @lcuniqsup have multiple csv
				--12/03/13  YS    changed lcUniqSup to take 'All' instead of '' 
				/*--and 1= CASE WHEN @lcUniqSup = 'All' then 1 
				--WHEN Supinfo.Uniqsupno IN (select UNIQSUPNO from @unisupno ) then 1 ELSE 0 END*/ --09/11/2014 DRP:  removed and replaced by below to work properly with the user Id
				and 1= case WHEN supinfo.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
	ORDER BY dbo.SUPINFO.SUPNAME

--These results will be used for the CR results.  Also for the WebManex QuickView for the Detailed version of the report
	--07/25/13 YS use dynamic SQL to assign an actual range as a column name in place of 'Range1','Range2',... 'Range4'
	declare @sql nvarchar(max)
	if (@lcRptType = 'Detailed')
	Begin
			Begin
				--select * from @results
				set @sql= 
				'SELECT SupName,InvNo,InvDate,Due_Date,Trans_Dt,PoNum,InvAmount,BalAmt,ApStatus,[Current],'+@cols+ 
									 ',[Over],R1Start,R1end,R2Start,R2End,R3Start,R3End,R4Start,R4End,UniqSupno,Phone,Terms,Range1,Range2,Range3,Range4 FROM @results'
			 execute sp_executesql @sql,N'@results tApAging READONLY',@results
			End
	end
	
--These results will be used only for the WebManex QuickView results if the users selects to view the Summary version of the report.
	else if (@lcRptType = 'Summary')
	Begin		
			set @Sql='
				SELECT SupName,UniqSupno,phone,InvAmount,BalAmt,[Current],'+@cols+',[Over],R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End,Terms,Range1,Range2,Range3,Range4
					FROM(
				Select	SupName,UniqSupno,phone,SUM(InvAmount) as InvAmount,SUM(BalAmt) as BalAmt,SUM([Current]) as [Current],
						SUM([Over]) as [Over]
						,SUM(Range1) as Range1,SUM(Range2) as Range2,SUM(Range3) as Range3
						,SUM(Range4) as Range4,R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End,Terms
						from	@results
				group by SupName,UniqSupno,Phone,R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End,Terms) S '
				
				--07/25/13 YS sp_executesql procedure will take second parameter as User defined table type (UDTT) and we will pass @result table variable 
				execute sp_executesql @sql,N'@results tApAging READONLY',@results
			End
	--End


	END
/**********NON FC END**********/
ELSE
/******FC INSTALLED BEGIN******/	--11/21/2016 DRP:  Added
	BEGIN

	select @cols = STUFF((
		SELECT ',' + C.Name  
		from (select nRange,'Range'+RTRIM(cast(nRange as int))+' as ['+cast(nStart as varchar(4))+'-'+cast(nEND as varchar(4))+']'+
			', Range'+RTRIM(cast(nRange as int))+'FC as ['+cast(nStart as varchar(4))+'-'+cast(nEND as varchar(4))+'FC]' +
			-- 09/11/17 VL added PR code
			', Range'+RTRIM(cast(nRange as int))+'PR as ['+cast(nStart as varchar(4))+'-'+cast(nEND as varchar(4))+'PR]' name from AgingRangeSetup where AgingRangeSetup.cType='AP' ) C
	ORDER BY C.nRange
	FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'');

	-- 09/11/17 VL create a table variable to save FcUsedView, and use this table variable to update latest rate
	DECLARE @tFcusedView TABLE (FCUsed_Uniq char(10), Country varchar(60), CURRENCY varchar(40), Symbol varchar(3), Prefix varchar(7), UNIT varchar(10), Subunit varchar(10), Thou_sep varchar(1), Deci_Sep varchar(1), 
			Deci_no numeric(2,0), AskPrice numeric(13,5), AskPricePR numeric(13,5), Fchist_key char(10), Fcdatetime smalldatetime)
	INSERT @tFcusedView EXEC FcusedView
					
	-- 07/07/16 VL re-calculate appmts with original rate
	-- replace dbo.APMASTER.APPMTS to ROUND(dbo.fn_Convert4FCHC('F',APMASTER.Fcused_uniq, APMASTER.AppmtsFC, APMASTER.Fchist_key),2)
	-- 11/21/2016 VL We added one more (4th) parameter to fn_Convert4FCHC() that's used to convert for functional or presentation currency
	insert into @resultsFC
	SELECT      dbo.SUPINFO.SUPNAME, dbo.APMASTER.INVNO, isnull(dbo.APMASTER.INVDATE ,getdate()) as InvDate
				,isnull(dbo.APMASTER.DUE_DATE,getdate())as Due_Date, dbo.APMASTER.TRANS_DT as Trans_Dt, 
				dbo.APMASTER.PONUM, dbo.APMASTER.INVAMOUNT, dbo.APMASTER.INVAMOUNT - ROUND(dbo.fn_Convert4FCHC('F',APMASTER.Fcused_uniq, APMASTER.AppmtsFC, dbo.fn_GetFunctionalCurrency(), APMASTER.Fchist_key),2) - dbo.APMASTER.DISC_TKN AS BalAmt,dbo.APMASTER.APSTATUS
	--07/23/2013 DRP:  ALL OF THE RANGE RESULTS HAVE BEEN ADDED TO THE PROCEDURE, THEY USED TO ONLY BE CALCULATED WITHIN THE CR ITSELF, BUT NEEDED TO BE ADDED HERE FOR THE QUICKVIEW RESULTS			
				,case when @lcAgedOn = 'Invoice Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())<=0 then 
						dbo.APMASTER.INVAMOUNT - ROUND(dbo.fn_Convert4FCHC('F',APMASTER.Fcused_uniq, APMASTER.AppmtsFC, dbo.fn_GetFunctionalCurrency(), APMASTER.Fchist_key),2) - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.Due_Date,GETDATE()),GETDATE())<=0 then 
						dbo.APMASTER.INVAMOUNT - ROUND(dbo.fn_Convert4FCHC('F',APMASTER.Fcused_uniq, APMASTER.AppmtsFC, dbo.fn_GetFunctionalCurrency(), APMASTER.Fchist_key),2) - dbo.APMASTER.DISC_TKN else 000000000.00 end end end as [Current]
				,case when @lcAgedOn = 'Invoice Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a1.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate())<= a1.nEnd then 
						dbo.APMASTER.INVAMOUNT - ROUND(dbo.fn_Convert4FCHC('F',APMASTER.Fcused_uniq, APMASTER.AppmtsFC, dbo.fn_GetFunctionalCurrency(), APMASTER.Fchist_key),2) - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a1.nStart and datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate())<= a1.nEnd then 
						dbo.APMASTER.INVAMOUNT - ROUND(dbo.fn_Convert4FCHC('F',APMASTER.Fcused_uniq, APMASTER.AppmtsFC, dbo.fn_GetFunctionalCurrency(), APMASTER.Fchist_key),2) - dbo.APMASTER.DISC_TKN 
							else 000000000-00 end end end as Range1		
				,case when @lcAgedOn = 'Invoice Date' then
						case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a2.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate()) <= a2.nEnd then 
						dbo.APMASTER.INVAMOUNT - ROUND(dbo.fn_Convert4FCHC('F',APMASTER.Fcused_uniq, APMASTER.AppmtsFC, dbo.fn_GetFunctionalCurrency(), APMASTER.Fchist_key),2) - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a2.nStart and Datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate()) <= a2.nEnd then
						dbo.APMASTER.INVAMOUNT - ROUND(dbo.fn_Convert4FCHC('F',APMASTER.Fcused_uniq, APMASTER.AppmtsFC, dbo.fn_GetFunctionalCurrency(), APMASTER.Fchist_key),2) - dbo.APMASTER.DISC_TKN 
							else 000000000-00 end end end as Range2		
				,case when @lcAgedOn = 'Invoice Date' then
					case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a3.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate()) <= a3.nEnd then 
						dbo.APMASTER.INVAMOUNT - ROUND(dbo.fn_Convert4FCHC('F',APMASTER.Fcused_uniq, APMASTER.AppmtsFC, dbo.fn_GetFunctionalCurrency(), APMASTER.Fchist_key),2) - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
					case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a3.nStart and Datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate()) <= a3.nEnd then
						dbo.APMASTER.INVAMOUNT - ROUND(dbo.fn_Convert4FCHC('F',APMASTER.Fcused_uniq, APMASTER.AppmtsFC, dbo.fn_GetFunctionalCurrency(), APMASTER.Fchist_key),2) - dbo.APMASTER.DISC_TKN 
							else 000000000-00 end end end as Range3	
				,case when @lcAgedOn = 'Invoice Date' then
					case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a4.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate()) <= a4.nEnd then
						dbo.APMASTER.INVAMOUNT - ROUND(dbo.fn_Convert4FCHC('F',APMASTER.Fcused_uniq, APMASTER.AppmtsFC, dbo.fn_GetFunctionalCurrency(), APMASTER.Fchist_key),2) - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
					case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a4.nStart and Datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate()) <= a4.nEnd then
						dbo.APMASTER.INVAMOUNT - ROUND(dbo.fn_Convert4FCHC('F',APMASTER.Fcused_uniq, APMASTER.AppmtsFC, dbo.fn_GetFunctionalCurrency(), APMASTER.Fchist_key),2) - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end end end as Range4			
				,case when @lcAgedOn ='Invoice Date' then	
					case when DATEDIFF(day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE()) > a4.nend then 
						dbo.APMASTER.INVAMOUNT - ROUND(dbo.fn_Convert4FCHC('F',APMASTER.Fcused_uniq, APMASTER.AppmtsFC, dbo.fn_GetFunctionalCurrency(), APMASTER.Fchist_key),2) - dbo.APMASTER.DISC_TKN
							else 000000000.00 end 
				 else case when @lcAgedOn = 'Due Date' then 
					case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())> a4.nEnd then
						dbo.APMASTER.INVAMOUNT - ROUND(dbo.fn_Convert4FCHC('F',APMASTER.Fcused_uniq, APMASTER.AppmtsFC, dbo.fn_GetFunctionalCurrency(), APMASTER.Fchist_key),2) - dbo.APMASTER.DISC_TKN 		
							else 000000000.00 end end end as [Over]
				, a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End, a3.nStart AS R3Start, a3.nEnd AS R3End, 
				a4.nStart AS R4Start, a4.nEnd AS R4End, dbo.APMASTER.UNIQSUPNO,SUPINFO.PHONE,SUPINFO.TERMS,getdate() as AsOfDate,
				dbo.APMASTER.INVAMOUNTFC, dbo.APMASTER.INVAMOUNTFC - dbo.APMASTER.APPMTSFC - dbo.APMASTER.DISC_TKNFC AS BalAmtFC
				,case when @lcAgedOn = 'Invoice Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())<=0 then 
						dbo.APMASTER.INVAMOUNTFC - dbo.APMASTER.APPMTSFC - dbo.APMASTER.DISC_TKNFC 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.Due_Date,GETDATE()),GETDATE())<=0 then 
						dbo.APMASTER.INVAMOUNTFC - dbo.APMASTER.APPMTSFC - dbo.APMASTER.DISC_TKNFC else 000000000.00 end end end as [CurrentFC]
				,case when @lcAgedOn = 'Invoice Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a1.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate())<= a1.nEnd then 
						dbo.APMASTER.INVAMOUNTFC - dbo.APMASTER.APPMTSFC - dbo.APMASTER.DISC_TKNFC 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a1.nStart and datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate())<= a1.nEnd then 
						dbo.APMASTER.INVAMOUNTFC - dbo.APMASTER.APPMTSFC - dbo.APMASTER.DISC_TKNFC 
							else 000000000-00 end end end as Range1FC		
				,case when @lcAgedOn = 'Invoice Date' then
						case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a2.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate()) <= a2.nEnd then 
						dbo.APMASTER.INVAMOUNTFC - dbo.APMASTER.APPMTSFC - dbo.APMASTER.DISC_TKNFC 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a2.nStart and Datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate()) <= a2.nEnd then
						dbo.APMASTER.INVAMOUNTFC - dbo.APMASTER.APPMTSFC - dbo.APMASTER.DISC_TKNFC 
							else 000000000-00 end end end as Range2FC		
				,case when @lcAgedOn = 'Invoice Date' then
					case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a3.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate()) <= a3.nEnd then 
						dbo.APMASTER.INVAMOUNTFC - dbo.APMASTER.APPMTSFC - dbo.APMASTER.DISC_TKNFC 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
					case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a3.nStart and Datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate()) <= a3.nEnd then
						dbo.APMASTER.INVAMOUNTFC - dbo.APMASTER.APPMTSFC - dbo.APMASTER.DISC_TKNFC 
							else 000000000-00 end end end as Range3FC	
				,case when @lcAgedOn = 'Invoice Date' then
					case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a4.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate()) <= a4.nEnd then
						dbo.APMASTER.INVAMOUNTFC - dbo.APMASTER.APPMTSFC - dbo.APMASTER.DISC_TKNFC 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
					case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a4.nStart and Datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate()) <= a4.nEnd then
						dbo.APMASTER.INVAMOUNTFC - dbo.APMASTER.APPMTSFC - dbo.APMASTER.DISC_TKNFC 
							else 000000000.00 end end end as Range4FC			
				,case when @lcAgedOn ='Invoice Date' then	
					case when DATEDIFF(day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE()) > a4.nend then 
						dbo.APMASTER.INVAMOUNTFC - dbo.APMASTER.APPMTSFC - dbo.APMASTER.DISC_TKNFC
							else 000000000.00 end 
				 else case when @lcAgedOn = 'Due Date' then 
					case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())> a4.nEnd then
						dbo.APMASTER.INVAMOUNTFC - dbo.APMASTER.APPMTSFC - dbo.APMASTER.DISC_TKNFC 		
							else 000000000.00 end end end as [OverFC]
				, Apmaster.Fcused_uniq AS Fcused_uniq, Apmaster.Fchist_key AS Fchist_key, 00.000 AS Old2NewRate, 0.00000 AS AskPrice,
				--,MICSSYS.LIC_NAME--10/03/2014 DRP:  Removed
				-- 01/27/17 VL added functional currency code
				dbo.APMASTER.INVAMOUNTPR, dbo.APMASTER.INVAMOUNTPR - dbo.APMASTER.APPMTSPR - dbo.APMASTER.DISC_TKNPR AS BalAmtPR
				,case when @lcAgedOn = 'Invoice Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())<=0 then 
						dbo.APMASTER.INVAMOUNTPR - dbo.APMASTER.APPMTSPR - dbo.APMASTER.DISC_TKNPR 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.Due_Date,GETDATE()),GETDATE())<=0 then 
						dbo.APMASTER.INVAMOUNTPR - dbo.APMASTER.APPMTSPR - dbo.APMASTER.DISC_TKNPR else 000000000.00 end end end as [CurrentPR]
				,case when @lcAgedOn = 'Invoice Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a1.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate())<= a1.nEnd then 
						dbo.APMASTER.INVAMOUNTPR - dbo.APMASTER.APPMTSPR - dbo.APMASTER.DISC_TKNPR 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a1.nStart and datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate())<= a1.nEnd then 
						dbo.APMASTER.INVAMOUNTPR - dbo.APMASTER.APPMTSPR - dbo.APMASTER.DISC_TKNPR 
							else 000000000-00 end end end as Range1PR		
				,case when @lcAgedOn = 'Invoice Date' then
						case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a2.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate()) <= a2.nEnd then 
						dbo.APMASTER.INVAMOUNTPR - dbo.APMASTER.APPMTSPR - dbo.APMASTER.DISC_TKNPR 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a2.nStart and Datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate()) <= a2.nEnd then
						dbo.APMASTER.INVAMOUNTPR - dbo.APMASTER.APPMTSPR - dbo.APMASTER.DISC_TKNPR 
							else 000000000-00 end end end as Range2PR		
				,case when @lcAgedOn = 'Invoice Date' then
					case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a3.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate()) <= a3.nEnd then 
						dbo.APMASTER.INVAMOUNTPR - dbo.APMASTER.APPMTSPR - dbo.APMASTER.DISC_TKNPR 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
					case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a3.nStart and Datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate()) <= a3.nEnd then
						dbo.APMASTER.INVAMOUNTPR - dbo.APMASTER.APPMTSPR - dbo.APMASTER.DISC_TKNPR 
							else 000000000-00 end end end as Range3PR	
				,case when @lcAgedOn = 'Invoice Date' then
					case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a4.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate()) <= a4.nEnd then
						dbo.APMASTER.INVAMOUNTPR - dbo.APMASTER.APPMTSPR - dbo.APMASTER.DISC_TKNPR 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
					case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a4.nStart and Datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate()) <= a4.nEnd then
						dbo.APMASTER.INVAMOUNTPR - dbo.APMASTER.APPMTSPR - dbo.APMASTER.DISC_TKNPR 
							else 000000000.00 end end end as Range4PR			
				,case when @lcAgedOn ='Invoice Date' then	
					case when DATEDIFF(day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE()) > a4.nend then 
						dbo.APMASTER.INVAMOUNTPR - dbo.APMASTER.APPMTSPR - dbo.APMASTER.DISC_TKNPR
							else 000000000.00 end 
				 else case when @lcAgedOn = 'Due Date' then 
					case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())> a4.nEnd then
						dbo.APMASTER.INVAMOUNTPR - dbo.APMASTER.APPMTSPR - dbo.APMASTER.DISC_TKNPR 		
							else 000000000.00 end end end as [OverPR],
				00.000 AS Old2NewRatePR, 0.00000 AS AskPricePR,TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	FROM         dbo.APMASTER 
						-- 01/24/17 VL changed criteria to get 3 currencies
						INNER JOIN Fcused PF ON APMASTER.PrFcused_uniq = PF.Fcused_uniq
						INNER JOIN Fcused FF ON APMASTER.FuncFcused_uniq = FF.Fcused_uniq			
						INNER JOIN Fcused TF ON APMASTER.Fcused_uniq = TF.Fcused_uniq			
						INNER JOIN
						  dbo.SUPINFO ON dbo.APMASTER.UNIQSUPNO = dbo.SUPINFO.UNIQSUPNO
						  -- 01/27/17 VL comment out next line
						  --left outer JOIN Fcused ON Apmaster.FcUsed_uniq = Fcused.FcUsed_Uniq --11/21/2016 dRP:  changed to left outer join 
						  CROSS JOIN
						  dbo.AgingRangeSetup AS a2 CROSS JOIN
						  dbo.AgingRangeSetup AS a3 CROSS JOIN
						  dbo.AgingRangeSetup AS a4 CROSS JOIN
						  dbo.AgingRangeSetup AS a1 
						  --cross join MICSSYS
		--05/25/17 YS check for the balance using FC amount  
		where (dbo.APMASTER.INVAMOUNTFC - dbo.APMASTER.APPMTSFC - dbo.APMASTER.DISC_TKNFC <> 0)
		--WHERE		(dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN <> 0) 
				--(dbo.APMASTER.INVAMOUNTFC - dbo.APMASTER.APPMTSFC - dbo.APMASTER.DISC_TKNFC <> 0) or (dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN <> 0)	--05/24/17 DRP:  replaced with above  
				--and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end	--09/11/2014 DRP:  removed was only needed for CR version of reports
				AND (a1.cType = 'AP') AND (a1.nRange = 1) AND (a2.cType = 'AP') AND (a2.nRange = 2) 
					AND (a3.cType = 'AP') AND (a3.nRange = 3) AND (a4.cType = 'AP') AND (a4.nRange = 4) AND (dbo.APMASTER.APSTATUS <> 'Deleted')
				-- the below was added for the WebManex Version report only
				--07/18/2013 YS allow @lcuniqsup have multiple csv
				--12/03/13  YS    changed lcUniqSup to take 'All' instead of '' 
				/*--and 1= CASE WHEN @lcUniqSup = 'All' then 1 
				--WHEN Supinfo.Uniqsupno IN (select UNIQSUPNO from @unisupno ) then 1 ELSE 0 END*/ --09/11/2014 DRP:  removed and replaced by below to work properly with the user Id
				and 1= case WHEN supinfo.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
	ORDER BY TSymbol, dbo.SUPINFO.SUPNAME


	-- 02/29/16 VL un-comment out again, will just make @lLatestRate = 0 as default, so don't go through the code
	-- 02/03/16 VL comment out for now, don't see the field show on report, it slows down the speed
	---- 02/03/16 VL added if @lLatestRate = 1, will get latest rate to re-calculate the values
	-- 07/07/16 VL found when changing value from 1/0 to Yes/No, the 1 was changed to No, but it should be 'Yes'
	--IF @lLatestRate = 'No'
	IF @lLatestRate = 'Yes'
		BEGIN
		-- 09/11/17 VL comment out the code that use dbo.fn_CalculateFCRateVariance() function to calculate latest rate, it used the ratio of rate changes, sometimes caused $0.01 difference
		-- changed to use FC value/latest rate to get the new func or pr values
		--	01/11/17 VL added one more parameter for fn_CalculateFCRateVariance() which is the rate ratio calculated based on functional currency or presentation currency
		-- 01/27/17 VL added to update PR rate
		--UPDATE @ResultsFC SET Old2NewRate = dbo.fn_CalculateFCRateVariance(FcHist_key,'F'), Old2NewRatePR = dbo.fn_CalculateFCRateVariance(FcHist_key,'P')
		--UPDATE @resultsFC SET INVAMOUNT = Old2NewRate*InvAmount,
		--					BalAmt = Old2NewRate*BalAmt,
		--					[Current] = Old2NewRate*[Current],
		--					Range1 = Old2NewRate*Range1,
		--					Range2 = Old2NewRate*Range2,
		--					Range3 = Old2NewRate*Range3,
		--					Range4 = Old2NewRate*Range4,
		--					[Over] = Old2NewRate*[Over],
		--					-- 01/27/17 VL added to update PR fields
		--					INVAMOUNTPR = Old2NewRatePR*InvAmountPR,
		--					BalAmtPR = Old2NewRatePR*BalAmtPR,
		--					[CurrentPR] = Old2NewRatePR*[CurrentPR],
		--					Range1PR = Old2NewRatePR*Range1PR,
		--					Range2PR = Old2NewRatePR*Range2PR,
		--					Range3PR = Old2NewRatePR*Range3PR,
		--					Range4PR = Old2NewRatePR*Range4PR,
		--					[OverPR] = Old2NewRatePR*[OverPR]
				UPDATE @resultsFC SET INVAMOUNT = ROUND(INVAMOUNTFC/F.AskPrice,5),
									BalAmt = ROUND(BalAmtFC/F.AskPrice,5),
									[Current] = ROUND([CurrentFC]/F.AskPrice,5),
									Range1 = ROUND(Range1FC/F.AskPrice,5),
									Range2 = ROUND(Range2FC/F.AskPrice,5),
									Range3 = ROUND(Range3FC/F.AskPrice,5),
									Range4 = ROUND(Range4FC/F.AskPrice,5),
									[Over] = ROUND([OverFC]/F.AskPrice,5), 
									INVAMOUNTPR = ROUND(INVAMOUNTFC/F.AskPricePR,5),
									BalAmtPR = ROUND(BalAmtFC/F.AskPricePR,5),
									[CurrentPR] = ROUND([CurrentFC]/F.AskPricePR,5),
									Range1PR = ROUND(Range1FC/F.AskPricePR,5),
									Range2PR = ROUND(Range2FC/F.AskPricePR,5),
									Range3PR = ROUND(Range3FC/F.AskPricePR,5),
									Range4PR = ROUND(Range4FC/F.AskPricePR,5),
									[OverPR] = ROUND([OverFC]/F.AskPricePR,5)
						FROM @resultsFC R, @tFcusedView F
						WHERE R.Fcused_uniq = F.FCUsed_Uniq
		-- 09/11/17 VL End}

	END
	--END  --05/24/17 DRP:  this end needed to be removed

	--These results will be used for the CR results.  Also for the WebManex QuickView for the Detailed version of the report
	--07/25/13 YS use dynamic SQL to assign an actual range as a column name in place of 'Range1','Range2',... 'Range4'
	--05/24/17:  this Detailed and summary section needed to be moved up into the Foreign Currency Section it used to be residing outside of the FC If statemtn
	declare @sqlFC nvarchar(max)
	if (@lcRptType = 'Detailed')
	Begin
			Begin
				--select * from @results
				set @sqlFC= 
				'SELECT SupName,InvNo,InvDate,Due_Date,Trans_Dt,PoNum,InvAmount,BalAmt,ApStatus,[Current],'+@cols+ 
									 ',[Over],R1Start,R1end,R2Start,R2End,R3Start,R3End,R4Start,R4End,UniqSupno,Phone,Terms,Range1,Range2,Range3,Range4
									 ,InvAmountFC,BalAmtFC,CurrentFC,OverFC,Range1FC,Range2FC,Range3FC,Range4FC
									 ,InvAmountPR,BalAmtPR,CurrentPR,OverPR,Range1PR,Range2PR,Range3PR,Range4PR
									 ,TSymbol, PSymbol, FSymbol FROM @resultsFC ORDER BY TSymbol, Supname, Invno'
			 execute sp_executesql @sqlFC,N'@resultsFC tApAgingFC READONLY',@resultsFC	--05/24/17 DRP:  we kept referencing @results when it should have been @resultsFC and @sql needs to be @sqlFC
			End
	end
	
--These results will be used only for the WebManex QuickView results if the users selects to view the Summary version of the report. 
	else if (@lcRptType = 'Summary')
	Begin		
			set @SqlFC='
				SELECT SupName,UniqSupno,phone,InvAmount,BalAmt,[Current],'+@cols+',[Over],R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End,Terms,Range1,Range2,Range3,Range4
					,InvAmountFC,BalAmtFC,CurrentFC,OverFC,Range1FC,Range2FC,Range3FC,Range4FC
					,InvAmountPR,BalAmtPR,CurrentPR,OverPR,Range1PR,Range2PR,Range3PR,Range4PR
					,TSymbol, PSymbol, FSymbol
				FROM(
				Select	SupName,UniqSupno,phone,SUM(InvAmount) as InvAmount,SUM(BalAmt) as BalAmt,SUM([Current]) as [Current],
						SUM([Over]) as [Over]
						,SUM(Range1) as Range1,SUM(Range2) as Range2,SUM(Range3) as Range3
						,SUM(Range4) as Range4,R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End,Terms
						,SUM(InvAmountFC) as InvAmountFC,SUM(BalAmtFC) as BalAmtFC,SUM([CurrentFC]) as [CurrentFC],
						SUM([OverFC]) as [OverFC]
						,SUM(Range1FC) as Range1FC,SUM(Range2FC) as Range2FC,SUM(Range3FC) as Range3FC
						,SUM(Range4FC) as Range4FC
						,SUM(InvAmountPR) as InvAmountPR,SUM(BalAmtPR) as BalAmtPR,SUM([CurrentPR]) as [CurrentPR],
						SUM([OverPR]) as [OverPR]
						,SUM(Range1PR) as Range1PR,SUM(Range2PR) as Range2PR,SUM(Range3PR) as Range3PR
						,SUM(Range4PR) as Range4PR
						,TSymbol, PSymbol, FSymbol
				from	@resultsFC
				group by SupName,UniqSupno,Phone,R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End,Terms,TSymbol, PSymbol, FSymbol) S ORDER BY TSymbol, SupName'
				
				--07/25/13 YS sp_executesql procedure will take second parameter as User defined table type (UDTT) and we will pass @result table variable 
				execute sp_executesql @sqlFC,N'@resultsFC tApAgingFC READONLY',@resultsFC  --05/24/17 DRP:  we kept referencing @results when it should have been @resultsFC and @sql needs to be @sqlFC
			End
	end
/******FC INSTALLED END******/
		
end