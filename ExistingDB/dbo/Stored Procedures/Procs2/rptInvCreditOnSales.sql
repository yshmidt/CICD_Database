


-- =============================================
-- Author:		<Debbie and Vicky> 
-- Create date: <02/28/2012>
-- Description:	<compiles details for the  Credit on Sales Summary In Percentage by Customer>
-- Reports:     <used on inv_rep9.rpt>
-- Modified:	10/04/2013 DRP:  Needed to change the parameters from @ldStartDate to @lcDateStart, etc. . . . 
--				01/18/2017	VL:	 added functional currency code
-- 07/16/18 VL changed custname from char(35) to char(50)
-- =============================================
CREATE PROCEDURE [dbo].[rptInvCreditOnSales] 

--10/04/2013 DRP:   @ldStartDate smalldatetime, @ldEndDate smalldatetime
	@lcDateStart as smalldatetime = null
	, @lcDateEnd as smalldatetime = null


 , @userId uniqueidentifier=null 
as
begin
-- 01/18/17 VL separate FC and non FC
IF dbo.fn_IsFCInstalled() = 0
	BEGIN
	-- 07/16/18 VL changed custname from char(35) to char(50)
	DECLARE @ZInvDetl TABLE (Custno char(10), CustName char(50), CmAmt numeric(20,2),InvAmt numeric(20,2), [Percent] numeric(6,2),InvoiceNo char (10))

	INSERT @ZInvDetl

	--this will gather the invoice records
	select	plmain.CUSTNO,customer.CUSTNAME,cast(0.00 as numeric(20,2)) as CmAmt,(plmain.INVTOTAL-FREIGHTAMT-plmain.TOTTAXE-TOTTAXF) as InvAmt, 000.00 as [percent],plmain.INVOICENO
	from	PLMAIN
			inner join customer on plmain.CUSTNO = customer.CUSTNO
	where	plmain.INVDATE between @lcDateStart and @lcDateEnd
			and IS_INVPOST = 1

	union all
	--gathers credit memo records that are associated to invoice records
	select	cmmain.CUSTNO, customer.CUSTNAME,(CMTOTAL-CM_FRT-CM_FRT_TAX-cmmain.TOTTAXE) as CmAmt, CAST (0.00 as numeric(20,2)) as InvAmt,000.00 as [percent],cmmain.CMEMONO as invoiceno
	from	CMMAIN
			inner join CUSTOMER on cmmain.CUSTNO = customer.CUSTNO
	where	cmmain.INVDATE between @lcDateStart and @lcDateEnd
			and cmtype = 'I'
			and left(cmmain.invoiceno,3) <> 'CMR' 
			and IS_CMPOST = 1
		
	union all
	--gather the credit memo's originating from General CreditMemo's not related to any invoice records
	select	cmmain.custno,customer.CUSTNAME,(CMTOTAL-CM_FRT-CM_FRT_TAX-cmmain.TOTTAXE) as CmAmt, CAST (0.00 as numeric (20,2)) as InvAmt, 000.00 as [percent],CMEMONO as invoiceno
	from	CMMAIN	
			inner join CUSTOMER on cmmain.CUSTNO = customer.CUSTNO
	where	cmmain.CMDATE between @lcDateStart and @lcDateEnd
			and CMMAIN.is_cmpost = 1
			and CMTYPE = 'M'

	union all
	--gather the credit memo's originating from Stand Alone RMA's	
	select	cmmain.custno,customer.CUSTNAME,(CMTOTAL-CM_FRT-CM_FRT_TAX-cmmain.TOTTAXE) as CmAmt, CAST (0.00 as numeric (20,2)) as InvAmt, 000.00 as [percent],CMEMONO as invoiceno
	from	CMMAIN	
			inner join CUSTOMER on cmmain.CUSTNO = customer.CUSTNO
	where	cmmain.CMDATE between @lcDateStart and @lcDateEnd
			and CMMAIN.is_cmpost = 1
			and CMTYPE = 'I'	
			and left(cmmain.invoiceno,3) = 'CMR'


	-- Calculate InvAmt and Percent for each customer
	SELECT	Custno, Custname, sum(CmAmt) as CmAmt,SUM(InvAmt) AS InvAmt,case when sum(invAmt) = 0.00 then 0.00 else SUM(CmAmt)/SUM(InvAmt)* 100 end AS [Percent]
	FROM	@ZInvDetl
	GROUP BY Custno, Custname
	ORDER BY case when sum(invAmt) = 0.00 then 0.00 else SUM(CmAmt)/SUM(InvAmt)* 100 end desc
	END
