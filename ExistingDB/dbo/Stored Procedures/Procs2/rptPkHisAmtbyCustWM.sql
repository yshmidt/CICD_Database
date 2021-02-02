
-- =============================================
-- Author:		<Debbie>
-- Create date: <11/10/2010>
-- Description:	<compiles detailed Packing List information with $ Amount>
-- Reports:     <used on pkhisamt.rpt and pkhis_pt.rpt>
-- Modified:	04/17/2012 DRP: found that if there was a large number of misc items added to the packing list that exceeded 10 that it would then begin not sorting them as desired.
-- 01/28/2015 DRP:  added the followig fields to the results as requested (TOTEXTEN,TOTTAXE,FREIGHTAMT,TOTTAXF)
-- had to create WM version of the procedure to work with the cloud quickview.  Added the /*CUSTOMER LIST*/
-- 02/16/2016 VL:	 Added FC code
-- 04/08/2016 VL:   Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 01/19/2017 VL:   Added functional currency code
-- 04/17/17 DRP:	Removed the @customerStatus parameter,  added code for Part_no to display "Misc Item".  report "Daily Shipment History by Part Number" will no longer be displayed it has been replaced by "Shipment History - By Customer or By Part Number"   
-- 07/16/18 VL changed custname from char(35) to char(50)
-- 07/26/19 VL added salestypeid, request by Paramit #5542
-- =============================================
CREATE PROCEDURE [dbo].[rptPkHisAmtbyCustWM]
--06/08/2011 ~ Deb: added the Date Range and Customer Parameter to speed the response time on larger datasets 
--06/08/2011 ~ Deb:	Also had to make the Stored Procedure more unique to each report because of these parameters.  
--					I used to have pkhis_pk.rpt, pkhis_p.rpt and pkhis_so.rpt also using this SP, but now they will more than likely have to have their own.
		--declare
		@lcDateStart as smalldatetime= null
		,@lcDateEnd as smalldatetime = null
		,@lcCustno as varchar (MAX) = 'All'									--01/28/2015 DRP:  Added
		,@lcSort as char(12) = 'Part Number'		--Part Number or Customer	--01/28/2015 DRP:  Added
		--,@customerStatus char(8)='All'			--04/17/17 DRP:  removed
		, @userId uniqueidentifier= null

AS
BEGIN


/*CUSTOMER LIST*/	--01/28/2015 DRP:  Added	
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

-- 02/15/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
BEGIN
IF @lFCInstalled = 0
	BEGIN

	/*SELECT STATEMENT*/
	--04/17/2012 DRP:	found that if there was a large number of misc items added to the packing list that exceeded 10 that it would then begin not sorting them as desired. 
	--					added the sortby field below to address this situation. 

	-- 07/16/18 VL changed custname from char(35) to char(50)
	declare @t1 as table (CUSTNO char(10),CUSTNAME char(50),STATUS char(8),Sono char(10),SHIPDATE smalldatetime,packlistno char(10),INVOICENO char(10),PONO char(20),line_no char(10),sortby char(10),PART_NO char(30),REVISION char(8)
						,PART_CLASS char(8),PART_TYPE char(8),DESCRIPT char(50),PkPriceDesc char(50),recordtype char(1),QUANTITY numeric(10,2),PRICE numeric(14,5),EXTENDED numeric(20,2),tax char(1)
						,InvTotal Numeric(20,2),poststatus char(10),TOTEXTEN Numeric(20,2),TOTTAXE Numeric(20,2),FREIGHTAMT Numeric(20,2),TOTTAXF Numeric(20,2)
						-- 07/26/19 VL added salestypeid, request by Paramit #5542
						, SaletypeId char(10))
					
	insert into @t1 
	select		t1.CUSTNO,t1.CUSTNAME, t1.STATUS, t1.Sono, t1.SHIPDATE, t1.packlistno, t1.INVOICENO, isnull(t1.PONO,''), t1.line_no,t1.sortby, isnull(t1.PART_NO,'Misc Item'),isnull(t1.REVISION,'')
				,isnull(t1.PART_CLASS,''),isnull(t1.PART_TYPE,''),isnull(t1.DESCRIPT,''), t1.PkPriceDesc, t1.recordtype, t1.QUANTITY, t1.PRICE, t1.EXTENDED, t1.tax,
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
				--case when PLMAIN.SONO = '' then cast(PLPRICES.UNIQUELN as CHAR(7)) else cast(SODETAIL.LINE_NO as CHAR(7)) end as line_no,
				INVENTOR.PART_NO,INVENTOR.REVISION,INVENTOR.PART_CLASS,INVENTOR.PART_TYPE,INVENTOR.DESCRIPT,
				case when PLPRICES.RECORDTYPE = 'O' then cast(PLPRICES.DESCRIPT as CHAR(45)) else cast(INVENTOR.PART_NO  + INVENTOR.REVISION as CHAR(45)) end as PkPriceDesc,
				PLPRICES.RECORDTYPE, PLPRICES.QUANTITY,PLPRICES.PRICE,PLPRICES.EXTENDED,
				case when PLPRICES.TAXABLE = 1 then 'Y' else '' end as tax,PLMAIN.INVTOTAL,
				case when PLMAIN.PRINTED = 0 then 'Unposted' else case when PLMAIN.printed = 1 then 'Posted' end end as PostStatus,TOTEXTEN,TOTTAXE,FREIGHTAMT,TOTTAXF
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
	Where		datediff(day,plmain.shipdate,@lcDateStart)<=0 and datediff(day,plmain.shipdate,@lcDateEnd)>=0	
				and 1 = case when customer.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
		)t1

	if (@lcSort = 'Part Number')
		Begin
			select * from @t1 order by part_no,Revision,PacklistNo,Sortby,line_no
		End

	else if (@lcSort = 'Customer')
		Begin
			select * from @t1 Order by custname,sono,packlistno,sortby,line_no
		End
	END
