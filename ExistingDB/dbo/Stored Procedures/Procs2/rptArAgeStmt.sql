-- =============================================
-- Author:		<Debbie>
-- Create date: <10/03/2014>
-- Description:	<Was created and used on ar_stmt>
-- Modified:	01/06/2015 DRP:  Added @customerStatus Filter 
--				10/26/2015 DRP:  Added sono to the results per request from a user to have it display on the Quickview. 
--				03/03/2016 VL:	 Added FC code
--				04/08/2016 VL:	 Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--				06/27/2016 VL:	 Used ACCTSREC.INVTOTALFC-ACCTSREC.ARCREDITSFC <> 0.00 for FC installed, not use both and (ACCTSREC.INVTOTAL-ACCTSREC.ARCREDITS <> 0.00	OR ACCTSREC.INVTOTALFC-ACCTSREC.ARCREDITSFC <> 0.00)
--				06/30/2016 VL:	 added one more parameter to calculate with original rate or latest rate, and used 0 as default, Linda from Penang said this report should always use original rate
--				07/01/2016 DRP:  Added RateUsed to the results so we can display which rate is being used for a FC system.  if FC is not being used the RateUsed field will remain blank. 
--				08/11/16 DRP:   added Address3 and Address4 to the BillToAddress field
--				01/11/17   VL:	 added one more parameter for fn_CalculateFCRateVariance() which is the rate ratio calculated based on functional currency or presentation currency
--				01/13/17   VL:	 Added functional currency fields
-- 01/16/2020 YS added new column to plmain table pono for the manual invoice w/o sales order. Need to identify the table in the sql
-- 03/31/2020 YS changed link from customer to shipbill. The default value is not saved in the customer.blinkadd and slinkadd anymore
-- =============================================
CREATE PROCEDURE [dbo].[rptArAgeStmt]

--declare	
@lcCustNo varchar(max) = 'All'
,@lcSort char(15) = 'Due Date'	--Invoice Number or Due Date
,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
,@userId uniqueidentifier = null
-- 06/30/16 VL added one more parameter to calculate with original rate or latest rate, and used 0 as default, Linda from Penang said this report should always use original rate
,@lLatestRate bit = 0 -- Penang always use latest rate to show

as
Begin

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


