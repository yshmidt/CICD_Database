-- =============================================
-- Author:		<Vicky Lu>
-- Create date: <02/05/2016>
-- Description:	<a report 'APAGEPG' created for Penang, converted to SQL, lcRptType = 'Summary' or 'Forex'>
-- Modified:	
-- 04/08/16 VL	Changed to get HC from function
-- 01/11/17 VL  added one more parameter for dbo.fn_Convert4FCHC()
-- 02/03/17 VL	added functional currency code
-- 06/20/17 VL changed fn_GetHomeCurrency to use fn_GetFunctionalCurrency
-- =============================================
create PROCEDURE [dbo].[rptApAgeDetailAllCurrenciesFC]
--declare

@lcUniqSup as varchar(max) = 'All'		--this was added for the WebManex Version of the report only    --12/03/13  YS    changed lcUniqSup to take 'All' instead of '' 
,@lcAgedOn as char(12) = 'Invoice Date'	-- 07/23/2013 DRP: (Invoice Date or Due Date)  Added to be used for the WebManex Reports and Quickviews.  CR is not using it at this time. 
,@lcRptType as char(10) = 'Summary'	--02/09/16 VL:  (Summary or Forex)
, @userId uniqueidentifier= null
,@supplierStatus varchar(20) = 'All'

AS
BEGIN

-- get list of approved suppliers for this user
DECLARE @tSupplier tSupplier
declare @tSupNo as table (Uniqsupno char (10))
DECLARE @HCurrency char(3), @SUMBalamt numeric(12,2), @SUMCurrent numeric(12,2), @SUMRange1 numeric(12,2), @SUMRange2 numeric(12,2), @SUMRange3 numeric(12,2), @SUMRange4 numeric(12,2),
		@SUMOver numeric(12,2)

-- 04/08/16 VL changed to call function
-- 06/20/17 VL changed fn_GetHomeCurrency to use fn_GetFunctionalCurrency
SELECT @HCurrency = Symbol FROM Fcused WHERE Fcused_uniq = dbo.fn_GetFunctionalCurrency()

INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, @supplierStatus;

IF @lcUniqSup<>'All' and @lcUniqSup<>'' and @lcUniqSup is not null
	insert into @tSupNo  select * from  dbo.[fn_simpleVarcharlistToTable](@lcUniqSup,',') WHERE cast(ID as char(10)) IN (SELECT UniqSupno from @tSupplier)
