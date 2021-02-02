

-- =============================================
-- Author:		Debbie
-- Create date: 02/23/2012
-- Description:	This Stored Procedure was created for the Invoice Report Summary
-- Reports Using Stored Procedure:  inv_rep2.rpt
-- Modified:	01/15/2014 DRP:  added the @userid parameter for WebManex
--				10/30/15 DRP:	Added the /*CUSTOMER LIST*/, changed @lcCust to be @lcCustNo to work with the Web Parameters that already exist.  also changed the Date Range filter.  
--				02/17/2016 VL:	Added FC code
--				03/22/16 DRP:  used the same procedure for the inv_rep2 and inv_rep6 report.  Added the @lcSort parameter.  The by Customer section is basically the original code.. Added the by Date section where it sums on the invtotal and calculates the runningBal	
--				03/22/16 VL:   Added FC fields and changed to use @detailFC temp table
--				04/08/16 VL:   Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--				04/22/2016 DRP:  added Fcused.Symbol AS TCurrency, @FCurrency AS FCurrency
--								 in the Foreign Currency By Date section I needed to change the running balance to point to the @DetailedFC instead of the @Detailed.  also needed to rename the From @DetailFC b to be @DetailFC c otherwise it was not calculating the correct running balance 
--				01/18/2017 VL:   Added functional currency code
-- 09/05/17 VL added invoiceno for order by Date
-- 07/16/18 VL changed custname from char(35) to char(50)
-- =============================================
CREATE PROCEDURE [dbo].[rptInvoiceSummary]
--declare
		@lcDateStart as smalldatetime= null
		,@lcDateEnd as smalldatetime = null
		,@lcCustNo as varchar (Max) = 'All'
		,@lcSort as char(15) = 'by Date'	--by Customer or by Date
		,@userId uniqueidentifier=null
		
AS 
BEGIN


/*CUSTOMER LIST*/		--10/30/15 DRP:  Added
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	
		
		IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)
		ELSE

		IF  @lcCustNo='All'	
		BEGIN
			INSERT INTO @Customer SELECT CustNo FROM @tCustomer
		END

-- 09/05/17 VL added Invoiceno
-- 07/16/18 VL changed custname from char(35) to char(50)
declare @detail as table (INVDATE date,custno char(10),custname char(50),INVTOTAL numeric(15,2),invoiceno char(10), id int not null identity(1,1) primary key)

-- 03/22/16 VL added Currency field
-- 01/18/17 VL added functional currency fields and changed TCurrency to 3 currency symbols
-- 09/05/17 VL added Invoiceno
-- 07/16/18 VL changed custname from char(35) to char(50)
declare @detailFC as table (INVDATE date,custno char(10),custname char(50),INVTOTAL numeric(15,2),INVTOTALFC numeric(15,2), INVTOTALPR numeric(15,2), TSymbol char(3), PSymbol char(3), FSymbol char(3), Invoiceno char(10), id int not null identity(1,1) primary key)

/*RECORD SELECTION*/

