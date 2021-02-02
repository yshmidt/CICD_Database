-- =============================================
-- Author:		Debbie
-- Create date: 07/17/2014
-- Description:	
-- Used On:		aptrans
-- Modified:	07/17/2014 DRP:  used to have rptApTransactionView, but needed to create this as a stored procedure in order for it to work properly with the WebMAnex parameters.  
--				12/12/14 DS Added supplier status filter
--				03/14/16	VL:	 Added FC code
--				04/08/16	VL:	 Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--				01/11/17	VL:	 added one more parameter for fn_CalculateFCRateVariance() which is the rate ratio calculated based on functional currency or presentation currency
--				01/30/17	VL:	 added functional currency code
-- 08/09/17 VL Found when re-calculating to latest rate, missed in some place for PR fields
-- 08/11/17 VL Sometimes it does create 1 cent balance in PR value while FUNC value has 0 dollar balance
-- we did count the 1 cent when releasing to GL to proper GL account, but the PR balance might still have 1 cent in the APmaster table, so here change to check if FUNC balance is 0, then show 0 as PR balance, 
-- so user won't get confused, same to appmtsPR field.
-- 08/11/17 VL The FUNC and PR BalAmt, InvAmount, Appmts and Disc_Tkn were always calculated to use latest rate to show in this report, but Penang decided we should use original rate (don't recalculate), so will remove 
-- the fn_CalculateFCRateVariance(), Zendesk#1183
-- =============================================
CREATE PROCEDURE [dbo].[rptApTrans]


	@lcDateStart as smalldatetime = null		
	,@lcDateEnd as smalldatetime = null
	,@lcUniqSupNo as varchar(max) = 'All'
	,@userId uniqueidentifier= null
	,@supplierStatus varchar(20) = 'All'
	
as
begin	
	
/*SUPPLIER LIST*/

	---- SET NOCOUNT ON added to prevent extra result sets from
	---- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE  @tSupplier tSupplier
	declare @tSupNo as table (Uniqsupno char (10))
	-- get list of Suppliers for @userid with access
	INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, @supplierStatus ;
	
	--- have to check for all suppliers @lcUniqSupNo for all no need to run [fn_simpleVarcharlistToTable], no data will be retuned
	IF @lcUniqSupNo is not null and @lcUniqSupNo <>'' and @lcUniqSupNo<>'All'
		insert into @tSupNo select * from dbo.[fn_simpleVarcharlistToTable](@lcUniqSupNo,',')
			where CAST (id as CHAR(10)) in (select Uniqsupno from @tSupplier)
	ELSE
	--- empty or null customer or part number means no selection were made
	IF  @lcUniqSupNo='All'	
	BEGIN
		INSERT INTO @tSupNo SELECT UniqSupno FROM @tSupplier	
	
	END		 
	

		
/*BEGINNING OF SELECT STATEMENT*/

-- 03/14/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
BEGIN
IF @lFCInstalled = 0
	BEGIN	

	/*APMASTER RECORDS*/
	SELECT	dbo.SUPINFO.SUPNAME, CAST(dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN AS Numeric(12, 2)) AS BalAmt
			,dbo.APMASTER.DUE_DATE, dbo.APMASTER.PONUM, dbo.APMASTER.INVNO, dbo.APMASTER.INVDATE, dbo.APMASTER.INVAMOUNT, dbo.APMASTER.APPMTS
			,dbo.APMASTER.DISC_TKN, dbo.APMASTER.UNIQAPHEAD, dbo.APMASTER.TRANS_DT
			,CAST(CASE WHEN LEFT(invno, 2)<> 'DM' THEN 'AP-Invoice' ELSE 'AP-Debit Memo' END AS char(15)) AS Type, dbo.APMASTER.UNIQSUPNO
			, CAST(' ' AS char(35)) AS InvRef, CAST(' ' AS char(75)) AS ApChkRef, CAST(0.00 AS Numeric(12, 2)) AS CurrTotal
	FROM	dbo.APMASTER INNER JOIN
			dbo.SUPINFO ON dbo.APMASTER.UNIQSUPNO = dbo.SUPINFO.UNIQSUPNO
	WHERE	1= case WHEN apmaster.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
			and cast(trans_Dt as Date) between  @lcDateStart AND @lcDateEnd
			and (dbo.APMASTER.APSTATUS <> 'Deleted') 
			AND (LEFT(dbo.APMASTER.REASON, 7) <> 'PrePaid')
		
	UNION

	/*AP DEBIT MEMOS*/
	SELECT	SUPINFO_3.SUPNAME, CAST(0.00 AS Numeric(12, 2)) AS BalAmt, CAST(NULL AS smalldatetime) AS due_date, APMASTER_3.PONUM
			,dbo.DMEMOS.DMEMONO AS Invno, CAST(NULL AS smalldatetime) AS INVDATE, - dbo.DMEMOS.DMTOTAL AS InvAmount, CAST(0.00 AS Numeric(12, 2)) AS APPMTS
			,CAST(0.00 AS Numeric(12, 2)) AS DISC_TKN, dbo.DMEMOS.UNIQAPHEAD, dbo.DMEMOS.DMDATE AS Trans_dt, CAST('AP-Debit Memo' AS char(15)) AS Type
			,dbo.DMEMOS.UNIQSUPNO, CAST('For InvNo:' + APMASTER_3.INVNO AS char(35)) AS InvRef, CAST(' ' AS char(75)) AS ApChkRef, CAST(0.00 AS Numeric(12, 2)) AS CurrTotal
	FROM	dbo.DMEMOS 
			INNER JOIN dbo.SUPINFO AS SUPINFO_3 ON dbo.DMEMOS.UNIQSUPNO = SUPINFO_3.UNIQSUPNO 
			INNER JOIN dbo.APMASTER AS APMASTER_3 ON dbo.DMEMOS.UNIQAPHEAD = APMASTER_3.UNIQAPHEAD
	WHERE	1= case WHEN DMEMOS.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
			and cast(DMDATE as Date) between  @lcDateStart AND @lcDateEnd
			AND (dbo.DMEMOS.DMTYPE = 1) AND (dbo.DMEMOS.DMAPPLIED <> 0.00)

	/*AP CHECKS*/
	UNION

	/* 07/26/13 YS mdofied check to allow checks w/o invoices*/ 
	SELECT	SUPINFO_2.SUPNAME, CAST(0.00 AS Numeric(12, 2)) AS BalAmt, CAST(NULL AS smalldatetime) AS due_date, ISNULL(APMASTER_2.PONUM, SPACE(15)) AS PONUM
			,CASE WHEN dbo.apchkmst.status = 'Void' THEN dbo.APCHKMST.CHECKNO + ' ~ Voided' WHEN dbo.apchkmst.status = 'Voiding Entry' THEN dbo.apchkmst.checkno + ' ~ Voiding Entry'
				WHEN dbo.apchkmst.status = 'Void/Reprinted' THEN dbo.apchkmst.checkno + ' ~ Voided/Reprinted' ELSE dbo.apchkmst.checkno END AS Invno
			,CAST(NULL AS smalldatetime) AS INVDATE, - dbo.APCHKDET.APRPAY AS InvAmount, CAST(0.00 AS Numeric(12, 2)) AS APPMTS, CAST(0.00 AS Numeric(12, 2)) AS DISC_TKN
			,dbo.APCHKDET.UNIQAPHEAD, dbo.APCHKMST.CHECKDATE AS Trans_dt, CAST('Ap-Check' AS char(15)) AS Type, dbo.APCHKMST.UNIQSUPNO
			,CAST(CASE WHEN APCHKMST.LAPPREPAY = 1 OR APMASTER_2.INVNO IS NULL THEN dbo.apchkdet.item_desc ELSE 'For Invno:' + APMASTER_2.INVNO END AS char(35)) AS InvRef
			,CAST(dbo.APCHKMST.CHECKNOTE AS char(75)) AS ApChkRef, CAST(0.00 AS Numeric(12, 2)) AS CurrTotal
	FROM	dbo.SUPINFO AS SUPINFO_2 
			INNER JOIn dbo.APCHKMST ON SUPINFO_2.UNIQSUPNO = dbo.APCHKMST.UNIQSUPNO 
			INNER JOIN dbo.APCHKDET ON dbo.APCHKMST.APCHK_UNIQ = dbo.APCHKDET.APCHK_UNIQ 
			LEFT OUTER JOIN dbo.APMASTER AS APMASTER_2 ON dbo.APCHKDET.UNIQAPHEAD = APMASTER_2.UNIQAPHEAD
	WHERE	1= case WHEN APCHKMST.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
			and cast(CHECKDATE as Date) between  @lcDateStart AND @lcDateEnd

	UNION

	/*AP OFFSETS*/
	SELECT	TOP (100) PERCENT SUPINFO_1.SUPNAME, CAST(0.00 AS Numeric(12, 2)) AS BalAmt, CAST(NULL AS smalldatetime) AS due_date, APMASTER_1.PONUM
			,CAST(' ' AS char(20)) AS InvNo, CAST(NULL AS smalldatetime) AS INVDATE, dbo.APOFFSET.AMOUNT AS InvAmount, CAST(0.00 AS Numeric(12, 2)) AS APPMTS
			,CAST(0.00 AS Numeric(12, 2)) AS DISC_TKN, dbo.APOFFSET.UNIQAPHEAD, dbo.APOFFSET.DATE AS Trans_dt, CAST('AP-Offset' AS char(15)) AS Type
			,dbo.APOFFSET.UNIQSUPNO,CAST(CASE WHEN dbo.apoffset.ref_no = 'PrePaidCk' THEN 'For ' + dbo.apoffset.ref_no ELSE 'For InvNo:' + dbo.APOFFSET.INVNO END AS char(35)) AS InvRef
			,CAST(' ' AS char(75)) AS ApChkRef, CAST(0.00 AS Numeric(12, 2)) AS CurrTotal
	FROM	dbo.APOFFSET 
			INNER JOIN dbo.SUPINFO AS SUPINFO_1 ON dbo.APOFFSET.UNIQSUPNO = SUPINFO_1.UNIQSUPNO 
			INNER JOIN dbo.APMASTER AS APMASTER_1 ON dbo.APOFFSET.UNIQAPHEAD = APMASTER_1.UNIQAPHEAD
	WHERE	1= case WHEN APOFFSET.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
			and cast(APOFFSET.DATE as Date) between  @lcDateStart AND @lcDateEnd

	ORDER BY SUPNAME, TRANS_DT

	END
ELSE
-- FC installed	
	BEGIN
	/*APMASTER RECORDS*/
	-- 08/11/17 VL The FUNC and PR BalAmt, InvAmount and Appmts were always calculated to use latest rate to show in this report, but Penang decided we should use original rate (don't recalculate), so will remove 
	-- the fn_CalculateFCRateVariance(), Zendesk#1183
	SELECT	dbo.SUPINFO.SUPNAME, 
			--CAST((dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN)*dbo.fn_CalculateFCRateVariance(Fchist_key,'F') AS Numeric(12, 2)) AS BalAmt
			CAST(dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN AS Numeric(12, 2)) AS BalAmt
			,dbo.APMASTER.DUE_DATE, dbo.APMASTER.PONUM, dbo.APMASTER.INVNO, dbo.APMASTER.INVDATE
			--,CAST(dbo.APMASTER.INVAMOUNT*dbo.fn_CalculateFCRateVariance(Apmaster.Fchist_key,'F') AS NUMERIC(12,2)) AS INVAMOUNT
			,dbo.APMASTER.INVAMOUNT
			--,CAST(dbo.APMASTER.APPMTS*dbo.fn_CalculateFCRateVariance(Fchist_key,'F') AS NUMERIC(12,2)) AS APPMTS
			,dbo.APMASTER.APPMTS
			--,CAST(dbo.APMASTER.DISC_TKN*dbo.fn_CalculateFCRateVariance(Fchist_key,'F') AS numeric(12,2)) AS Disc_Tkn
			,dbo.APMASTER.DISC_TKN
			,dbo.APMASTER.UNIQAPHEAD, dbo.APMASTER.TRANS_DT
			,CAST(CASE WHEN LEFT(invno, 2)<> 'DM' THEN 'AP-Invoice' ELSE 'AP-Debit Memo' END AS char(15)) AS Type, dbo.APMASTER.UNIQSUPNO
			, CAST(' ' AS char(35)) AS InvRef, CAST(' ' AS char(75)) AS ApChkRef, CAST(0.00 AS Numeric(12, 2)) AS CurrTotal
			,CAST(dbo.APMASTER.INVAMOUNTFC - dbo.APMASTER.APPMTSFC - dbo.APMASTER.DISC_TKNFC AS Numeric(12, 2)) AS BalAmtFC
			,dbo.APMASTER.INVAMOUNTFC, dbo.APMASTER.APPMTSFC,dbo.APMASTER.DISC_TKNFC,CAST(0.00 AS Numeric(12, 2)) AS CurrTotalFC
			-- 01/30/17 VL added functional currency code
			-- 08/11/17 VL Sometimes it does create 1 cent balance in PR value while FUNC value has 0 dollar balance
			-- we did count the 1 cent when releasing to GL, but the PR balance might still have 1 cent in the APmaster table, so here change to check if FUNC balance is 0, then show 0 as PR balance, so user won't get confused
			--,CAST((dbo.APMASTER.INVAMOUNTPR - dbo.APMASTER.APPMTSPR - dbo.APMASTER.DISC_TKNPR)*dbo.fn_CalculateFCRateVariance(Fchist_key,'P') AS Numeric(12, 2)) AS BalAmtPR
			,CASE WHEN dbo.APMASTER.INVAMOUNT - dbo.APMASTER.APPMTS - dbo.APMASTER.DISC_TKN <> 0 THEN CAST(dbo.APMASTER.INVAMOUNTPR - dbo.APMASTER.APPMTSPR - dbo.APMASTER.DISC_TKNPR AS Numeric(12, 2)) ELSE 0.00 END AS BalAmtPR
			,dbo.APMASTER.INVAMOUNTPR
			-- 08/11/17 VL Sometimes it does create 1 cent balance in PR value while FUNC value has 0 dollar balance
			-- we did count the 1 cent when releasing to GL, but the PR balance might still have 1 cent in the APmaster table, so here change to check if FUNC balance is 0, then show 0 as PR balance, so user won't get confused
			--dbo.APMASTER.APPMTSPR
			,CASE WHEN APMASTER.INVAMOUNT <> APMASTER.APPMTS THEN dbo.APMASTER.APPMTSPR	ELSE APMASTER.INVAMOUNTPR END AS AppmtsPR
			,dbo.APMASTER.DISC_TKNPR,CAST(0.00 AS Numeric(12, 2)) AS CurrTotalPR		
			,TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	FROM	dbo.APMASTER
			-- 01/30/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON APMASTER.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON APMASTER.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON APMASTER.Fcused_uniq = TF.Fcused_uniq			
			INNER JOIN dbo.SUPINFO ON dbo.APMASTER.UNIQSUPNO = dbo.SUPINFO.UNIQSUPNO
	WHERE	1= case WHEN apmaster.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
			and cast(trans_Dt as Date) between  @lcDateStart AND @lcDateEnd
			and (dbo.APMASTER.APSTATUS <> 'Deleted') 
			AND (LEFT(dbo.APMASTER.REASON, 7) <> 'PrePaid')

	UNION

	/*AP DEBIT MEMOS*/
	SELECT	SUPINFO_3.SUPNAME, CAST(0.00 AS Numeric(12, 2)) AS BalAmt, CAST(NULL AS smalldatetime) AS due_date, APMASTER_3.PONUM
			,dbo.DMEMOS.DMEMONO AS Invno, CAST(NULL AS smalldatetime) AS INVDATE
			--,CAST(-dbo.DMEMOS.DMTOTAL*dbo.fn_CalculateFCRateVariance(Dmemos.Fchist_key,'F') AS numeric(12,2)) AS InvAmount
			,CAST(-dbo.DMEMOS.DMTOTAL AS numeric(12,2)) AS InvAmount
			,CAST(0.00 AS Numeric(12, 2)) AS APPMTS
			,CAST(0.00 AS Numeric(12, 2)) AS DISC_TKN, dbo.DMEMOS.UNIQAPHEAD, dbo.DMEMOS.DMDATE AS Trans_dt, CAST('AP-Debit Memo' AS char(15)) AS Type
			,dbo.DMEMOS.UNIQSUPNO, CAST('For InvNo:' + APMASTER_3.INVNO AS char(35)) AS InvRef, CAST(' ' AS char(75)) AS ApChkRef, CAST(0.00 AS Numeric(12, 2)) AS CurrTotal
			,CAST(0.00 AS Numeric(12, 2)) AS BalAmtFC,- dbo.DMEMOS.DMTOTALFC AS InvAmountFC, CAST(0.00 AS Numeric(12, 2)) AS APPMTSFC
			,CAST(0.00 AS Numeric(12, 2)) AS DISC_TKNFC,CAST(0.00 AS Numeric(12, 2)) AS CurrTotalFC
			-- 01/30/17 VL added functional currency code
			,CAST(0.00 AS Numeric(12, 2)) AS BalAmtPR
			--,CAST(-dbo.DMEMOS.DMTOTALPR*dbo.fn_CalculateFCRateVariance(Dmemos.Fchist_key,'P') AS numeric(12,2)) AS InvAmountPR, CAST(0.00 AS Numeric(12, 2)) AS APPMTSPR
			,CAST(-dbo.DMEMOS.DMTOTALPR AS numeric(12,2)) AS InvAmountPR, CAST(0.00 AS Numeric(12, 2)) AS APPMTSPR
			,CAST(0.00 AS Numeric(12, 2)) AS DISC_TKNPR,CAST(0.00 AS Numeric(12, 2)) AS CurrTotalPR
			,TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	FROM	dbo.DMEMOS
			-- 01/30/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON DMEMOS.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON DMEMOS.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON DMEMOS.Fcused_uniq = TF.Fcused_uniq			
			INNER JOIN dbo.SUPINFO AS SUPINFO_3 ON dbo.DMEMOS.UNIQSUPNO = SUPINFO_3.UNIQSUPNO 
			INNER JOIN dbo.APMASTER AS APMASTER_3 ON dbo.DMEMOS.UNIQAPHEAD = APMASTER_3.UNIQAPHEAD
	WHERE	1= case WHEN DMEMOS.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
			and cast(DMDATE as Date) between  @lcDateStart AND @lcDateEnd
			AND (dbo.DMEMOS.DMTYPE = 1) AND (dbo.DMEMOS.DMAPPLIED <> 0.00)

	/*AP CHECKS*/
	UNION

	/* 07/26/13 YS mdofied check to allow checks w/o invoices*/ 
	SELECT	SUPINFO_2.SUPNAME, CAST(0.00 AS Numeric(12, 2)) AS BalAmt, CAST(NULL AS smalldatetime) AS due_date, ISNULL(APMASTER_2.PONUM, SPACE(15)) AS PONUM
			,CASE WHEN dbo.apchkmst.status = 'Void' THEN dbo.APCHKMST.CHECKNO + ' ~ Voided' WHEN dbo.apchkmst.status = 'Voiding Entry' THEN dbo.apchkmst.checkno + ' ~ Voiding Entry'
				WHEN dbo.apchkmst.status = 'Void/Reprinted' THEN dbo.apchkmst.checkno + ' ~ Voided/Reprinted' ELSE dbo.apchkmst.checkno END AS Invno
			,CAST(NULL AS smalldatetime) AS INVDATE
			--, CAST(-dbo.APCHKDET.APRPAY*dbo.fn_CalculateFCRateVariance(Apchkmst.Fchist_key,'F') AS numeric(12,2)) AS InvAmount
			, CAST(-dbo.APCHKDET.APRPAY AS numeric(12,2)) AS InvAmount
			, CAST(0.00 AS Numeric(12, 2)) AS APPMTS, CAST(0.00 AS Numeric(12, 2)) AS DISC_TKN
			,dbo.APCHKDET.UNIQAPHEAD, dbo.APCHKMST.CHECKDATE AS Trans_dt, CAST('Ap-Check' AS char(15)) AS Type, dbo.APCHKMST.UNIQSUPNO
			,CAST(CASE WHEN APCHKMST.LAPPREPAY = 1 OR APMASTER_2.INVNO IS NULL THEN dbo.apchkdet.item_desc ELSE 'For Invno:' + APMASTER_2.INVNO END AS char(35)) AS InvRef
			,CAST(dbo.APCHKMST.CHECKNOTE AS char(75)) AS ApChkRef, CAST(0.00 AS Numeric(12, 2)) AS CurrTotal
			,CAST(0.00 AS Numeric(12, 2)) AS BalAmtFC,- dbo.APCHKDET.APRPAYFC AS InvAmountFC, CAST(0.00 AS Numeric(12, 2)) AS APPMTSFC
			, CAST(0.00 AS Numeric(12, 2)) AS DISC_TKNFC, CAST(0.00 AS Numeric(12, 2)) AS CurrTotalFC
			-- 01/30/17 VL added functional currency code
			,CAST(0.00 AS Numeric(12, 2)) AS BalAmtPR
			--,CAST(-dbo.APCHKDET.APRPAYPR*dbo.fn_CalculateFCRateVariance(Apchkmst.Fchist_key,'P') AS numeric(12,2)) AS InvAmountPR, CAST(0.00 AS Numeric(12, 2)) AS APPMTSPR
			,CAST(-dbo.APCHKDET.APRPAYPR AS numeric(12,2)) AS InvAmountPR, CAST(0.00 AS Numeric(12, 2)) AS APPMTSPR
			, CAST(0.00 AS Numeric(12, 2)) AS DISC_TKNPR, CAST(0.00 AS Numeric(12, 2)) AS CurrTotalPR
			,TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	FROM	dbo.SUPINFO AS SUPINFO_2 
			INNER JOIn dbo.APCHKMST ON SUPINFO_2.UNIQSUPNO = dbo.APCHKMST.UNIQSUPNO 
			-- 01/30/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON APCHKMST.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON APCHKMST.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON APCHKMST.Fcused_uniq = TF.Fcused_uniq			
			INNER JOIN dbo.APCHKDET ON dbo.APCHKMST.APCHK_UNIQ = dbo.APCHKDET.APCHK_UNIQ 
			LEFT OUTER JOIN dbo.APMASTER AS APMASTER_2 ON dbo.APCHKDET.UNIQAPHEAD = APMASTER_2.UNIQAPHEAD
	WHERE	1= case WHEN APCHKMST.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
			and cast(CHECKDATE as Date) between  @lcDateStart AND @lcDateEnd

	UNION

	/*AP OFFSETS*/
	SELECT	TOP (100) PERCENT SUPINFO_1.SUPNAME, CAST(0.00 AS Numeric(12, 2)) AS BalAmt, CAST(NULL AS smalldatetime) AS due_date, APMASTER_1.PONUM
			,CAST(' ' AS char(20)) AS InvNo, CAST(NULL AS smalldatetime) AS INVDATE
			--,CAST(dbo.APOFFSET.AMOUNT*dbo.fn_CalculateFCRateVariance(Apoffset.Fchist_key,'F') AS numeric(12,2)) AS InvAmount
			,CAST(dbo.APOFFSET.AMOUNT AS numeric(12,2)) AS InvAmount
			, CAST(0.00 AS Numeric(12, 2)) AS APPMTS
			,CAST(0.00 AS Numeric(12, 2)) AS DISC_TKN, dbo.APOFFSET.UNIQAPHEAD, dbo.APOFFSET.DATE AS Trans_dt, CAST('AP-Offset' AS char(15)) AS Type
			,dbo.APOFFSET.UNIQSUPNO,CAST(CASE WHEN dbo.apoffset.ref_no = 'PrePaidCk' THEN 'For ' + dbo.apoffset.ref_no ELSE 'For InvNo:' + dbo.APOFFSET.INVNO END AS char(35)) AS InvRef
			,CAST(' ' AS char(75)) AS ApChkRef, CAST(0.00 AS Numeric(12, 2)) AS CurrTotal
			,CAST(0.00 AS Numeric(12, 2)) AS BalAmtFC, dbo.APOFFSET.AMOUNTFC AS InvAmountFC, CAST(0.00 AS Numeric(12, 2)) AS APPMTSFC
			,CAST(0.00 AS Numeric(12, 2)) AS DISC_TKNFC, CAST(0.00 AS Numeric(12, 2)) AS CurrTotalFC
			-- 01/30/17 VL added functional currency code
			,CAST(0.00 AS Numeric(12, 2)) AS BalAmtPR
			--, CAST(dbo.APOFFSET.AMOUNTPR*dbo.fn_CalculateFCRateVariance(Apoffset.Fchist_key,'P') AS numeric(12,2)) AS InvAmountPR, CAST(0.00 AS Numeric(12, 2)) AS APPMTSPR
			, CAST(dbo.APOFFSET.AMOUNTPR AS numeric(12,2)) AS InvAmountPR, CAST(0.00 AS Numeric(12, 2)) AS APPMTSPR
			,CAST(0.00 AS Numeric(12, 2)) AS DISC_TKNPR, CAST(0.00 AS Numeric(12, 2)) AS CurrTotalPR
			,TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	FROM	dbo.APOFFSET
			-- 01/30/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON APOFFSET.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON APOFFSET.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON APOFFSET.Fcused_uniq = TF.Fcused_uniq			
			INNER JOIN dbo.SUPINFO AS SUPINFO_1 ON dbo.APOFFSET.UNIQSUPNO = SUPINFO_1.UNIQSUPNO 
			INNER JOIN dbo.APMASTER AS APMASTER_1 ON dbo.APOFFSET.UNIQAPHEAD = APMASTER_1.UNIQAPHEAD
	WHERE	1= case WHEN APOFFSET.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
			and cast(APOFFSET.DATE as Date) between  @lcDateStart AND @lcDateEnd

	ORDER BY TSymbol,SUPNAME, TRANS_DT

	END
END--END of IF FC installed
end