ELSE
-- FC installed
	BEGIN
	/*SELECT STATEMENT*/
	--04/17/2012 DRP:	found that if there was a large number of misc items added to the packing list that exceeded 10 that it would then begin not sorting them as desired. 
	--					added the sortby field below to address this situation. 
	-- 01/19/17 VL added functional currency code and comment out old Currency fields
	-- 07/16/18 VL changed custname from char(35) to char(50)
	declare @t2 as table (CUSTNO char(10),CUSTNAME char(50),STATUS char(8),Sono char(10),SHIPDATE smalldatetime,packlistno char(10),INVOICENO char(10),PONO char(20),line_no char(10),sortby char(10),PART_NO char(30),REVISION char(8)
						,PART_CLASS char(8),PART_TYPE char(8),DESCRIPT char(50),PkPriceDesc char(50),recordtype char(1),QUANTITY numeric(10,2),PRICE numeric(14,5),EXTENDED numeric(20,2),tax char(1)
						,InvTotal Numeric(20,2),poststatus char(10),TOTEXTEN Numeric(20,2),TOTTAXE Numeric(20,2),FREIGHTAMT Numeric(20,2),TOTTAXF Numeric(20,2)
						,PRICEFC numeric(14,5),EXTENDEDFC numeric(20,2),InvTotalFC Numeric(20,2),TOTEXTENFC Numeric(20,2),TOTTAXEFC Numeric(20,2),FREIGHTAMTFC Numeric(20,2),TOTTAXFFC Numeric(20,2)
						,Fcused_uniq char(10)
						--,Currency char(3))
						,PRICEPR numeric(14,5),EXTENDEDPR numeric(20,2),InvTotalPR Numeric(20,2),TOTEXTENPR Numeric(20,2),TOTTAXEPR Numeric(20,2),FREIGHTAMTPR Numeric(20,2),TOTTAXFPR Numeric(20,2)
						,TSymbol char(3), PSymbol char(3), FSymbol char(3)
						-- 07/26/19 VL added salestypeid, request by Paramit #5542
						, SaletypeId char(10))
					
	insert into @t2
	select		t2.CUSTNO,t2.CUSTNAME, t2.STATUS, t2.Sono, t2.SHIPDATE, t2.packlistno, t2.INVOICENO, isnull(t2.PONO,''), t2.line_no,t2.sortby, isnull(t2.PART_NO,'Misc Item'),isnull(t2.REVISION,'')
				,isnull(t2.PART_CLASS,''),isnull(t2.PART_TYPE,''),isnull(t2.DESCRIPT,''), t2.PkPriceDesc, t2.recordtype, t2.QUANTITY, t2.PRICE, t2.EXTENDED, t2.tax,
				CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then INVTOTAL ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotal,
				t2.poststatus,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then TOTEXTEN ELSE CAST(0.00 as Numeric(20,2)) END AS TOTEXTEN
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then TOTTAXE ELSE CAST(0.00 as Numeric(20,2)) END AS TOTTAXE
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then FREIGHTAMT ELSE CAST(0.00 as Numeric(20,2)) END AS FREIGHTAMT
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then TOTTAXF ELSE CAST(0.00 as Numeric(20,2)) END AS TOTTAXF
				,t2.PRICEFC, t2.EXTENDEDFC
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then INVTOTALFC ELSE CAST(0.00 as Numeric(20,2)) END AS InvTotalFC
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then TOTEXTENFC ELSE CAST(0.00 as Numeric(20,2)) END AS TOTEXTENFC
				-- 01/19/17 I think the name TOTTAXEFCFC should be TOTTAXEFC
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then TOTTAXEFC ELSE CAST(0.00 as Numeric(20,2)) END AS TOTTAXEFC
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then FREIGHTAMTFC ELSE CAST(0.00 as Numeric(20,2)) END AS FREIGHTAMTFC
				,CASE WHEN ROW_NUMBER() OVER(Partition by custname,invoiceno Order by invoiceno)=1 Then TOTTAXFFC ELSE CAST(0.00 as Numeric(20,2)) END AS TOTTAXFFC
				,Fcused_uniq--,Currency
				-- 01/19/17 VL added functional currency code
				,t2.PRICEPR, t2.EXTENDEDPR
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
				--case when PLMAIN.SONO = '' then cast(PLPRICES.UNIQUELN as CHAR(7)) else cast(SODETAIL.LINE_NO as CHAR(7)) end as line_no,
				INVENTOR.PART_NO,INVENTOR.REVISION,INVENTOR.PART_CLASS,INVENTOR.PART_TYPE,INVENTOR.DESCRIPT,
				case when PLPRICES.RECORDTYPE = 'O' then cast(PLPRICES.DESCRIPT as CHAR(45)) else cast(INVENTOR.PART_NO  + INVENTOR.REVISION as CHAR(45)) end as PkPriceDesc,
				PLPRICES.RECORDTYPE, PLPRICES.QUANTITY,PLPRICES.PRICE,PLPRICES.EXTENDED,
				case when PLPRICES.TAXABLE = 1 then 'Y' else '' end as tax,PLMAIN.INVTOTAL,
				case when PLMAIN.PRINTED = 0 then 'Unposted' else case when PLMAIN.printed = 1 then 'Posted' end end as PostStatus,TOTEXTEN,TOTTAXE,FREIGHTAMT,TOTTAXF
				,PLPRICES.PRICEFC,PLPRICES.EXTENDEDFC, PLMAIN.INVTOTALFC,TOTEXTENFC,TOTTAXEFC,FREIGHTAMTFC,TOTTAXFFC, Plmain.Fcused_uniq AS Fcused_uniq --Fcused.Symbol AS Currency
				-- 01/19/17 VL added functional currency code
				,PLPRICES.PRICEPR,PLPRICES.EXTENDEDPR, PLMAIN.INVTOTALPR,TOTEXTENPR,TOTTAXEPR,FREIGHTAMTPR,TOTTAXFPR, TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
				-- 07/26/19 VL added salestypeid, request by Paramit #5542
				,ISNULL(Soprices.SaleTypeId,SPACE(10)) AS SaletypeId
	from		PLMAIN
				-- 01/19/17 VL changed criteria to get 3 currencies
				INNER JOIN Fcused PF ON plmain.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON plmain.FuncFcused_uniq = FF.Fcused_uniq			
				INNER JOIN Fcused TF ON plmain.Fcused_uniq = TF.Fcused_uniq 
				INNER JOIN CUSTOMER on CUSTOMER.CUSTNO = PLMAIN.custno left outer join
				SOMAIN on PLMAIN.SONO = SOMAIN.SONO and PLMAIN.CUSTNO = SOMAIN.CUSTNO left outer join
				PLPRICES on PLMAIN.PACKLISTNO = PLPRICES.PACKLISTNO left outer join
				SODETAIL on PLPRICES.UNIQUELN = SODETAIL.UNIQUELN left outer join
				INVENTOR on SODETAIL.UNIQ_KEY = INVENTOR.UNIQ_KEY
				-- 07/26/19 VL added salestypeid, request by Paramit #5542
				LEFT OUTER JOIN Soprices ON Plprices.PLPRICELNK = Soprices.PLPRICELNK
	Where		datediff(day,plmain.shipdate,@lcDateStart)<=0 and datediff(day,plmain.shipdate,@lcDateEnd)>=0	
				and 1 = case when customer.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
		)t2

	if (@lcSort = 'Part Number')
		Begin
			select * from @t2 order by part_no,Revision,PacklistNo,Sortby,line_no
		End

	else if (@lcSort = 'Customer')
		Begin
			select * from @t2 Order by custname,sono,packlistno,sortby,line_no
		End
	END
END-- End of IF FC installed

END