-- 02/17/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0
	BEGIN
		if @lcSort = 'by Customer'
			BEGIN	--by Customer Beginning
				select	plmain.custno,custname,INVOICENO,INVDATE,SONO,PACKLISTNO,totexten,freightamt,dsctamt,SUM(TOTTAXE + TOTTAXF) as Taxes,INVTOTAL,cast (0.00 as numeric (17,7)) as RunningBal
				from	PLMAIN
						inner join CUSTOMER on plmain.CUSTNO = customer.CUSTNO
		
				WHERE	--INVDATE >=@lcDateStart AND INVDATE<@lcDateEnd+1	--10/30/15 DRP:  REPLACED WITH THE BELOW
						DATEDIFF(Day,INVDATE,@lcDateStart)<=0 AND DATEDIFF(Day,INVDATE,@lcDateEnd)>=0
						--and CUSTNAME like case when @lcCust ='*' then '%' else @lcCust+'%' end	--10/30/15 DRP:  replaced by the below
						and (@lcCustNo='All' OR exists (select 1 from @Customer t inner join customer c on t.custno=c.custno where c.custno=plmain.custno))
		
				group by plmain.CUSTNO,custname,INVOICENO,INVDATE,SONO,PACKLISTNO,totexten,freightamt,dsctamt,INVTOTAL
			END -- by Customer End

		else 

		if @lcSort = 'by Date'
			BEGIN  --by Date Beginning
				-- 09/05/17 VL added Invoiceno and order by custname, invoiceno
				INSERT INTO @detail
				select	INVDATE,plmain.custno,custname,SUM(INVTOTAL) INVTOTAL, Invoiceno
				from	PLMAIN
						inner join CUSTOMER on plmain.CUSTNO = customer.CUSTNO
				WHERE	DATEDIFF(Day,INVDATE,@lcDateStart)<=0 AND DATEDIFF(Day,INVDATE,@lcDateEnd)>=0
						and (@lcCustNo='All' OR exists (select 1 from @Customer t inner join customer c on t.custno=c.custno where c.custno=plmain.custno))
				group by INVDATE,plmain.CUSTNO,custname, Invoiceno
				order by invdate, custname, invoiceno

					select	a.invdate,a.custno,a.custname, a.INVTOTAL, (SELECT SUM(b.INVTOTAL)FROM @Detail b WHERE b.id <= a.id) as RunningBal
					FROM   @Detail a inner join @Detail D on a.id = D.id
					ORDER BY a.id
			END -- by Date End
	END  --FC not installed End