ELSE
	BEGIN
		IF @lcUniqSup='All'
		insert into @tSupno  select UniqSupno from @tSupplier
	END				

		
	--07/25/13 YS create string for the names of the columnsbased on the AgingRangeSetup
	declare @cols as nvarchar(max)
	
	select @cols = STUFF((
	SELECT ',' + C.Name  
		from (select nRange,'Range'+RTRIM(cast(nRange as int))+' as ['+cast(nStart as varchar(4))+'-'+cast(nEND as varchar(4))+']'+
			', Range'+RTRIM(cast(nRange as int))+'FC as ['+cast(nStart as varchar(4))+'-'+cast(nEND as varchar(4))+'FC]'+
			', Range'+RTRIM(cast(nRange as int))+'PR as ['+cast(nStart as varchar(4))+'-'+cast(nEND as varchar(4))+'PR]' name from AgingRangeSetup where AgingRangeSetup.cType='AP') C
	ORDER BY C.nRange
	FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'');
	

	-- 02/03/16 VL use new tApAgingFC type, try to avoid changing tApAging type
	DECLARE @results as tApAgingFC
	

	insert into @results
	SELECT      dbo.SUPINFO.SUPNAME, dbo.APMASTER.INVNO, isnull(dbo.APMASTER.INVDATE,getdate()) as InvDate
				,isnull(dbo.APMASTER.DUE_DATE,getdate())as Due_Date, dbo.APMASTER.TRANS_DT as Trans_Dt, 
				dbo.APMASTER.PONUM, dbo.APMASTER.INVAMOUNT, dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN AS BalAmt,dbo.APMASTER.APSTATUS
	--07/23/2013 DRP:  ALL OF THE RANGE RESULTS HAVE BEEN ADDED TO THE PROCEDURE, THEY USED TO ONLY BE CALCULATED WITHIN THE CR ITSELF, BUT NEEDED TO BE ADDED HERE FOR THE QUICKVIEW RESULTS			
				,case when @lcAgedOn = 'Invoice Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())<=0 then 
						dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.Due_Date,GETDATE()),GETDATE())<=0 then 
						dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN else 000000000.00 end end end as [Current]
				,case when @lcAgedOn = 'Invoice Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a1.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate())<= a1.nEnd then 
						dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a1.nStart and datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate())<= a1.nEnd then 
						dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN 
							else 000000000-00 end end end as Range1		
				,case when @lcAgedOn = 'Invoice Date' then
						case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a2.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate()) <= a2.nEnd then 
						dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a2.nStart and Datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate()) <= a2.nEnd then
						dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN 
							else 000000000-00 end end end as Range2		
				,case when @lcAgedOn = 'Invoice Date' then
					case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a3.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate()) <= a3.nEnd then 
						dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
					case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a3.nStart and Datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate()) <= a3.nEnd then
						dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN 
							else 000000000-00 end end end as Range3	
				,case when @lcAgedOn = 'Invoice Date' then
					case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a4.nStart and DateDiff(day,isnull(dbo.apmaster.INVDATE ,getdate()),getdate()) <= a4.nEnd then
						dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
					case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a4.nStart and Datediff(day,isnull(dbo.apmaster.DUE_DATE,getdate()),getdate()) <= a4.nEnd then
						dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end end end as Range4			
				,case when @lcAgedOn ='Invoice Date' then	
					case when DATEDIFF(day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE()) > a4.nend then 
						dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN
							else 000000000.00 end 
				 else case when @lcAgedOn = 'Due Date' then 
					case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())> a4.nEnd then
						dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN 		
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
				, Apmaster.Fcused_uniq AS Fcused_uniq, Apmaster.Fchist_key AS Fchist_key, 00.000 AS Old2NewRate, 0 AS AskPrice,
				-- 02/03/17 VL added functional currency fields
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
				00.000 AS Old2NewRate, 0 AS AskPrice, TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol

				--,MICSSYS.LIC_NAME--10/03/2014 DRP:  Removed
				
	FROM         dbo.APMASTER 
						--02/03/17 VL changed criteria to get 3 currencies
						INNER JOIN Fcused PF ON APMASTER.PrFcused_uniq = PF.Fcused_uniq
						INNER JOIN Fcused FF ON APMASTER.FuncFcused_uniq = FF.Fcused_uniq			
						INNER JOIN Fcused TF ON APMASTER.Fcused_uniq = TF.Fcused_uniq			
						INNER JOIN
						  dbo.SUPINFO ON dbo.APMASTER.UNIQSUPNO = dbo.SUPINFO.UNIQSUPNO
						 CROSS JOIN
						  dbo.AgingRangeSetup AS a2 CROSS JOIN
						  dbo.AgingRangeSetup AS a3 CROSS JOIN
						  dbo.AgingRangeSetup AS a4 CROSS JOIN
						  dbo.AgingRangeSetup AS a1 
						  --cross join MICSSYS
	WHERE		(dbo.APMASTER.INVAMOUNTFC - dbo.APMASTER.APPMTSFC - dbo.APMASTER.DISC_TKNFC <> 0) 
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

	
declare @sql nvarchar(max)
if (@lcRptType = 'Summary')
	Begin
		set @sql= 
		-- 02/03/17 VL added functional currency code
		'SELECT SupName,InvNo,InvDate,Due_Date,Trans_Dt,PoNum,InvAmount,BalAmt,ApStatus,[Current],'+@cols+ 
									 ',[Over],R1Start,R1end,R2Start,R2End,R3Start,R3End,R4Start,R4End,UniqSupno,Phone,Terms,Range1,Range2,Range3,Range4
									 ,InvAmountFC,BalAmtFC,CurrentFC,OverFC,Range1FC,Range2FC,Range3FC,Range4FC
									 ,InvAmountPR,BalAmtPR,CurrentPR,OverPR,Range1PR,Range2PR,Range3PR,Range4PR,TSymbol,PSymbol,FSymbol
									 ,S.SUMBalamt, S.CurrentPCT, S.Range1PCT, S.Range2PCT, S.Range3PCT, S.Range4PCT, S.OverPCT
									 FROM @results, (SELECT SUM(Balamt) AS SUMBalamt, (SUM([Current])/SUM(Balamt))*100 AS CurrentPCT
									 ,(SUM(Range1)/SUM(Balamt))*100 AS Range1PCT, (SUM(Range2)/SUM(Balamt))*100 AS Range2PCT, (SUM(Range3)/SUM(Balamt))*100 AS Range3PCT
									 ,(SUM(Range4)/SUM(Balamt))*100 AS Range4PCT, (SUM([Over])/SUM(Balamt))*100 AS OverPCT FROM @results) AS S
									 ORDER BY Supname, Invno'

		execute sp_executesql @sql,N'@results tApAgingFC READONLY',@results
	END
	
