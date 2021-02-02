-- =============================================
-- Author:		<Debbie>
-- Create date: <10/09/2014>
-- Description:	Used on AR_REP10 or AR_REP11   "AR Tax Distribution Detail By Customer" or "AR Tax Distribution Summary by Customer"  
-- Modified:	10/09/2014 DRP:  Only created for QuickView at this time.
--				01/06/2015 DRP:  Added @customerStatus Filter 
--				01/17/2017	VL:	 Added FC and functional currency code
-- 11/02/17 VL added Tax_AmtFC and Tax_AmtPR
-- =============================================
CREATE PROCEDURE [dbo].[rptArAgeTaxDistr]

--declare 
@lcDateStart as smalldatetime = NULL
,@lcDateEnd as smalldatetime = NULL
,@lcRptType as char(10) = 'Detailed'		--Detailed or Summary
,@userId uniqueidentifier = null


as
Begin
/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	
					INSERT INTO @Customer SELECT CustNo FROM @tCustomer
		


/*SELECT STATEMENT*/

-- 01/17/17 VL added code to separate non FC and FC 
BEGIN
IF dbo.fn_IsFCInstalled() = 0
	BEGIN
	if(@lcRptType = 'Detailed')
		Begin --&&  Detailed Begin
			; with zInv as (
				select	CUSTOMER.CUSTNAME,plmain.INVOICENO,CAST (INVDATE AS DATE) AS InvDate,plmain.INVTOTAL,plmain.PACKLISTNO
				from	PLMAIN
						INNER JOIN CUSTOMER ON PLMAIN.CUSTNO = CUSTOMER.CUSTNO
				where	datediff(day,plmain.INVDATE,@lcDateStart)<=0 and datediff(day,plmain.INVDATE,@lcDateEnd)>=0
						and PLMAIN.TOTTAXE <> 0.00	
						and 1 = case when plmain.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end	
				)

			,
				zInvTax as
				(
				select	PACKLISTNO,INVSTDTX.TAX_ID,INVSTDTX.TAXDESC,sum(INVSTDTX.TAX_AMT) as TAX_AMT
				from	INVSTDTX
				where	INVOICENO = ''
				group by PACKLISTNO,INVSTDTX.TAX_ID,INVSTDTX.TAXDESC
				)

	
			SELECT	CUSTNAME,INVOICENO,InvDate,CASE WHEN ROW_NUMBER() OVER(Partition by custname,zinv.invoiceno Order by zinv.invoiceno)=1 Then Zinv.INVTOTAL ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotal
					,TAX_ID,TAXDESC,TAX_AMT
			FROM	zInv 
					INNER JOIN zInvTax  ON zInv.PACKLISTNO = zInvTax.PACKLISTNO
		
		End	--&& Detailed End
	
	else if(@lcRptType = 'Summary')
		Begin
			select	customer.CUSTNAME,TAX_ID,TAXDESC,sum(TAX_AMT) as TAX_AMT
			from	PLMAIN
					inner join INVSTDTX on plmain.PACKLISTNO = INVSTDTX.PACKLISTNO
					INNER JOIN CUSTOMER ON PLMAIN.CUSTNO = CUSTOMER.CUSTNO
			where	datediff(day,plmain.INVDATE,@lcDateStart)<=0 and datediff(day,plmain.INVDATE,@lcDateEnd)>=0
					and PLMAIN.TOTTAXE <> 0.00
					and invstdtx.INVOICENO = ''
			GROUP BY CUSTNAME,TAX_ID,TAXDESC
		
		End
	END
