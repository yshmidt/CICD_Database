		-- =============================================
		-- Author:		<Yelena, Debbie>
		-- Create date: <09/16/2010>
		-- Description:	<Was created and used on [apageasof.rpt]>
		-- Modified:	11/06/2012 DRP:  When I updated to OLE DB (ADO) drivers on the CR, it was requiring that the AsOfDate field be smalldatetime.
		--				09/12/2013 DRP:  it was reported that when AP offsets where applied that they were not properly be deducted from the AP Aging As report. 
		--								 I modified parts of the code below so that it will indicate the prepayments using the lPrePay.  The issue was the fact that the results were not placing the same value in the invoice field
		--								 so when the results attempted to group/sum on the invoice field they did not match for prepayments used in offsets and then they would remain on the report. 
		--				02/07/2014 DRP:  I added  ";With tresults" to the procedure so that I could filter out at the end any results where the BalAmt = 0.00
		--				02/17/2014 DRP:  I used to be filtering off of the InvTransDate . . . but found that the users can change this transDate to be way in the future while the invoices were still displaying on the aging with Inv and duedate that were current
		--								 Replaced the T1 where . . . statement below with "where  DATEDIFF(Day,t1.INVDATE,@lcdate)>=0"  so that the results will be filtered off of the InvDate field. 
		--				02/17/2014 DRP:  Prior to this modification PrePays would not be included into any of the Aging columns.  But then it would not match the Aging Detail screen totals.  
		--								 The AgeDate formula has been changed where PrePayments are involved.  When it is a prePay it will take the date that was entered into the @lcDate as the AgeDate instead of leaving it null.
		--				02/19/2014 DRP:  I needed to make sure that I did not pull in Cancelled Debit Memos.
		--				02/19/2014 DRP:  I needed to add the apckd_uniq to the reference to make the records unique . . . 
		--				02/20/2014 DRP:  Found that I had a typo in the Where clause of the APMASTER section and (ap1.APSTATUS <> '= Deleted')  changed it to be and (ap1.APSTATUS <> 'Deleted')
		--				02/26/2014 DRP:  Needed to change the filter at the end of the procedure back to Trans_dt.  So even if they enter in an invoice date way in the future the report will still pull it and match the screen
		--								 There is still a chance that the users might change the Trans_date upon posting to the GL . . . but we will have to document that as a possible reason why the screen does not match the reports. 
		--				09/29/2014 DRP:  Found that if the user left the @lcDate blank that it was not displaying any results.  Added to the procedure so if @lcDate is blank then it will take the current calendar date. 
		--								 also had to change the section that would get the desired @lcdate.  In the situation where the Fy and Period were entered before, the Stimulsoft was not seeing it and it would either error out or take the current date each time. 
		--				10/01/2014 DRP:  needed to add the Supplier Terms and Phone to the results.  Also needed to add the PO #, InvAmount to the results 
		--				10/03/2014 DRP:  Added the Supplier List so that the correct suppliers are listed that the user is approved to see. 
		--								 Added script in order for the Ranges to display properly within QuickView and Reports.  Had to make changs to the tresult in order for them to match the tApAging Type
		--				12/12/14 DS Added supplier status filter
		--				02/06/2015 DRP:  changed the dm filter to not pull in both Cancelled or Pending debit memos
		--				02/24/2015 DRP:  Added the @lcUniqSupNo parameter to allow the users the ability to run the AP Aging As Of Report per Single Supplier if desired. 		
		--				02/04/2016 VL:   Added code for foreign currency and one more parameter to use original/latest rate to re-calculate HC values (not show on report now)
		--				05/17/16 DRP:	 Change the @lcUniqSupNo to be @lcUniqSup
		--				11/23/16 DRP:	 removed the @supplierStatus parameter and changed <<INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, @supplierStatus>> to be <<INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, 'All'>>
		--				01/11/17 VL:	 added one more parameter for fn_CalculateFCRateVariance() which is the rate ratio calculated based on functional currency or presentation currency
		--				02/03/17 VL:	 added functional currency code
		--				02/17/17 DRP:	Changed the <<INNER JOIN  Fcused ON Fcused.Fcused_uniq = ar1.Fcused_uniq>> to be <<left outer JOIN  Fcused ON Fcused.Fcused_uniq = ar1.Fcused_uniq>>
		--								also changed <<where tresults.BalAmtFC <> 0.00 and BalAmt <> 0.00>> to be <<where tresults.BalAmtFC <> 0.00 or BalAmt <> 0.00>>
-- 09/21/17 VL changed to check BalAmtFC <> 0 for FC installed and check BalAmt <> for FC not installed
-- 09/22/17 VL changed the way to calculate latest rate
-- 07/13/18 VL changed supname from char(30) to char(50)
--- missing code from Func
-- 09/26/18 VL: Added back @supplierStatus parameter (comment out by DRP 11/23/16).  Paramit reported an issue that the user was unable to view "Inactive" supplier, but the 'All' checkbox brought all suppliers (active and inactive).  I added the 'status' option back, so user can select status and here will reflect the status
-- 11/09/18 VL added AND (Ap1.InvAmount - Ap1.APPMTS - Ap1.DISC_TKN <> 0 OR Ap1.InvAmountFC - Ap1.APPMTSFC - Ap1.DISC_TKNFC <> 0), why we didn't filter out those records that have no balance?, also consider if FC is installed
-- 03/18/19 VL: need to remove the criteria AND (Ap1.InvAmount - Ap1.APPMTS - Ap1.DISC_TKN <> 0 OR Ap1.InvAmountFC - Ap1.APPMTSFC - Ap1.DISC_TKNFC <> 0) I added back in 11/09/18.  The "AS of" report should not limit by the criteria, I added FC installed considation at the last SQL
		-- =============================================
		CREATE PROCEDURE [dbo].[rptApAgeasofFC]
			 --Add the parameters for the stored procedure here