ELSE
	--	@lcRptType = 'Forex'
	BEGIN
		-- Get latest ER rate
		;WITH ZMaxDate AS
		(SELECT MAX(Fcdatetime) AS Fcdatetime, FcUsed_Uniq 
			FROM FcHistory 
			GROUP BY Fcused_Uniq),
		ZFCLatestRate AS 
		(SELECT FcHistory.AskPrice, FcHistory.Fcused_uniq
			FROM FcHistory, ZMaxDate
			WHERE FcHistory.FcUsed_Uniq = ZMaxDate.FcUsed_Uniq
			AND FcHistory.Fcdatetime = ZMaxDate.Fcdatetime),
		ResultSUM AS
		(
		-- 02/03/17 VL removed Currency and added 3 currency symbols:Currency AS FCurrency
		SELECT TSymbol, PSymbol, FSymbol, Fcused_uniq,
		SUM(InvAmount) AS InvAmount, SUM(Balamt) AS Balamt,
		SUM([Current]) AS [Current], SUM(Range1) AS Range1, SUM(Range2) AS Range2, SUM(Range3) AS Range3, SUM(Range4) AS Range4, SUM([Over]) AS [Over],
		SUM(InvAmountFC) AS InvAmountFC, SUM(BalamtFC) AS BalamtFC,
		SUM([CurrentFC]) AS [CurrentFC], SUM(Range1FC) AS Range1FC, SUM(Range2FC) AS Range2FC, SUM(Range3FC) AS Range3FC, SUM(Range4FC) AS Range4FC, SUM([OverFC]) AS [OverFC],
		dbo.fn_Convert4FCHC('F',FcUsed_Uniq, SUM(InvAmountFC),dbo.fn_GetFunctionalCurrency(),'') AS InvAmountRV, dbo.fn_Convert4FCHC('F',FcUsed_Uniq, SUM(BalamtFC),dbo.fn_GetFunctionalCurrency(),'') AS BalamtRV,
		dbo.fn_Convert4FCHC('F',FcUsed_Uniq, SUM(CurrentFC),dbo.fn_GetFunctionalCurrency(),'') AS CurrentRV, dbo.fn_Convert4FCHC('F',FcUsed_Uniq, SUM(Range1FC),dbo.fn_GetFunctionalCurrency(),'') AS Range1RV,
		dbo.fn_Convert4FCHC('F',FcUsed_Uniq, SUM(Range2FC),dbo.fn_GetFunctionalCurrency(),'') AS Range2RV, dbo.fn_Convert4FCHC('F',FcUsed_Uniq, SUM(Range3FC),dbo.fn_GetFunctionalCurrency(),'') AS Range3RV,
		dbo.fn_Convert4FCHC('F',FcUsed_Uniq, SUM(Range4FC),dbo.fn_GetFunctionalCurrency(),'') AS Range4RV, dbo.fn_Convert4FCHC('F',FcUsed_Uniq, SUM(OverFC),dbo.fn_GetFunctionalCurrency(),'') AS OverRV, 0.00 AS SumBalAmt
		FROM @results GROUP BY TSymbol,PSymbol,FSymbol, Fcused_uniq)
		-- 02/03/17 VL remove HCurrency:@HCurrency AS HCurrency
		SELECT ResultSUM.*, ZFCLatestRate.ASkPrice AS ER
			FROM ResultSUM, ZFCLatestRate
		WHERE ResultSUM.Fcused_uniq = ZFCLatestRate.Fcused_Uniq
		ORDER BY TSymbol
		
	END

		
end