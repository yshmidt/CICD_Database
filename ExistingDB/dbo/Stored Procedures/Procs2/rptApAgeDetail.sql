-- =============================================
-- Author:		<Debbie>
-- Create date: <11/27/2012>
-- Description:	<Was created and used on apagedet.rpt ~  apagesum.rpt>
-- Modified:	11/27/2012 DRP:  This stored procedure repaces the rptApAgeView.  We needed to have the Supplier Parameter added into the stored procedure itself and a view does not allow it. 
--				07/18/2013 YS allow @lcuniqsup have multiple csv
--				07/25/2013 YS change Range1,Range2,... columns to show an actual range , i.e Range1 as [1-30],Range2 as [31-60],... where [1-30] comes from AgingRangeSetup table
--				07/25/2013 DRP:  added the @lcIsReport parameter so that we could indicate what type of results to provide.  They had to be different for the CR and the quickview.  CR did not like when the field changed for the Ranges
--				09/20/2013 DRP:  the @lcUniqSup was not working properly for the WebReports.  I removed the * from the parameter default and any place that was calling this parameter
--				12/03/2013  YS    changed lcUniqSup to take 'All' instead of '' 
--				09/09/2014 DRp:  The Supplier Selection was not properly filtering out per the User Id.  
--				12/12/14 DS Added supplier status filter
-- =============================================
create PROCEDURE [dbo].[rptApAgeDetail]

 @lcSup as varchar (35) = '*'
 --12/03/13  YS    changed lcUniqSup to take 'All' instead of '' 
,@lcUniqSup as varchar(max) = 'All'		--this was added for the WebManex Version of the report only 
,@lcAgedOn as char(12) = 'Invoice Date'		-- 07/23/2013 DRP: (Invoice Date or Due Date)  Added to be used for the WebManex Reports and Quickviews.  CR is not using it at this time. 
,@lcRptType as char(10) = 'Detailed'	--07/24/2013 DRP:  (Detailed or Summary)  Added for Quickview results so it knows to display detailed or summary results. 
,@lcIsReport as bit = 1					--07/25/2013 DRP:  Found that the CR report does not handle the changing of the resulting fields/columns.  We will use the parameter to determine which results will be displayed
										--				   1 = Crystal or Stimulsoft Report . . .  0 =  WebManex QuickView results
, @userId uniqueidentifier= null
,@supplierStatus varchar(20) = 'All'

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
	--	insert into @unisupno  select * from  dbo.[fn_simpleVarcharlistToTable](@lcUniqSup,',') --09/09/2014 DRP:  This section had to be commented out and replaced with the below to work properly with the User Id


-- get list of approved suppliers for this user
DECLARE @tSupplier tSupplier
declare @tSupNo as table (Uniqsupno char (10))

INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, @supplierStatus  ;

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
		from (select nRange,'Range'+RTRIM(cast(nRange as int))+' as ['+cast(nStart as varchar(4))+'-'+cast(nEND as varchar(4))+']' name from AgingRangeSetup where AgingRangeSetup.cType='AP' ) C
	ORDER BY C.nRange
	FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'');
	
	
	--declare @results1 as table (SupName CHAR (30),InvNo CHAR(20),InvDate SMALLDATETIME,Due_Date SMALLDATETIME,Trans_Dt SMALLDATETIME,PoNum CHAR (15),InvAmount NUMERIC(12,2)
	--						   ,BalAmt NUMERIC(12,2),ApStatus char(15),[Current] numeric(12,2),Range1 numeric(12,2),Range2 numeric(12,2),Range3 numeric(12,2),Range4 numeric(12,2)
	--						   ,[Over] numeric(12,2),R1Start numeric(3),R1end numeric(3),R2Start numeric(3),R2End numeric(3),R3Start numeric(3),R3End numeric(3),R4Start numeric(3)
	--						   ,R4End numeric(3),UniqSupno char(10),Phone char(19),Terms char(15),Lic_name char(40))
	
	--07/25/13 YS use new UDTT tApAging
	declare @results as tApAging
	

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
						case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a1.nStart and getdate()-dbo.apmaster.INVDATE <= a1.nEnd then 
						dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a1.nStart and getdate()-dbo.apmaster.DUE_DATE <= a1.nEnd then 
						dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN 
							else 000000000-00 end end end as Range1		
				,case when @lcAgedOn = 'Invoice Date' then
						case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a2.nStart and getdate()-dbo.apmaster.INVDATE <= a2.nEnd then 
						dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
						case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a2.nStart and getdate()-dbo.apmaster.DUE_DATE <= a2.nEnd then
						dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN 
							else 000000000-00 end end end as Range2		
				,case when @lcAgedOn = 'Invoice Date' then
					case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a3.nStart and getdate()-dbo.apmaster.INVDATE <= a3.nEnd then 
						dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
					case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a3.nStart and getdate()-dbo.apmaster.DUE_DATE <= a3.nEnd then
						dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN 
							else 000000000-00 end end end as Range3	
				,case when @lcAgedOn = 'Invoice Date' then
					case when DATEDIFF(Day,ISNULL(apmaster.INVDATE,GETDATE()),GETDATE())>= a4.nStart and getdate()-dbo.apmaster.INVDATE <= a4.nEnd then
						dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN 
							else 000000000.00 end
				 else case when @lcAgedOn = 'Due Date' then 
					case when DATEDIFF(Day,ISNULL(apmaster.DUE_DATE,GETDATE()),GETDATE())>= a4.nStart and getdate()-dbo.apmaster.DUE_DATE <= a4.nEnd then
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
				a4.nStart AS R4Start, a4.nEnd AS R4End, dbo.APMASTER.UNIQSUPNO,SUPINFO.PHONE,SUPINFO.TERMS,MICSSYS.LIC_NAME
				
	FROM         dbo.APMASTER INNER JOIN
						  dbo.SUPINFO ON dbo.APMASTER.UNIQSUPNO = dbo.SUPINFO.UNIQSUPNO CROSS JOIN
						  dbo.AgingRangeSetup AS a2 CROSS JOIN
						  dbo.AgingRangeSetup AS a3 CROSS JOIN
						  dbo.AgingRangeSetup AS a4 CROSS JOIN
						  dbo.AgingRangeSetup AS a1 cross join
						  MICSSYS
	WHERE		(dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN <> 0) 
				and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end
				AND (a1.cType = 'AP') AND (a1.nRange = 1) AND (a2.cType = 'AP') AND (a2.nRange = 2) 
					AND (a3.cType = 'AP') AND (a3.nRange = 3) AND (a4.cType = 'AP') AND (a4.nRange = 4) AND (dbo.APMASTER.APSTATUS <> 'Deleted')
				-- the below was added for the WebManex Version report only
				--07/18/2013 YS allow @lcuniqsup have multiple csv
				--12/03/13  YS    changed lcUniqSup to take 'All' instead of '' 
				/*--and 1= CASE WHEN @lcUniqSup = 'All' then 1 
				--WHEN Supinfo.Uniqsupno IN (select UNIQSUPNO from @unisupno ) then 1 ELSE 0 END*/
				and 1= case WHEN apmaster.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
					
	ORDER BY dbo.SUPINFO.SUPNAME
	--select * from @results
--These results will be used for the CR results.  Also for the WebManex QuickView for the Detailed version of the report
	--07/25/13 YS use dynamic SQL to assign an actual range as a column name in place of 'Range1','Range2',... 'Range4'
	declare @sql nvarchar(max)
	if (@lcRptType = 'Detailed')
	Begin
		if(@lcIsReport = 1)
			Begin
				select * from @results
			End
		else if (@lcIsReport = 0)
			Begin
				set @sql= 	
				'SELECT SupName ,InvNo,InvDate,Due_Date,Trans_Dt,PoNum,InvAmount,BalAmt,ApStatus,[Current],'+@cols+ 
									 ',[Over],R1Start,R1end,R2Start,R2End,R3Start,R3End,R4Start,R4End,UniqSupno,Phone,Terms,Lic_name FROM @results';
			
				--07/25/13 YS sp_executesql procedure will take second parameter as User defined table type (UDTT) and we will pass @result table variable 
				execute sp_executesql @sql,N'@results tApAging READONLY',@results
			end
	end
	
--These results will be used only for the WebManex QuickView results if the users selects to view the Summary version of the report.
	else if (@lcRptType = 'Summary')
	Begin
		if(@lcIsReport = 1)
			Begin
				Select	SupName,UniqSupno,phone,SUM(InvAmount) as InvAmount,SUM(BalAmt) as BalAmt,SUM([Current]) as [Current],SUM(Range1) as Range1,SUM(Range2) as Range2,SUM(Range3) as Range3
						,SUM(Range4) as Range4,R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End
				from	@results
				group by SupName,UniqSupno,Phone,R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End
			End
		else if (@lcIsReport = 0)
			Begin
				set @Sql='
				SELECT SupName,UniqSupno,phone,InvAmount,BalAmt,[Current],'+@cols+',[Over],R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End
				FROM(
				Select	SupName,UniqSupno,phone,SUM(InvAmount) as InvAmount,SUM(BalAmt) as BalAmt,SUM([Current]) as [Current],
						SUM([Over]) as [Over]
						,SUM(Range1) as Range1,SUM(Range2) as Range2,SUM(Range3) as Range3
						,SUM(Range4) as Range4,R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End
				from	@results
				group by SupName,UniqSupno,Phone,R1Start,R1End,R2Start,R2End,R3Start,R3End,R4Start,R4End ) S '
				
				--07/25/13 YS sp_executesql procedure will take second parameter as User defined table type (UDTT) and we will pass @result table variable 
				execute sp_executesql @sql,N'@results tApAging READONLY',@results
			End
	End
		
end