-- 03/02/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0
	BEGIN
	if (@lcSort = 'Invoice Number')
		Begin
		-- 01/16/2020 YS added new column to plmain table pono for the manual invoice w/o sales order. Need to identify the table in the sql
			select	customer.CUSTNAME,rtrim(ACCTSREC.INVNO)as invno,ACCTSREC.INVDATE,ACCTSREC.DUE_DATE,isnull(somain.PONO,plmain.pono) as PONO,ACCTSREC.INVTOTAL,ACCTSREC.INVTOTAL-ACCTSREC.ARCREDITS as BalAmt,customer.TERMS
					,isnull(somain.sono,'') as sono	--10/16/15 DRP:  Added  
					,rtrim(SHIPBILL.Address1)+case when SHIPBILL.address2<> '' then char(13)+char(10)+rtrim(SHIPBILL.address2) else '' end+
					case when SHIPBILL.address3<> '' then char(13)+char(10)+rtrim(SHIPBILL.address3) else '' end+
					case when SHIPBILL.address4<> '' then char(13)+char(10)+rtrim(SHIPBILL.address4) else '' end+
					CASE WHEN SHIPBILL.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(SHIPBILL.City)+',  '+rtrim(SHIPBILL.State)+'      '+RTRIM(SHIPBILL.zip)  ELSE '' END +
					CASE WHEN SHIPBILL.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(SHIPBILL.Country) ELSE '' end+
					case when SHIPBILL.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(SHIPBILL.PHONE) else '' end+
					case when SHIPBILL.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(SHIPBILL.FAX) else '' end  as BillToAddress
					,cast ('' as char(30)) as RateUsed	--07/01/2016 DRP:  Added

			from	ACCTSREC
					left outer join PLMAIN on ACCTSREC.CUSTNO = plmain.CUSTNO and ACCTSREC.INVNO = plmain.INVOICENO
					left outer join SOMAIN on plmain.SONO = somain.sono
					inner join CUSTOMER on ACCTSREC.CUSTNO = customer.CUSTNO
					-- 03/31/2020 YS changed link from customer to shipbill. The default value is not saved in the customer.blinkadd and slinkadd anymore
					--inner join SHIPBILL on CUSTOMER.BLINKADD = SHIPBILL.LINKADD
					inner join SHIPBILL on CUSTOMER.custno = SHIPBILL.custno and shipbill.RECORDTYPE='B' and SHIPBILL.IsDefaultAddress=1

			where	1 = case when Customer.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
					and ACCTSREC.INVTOTAL-ACCTSREC.ARCREDITS <> 0.00
					and SHIPBILL.RECORDTYPE = 'B'
				order by Custname,invno
		end
	else if (@lcSort = 'Due Date')
		Begin
		-- 01/16/2020 YS added new column to plmain table pono for the manual invoice w/o sales order. Need to identify the table in the sql
			select	customer.CUSTNAME,rtrim(ACCTSREC.INVNO)as invno,ACCTSREC.INVDATE,ACCTSREC.DUE_DATE,isnull(somain.PONO,plmain.pono) as PONO,ACCTSREC.INVTOTAL,ACCTSREC.INVTOTAL-ACCTSREC.ARCREDITS as BalAmt,customer.TERMS
					,isnull(somain.sono,'') as sono	--10/16/15 DRP:  Added  
					,rtrim(SHIPBILL.Address1)+case when SHIPBILL.address2<> '' then char(13)+char(10)+rtrim(SHIPBILL.address2) else '' end+
						case when SHIPBILL.address3<> '' then char(13)+char(10)+rtrim(SHIPBILL.address3) else '' end+
						case when SHIPBILL.address4<> '' then char(13)+char(10)+rtrim(SHIPBILL.address4) else '' end+
						CASE WHEN SHIPBILL.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(SHIPBILL.City)+',  '+rtrim(SHIPBILL.State)+'      '+RTRIM(SHIPBILL.zip)  ELSE '' END +
						CASE WHEN SHIPBILL.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(SHIPBILL.Country) ELSE '' end+
						case when SHIPBILL.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(SHIPBILL.PHONE) else '' end+
						case when SHIPBILL.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(SHIPBILL.FAX) else '' end  as BillToAddress
						,cast ('' as char(30)) as RateUsed	--07/01/2016 DRP:  Added

			from	ACCTSREC
					left outer join PLMAIN on ACCTSREC.CUSTNO = plmain.CUSTNO and ACCTSREC.INVNO = plmain.INVOICENO
					left outer join SOMAIN on plmain.SONO = somain.sono
					inner join CUSTOMER on ACCTSREC.CUSTNO = customer.CUSTNO
					-- 03/31/2020 YS changed link from customer to shipbill. The default value is not saved in the customer.blinkadd and slinkadd anymore
					--inner join SHIPBILL on CUSTOMER.BLINKADD = SHIPBILL.LINKADD
					inner join SHIPBILL on CUSTOMER.custno = SHIPBILL.custno and shipbill.RECORDTYPE='B' and SHIPBILL.IsDefaultAddress=1

			where	1 = case when Customer.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
					and ACCTSREC.INVTOTAL-ACCTSREC.ARCREDITS <> 0.00
					and SHIPBILL.RECORDTYPE = 'B'
			order by CUSTNAME,DUE_DATE
		End 
	END