ELSE
--  FC installed
	BEGIN  -- Begin FC installed

	-- 01/18/17 VL comment out the code, will get 3 currencies in SQL statement
	--DECLARE @FCurrency char(3) = ''
	--	-- 04/22/16 DRP changed to get HC fcused_uniq from function
	--	SELECT @FCurrency = Symbol FROM Fcused WHERE Fcused.Fcused_uniq = dbo.fn_GetHomeCurrency()

		if @lcSort = 'by Customer'
			BEGIN	--by Customer Beginning
				select	plmain.custno,custname,INVOICENO,INVDATE,SONO,PACKLISTNO,totexten,freightamt,dsctamt,SUM(TOTTAXE + TOTTAXF) as Taxes,INVTOTAL
						,totextenFC,freightamtFC,dsctamtFC,SUM(TOTTAXEFC+ TOTTAXFFC) as TaxesFC,INVTOTALFC, Plmain.Fcused_uniq
						-- 01/18/17 VL changed to get presentation currency fields and 3 currency symbols
						--, Fcused.Symbol AS Currency	--04/22/2016 dRP:  replaced with below
						--,Fcused.Symbol AS TCurrency
						--,@FCurrency as FCurrency
						,totextenPR,freightamtPR,dsctamtPR,SUM(TOTTAXEPR+ TOTTAXFPR) as TaxesPR,INVTOTALPR
						,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
				from	PLMAIN 
						-- 01/18/17 VL changed criteria to get 3 currencies
						INNER JOIN Fcused PF ON plmain.PrFcused_uniq = PF.Fcused_uniq
						INNER JOIN Fcused FF ON plmain.FuncFcused_uniq = FF.Fcused_uniq			
						INNER JOIN Fcused TF ON plmain.Fcused_uniq = TF.Fcused_uniq
						inner join CUSTOMER on plmain.CUSTNO = customer.CUSTNO
				WHERE	--INVDATE >=@lcDateStart AND INVDATE<@lcDateEnd+1	--10/30/15 DRP:  REPLACED WITH THE BELOW
						DATEDIFF(Day,INVDATE,@lcDateStart)<=0 AND DATEDIFF(Day,INVDATE,@lcDateEnd)>=0
						--and CUSTNAME like case when @lcCust ='*' then '%' else @lcCust+'%' end	--10/30/15 DRP:  replaced by the below
						and (@lcCustNo='All' OR exists (select 1 from @Customer t inner join customer c on t.custno=c.custno where c.custno=plmain.custno))
				group by plmain.CUSTNO,custname,INVOICENO,INVDATE,SONO,PACKLISTNO,totexten,freightamt,dsctamt,INVTOTAL
						,totextenFC,freightamtFC,dsctamtFC,INVTOTALFC, Plmain.Fcused_uniq --fcused.Symbol
						,totextenPR,freightamtPR,dsctamtPR,INVTOTALPR,TF.Symbol, PF.Symbol, FF.Symbol
				ORDER BY TSymbol, Custname, invoiceno
			END -- by Customer End

		else 

		if @lcSort = 'by Date'
			BEGIN  --by Date Beginning
				-- 03/22/16 VL added Currency field
				-- 01/18/17 VL added functional currency fields
				-- 09/05/17 VL added Invoiceno and order by invoiceno
				INSERT INTO @detailFC
				select	INVDATE,plmain.custno,custname,SUM(INVTOTAL) INVTOTAL,SUM(INVTOTALFC) INVTOTALFC
						--, Fcused.Symbol AS Currency	--04/22/2016 DRP:  replaced with below
						-- 01/18/17 VL changed to use 3 currency symbols
						--,Fcused.Symbol AS TCurrency
						,SUM(INVTOTALPR) INVTOTALPR
						,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol, Invoiceno
				from	PLMAIN
						-- 01/18/17 VL changed criteria to get 3 currencies
						INNER JOIN Fcused PF ON plmain.PrFcused_uniq = PF.Fcused_uniq
						INNER JOIN Fcused FF ON plmain.FuncFcused_uniq = FF.Fcused_uniq			
						INNER JOIN Fcused TF ON plmain.Fcused_uniq = TF.Fcused_uniq
						inner join CUSTOMER on plmain.CUSTNO = customer.CUSTNO
				WHERE	DATEDIFF(Day,INVDATE,@lcDateStart)<=0 AND DATEDIFF(Day,INVDATE,@lcDateEnd)>=0
						and (@lcCustNo='All' OR exists (select 1 from @Customer t inner join customer c on t.custno=c.custno where c.custno=plmain.custno))
				group by TF.Symbol, PF.Symbol, FF.Symbol, INVDATE,custname,plmain.CUSTNO, plmain.invoiceno
				-- 09/05/17 VL changed the order by to remove TSymbol, because transaction report doesn't need to have running total, so use invdate as first, and report form will use TSymbol to group
				--ORDER BY TSymbol, INVDATE,Custname, invoiceno	--04/22/2016 DRP:  needed to add the Custname to the sort order
				ORDER BY CONVERT(DATE,INVDATE),Custname, invoiceno	--04/22/2016 DRP:  needed to add the Custname to the sort order
				--select * from @detailFC

					-- 03/22/16 VL added InvtotalFC, RunningBalFC and Currency fields
					select	a.invdate,a.custno,a.custname, a.INVTOTAL, (SELECT SUM(c.INVTOTAL)FROM @DetailFC c WHERE c.id <= a.id) as RunningBal	--04/22/2016 DRP:  changed it from @Detail to @DetailFC also needed to rename the From @DetailFC b to be @DetailFC c otherwise it was not calculating the correct running balance 
						,a.INVTOTALFC, (SELECT SUM(b.INVTOTALFC)FROM @DetailFC b WHERE b.id <= a.id) as RunningBalFC
						,a.INVTOTALPR, (SELECT SUM(b.INVTOTALPR)FROM @DetailFC b WHERE b.id <= a.id) as RunningBalPR,
						-- 01/18/17 VL changed currency symbols
						--a.TCurrency,@FCurrency as FCurrency
						a.TSymbol, a.PSymbol, a.FSymbol, a.Invoiceno
					FROM   @DetailFC a inner join @DetailFC D on a.id = D.id
					ORDER BY a.id

			END -- by Date End
		END

	END--End of IF FC installed


END