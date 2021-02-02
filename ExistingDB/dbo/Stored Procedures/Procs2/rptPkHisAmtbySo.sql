


-- =============================================
-- Author:		<Debbie>
-- Create date: <11/10/2010>
-- Description:	<compiles detailed Packing List information with $ Amount>
-- Reports:     <used on pkhisamt.rpt, pkhis_pk.rpt, pkhis_p.rpt, pkhis_so >
-- Modified:	04/16/2012 DRP: found that if there was a large number of misc items added to the packing list that exceeded 10 that it would then begin not sorting them as desired. 
-- 01/15/2014 DRP:  added the @userid parameter for WebManex
-- 01/28/2015 DRP:  added the followig fields to the results as requested (TOTEXTEN,TOTTAXE,FREIGHTAMT,TOTTAXF)
-- 02/15/2016 VL:	 added FC code
-- 04/08/2016 VL:   Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 01/19/2017 VL:   Added functional currency code
-- 07/19/17 DRP:  needed to add the /*CUSTOMER LIST*/ in order to make sure only records the users are approved to see are displayed.
-- 07/26/19 VL added salestypeid, request by Paramit #5542
-- =============================================
CREATE PROCEDURE [dbo].[rptPkHisAmtbySo] 

--06/09/2011 ~ Deb: added the Sales Order Parameter to speed the response time on larger datasets 
--06/09/2011 ~ Deb:	Also had to make the Stored Procedure more unique to each report because of these parameters.  
--					I used to have pkhisamt.rpt, pkhis_pk.rpt, pkhis_p.rpt and pkhis_so.rpt also using this SP, but now they will more than likely have to have their own.
		@lcSoNo char(10) = ''
		,@userId uniqueidentifier=null
		
AS
BEGIN

/*CUSTOMER LIST*/		--07/19/17 DRP:  added	
	DECLARE  @tCustomer as tCustomer
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustome

-- 02/15/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()


BEGIN
IF @lFCInstalled = 0
	BEGIN

	--04/16/2012 DRP:	found that if there was a large number of misc items added to the packing list that exceeded 10 that it would then begin not sorting them as desired. 
	--					added the sortby field below to address this situation. 
	select		t1.CUSTNO,t1.CUSTNAME, t1.STATUS, t1.Sono, t1.SHIPDATE, t1.packlistno, t1.INVOICENO, t1.PONO, t1.line_no,t1.sortby, t1.PART_NO, t1.REVISION, t1.PART_CLASS, t1.PART_TYPE,
				t1.DESCRIPT, t1.PkPriceDesc, t1.recordtype, t1.QUANTITY, t1.PRICE, t1.EXTENDED, t1.tax,
				CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then INVTOTAL ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotal,
				t1.poststatus,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then TOTEXTEN ELSE CAST(0.00 as Numeric(20,2)) END AS TOTEXTEN
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then TOTTAXE ELSE CAST(0.00 as Numeric(20,2)) END AS TOTTAXE
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then FREIGHTAMT ELSE CAST(0.00 as Numeric(20,2)) END AS FREIGHTAMT
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then TOTTAXF ELSE CAST(0.00 as Numeric(20,2)) END AS TOTTAXF
				-- 07/26/19 VL added salestypeid, request by Paramit #5542
				,SaleTypeId
	From(
	select		customer.CUSTNO, CUSTOMER.CUSTNAME,	CUSTOMER.STATUS,
				case when PLMAIN.SONO = '' then cast('Manual PL' as CHAR(10)) else cast(PLMAIN.SONO as CHAR(10)) end as Sono,
				PLMAIN.shipdate,plmain.PACKLISTNO, PLMAIN.INVOICENO,SOMAIN.PONO,
				ISNULL(cast(sodetail.line_no as CHAR (10)),cast(PLPRICES.uniqueln as CHAR (10))) as Line_No,
				ISNULL(sodetail.line_no,'X'+dbo.padl(rtrim(substring(PLPRICES.uniqueln,2,6)),6,'0')) as sortby,
				INVENTOR.PART_NO,INVENTOR.REVISION,INVENTOR.PART_CLASS,INVENTOR.PART_TYPE,INVENTOR.DESCRIPT,
				case when PLPRICES.RECORDTYPE = 'O' then cast(PLPRICES.DESCRIPT as CHAR(45)) else cast(INVENTOR.PART_NO  + INVENTOR.REVISION as CHAR(45)) end as PkPriceDesc,
				PLPRICES.RECORDTYPE, PLPRICES.QUANTITY,PLPRICES.PRICE,PLPRICES.EXTENDED,
				case when PLPRICES.TAXABLE = 1 then 'Y' else '' end as tax,PLMAIN.INVTOTAL,
				case when PLMAIN.PRINTED = 0 then 'Unposted' else case when PLMAIN.printed = 1 then 'Posted' end end as PostStatus
				,TOTEXTEN,TOTTAXE,FREIGHTAMT,TOTTAXF
				-- 07/26/19 VL added salestypeid, request by Paramit #5542
				,ISNULL(Soprices.SaleTypeId,SPACE(10)) AS SaletypeId

	from		PLMAIN inner join
				CUSTOMER on CUSTOMER.CUSTNO = PLMAIN.custno left outer join
				SOMAIN on PLMAIN.SONO = SOMAIN.SONO and PLMAIN.CUSTNO = SOMAIN.CUSTNO left outer join
				PLPRICES on PLMAIN.PACKLISTNO = PLPRICES.PACKLISTNO left outer join
				SODETAIL on PLPRICES.UNIQUELN = SODETAIL.UNIQUELN left outer join
				INVENTOR on SODETAIL.UNIQ_KEY = INVENTOR.UNIQ_KEY
				-- 07/26/19 VL added salestypeid, request by Paramit #5542
				LEFT OUTER JOIN Soprices ON Plprices.PLPRICELNK = Soprices.PLPRICELNK

	Where		PLMAIN.SONO = dbo.padl(@lcSoNo,10,'0')
				and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno)	--07/19/17 DRP:  added


	)t1
	order by 2, 4
	END