--declare
		@lcDate as date=  null
		,@lcFy as char(4)=''
		,@lnPeriod as int = ''
		,@lcAgeBy as varchar(12)='Invoice Date'
		, @userId uniqueidentifier= null
		-- 09/26/18 VL added the @supplierStatus back
		,@supplierStatus varchar(20) = 'All'	--11/23/16 DRP:  removed
		,@lcUniqSup varchar(max) = 'All'	--02/24/2015 DRP:  Added
		-- 02/04/16 VL added to show values in latest rate or not
		,@lLatestRate bit = 0

AS
BEGIN

/*SUPPLIER LIST*/ --10/03/2014 DRP:  Added --02/24/2015 DRP:  needed to change the Supplier LIst to work with the @lcuniqSupNo parameter. 
		SET NOCOUNT ON;
-- 09/22/17 VL create a table variable to use in calculating latest rate, the CTE with function just took too long
-- 07/13/18 VL changed supname from char(30) to char(50)
DECLARE @ZtresultRate TABLE (UNIQAPHEAD char(10), Trans_dt smalldatetime, supname char(50), uniqsupno char(10), Invno char(25), InvTransDt smalldatetime,
							INVDATE	smalldatetime, Due_date	smalldatetime, PONUM char(15), InvAmount numeric(12,2), Amount numeric(12,2), is_rel_gl bit, 
							Status char(15), reference char(30), R1Start numeric(3,0), R1End numeric(3,0), R2Start numeric(3,0), R2End numeric(3,0),
							R3Start numeric(3,0), R3End numeric(3,0), R4Start numeric(3,0), R4End numeric(3,0), AgeDate smalldatetime, terms char(15),
							phone char(19), APSTATUS char(15), invAmountFC numeric(12,2), AmountFC numeric(12,2), Fcused_uniq char(10), Fchist_keyH char(10),
							Fchist_keyC char(10), invAmountPR numeric(12,2), AmountPR numeric(12,2),TSymbol char(3),PSymbol char(3),FSymbol char(3),
							Old2NewRateH numeric(11,8), Old2NewRateC numeric(11,8), Old2NewRateHPR numeric(11,8), Old2NewRateCPR numeric(11,8))

-- 09/22/17 VL added for FC installed or not
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

-- 09/22/17 VL create a table variable to save FcUsedView, and use this table variable to update latest rate
DECLARE @tFcusedView TABLE (FCUsed_Uniq char(10), Country varchar(60), CURRENCY varchar(40), Symbol varchar(3), Prefix varchar(7), UNIT varchar(10), Subunit varchar(10), Thou_sep varchar(1), Deci_Sep varchar(1), 
		Deci_no numeric(2,0), AskPrice numeric(13,5), AskPricePR numeric(13,5), Fchist_key char(10), Fcdatetime smalldatetime)
INSERT @tFcusedView EXEC FcusedView

	DECLARE  @tSupplier tSupplier
	declare @tSupNo as table (Uniqsupno char (10))
	-- get list of Suppliers for @userid with access
	-- 09/26/18 VL changed to add supplier by @supplierStatus, not 'All'
	--INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, 'All';	--11/23/16 DRP:  replaced @supplierStatus with All
	INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, @supplierStatus;	--11/23/16 DRP:  replaced @supplierStatus with All

	--- have to check for all suppliers @lcUniqSupNo for all no need to run [fn_simpleVarcharlistToTable], no data will be retuned
	IF @lcUniqSup is not null and @lcUniqSup <>'' and @lcUniqSup<>'All'
		insert into @tSupNo select * from dbo.[fn_simpleVarcharlistToTable](@lcUniqSup,',')
			where CAST (id as CHAR(10)) in (select Uniqsupno from @tSupplier)
	ELSE
	--- empty or null customer or part number means no selection were made
	IF  @lcUniqSup='All'	
	BEGIN
		INSERT INTO @tSupNo SELECT UniqSupno FROM @tSupplier	
	
	END

				if @lcFy<>'' and @lnPeriod<>''
				BEGIN
						SELECT @lcDate=glfyrsdetl.ENDDATE 
							FROM glfyrsdetl inner join glfiscalyrs on glfiscalyrs.FY_UNIQ = glfyrsdetl.FK_FY_UNIQ 
							WHERE glfiscalyrs.FISCALYR =@lcFy and glfyrsdetl.PERIOD =@lnPeriod
					END -- @lcFy<>' ' and @lnPeriod<>0
				else	--09/29/2014 DRP:  Added
						begin
							select @lcDate = case when @lcDate is null then getdate() else @lcDate end
				end	--09/29/2014 DRP:  End Add
				
				/*09/29/2014 DRP:  replaced the below with the above, otherwise the Stimulsoft report was not working when Fy and Period was entered
				--IF @lcDate IS NULL
				--BEGIN
				--	-- look for the end of the given fiscal year period
				--	if @lcFy<>'' and @lnPeriod<>''
				--	BEGIN
				--		SELECT @lcDate=glfyrsdetl.ENDDATE 
				--			FROM glfyrsdetl inner join glfiscalyrs on glfiscalyrs.FY_UNIQ = glfyrsdetl.FK_FY_UNIQ 
				--			WHERE glfiscalyrs.FISCALYR =@lcFy and glfyrsdetl.PERIOD =@lnPeriod
				--	END -- @lcFy<>' ' and @lnPeriod<>0
				--	else	--09/29/2014 DRP:  Added
				--		begin
				--			select @lcDate = getdate()
				--		end	--09/29/2014 DRP:  End Add
				--END	-- @lcDate IS NULL
				09/29/2014 DRP:  Replacement end*/