ELSE
	BEGIN
	if(@lcRptType = 'Detailed')
		Begin --&&  Detailed Begin
			; with zInv as (
				select	CUSTOMER.CUSTNAME,plmain.INVOICENO,CAST (INVDATE AS DATE) AS InvDate,plmain.INVTOTAL,plmain.PACKLISTNO,
						-- 01/17/17 VL added functional currency fields
						plmain.INVTOTALFC, plmain.INVTOTALPR, TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
				from	PLMAIN
						-- 01/17/17 VL changed criteria to get 3 currencies
						INNER JOIN Fcused PF ON PLMAIN.PrFcused_uniq = PF.Fcused_uniq
						INNER JOIN Fcused FF ON PLMAIN.FuncFcused_uniq = FF.Fcused_uniq			
						INNER JOIN Fcused TF ON PLMAIN.Fcused_uniq = TF.Fcused_uniq
						INNER JOIN CUSTOMER ON PLMAIN.CUSTNO = CUSTOMER.CUSTNO
				where	datediff(day,plmain.INVDATE,@lcDateStart)<=0 and datediff(day,plmain.INVDATE,@lcDateEnd)>=0
						and PLMAIN.TOTTAXE <> 0.00	
						and 1 = case when plmain.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end	
				)

			,
				zInvTax as
				(
				-- 01/17/17 VL added functional currency fields
				select	PACKLISTNO,INVSTDTX.TAX_ID,INVSTDTX.TAXDESC,sum(INVSTDTX.TAX_AMT) as TAX_AMT,sum(INVSTDTX.TAX_AMTFC) as TAX_AMTFC,sum(INVSTDTX.TAX_AMTPR) as TAX_AMTPR
				from	INVSTDTX
				where	INVOICENO = ''
				group by PACKLISTNO,INVSTDTX.TAX_ID,INVSTDTX.TAXDESC
				)

	
			SELECT	CUSTNAME,INVOICENO,InvDate,CASE WHEN ROW_NUMBER() OVER(Partition by custname,zinv.invoiceno Order by zinv.invoiceno)=1 Then Zinv.INVTOTAL ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotal,
					-- 01/17/17 VL added functional currency fields
					CASE WHEN ROW_NUMBER() OVER(Partition by custname,zinv.invoiceno Order by zinv.invoiceno)=1 Then Zinv.INVTOTALFC ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotalFC,
					CASE WHEN ROW_NUMBER() OVER(Partition by custname,zinv.invoiceno Order by zinv.invoiceno)=1 Then Zinv.INVTOTALPR ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotalPR,
					TSymbol, PSymbol, FSymbol	
					,TAX_ID,TAXDESC,TAX_AMT
					-- 11/02/17 VL added Tax_AmtFC and Tax_AmtPR
					,Tax_AmtFC, Tax_AmtPR
			FROM	zInv 
					INNER JOIN zInvTax  ON zInv.PACKLISTNO = zInvTax.PACKLISTNO
		
		End	--&& Detailed End
	
	else if(@lcRptType = 'Summary')
		Begin
			select	customer.CUSTNAME,TAX_ID,TAXDESC,sum(TAX_AMT) as TAX_AMT,
					-- 01/17/17 VL added functional currency fields
					sum(TAX_AMTFC) as TAX_AMTFC,sum(TAX_AMTPR) as TAX_AMTPR, TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
			from	PLMAIN
					-- 01/17/17 VL changed criteria to get 3 currencies
					INNER JOIN Fcused PF ON PLMAIN.PrFcused_uniq = PF.Fcused_uniq
					INNER JOIN Fcused FF ON PLMAIN.FuncFcused_uniq = FF.Fcused_uniq			
					INNER JOIN Fcused TF ON PLMAIN.Fcused_uniq = TF.Fcused_uniq
					inner join INVSTDTX on plmain.PACKLISTNO = INVSTDTX.PACKLISTNO
					INNER JOIN CUSTOMER ON PLMAIN.CUSTNO = CUSTOMER.CUSTNO
			where	datediff(day,plmain.INVDATE,@lcDateStart)<=0 and datediff(day,plmain.INVDATE,@lcDateEnd)>=0
					and PLMAIN.TOTTAXE <> 0.00
					and invstdtx.INVOICENO = ''
			GROUP BY CUSTNAME,TAX_ID,TAXDESC, TF.Symbol, PF.Symbol, FF.Symbol
		
		End
	END
END
	
END