ELSE
-- FC installed
	BEGIN
	--04/16/2012 DRP:	found that if there was a large number of misc items added to the packing list that exceeded 10 that it would then begin not sorting them as desired. 
	--					added the sortby field below to address this situation. 
	select		t1.CUSTNO,t1.CUSTNAME, t1.STATUS, t1.Sono, t1.SHIPDATE, t1.packlistno, t1.INVOICENO, t1.PONO, t1.line_no,t1.sortby, t1.PART_NO, t1.REVISION, t1.PART_CLASS, t1.PART_TYPE,
				t1.DESCRIPT, t1.PkPriceDesc, t1.recordtype, t1.QUANTITY, t1.PRICE, t1.EXTENDED, t1.tax,
				CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then INVTOTAL ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotal,
				t1.poststatus,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then TOTEXTEN ELSE CAST(0.00 as Numeric(20,2)) END AS TOTEXTEN
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then TOTTAXE ELSE CAST(0.00 as Numeric(20,2)) END AS TOTTAXE
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then FREIGHTAMT ELSE CAST(0.00 as Numeric(20,2)) END AS FREIGHTAMT
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then TOTTAXF ELSE CAST(0.00 as Numeric(20,2)) END AS TOTTAXF
				,t1.PRICEFC, t1.EXTENDEDFC
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then INVTOTALFC ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotalFC
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then TOTEXTENFC ELSE CAST(0.00 as Numeric(20,2)) END AS TOTEXTENFC
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then TOTTAXEFC ELSE CAST(0.00 as Numeric(20,2)) END AS TOTTAXEFC
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then FREIGHTAMTFC ELSE CAST(0.00 as Numeric(20,2)) END AS FREIGHTAMTFC
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then TOTTAXFFC ELSE CAST(0.00 as Numeric(20,2)) END AS TOTTAXFFC
				,t1.Fcused_uniq--, t1.Currency
				-- 01/19/17 VL added functional currency code
				,t1.PRICEPR, t1.EXTENDEDPR
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then INVTOTALPR ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotalPR
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then TOTEXTENPR ELSE CAST(0.00 as Numeric(20,2)) END AS TOTEXTENPR
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then TOTTAXEPR ELSE CAST(0.00 as Numeric(20,2)) END AS TOTTAXEPR
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then FREIGHTAMTPR ELSE CAST(0.00 as Numeric(20,2)) END AS FREIGHTAMTPR
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then TOTTAXFPR ELSE CAST(0.00 as Numeric(20,2)) END AS TOTTAXFPR
				,TSymbol, PSymbol, FSymbol
				-- 07/26/19 VL added salestypeid, request by Paramit #5542
				,SaleTypeId
	From(
	select		customer.CUSTNO, CUSTOMER.CUSTNAME,	CUSTOMER.STATUS,
				case when PLMAIN.SONO = '' then cast('Manual PL' as CHAR(10)) else cast(PLMAIN.SONO as CHAR(10)) end as Sono,
				PLMAIN.shipdate,plmain.PACKLISTNO, PLMAIN.INVOICENO,SOMAIN.PONO,
				ISNULL(cast(sodetail.line_no as CHAR (10)),cast(PLPRICES.uniqueln as CHAR (10))) as Line_No,
				ISNULL(sodetail.line_no,'X'+dbo.padl(rtrim(substring(PLPRICES.uniqueln,2,6)),6,'0')) as sortby,
				INVENTOR.PART_NO,INVENTOR.REVISION,INVENTOR.PART_CLASS,INVENTOR.PART_TYPE,INVENTOR.DESCRIPT,
				case when PLPRICES.RECORDTYPE = 'O' then cast(PLPRICES.DESCRIPT as CHAR(45)) else cast(INVENTOR.PART_NO  + INVENTOR.REVISION as CHAR(45)) end as PkPriceDesc,
				PLPRICES.RECORDTYPE, PLPRICES.QUANTITY,PLPRICES.PRICE,PLPRICES.EXTENDED,
				case when PLPRICES.TAXABLE = 1 then 'Y' else '' end as tax,PLMAIN.INVTOTAL,
				case when PLMAIN.PRINTED = 0 then 'Unposted' else case when PLMAIN.printed = 1 then 'Posted' end end as PostStatus
				,TOTEXTEN,TOTTAXE,FREIGHTAMT,TOTTAXF
				,PLPRICES.PRICEFC,PLPRICES.EXTENDEDFC
				,PLMAIN.INVTOTALFC,TOTEXTENFC,TOTTAXEFC,FREIGHTAMTFC,TOTTAXFFC, Plmain.Fcused_uniq AS Fcused_uniq--, Fcused.Symbol AS Currency
				-- 01/19/17 VL added functional currency code
				,PLPRICES.PRICEPR,PLPRICES.EXTENDEDPR, PLMAIN.INVTOTALPR,TOTEXTENPR,TOTTAXEPR,FREIGHTAMTPR,TOTTAXFPR, TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
				-- 07/26/19 VL added salestypeid, request by Paramit #5542
				,ISNULL(Soprices.SaleTypeId,SPACE(10)) AS SaletypeId

	from		PLMAIN 
				-- 01/19/17 VL changed criteria to get 3 currencies
				INNER JOIN Fcused PF ON plmain.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON plmain.FuncFcused_uniq = FF.Fcused_uniq			
				INNER JOIN Fcused TF ON plmain.Fcused_uniq = TF.Fcused_uniq inner join
				CUSTOMER on CUSTOMER.CUSTNO = PLMAIN.custno left outer join
				SOMAIN on PLMAIN.SONO = SOMAIN.SONO and PLMAIN.CUSTNO = SOMAIN.CUSTNO left outer join
				PLPRICES on PLMAIN.PACKLISTNO = PLPRICES.PACKLISTNO left outer join
				SODETAIL on PLPRICES.UNIQUELN = SODETAIL.UNIQUELN left outer join
				INVENTOR on SODETAIL.UNIQ_KEY = INVENTOR.UNIQ_KEY
				-- 07/26/19 VL added salestypeid, request by Paramit #5542
				LEFT OUTER JOIN Soprices ON Plprices.PLPRICELNK = Soprices.PLPRICELNK

	Where		PLMAIN.SONO = dbo.padl(@lcSoNo,10,'0')
				and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno)	--07/19/17 DRP:  added


	)t1
	order by TSymbol, 2, 4
	END
END -- end of IF FC installed
END