/*10/03/2014 DRP:  NEEDED TO ADD THE ELOW IN ORDER FOR THE RANGES TO DISPLAY IN BOTH QUICKVIEW AND REPORT*/
	--07/25/13 YS create string for the names of the columnsbased on the AgingRangeSetup
	declare @cols as nvarchar(max)
	
	-- 02/03/17 VL added functional currency fields
	select @cols = STUFF((
	SELECT ',' + C.Name  
		from (select nRange,'Range'+RTRIM(cast(nRange as int))+' as ['+cast(nStart as varchar(4))+'-'+cast(nEND as varchar(4))+']'+
			', Range'+RTRIM(cast(nRange as int))+'FC as ['+cast(nStart as varchar(4))+'-'+cast(nEND as varchar(4))+'FC]' + 
			', Range'+RTRIM(cast(nRange as int))+'PR as ['+cast(nStart as varchar(4))+'-'+cast(nEND as varchar(4))+'PR]' name from AgingRangeSetup where AgingRangeSetup.cType='AP' ) C
	ORDER BY C.nRange
	FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'');
/*10/03/2014 DRP:  END ADD*/

	-- 02/04/16 VL changed to use tApAgingFC
	declare @results as tApAgingFC


;WITH tresult1 AS
(
				--This will pull the main information from the APMASTER tables.  This should include and pull fwd General Debit Memo's also.
				-- 02/04/16 VL use Fchist_keyH for the apmaster fchist_key and Fchist_keyC as fchist_key from rest of tables, InvAmount will use Fchist_keyH 
				-- to calculate, rest value fields will use Fchist_keyC to calculate
				-- 07/13/18 VL changed supname from char(30) to char(50)
				SELECT		ap1.UNIQAPHEAD, ap1.TRANS_DT, cast (s1.SUPNAME as CHAR(50)) as supname, s1.uniqsupno, cast (ap1.INVNO as CHAR(25)) as invno, 
							ap1.TRANS_DT as InvTransDt	--02/17/2014 DRP:, ap1.INVDATE
							,case when ap1.lPrepay = 1 then ap1.TRANS_DT else ap1.invdate end as INVDATE	--02/17/2014 drp: ap1.DUE_DATE
							,CASE WHEN AP1.lPrepay = 1 then ap1.TRANS_DT else ap1.due_date end as Due_date,cast (ap1.PONUM as CHAR(15)) as PONUM,ap1.invAmount
							,cast (ap1.INVAMOUNT as numeric (12,2)) as Amount,ap1.IS_REL_GL,cast (ap1.APSTATUS as CHAR(15)) as Status,CAST ('' as CHAR (30)) as Reference, 
							a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End, a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start, a4.nEnd AS R4End,
--02/17/2014 DRP:			--CASE WHEN @lcAgeBy ='Invoice Date' THEN ap1.INVDATE ELSE ap1.Due_date END AS AgeDate 							
							case when @lcAgeBy = 'Due Date' and ap1.lPrepay = 0 then ap1.DUE_DATE else 
								case when @lcAgeBy = 'Due Date' and  ap1.lprepay = 1 then @lcdate else 
									case when @lcAgeBy = 'Invoice Date' and ap1.lprepay = 0 then ap1.InvDate else
										case when @lcAgeBy = 'Invoice date' and ap1.lprepay = 1 then @lcDate end end end end as AgeDate 
							,s1.terms,s1.phone	,AP1.APSTATUS		       
							,ap1.invAmountFC
							,cast (ap1.INVAMOUNTFC as numeric (12,2)) as AmountFC
							,ap1.Fcused_uniq AS Fcused_uniq, ap1.Fchist_key AS Fchist_keyH, ap1.Fchist_key AS Fchist_keyC
							-- 02/03/17 VL added functional currency code, also comment out Fcused.Symbol AS Currency
							,ap1.invAmountPR
							,cast (ap1.INVAMOUNTPR as numeric (12,2)) as AmountPR
							,TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
				FROM dbo.APMASTER as ap1 
						--02/03/17 VL changed criteria to get 3 currencies
						left outer JOIN Fcused PF ON ap1.PrFcused_uniq = PF.Fcused_uniq
						left outer JOIN Fcused FF ON ap1.FuncFcused_uniq = FF.Fcused_uniq			
						left outer JOIN Fcused TF ON ap1.Fcused_uniq = TF.Fcused_uniq			
						INNER JOIN dbo.SUPINFO as s1 ON ap1.unIQSUPNO = s1.UNIQSUPNO 
									 cross join
									  dbo.AgingRangeSetup AS a4 CROSS JOIN
									  dbo.AgingRangeSetup AS a1 CROSS JOIN
									  dbo.AgingRangeSetup AS a2 CROSS JOIN
									  dbo.AgingRangeSetup AS a3
				WHERE     (ap1.INVAMOUNT <> 0.00 OR ap1.INVAMOUNTFC <> 0.00) 
/*02/20/2014 DRP		   and (ap1.APSTATUS <> '= Deleted') */
						   and (ap1.APSTATUS <> 'Deleted') 
						   and (ap1.is_rel_gl = 1)and (a1.cType = 'AP') AND (a1.nRange = 1) AND (a2.cType = 'AP') AND (a2.nRange = 2) 
									  AND (a3.cType = 'Ap') AND (a3.nRange = 3) AND (a4.cType = 'Ap') AND (a4.nRange = 4)


				union
				--This is pulling the APCHECK information.  It should also include records for AP Prepayments.
				-- 07/13/18 VL changed supname from char(30) to char(50)
				SELECT		ap2.uniqaphead	--02/17/2014 DRP--ckd2.UNIQAPHEAD
							,ckm2.CHECKDATE AS Trans_dt, cast (s2.SUPNAME as CHAR(50)) as supname, s2.uniqsupno, 
		/*09/12/2013 DRP*/	--case when left(ckd2.item_desc,6) = 'PrePay' then cast ('PrePayment: ' + right(ckd2.item_desc,11)  as CHAR(25)) else cast (ckd2.INVNO as CHAR(25)) end as InvNo, 
		--02/17/2014 DRP	case when ap2.lprepay = 1 then cast ('PrePayment: '+ right(ckd2.item_desc,11) as char(25)) else cast (ckd2.INVNO as CHAR(25)) end as InvNo
							case when ap2.lprepay = 1 then cast ('PrePayment: '+ ap2.ponum as char(25)) else cast (ckd2.INVNO as CHAR(25)) end as InvNo, ap2.TRANS_DT as InvTransDt
		--02/17/2014		, case when LEFT(ckd2.item_desc, 6) = 'PrePay' then ap2.trans_dt else ap2.INVDATE end as INVDATE, 
							, case when ap2.lprepay = 1 then ap2.trans_dt else ap2.INVDATE end as INVDATE --02/17/2014 DRP	ap2.DUE_DATE
							,CASE WHEN AP2.lPrepay = 1 then ap2.TRANS_DT else aP2.due_date end as Due_date	--, cast('' as char(15)) as ponum
							,cast (ap2.PONUM as CHAR(15)) as PONUM,ap2.invAmount, CAST(-(ckd2.APRPAY + ckd2.DISC_TKN) as numeric(12,2)) AS Amount, ckm2.IS_REL_GL
		/*02/19/2014 DRP	, cast (ckm2.STATUS as CHAR(15)) as status, cast ('Chk:  ' + ckm2.CHECKNO AS CHAR (25)) AS Reference, */
							, cast (ckm2.STATUS as CHAR(15)) as status, cast ('Chk:  ' + ckm2.CHECKNO+ckd2.apckd_uniq AS CHAR (30)) AS Reference, 
							a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End, a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start, a4.nEnd AS R4End,
--02/17/2014 DRP:		--	CASE WHEN @lcAgeBy ='Invoice Date' THEN ap2.INVDATE ELSE ap2.Due_date END AS AgeDate
							case when @lcAgeBy = 'Due Date' and ap2.lPrepay = 0 then ap2.DUE_DATE else 
								case when @lcAgeBy = 'Due Date' and  ap2.lprepay = 1 then @lcdate else 
									case when @lcAgeBy = 'Invoice Date' and ap2.lprepay = 0 then ap2.InvDate else
										case when @lcAgeBy = 'Invoice date' and ap2.lprepay = 1 then @lcDate end end end end as AgeDate 
							,s2.terms,s2.phone,AP2.APSTATUS	
							,ap2.invAmountFC, CAST(-(ckd2.APRPAYFC + ckd2.DISC_TKNFC) as numeric(12,2)) AS AmountFC
							,ap2.Fcused_uniq AS Fcused_uniq, ap2.Fchist_key AS Fchist_keyH, ckm2.Fchist_key AS Fchist_keyC
							-- 02/03/17 VL added functional currency code, also comment out Fcused.Symbol AS Currency
							,ap2.invAmountPR, CAST(-(ckd2.APRPAYPR + ckd2.DISC_TKNPR) as numeric(12,2)) AS AmountPR
							,TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
				FROM         dbo.apmaster as ap2 
							--02/03/17 VL changed criteria to get 3 currencies
							left outer JOIN Fcused PF ON ap2.PrFcused_uniq = PF.Fcused_uniq
							left outer JOIN Fcused FF ON ap2.FuncFcused_uniq = FF.Fcused_uniq			
							left outer JOIN Fcused TF ON ap2.Fcused_uniq = TF.Fcused_uniq			
							left outer join 
									  dbo.APCHKDET as ckd2 on ap2.UNIQAPHEAD = ckd2.UNIQAPHEAD INNER JOIN
									  dbo.APCHKMST as ckm2 ON ckd2.APCHK_UNIQ = ckm2.APCHK_UNIQ INNER JOIN
									  dbo.SUPINFO as s2 ON ckm2.UNIQSUPNO = s2.UNIQSUPNO 
									  CROSS JOIN
									  dbo.AgingRangeSetup AS a4 CROSS JOIN
									  dbo.AgingRangeSetup AS a1 CROSS JOIN
									  dbo.AgingRangeSetup AS a2 CROSS JOIN
									  dbo.AgingRangeSetup AS a3
				WHERE     (ckm2.IS_REL_GL = 1) and (a1.cType = 'AP') AND (a1.nRange = 1) AND (a2.cType = 'AP') AND (a2.nRange = 2) AND (a3.cType = 'Ap') AND (a3.nRange = 3) AND (a4.cType = 'Ap') 
									  AND (a4.nRange = 4)

				Union

				--this will pull fwd any Invoice Debit Memo information.
				-- 07/13/18 VL changed supname from char(30) to char(50)
				SELECT			dm3.UNIQAPHEAD, dm3.DMDATE AS Trans_dt, cast (s3.SUPNAME as CHAR(50)) as supname, s3.uniqsupno, cast (dm3.INVNO as CHAR (25)) as invno, 
								ap3.trans_dt as InvTransDt	--02/17/2014 DRP:,ap3.INVDATE
								,case when ap3.lprepay = 1 then ap3.trans_dt else ap3.INVDATE end as INVDATE	--02/17/2014 DRP:,ap3.DUE_DATE
								,CASE WHEN AP3.lPrepay = 1 then ap3.TRANS_DT else ap3.due_date end as Due_date, CAST(dm3.PONUM AS CHAR(15)) AS PONUM,ap3.invAmount
								, cast (-(dm3.DMTOTAL) as numeric(12,2)) AS Amount, dm3.IS_REL_GL, cast (dm3.DMSTATUS as CHAR(15)) AS Status
								, CAST('DM:  ' + dm3.DMEMONO AS CHAR(30)) AS Reference, a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End
								, a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start, a4.nEnd AS R4End,
--02/17/2014 DRP:				--CASE WHEN @lcAgeBy ='Invoice Date' THEN ap3.INVDATE ELSE ap3.Due_date END AS AgeDate
								case when @lcAgeBy = 'Due Date' and ap3.lPrepay = 0 then ap3.DUE_DATE else 
									case when @lcAgeBy = 'Due Date' and  ap3.lprepay = 1 then @lcdate else 
										case when @lcAgeBy = 'Invoice Date' and ap3.lprepay = 0 then ap3.InvDate else
											case when @lcAgeBy = 'Invoice date' and ap3.lprepay = 1 then @lcDate end end end end as AgeDate 
								,s3.terms,s3.phone,AP3.APSTATUS				
								,ap3.invAmountFC
								, cast (-(dm3.DMTOTALFC) as numeric(12,2)) AS AmountFC
								,dm3.Fcused_uniq AS Fcused_uniq, Ap3.Fchist_key AS Fchist_keyH, dm3.Fchist_key AS Fchist_keyC
								-- 02/03/17 VL added functional currency code, also comment out Fcused.Symbol AS Currency
								,ap3.invAmountPR
								, cast (-(dm3.DMTOTALPR) as numeric(12,2)) AS AmountPR
								,TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
				FROM         dbo.DMEMOS as dm3
								--02/03/17 VL changed criteria to get 3 currencies
								left outer JOIN Fcused PF ON dm3.PrFcused_uniq = PF.Fcused_uniq
								left outer JOIN Fcused FF ON dm3.FuncFcused_uniq = FF.Fcused_uniq			
								left outer JOIN Fcused TF ON dm3.Fcused_uniq = TF.Fcused_uniq			
								INNER JOIN
									  dbo.SUPINFO as s3 ON dm3.UNIQSUPNO = s3.UNIQSUPNO 
									  INNER JOIN
									  dbo.APMASTER as ap3 ON dm3.UNIQAPHEAD = ap3.UNIQAPHEAD CROSS JOIN
									  dbo.AgingRangeSetup AS a4 CROSS JOIN
									  dbo.AgingRangeSetup AS a1 CROSS JOIN
									  dbo.AgingRangeSetup AS a2 CROSS JOIN
									  dbo.AgingRangeSetup AS a3
				WHERE     (dm3.IS_REL_GL = 1) AND (a1.cType = 'AP') AND (a1.nRange = 1) AND (a2.cType = 'AP') AND (a2.nRange = 2) AND (a3.cType = 'Ap') AND 
									  (a3.nRange = 3) AND (a4.cType = 'Ap') AND (a4.nRange = 4) AND (dm3.DMTYPE = 1) 
						  --and dm3.dmstatus <> 'Cancelled'  --02/19/2014 DRP:  needed to make sure that I did not pull in Cancelled Debit Memos
						  and dm3.dmstatus not in ('Cancelled','Pending')	--02/06/2015 DRP:  added to make sure that I am also not pulling Pending Debit Memos

				union
				--this section will pull fwd the ap offset information
				-- 07/13/18 VL changed supname from char(30) to char(50)
				SELECT		apo4.UNIQAPHEAD, apo4.DATE as Trans_dt, cast (s4.SUPNAME as CHAR(50)) as supname, s4.uniqsupno, 
		/*09/12/2013 DRP*/	--CASE WHEN apo4.ref_no = 'PrePaidCk' THEN CAST('PrePayment: ' + ap4.ponum AS char(25)) ELSE CAST(apo4.Invno AS char(25)) END AS Invno, 
		/*09/12/2013 DRP*/	case when ap4.lPrepay = 1 then CAST('PrePayment: '+ap4.PONUM as CHAR(25)) else CAST (apo4.invno as CHAR(25)) end as Invno,ap4.trans_dt as InvTransDt
		/*09/12/2013 DRP*/	--, CASE WHEN APO4.REF_NO = 'PrePaidCk' then ap4.trans_dt else ap4.INVDATE end as INVDATE,
		/*09/12/2013 DRP*/	,case when ap4.lprepay =1 then ap4.TRANS_DT else ap4.INVDATE end as INVDATE	--02/17/2014 drp:,ap4.DUE_DATE
							,case when ap4.lPrepay = 1 then ap4.trans_dt else ap4.DUE_DATE end as Due_date	--, cast ('' as char(15)) as ponum
							,cast (ap4.PONUM as CHAR(15)) as PONUM,ap4.invAmount, cast (apo4.AMOUNT as numeric(12,2)) as Amount, APO4.is_rel_gl, 
							CAST('' AS char(15)) AS status, CAST('Offset:  ' + apo4.UNIQ_APOFF AS CHAR(30))AS reference, 
							a1.nStart AS R1Start, a1.nEnd AS R1End, a2.nStart AS R2Start, a2.nEnd AS R2End, a3.nStart AS R3Start, a3.nEnd AS R3End, a4.nStart AS R4Start, a4.nEnd AS R4End,
--02/17/2014 DRP:			--CASE WHEN @lcAgeBy ='Invoice Date' THEN ap4.INVDATE ELSE ap4.Due_date END AS AgeDate
							case when @lcAgeBy = 'Due Date' and ap4.lPrepay = 0 then ap4.DUE_DATE else 
								case when @lcAgeBy = 'Due Date' and  ap4.lprepay = 1 then @lcdate else 
									case when @lcAgeBy = 'Invoice Date' and ap4.lprepay = 0 then ap4.InvDate else
										case when @lcAgeBy = 'Invoice date' and ap4.lprepay = 1 then @lcDate end end end end as AgeDate 
							,s4.terms,s4.phone,AP4.APSTATUS	
							,ap4.invAmountFC, cast (apo4.AMOUNTFC as numeric(12,2)) as AmountFC
							,apo4.Fcused_uniq AS Fcused_uniq, Ap4.Fchist_key AS Fchist_keyH, apo4.Fchist_key AS Fchist_keyC
							-- 02/03/17 VL added functional currency code, also comment out Fcused.Symbol AS Currency
							,ap4.invAmountPR, cast (apo4.AMOUNTPR as numeric(12,2)) as AmountPR
							,TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
				FROM         dbo.APOFFSET as apo4 
								--02/03/17 VL changed criteria to get 3 currencies
								left outer JOIN Fcused PF ON apo4.PrFcused_uniq = PF.Fcused_uniq
								left outer JOIN Fcused FF ON apo4.FuncFcused_uniq = FF.Fcused_uniq			
								left outer JOIN Fcused TF ON apo4.Fcused_uniq = TF.Fcused_uniq			
								INNER JOIN
									  dbo.SUPINFO as s4 ON apo4.UNIQSUPNO = s4.UNIQSUPNO 
									  INNER JOIN
									  dbo.APMASTER as ap4 ON apo4.UNIQAPHEAD = ap4.UNIQAPHEAD CROSS JOIN
									  dbo.AgingRangeSetup AS a4 CROSS JOIN
									  dbo.AgingRangeSetup AS a1 CROSS JOIN
									  dbo.AgingRangeSetup AS a2 CROSS JOIN
									  dbo.AgingRangeSetup AS a3
				WHERE     (a1.cType = 'AP') AND (a1.nRange = 1) AND (a2.cType = 'AP') AND (a2.nRange = 2) AND (a3.cType = 'Ap') AND (a3.nRange = 3) AND (a4.cType = 'Ap') 
									  AND (a4.nRange = 4)

)

-- 09/22/17 VL found calling dbl-fn_calculateFCRateVAriance() really takes time in the CTE cursor, tried to use table variable to see if it speeds up
--02/07/2014 DRP:  Added the below :with tresults so I can filter out the BalAmt = 0.00 at the end. 
-- 02/04/16 VL need to update HC based on using latest rate/original rate and will calulate first, then SUM() group by Currency, Supname		
--tresultRate as 
--( 
--	--	01/11/17 VL added one more parameter for fn_CalculateFCRateVariance() which is the rate ratio calculated based on functional currency or presentation currency
--	-- 02/03/17 VL added Old2NewRateHPR and Old2NewRateCPR for presentation currency
--	SELECT tresult1.*, CASE WHEN @lLatestRate = 1 THEN dbo.fn_CalculateFCRateVariance(FcHist_keyH,'F') ELSE 1 END AS Old2NewRateH, 
--					CASE WHEN @lLatestRate = 1 THEN dbo.fn_CalculateFCRateVariance(FcHist_keyC,'F') ELSE 1 END AS Old2NewRateC,
--					CASE WHEN @lLatestRate = 1 THEN dbo.fn_CalculateFCRateVariance(FcHist_keyH,'P') ELSE 1 END AS Old2NewRateHPR, 
--					CASE WHEN @lLatestRate = 1 THEN dbo.fn_CalculateFCRateVariance(FcHist_keyC,'P') ELSE 1 END AS Old2NewRateCPR 
--		FROM tresult1
--),
--t1 AS 
--(
---- if @lLastestRate = 1, need to recalculate invamount and amount
--	SELECT supname, invno, Trans_dt,invdate, due_date, invtransdt, uniqaphead, ponum, 
--		 invamount*Old2NewRateH  AS invamount, 
--		amount*Old2NewRateC AS amount, 
--			apstatus, r1start, r1end, r2start, r2end, r3start, r3end, r4start, r4end, uniqsupno, phone, terms, AgeDate, invamountfc, amountfc, 
--			fcused_uniq, 
--			-- 02/03/17 VL comment out currency and added functional currency fields
--			invamountPR*Old2NewRateHPR  AS invamountPR, amountPR*Old2NewRateCPR AS amountPR, TSymbol, PSymbol, FSymbol
--		FRoM tresultRate
--),
-- 09/22/17 VL start new code to use table variable and re-calculate the latest rate by FC value/rate, not multiply the dbo.fn_CalculateFCRateVariance
INSERT INTO @ZtresultRate (UNIQAPHEAD , Trans_dt, supname, uniqsupno, Invno, InvTransDt,INVDATE, Due_date, PONUM, InvAmount, Amount, is_rel_gl, 
							Status, reference, R1Start, R1End , R2Start , R2End ,R3Start , R3End, R4Start , R4End , AgeDate , terms ,
							phone,  APSTATUS , invAmountFC , AmountFC , Fcused_uniq , Fchist_keyH ,Fchist_keyC , invAmountPR , AmountPR ,
							TSymbol ,PSymbol ,FSymbol, Old2NewRateH , Old2NewRateC , Old2NewRateHPR , Old2NewRateCPR )
	SELECT UNIQAPHEAD , Trans_dt, supname, uniqsupno, Invno, InvTransDt,INVDATE, Due_date, PONUM, InvAmount, Amount, is_rel_gl, 
							Status, reference, R1Start, R1End , R2Start , R2End ,R3Start , R3End, R4Start , R4End , AgeDate , terms ,
							phone,  APSTATUS , invAmountFC , AmountFC , Fcused_uniq , Fchist_keyH ,Fchist_keyC , invAmountPR , AmountPR ,
							TSymbol ,PSymbol ,FSymbol,1 AS Old2NewRateH , 1 AS Old2NewRateC , 1 AS Old2NewRateHPR , 1 AS Old2NewRateCPR
	FROM tresult1
IF @lLatestRate = 1 AND @lFCInstalled = 1
	BEGIN
	UPDATE @ZtresultRate SET	invamount = ROUND(invamountFC/F.AskPrice,2),
								amount = ROUND(amountFC/F.AskPrice,2),
								invamountPR = ROUND(invamountFC/F.AskPricePR,2),
								amountPR = ROUND(amountFC/F.AskPricePR,2)
				FROM @ZtresultRate R, @tFcusedView F
				WHERE R.Fcused_uniq = F.FCUsed_Uniq


END
-- 09/22/17 VL End}
;WITH t1 AS 
(
-- if @lLastestRate = 1, need to recalculate invamount and amount
	SELECT supname, invno, Trans_dt,invdate, due_date, invtransdt, uniqaphead, ponum, invamount, amount, 
			apstatus, r1start, r1end, r2start, r2end, r3start, r3end, r4start, r4end, uniqsupno, phone, terms, AgeDate, invamountfc, amountfc, 
			fcused_uniq, 
			-- 02/03/17 VL comment out currency and added functional currency fields
			invamountPR, amountPR, TSymbol, PSymbol, FSymbol
		FRoM @ZtresultRate
),
tresults AS		
(				
				
	select t1.supname,t1.invno,t1.InvDate,t1.Due_Date,t1.InvTransDt,t1.ponum,t1.invAmount,SUM(t1.amount) as BalAmt,T1.ApStatus
			,case when DATEDIFF(day,t1.agedate,@lcDate) <=0 then SUM(t1.amount) else CAST(0.00 as numeric(12,2)) end as [Current],
			case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r1start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r1end then SUM(t1.amount) else CAST(0.00 as numeric(12,2)) end as Range1,
			case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r2start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r2end then SUM(t1.amount) else CAST(0.00 as numeric(12,2)) end as Range2,
			case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r3start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r3end then SUM(t1.amount) else CAST(0.00 as numeric(12,2)) end as Range3,
			case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r4start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r4end then SUM(t1.amount) else CAST(0.00 as numeric(12,2)) end as Range4,
			case when DATEDIFF(day,t1.agedate,@lcDate) > t1.r4end then SUM(t1.amount) else CAST(0.00 as numeric(12,2)) end as [Over]
			, t1.R1Start, t1.R1End, t1.R2Start, t1.R2End, t1.R3Start, t1.R3End, t1.R4Start, t1.R4End,t1.uniqsupno,Phone,Terms, cast (@lcdate as smalldatetime) as AsOfDate 
			,t1.invAmountFC,SUM(t1.amountFC) as BalAmtFC
			,case when DATEDIFF(day,t1.agedate,@lcDate) <=0 then SUM(t1.amountFC) else CAST(0.00 as numeric(12,2)) end as [CurrentFC],
			case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r1start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r1end then SUM(t1.amountFC) else CAST(0.00 as numeric(12,2)) end as Range1FC,
			case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r2start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r2end then SUM(t1.amountFC) else CAST(0.00 as numeric(12,2)) end as Range2FC,
			case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r3start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r3end then SUM(t1.amountFC) else CAST(0.00 as numeric(12,2)) end as Range3FC,
			case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r4start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r4end then SUM(t1.amountFC) else CAST(0.00 as numeric(12,2)) end as Range4FC,
			case when DATEDIFF(day,t1.agedate,@lcDate) > t1.r4end then SUM(t1.amountFC) else CAST(0.00 as numeric(12,2)) end as [OverFC]
			-- 02/03/17 VL comment out Currency and added functional currency codes
			--t1.Currency
			,t1.invAmountPR,SUM(t1.amountPR) as BalAmtPR
			,case when DATEDIFF(day,t1.agedate,@lcDate) <=0 then SUM(t1.amountPR) else CAST(0.00 as numeric(12,2)) end as [CurrentPR],
			case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r1start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r1end then SUM(t1.amountPR) else CAST(0.00 as numeric(12,2)) end as Range1PR,
			case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r2start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r2end then SUM(t1.amountPR) else CAST(0.00 as numeric(12,2)) end as Range2PR,
			case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r3start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r3end then SUM(t1.amountPR) else CAST(0.00 as numeric(12,2)) end as Range3PR,
			case when DATEDIFF(day,t1.agedate,@lcDate) >= t1.r4start and DATEDIFF(day,t1.agedate,@lcDate) <= t1.r4end then SUM(t1.amountPR) else CAST(0.00 as numeric(12,2)) end as Range4PR,
			case when DATEDIFF(day,t1.agedate,@lcDate) > t1.r4end then SUM(t1.amountPR) else CAST(0.00 as numeric(12,2)) end as [OverPR],
			t1.TSymbol, t1.PSymbol, t1.FSymbol
	from t1


/*02/17/2014 DRP:   it was not correct to filter off of the Trans_dt
				--where (DATEPART(Year,t1.TRANS_DT)<DatePart(Year,@lcDate)) 
				--	OR (DATEPART(Year,t1.TRANS_DT)=DatePart(Year,@lcDate) and DATEPART(Month,t1.TRANS_DT)<DatePart(Month,@lcDate))
				--	OR (DATEPART(Year,t1.TRANS_DT)=DatePart(Year,@lcDate) and DATEPART(Month,t1.TRANS_DT)=DatePart(Month,@lcDate) AND DatePart(Day,t1.TRANS_DT)<=DatePart(Day,@lcDate)) 
*/
/*02/26/2014 DRP: where  DATEDIFF(Day,t1.INVDATE,@lcdate)>=0*/
				where  DATEDIFF(Day,t1.Trans_dt,@lcdate)>=0 
						and 1= case WHEN t1.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END

				-- 02/03/17 VL added TSymbol, PSymbol, FSymbol
				group by TSymbol, PSymbol, FSymbol, t1.supname, t1.UNIQSUPNO, t1.uniqaphead, t1.invno, t1.invTransDt, t1.INVDATE, t1.DUE_DATE, t1.ponum,t1.invamount,t1.invamountFC,t1.invamountPR,T1.APSTATUS, t1.R1Start, t1.R1End, t1.R2Start, t1.R2End, t1.R3Start, t1.R3End, t1.R4Start, t1.R4End, agedate,terms,phone	
		)
		-- 02/04/16 VL specify field names
		-- 02/03/17 VL added funcitonal currency code
		insert into @results (supname,invno,InvDate,Due_Date,ponum,invAmount,BalAmt,ApStatus,[Current],range1, range2, range3, range4,[over],
				R1Start,R1End,R2Start,R2End,R3Start, R3End, R4Start, R4End,uniqsupno,Phone,Terms, AsOfDate, invAmountFC,  BalAmtFC,
				CurrentFC,range1FC, range2FC, range3FC, range4FC, overFC, 
				invAmountPR,  BalAmtPR,
				CurrentPR,range1PR, range2PR, range3PR, range4PR, overPR, TSymbol, PSymbol, FSymbol)
		select supname,invno,InvDate,Due_Date,ponum,invAmount,BalAmt,ApStatus,[Current],range1, range2, range3, range4,[over],
				R1Start,R1End,R2Start,R2End,R3Start, R3End, R4Start, R4End,uniqsupno,Phone,Terms, AsOfDate, invAmountFC,  BalAmtFC,
				CurrentFC,range1FC, range2FC, range3FC, range4FC, overFC, 
				invAmountPR,  BalAmtPR,
				CurrentPR,range1PR, range2PR, range3PR, range4PR, overPR, TSymbol, PSymbol, FSymbol
		 -- 09/21/17 VL changed to check different fields based on if FC is installed or not
		 --from tresults where (BalamtFC <> 0 or BalAmt <> 0) --02/17/17 DRP:  change to be or instead of and
		 from tresults 
		  -- 03/18/19 VL also consider FC installed or not, if user doesn't have FC installed, should only check Balamt
		 -- where 1 = CASE WHEN @lFCInstalled = 1 AND BalAmtFC <> 0 THEN 1
		 --							  WHEN @lFCInstalled = 0 AND BalAmt <> 0 THEN 1 ELSE 0 END
		  WHERE ((@lFCInstalled = 0 AND Balamt <>0) OR (@lFCInstalled = 1 AND BalamtFC <> 0))

		 
/*10/03/2014 DRP*/
--These results will be used for the CR results.  Also for the WebManex QuickView for the Detailed version of the report
	--07/25/13 YS use dynamic SQL to assign an actual range as a column name in place of 'Range1','Range2',... 'Range4'
	declare @sql nvarchar(max)
			Begin
				--select * from @results
				-- 02/03/17 VL added functional currency
				set @sql= 
				'SELECT SupName ,InvNo,InvDate,Due_Date,Trans_Dt,PoNum,InvAmount,BalAmt,ApStatus,[Current],'+@cols+ 
									 ',[Over],R1Start,R1end,R2Start,R2End,R3Start,R3End,R4Start,R4End,UniqSupno,Phone,Terms,Range1,Range2,Range3,Range4,AsofDate,
									 InvAmountFC,BalAmtFC,CurrentFC,OverFC,Range1FC,Range2FC,Range3FC,Range4FC,
									 InvAmountPR,BalAmtPR,CurrentPR,OverPR,Range1PR,Range2PR,Range3PR,Range4PR,TSymbol,PSymbol,FSymbol FROM @results ORDER BY TSymbol, Supname, Invno'
			 execute sp_executesql @sql,N'@results tApAgingFC READONLY',@results
			End
	
							

END