ELSE
-- FC instlled
	BEGIN
	if (@lcSort = 'Invoice Number')
		Begin
			-- 03/03/16 VL update Invtotal, BalAmt with latest rate, and also add IntTotalFC and BalAmtFC
			-- 01/16/2020 YS added new column to plmain table pono for the manual invoice w/o sales order. Need to identify the table in the sql
			select	customer.CUSTNAME,rtrim(ACCTSREC.INVNO)as invno,ACCTSREC.INVDATE,ACCTSREC.DUE_DATE,isnull(somain.PONO,plmain.pono) as PONO
					--,ACCTSREC.INVTOTAL,ACCTSREC.INVTOTAL-ACCTSREC.ARCREDITS as BalAmt
					-- 06/30/16 VL used @lLatestRate to control showing original rate or latest rate
					--,CAST(ACCTSREC.INVTOTAL*dbo.fn_CalculateFCRateVariance(ACCTSREC.Fchist_key) as numeric(20,2)) AS InvTotal
					--,CAST((ACCTSREC.INVTOTAL-ACCTSREC.ARCREDITS)*dbo.fn_CalculateFCRateVariance(ACCTSREC.Fchist_key) as numeric(20,2)) AS BalAmt
					,CASE WHEN @lLatestRate = 0 THEN CAST(Acctsrec.InvTotal AS numeric(20,2)) ELSE
						CAST(ACCTSREC.INVTOTAL*dbo.fn_CalculateFCRateVariance(ACCTSREC.Fchist_key,'F') as numeric(20,2)) END AS InvTotal
					,CASE WHEN @lLatestRate = 0 THEN CAST(Acctsrec.Invtotal-Acctsrec.Arcredits AS numeric(20,2)) ELSE
						CAST((ACCTSREC.INVTOTAL-ACCTSREC.ARCREDITS)*dbo.fn_CalculateFCRateVariance(ACCTSREC.Fchist_key,'F') as numeric(20,2)) END AS BalAmt
					,customer.TERMS
					,isnull(somain.sono,'') as sono	--10/16/15 DRP:  Added  
					,rtrim(SHIPBILL.Address1)+case when SHIPBILL.address2<> '' then char(13)+char(10)+rtrim(SHIPBILL.address2) else '' end+
					case when SHIPBILL.address3<> '' then char(13)+char(10)+rtrim(SHIPBILL.address3) else '' end+
					case when SHIPBILL.address4<> '' then char(13)+char(10)+rtrim(SHIPBILL.address4) else '' end+
					CASE WHEN SHIPBILL.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(SHIPBILL.City)+',  '+rtrim(SHIPBILL.State)+'      '+RTRIM(SHIPBILL.zip)  ELSE '' END +
					CASE WHEN SHIPBILL.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(SHIPBILL.Country) ELSE '' end+
					case when SHIPBILL.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(SHIPBILL.PHONE) else '' end+
					case when SHIPBILL.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(SHIPBILL.FAX) else '' end  as BillToAddress
					,ACCTSREC.INVTOTALFC,ACCTSREC.INVTOTALFC-ACCTSREC.ARCREDITSFC as BalAmtFC
					-- 01/13/17 VL added functional currency fields
					,CASE WHEN @lLatestRate = 0 THEN CAST(Acctsrec.InvTotalPR AS numeric(20,2)) ELSE
						CAST(ACCTSREC.INVTOTALPR*dbo.fn_CalculateFCRateVariance(ACCTSREC.Fchist_key,'P') as numeric(20,2)) END AS InvTotalPR
					,CASE WHEN @lLatestRate = 0 THEN CAST(Acctsrec.InvtotalPR-Acctsrec.ArcreditsPR AS numeric(20,2)) ELSE
						CAST((ACCTSREC.INVTOTALPR-ACCTSREC.ARCREDITSPR)*dbo.fn_CalculateFCRateVariance(ACCTSREC.Fchist_key,'P') as numeric(20,2)) END AS BalAmtPR
					--, Fcused.Symbol AS Currency
					,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
					,case when @lLatestRate = 1 then cast ('Using Latest Exchange Rate' as char (30)) else cast ('Using Original Exchange Rate' as char (30)) end as RateUsed	--07/01/2016 DRP:  Added
			from ACCTSREC
				-- 01/13/17 VL changed criteria to get 3 currencies
				INNER JOIN Fcused PF ON ACCTSREC.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON ACCTSREC.FuncFcused_uniq = FF.Fcused_uniq			
				INNER JOIN Fcused TF ON ACCTSREC.Fcused_uniq = TF.Fcused_uniq						
					left outer join PLMAIN on ACCTSREC.CUSTNO = plmain.CUSTNO and ACCTSREC.INVNO = plmain.INVOICENO
					left outer join SOMAIN on plmain.SONO = somain.sono
					inner join CUSTOMER on ACCTSREC.CUSTNO = customer.CUSTNO
					-- 03/31/2020 YS changed link from customer to shipbill. The default value is not saved in the customer.blinkadd and slinkadd anymore
					--inner join SHIPBILL on CUSTOMER.BLINKADD = SHIPBILL.LINKADD
					inner join SHIPBILL on CUSTOMER.custno = SHIPBILL.custno and shipbill.RECORDTYPE='B' and SHIPBILL.IsDefaultAddress=1

			where	1 = case when Customer.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
					and ACCTSREC.INVTOTALFC-ACCTSREC.ARCREDITSFC <> 0.00
					and SHIPBILL.RECORDTYPE = 'B'
				order by TSymbol,Custname,invno
		end
	else if (@lcSort = 'Due Date')
		Begin
			-- 03/03/16 VL update Invtotal, BalAmt with latest rate, and also add IntTotalFC and BalAmtFC
			-- 01/16/2020 YS added new column to plmain table pono for the manual invoice w/o sales order. Need to identify the table in the sql
			select	customer.CUSTNAME,rtrim(ACCTSREC.INVNO)as invno,ACCTSREC.INVDATE,ACCTSREC.DUE_DATE,isnull(somain.PONO,plmain.pono) as PONO
					--,ACCTSREC.INVTOTAL,ACCTSREC.INVTOTAL-ACCTSREC.ARCREDITS as BalAmt
					-- 06/30/16 VL used @lLatestRate to control showing original rate or latest rate
					--,CAST(ACCTSREC.INVTOTAL*dbo.fn_CalculateFCRateVariance(ACCTSREC.Fchist_key) as numeric(20,2)) AS InvTotal
					--,CAST((ACCTSREC.INVTOTAL-ACCTSREC.ARCREDITS)*dbo.fn_CalculateFCRateVariance(ACCTSREC.Fchist_key) as numeric(20,2)) AS BalAmt
					,CASE WHEN @lLatestRate = 0 THEN CAST(Acctsrec.InvTotal AS numeric(20,2)) ELSE
						CAST(ACCTSREC.INVTOTAL*dbo.fn_CalculateFCRateVariance(ACCTSREC.Fchist_key,'F') as numeric(20,2)) END AS InvTotal
					,CASE WHEN @lLatestRate = 0 THEN CAST(Acctsrec.Invtotal-Acctsrec.Arcredits AS numeric(20,2)) ELSE
						CAST((ACCTSREC.INVTOTAL-ACCTSREC.ARCREDITS)*dbo.fn_CalculateFCRateVariance(ACCTSREC.Fchist_key,'F') as numeric(20,2)) END AS BalAmt
					,customer.TERMS
					,isnull(somain.sono,'') as sono	--10/16/15 DRP:  Added  
					,rtrim(SHIPBILL.Address1)+case when SHIPBILL.address2<> '' then char(13)+char(10)+rtrim(SHIPBILL.address2) else '' end+
					case when SHIPBILL.address3<> '' then char(13)+char(10)+rtrim(SHIPBILL.address3) else '' end+
					case when SHIPBILL.address4<> '' then char(13)+char(10)+rtrim(SHIPBILL.address4) else '' end+
						CASE WHEN SHIPBILL.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(SHIPBILL.City)+',  '+rtrim(SHIPBILL.State)+'      '+RTRIM(SHIPBILL.zip)  ELSE '' END +
						CASE WHEN SHIPBILL.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(SHIPBILL.Country) ELSE '' end+
						case when SHIPBILL.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(SHIPBILL.PHONE) else '' end+
						case when SHIPBILL.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(SHIPBILL.FAX) else '' end  as BillToAddress
					,ACCTSREC.INVTOTALFC,ACCTSREC.INVTOTALFC-ACCTSREC.ARCREDITSFC as BalAmtFC
					-- 01/13/17 VL added functional currency fields
					,CASE WHEN @lLatestRate = 0 THEN CAST(Acctsrec.InvTotalPR AS numeric(20,2)) ELSE
						CAST(ACCTSREC.INVTOTALPR*dbo.fn_CalculateFCRateVariance(ACCTSREC.Fchist_key,'P') as numeric(20,2)) END AS InvTotalPR
					,CASE WHEN @lLatestRate = 0 THEN CAST(Acctsrec.InvtotalPR-Acctsrec.ArcreditsPR AS numeric(20,2)) ELSE
						CAST((ACCTSREC.INVTOTALPR-ACCTSREC.ARCREDITSPR)*dbo.fn_CalculateFCRateVariance(ACCTSREC.Fchist_key,'P') as numeric(20,2)) END AS BalAmtPR
					--, Fcused.Symbol AS Currency
					,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
					,case when @lLatestRate = 1 then cast ('Using Latest Exchange Rate' as char (30)) else cast ('Using Original Exchange Rate' as char (30)) end as RateUsed	--07/01/2016 DRP:  Added
			from ACCTSREC
				-- 01/13/17 VL changed criteria to get 3 currencies
				INNER JOIN Fcused PF ON ACCTSREC.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON ACCTSREC.FuncFcused_uniq = FF.Fcused_uniq			
				INNER JOIN Fcused TF ON ACCTSREC.Fcused_uniq = TF.Fcused_uniq						
					left outer join PLMAIN on ACCTSREC.CUSTNO = plmain.CUSTNO and ACCTSREC.INVNO = plmain.INVOICENO
					left outer join SOMAIN on plmain.SONO = somain.sono
					inner join CUSTOMER on ACCTSREC.CUSTNO = customer.CUSTNO
					-- 03/31/2020 YS changed link from customer to shipbill. The default value is not saved in the customer.blinkadd and slinkadd anymore
					--inner join SHIPBILL on CUSTOMER.BLINKADD = SHIPBILL.LINKADD
					inner join SHIPBILL on CUSTOMER.custno = SHIPBILL.custno and shipbill.RECORDTYPE='B' and SHIPBILL.IsDefaultAddress=1

			where	1 = case when Customer.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
					and ACCTSREC.INVTOTALFC-ACCTSREC.ARCREDITSFC <> 0.00
					and SHIPBILL.RECORDTYPE = 'B'
			order by TSymbol,CUSTNAME,DUE_DATE
		End 
	END
END-- if FC installed
end	