ELSE
	BEGIN
	-- 01/18/17 VL added FC and presentation currency fields
	-- 07/16/18 VL changed custname from char(35) to char(50)
	DECLARE @ZInvDetlFC TABLE (Custno char(10), CustName char(50), CmAmt numeric(20,2),InvAmt numeric(20,2), [Percent] numeric(6,2),InvoiceNo char (10),
						CmAmtFC numeric(20,2),InvAmtFC numeric(20,2), CmAmtPR numeric(20,2),InvAmtPR numeric(20,2), TSymbol char(3), PSymbol char(3), FSymbol char(3))

	INSERT @ZInvDetlFC

	--this will gather the invoice records
	-- 01/18/17 VL:   added functional currency code
	select	plmain.CUSTNO,customer.CUSTNAME,cast(0.00 as numeric(20,2)) as CmAmt,(plmain.INVTOTAL-FREIGHTAMT-plmain.TOTTAXE-TOTTAXF) as InvAmt, 000.00 as [percent],plmain.INVOICENO,
			cast(0.00 as numeric(20,2)) as CmAmtFC,(plmain.INVTOTALFC-FREIGHTAMTFC-plmain.TOTTAXEFC-TOTTAXFFC) as InvAmtFC,
			cast(0.00 as numeric(20,2)) as CmAmtPR,(plmain.INVTOTALPR-FREIGHTAMTPR-plmain.TOTTAXEPR-TOTTAXFPR) as InvAmtPR, 
			TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	from	PLMAIN
			-- 01/18/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON PLMAIN.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON PLMAIN.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON PLMAIN.Fcused_uniq = TF.Fcused_uniq
			inner join customer on plmain.CUSTNO = customer.CUSTNO
	where	plmain.INVDATE between @lcDateStart and @lcDateEnd
			and IS_INVPOST = 1

	union all
	--gathers credit memo records that are associated to invoice records
	select	cmmain.CUSTNO, customer.CUSTNAME,(CMTOTAL-CM_FRT-CM_FRT_TAX-cmmain.TOTTAXE) as CmAmt, CAST (0.00 as numeric(20,2)) as InvAmt,000.00 as [percent],cmmain.CMEMONO as invoiceno,
			(CMTOTALFC-CM_FRTFC-CM_FRT_TAXFC-cmmain.TOTTAXEFC) as CmAmtFC, CAST (0.00 as numeric(20,2)) as InvAmtFC,
			(CMTOTALPR-CM_FRTPR-CM_FRT_TAXPR-cmmain.TOTTAXEPR) as CmAmtPR, CAST (0.00 as numeric(20,2)) as InvAmtPR,
			TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	from	CMMAIN
			-- 01/18/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON CMMAIN.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON CMMAIN.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON CMMAIN.Fcused_uniq = TF.Fcused_uniq
			inner join CUSTOMER on cmmain.CUSTNO = customer.CUSTNO
	where	cmmain.INVDATE between @lcDateStart and @lcDateEnd
			and cmtype = 'I'
			and left(cmmain.invoiceno,3) <> 'CMR' 
			and IS_CMPOST = 1
		
	union all
	--gather the credit memo's originating from General CreditMemo's not related to any invoice records
	select	cmmain.custno,customer.CUSTNAME,(CMTOTAL-CM_FRT-CM_FRT_TAX-cmmain.TOTTAXE) as CmAmt, CAST (0.00 as numeric (20,2)) as InvAmt, 000.00 as [percent],CMEMONO as invoiceno,
			(CMTOTALFC-CM_FRTFC-CM_FRT_TAXFC-cmmain.TOTTAXEFC) as CmAmtFC, CAST (0.00 as numeric(20,2)) as InvAmtFC,
			(CMTOTALPR-CM_FRTPR-CM_FRT_TAXPR-cmmain.TOTTAXEPR) as CmAmtPR, CAST (0.00 as numeric(20,2)) as InvAmtPR,
			TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	from	CMMAIN
			-- 01/18/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON CMMAIN.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON CMMAIN.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON CMMAIN.Fcused_uniq = TF.Fcused_uniq
			inner join CUSTOMER on cmmain.CUSTNO = customer.CUSTNO
	where	cmmain.CMDATE between @lcDateStart and @lcDateEnd
			and CMMAIN.is_cmpost = 1
			and CMTYPE = 'M'

	union all
	--gather the credit memo's originating from Stand Alone RMA's	
	select	cmmain.custno,customer.CUSTNAME,(CMTOTAL-CM_FRT-CM_FRT_TAX-cmmain.TOTTAXE) as CmAmt, CAST (0.00 as numeric (20,2)) as InvAmt, 000.00 as [percent],CMEMONO as invoiceno,
			(CMTOTALFC-CM_FRTFC-CM_FRT_TAXFC-cmmain.TOTTAXEFC) as CmAmtFC, CAST (0.00 as numeric(20,2)) as InvAmtFC,
			(CMTOTALPR-CM_FRTPR-CM_FRT_TAXPR-cmmain.TOTTAXEPR) as CmAmtPR, CAST (0.00 as numeric(20,2)) as InvAmtPR,
			TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	from	CMMAIN
			-- 01/18/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON CMMAIN.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON CMMAIN.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON CMMAIN.Fcused_uniq = TF.Fcused_uniq
			inner join CUSTOMER on cmmain.CUSTNO = customer.CUSTNO
	where	cmmain.CMDATE between @lcDateStart and @lcDateEnd
			and CMMAIN.is_cmpost = 1
			and CMTYPE = 'I'	
			and left(cmmain.invoiceno,3) = 'CMR'


	-- Calculate InvAmt and Percent for each customer
	SELECT	Custno, Custname, sum(CmAmt) as CmAmt,SUM(InvAmt) AS InvAmt,case when sum(invAmt) = 0.00 then 0.00 else SUM(CmAmt)/SUM(InvAmt)* 100 end AS [Percent],
			sum(CmAmtFC) as CmAmtFC,SUM(InvAmtFC) AS InvAmtFC,
			sum(CmAmtPR) as CmAmtPR,SUM(InvAmtPR) AS InvAmtPR,
			TSymbol, PSymbol, FSymbol
	FROM	@ZInvDetlFC
	GROUP BY Custno, Custname, TSymbol, PSymbol, FSymbol
	ORDER BY case when sum(invAmt) = 0.00 then 0.00 else SUM(CmAmt)/SUM(InvAmt)* 100 end desc
	END
end