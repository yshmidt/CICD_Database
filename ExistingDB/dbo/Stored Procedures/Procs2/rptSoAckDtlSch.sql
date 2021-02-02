

-- =============================================
-- Author:		<Debbie>
-- Create date: <06/11/2010>
-- Description:	<compiles detailed sales order information>
-- Reports:     <used on soack.rpt, rmaack.rpt, proforma.rpt>
-- Modified:	10/20/2012 DRP:  Found that I was calculating the Discount value on the report incorrectly.  I removed where I was calculating the Discount amount and replaced it with the somain.soamtdsct.
--				03/20/2013 DRP:  Modified all of the address information to work as a Memo Fields as Yelena had suggested. 
--				03/21/2013 DRP:  It was found that in a situation where the user marked the item as taxable, but that particular customer happen to NOT have any tax information setup within the system
--								 that it was causing NULL to be returned in the ShipTax field and in turn causing the Grand Total on the resulting report to be blank. 
--				04/04/2013 DRP:  added code to filter out cancelled line items.
--				10/21/2013 DRP:  I needed to add the "and i2.CUSTNO = plmain.CUSTNO" whern i2 is joined otherwise I was getting every Customer Part number record that existed for the inventory part regardless which customer was selected for the Order. 				 
--				02/09/2016 VL:	 Added FC fields, also SO items can be shipped to different address, so the report has to group by sodetail.slinkadd
--				03/31/2016 VL:	 Added TCurrency (Transaction Currency) and FCurrency (Functional Currency) fields, also add address3 and address4
--				04/08/2016 VL:	 Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--				04/11/2016 DRP:  removed the micssys tables and fields from the results.  This will be added at the report level using the GetCompanyAddress
--				04/12/2016 DRP:  added ShipToCount to the results so we could determine if there are more than one ship to associated with the sales order or not. 
--								 added the @lcShipTo Parameter so the user can determine which ShipTo would be displayed in the header.
--								 added recordtype from the soprices table.
--								 added PTaxId char(8) and STaxId char(8)
--				04/21/2016 DRP:  Needed to remove the pricing information from this procedure because in the situation where there were multiple Prices and Multiple Schedules it would not handle it properly within the Stimulsoft report
--								 So now I had to update soackdtl.mrt and rmaackdtl.mrt to use this procedure instead.  The SOPRICES will be pulled into the report form and added as a subreport.  and also added HeaderShipto and HeaderShipToAddress to the results
--				10/07/16 DRP:	 Made modifications on how we gathered the Currency Symbols.  Added the Three values for the Func Currency project. 
--				02/03/2017 DRP:	 The code that I used to find the PTaxId and STaxID back on 04/12/2016 was not correct.  Needed to change the STaxId to pull TaxType = 'E' not 'S' and I needed to change the @lcSono to be <<dbo.padl(@lcSoNo,10,'0')>> for the TaxId section
--  06/16/17 DRP:  added the Discount information to the results in order to get the Tax rate to calculate correct at the item level after the Discounts have been applied at at the item level. 
--	12/04/19 VL:   Change tax calculation, there is no foreign tax in cube, has 'Tax On Goods' and 'Secondary Tax', so now only use SoPtax, and SoSTax, don't use SoTax anymore
-- =============================================
CREATE PROCEDURE [dbo].[rptSoAckDtlSch] 
--declare
		--04/01/2011 ~ Deb:  added the Sales Order parameter to speed the response time on larger datasets
		--declare
		@lcPartSrc char(9) = 'Internal'		-- 'Inernal' or 'Consigned' would be populated here.  This will determine if the Customer PN or Internal PN is displayed on the report. 
		,@lcSoNo char(10) = ''	-- Default in the Sales Order that happens to be open on screen.  with the option to manually enter in a Sales Order No.
		,@lcShipTo char(10) = ''		-- added this parameter so the user can determine which ShipTo would be displayed in the header.
		 , @userId uniqueidentifier=null 
AS
BEGIN


-- 02/08/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()


--SHIP TO ADDRESS COUNT
DECLARE @ShipToCount as table (ShipToCount numeric(5))

;with zSCount as (
select slinkadd from sodetail where sono = dbo.padl(@lcSoNo,10,'0') group by slinkadd
)
insert into @ShipToCount 
select count(*) n from zSCount

--04/13/2016 DRP:  added PTaxId char(8) and STaxId char(8)
--02/03/2017 DRP:  needed to change from <<TaxType = 'S'>> to be <<TaxType = 'E'>>, I also need to change <<sono = @lcSoNo>> to be <<sono = dbo.padl(@lcSoNo,10,'0')>>
DECLARE @PTaxID char(8), @STaxID char(8)
-- 12/04/19 VL changed to use new tax structure for cube
--SELECT @PTaxId = ISNULL((SELECT TOP 1 Tax_id FROM SOPRICESTAX WHERE sono = dbo.padl(@lcSoNo,10,'0') AND TaxType = 'P' ORDER BY Tax_id), SPACE(8))
--SELECT @STaxId = ISNULL((SELECT TOP 1 Tax_id FROM SOPRICESTAX WHERE sono = dbo.padl(@lcSoNo,10,'0') AND TaxType = 'E' ORDER BY Tax_id), SPACE(8))
SELECT @PTaxId = ISNULL((SELECT TOP 1 Tax_id FROM SOPRICESTAX WHERE sono = dbo.padl(@lcSoNo,10,'0') AND SetupTaxType = 'Tax On Goods' ORDER BY Tax_id), SPACE(8))
SELECT @STaxId = ISNULL((SELECT TOP 1 Tax_id FROM SOPRICESTAX WHERE sono = dbo.padl(@lcSoNo,10,'0') AND SetupTaxType = 'Secondary Tax' ORDER BY Tax_id), SPACE(8))


IF @lFCInstalled = 0
	BEGIN
		select t1.CUSTNO, t1.CUSTNAME,t1.blinkadd, t1.slinkadd,t1.discount, t1.PONO, t1.ORDERDATE, t1.SONO, 
							  t1.SHIPNO, t1.TERMS, t1.FOB, t1.SHIPVIA, t1.LINE_NO, t1.UNIQUELN, 
							  t1.part_no, t1.REV, t1.PART_CLASS, t1.PART_TYPE, t1.DESCRIPT, 
							  t1.UOFMEAS
							  --,t1.plpricelnk,t1.descriptio, CASE WHEN ROW_NUMBER() OVER(Partition by sono,line_no, plpricelnk Order by orderdate)=1 Then quantity ELSE CAST(0.00 as Numeric(20,2)) END AS Quantity, 
							  --CASE WHEN ROW_NUMBER() OVER(Partition by sono,line_no, plpricelnk Order by orderdate)=1 Then price ELSE CAST(0.00 as Numeric(20,2)) END AS price, 
							  --CASE WHEN ROW_NUMBER() OVER(Partition by sono,line_no, plpricelnk Order by orderdate)=1 Then extended ELSE CAST(0.00 as Numeric(20,2)) END AS itemExt, 
							  --t1.dscext/100 as dscext,extended-dscext/100 as subtotal2,t1.TAXABLE,t1.FLAT	--04/21/2016 DRP:  removed all of the Pricing fields
							  ,t1.NOTE,
							  CASE WHEN ROW_NUMBER() OVER(Partition by sono Order by orderdate)=1 Then soextend ELSE CAST(0.00 as Numeric(20,2)) END AS SOEXTENDED,
							  CASE WHEN ROW_NUMBER() OVER(Partition by sono Order by orderdate)=1 Then soptax ELSE CAST(0.00 as Numeric(20,2)) END AS soptax,
							  CASE WHEN ROW_NUMBER() OVER(Partition by sono Order by orderdate)=1 Then sostax ELSE CAST(0.00 as Numeric(20,2)) END AS sostax,
			--DRP 03/20/2013:  If item was marked as taxable but no tax records existed for that customer a null value would be returned instead of 0.00.  Implemented the isnull(t1.shiptax,0.00) below to address that issue. 
							  --isnull(t1.shiptax,0.00) as shiptax --04/21/2016 DRP:  removed all of the Pricing fields
							   t1.sonote,t1.sofoot,t1.Ord_type,t1.is_rma, t1.buyerlast, t1.buyerfirst, t1.ShipTo,t1.ShipToAddress
			--DRP 03/20/2013:  REPLACED BY ABOVE SupplierAddress.  Place all of the info below into one single Memo field. 		
							  --,t1.S_Add1, t1.S_Add2, t1.S_city, t1.S_State, t1.S_zip, t1.S_country
							  -- 12/04/19 VL removed ForeignTax field, now no US tax and ForignTax difference in cube
							  --, t1.FOREIGNTAX
							  , t1.billacount, t1.Billto,t1.BillToAddress
							  -- t1.B_Add1, t1.B_Add2, t1.B_city, t1.B_State, t1.B_zip, t1.B_country
							  ,t1.status
							 -- ,t1.lic_name,t1.LicAddress,t1.AKSTD_FOOT,t1.rma_foot,t1.field149
							  ,t1.saledsctid,t1.ShipToCount
							  --,t1.recordtype	--04/21/2016 DRP:  removed all of the Pricing fields
							  ,t1.PTaxId, t1.STaxID
							  -- 12/04/19 VL removed tax_rate because removed st1
							  --,t1.TAX_RATE		--04/19/2016 DRP:  Added
							  ,hs1.shipto as HeaderShipTo
							,rtrim(hs1.Address1)+case when hs1.address2<> '' then char(13)+char(10)+rtrim(hs1.address2) else '' end+
							  case when hs1.address3<> '' then char(13)+char(10)+rtrim(hs1.address3) else '' end+
							  case when hs1.address4<> '' then char(13)+char(10)+rtrim(hs1.address4) else '' end+
								CASE WHEN hs1.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(hs1.City)+',  '+rtrim(hs1.State)+'      '+RTRIM(hs1.zip)  ELSE '' END +
								CASE WHEN hs1.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(hs1.Country) ELSE '' end+
								case when hs1.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(hs1.PHONE) else '' end+
								case when hs1.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(hs1.FAX) else '' end  as HeaderShipToAddress
								,t1.SALEDSCTID,t1.DiscRate	--06/16/17 DRP:  Added
		                      
		                      
		                      
		from(
		SELECT     TOP (100) PERCENT c1.CUSTNO, c1.CUSTNAME,s1.blinkadd,sd1.slinkadd,s1.SOAMTDSCT as Discount
								--, case when c1.saledsctid = '' then cast(0.00 as numeric (12,2)) else sdc1.discount end as discount
								, s1.PONO, s1.ORDERDATE, s1.SONO,s1.SHIPNO, s1.TERMS, sd1.FOB, sd1.SHIPVIA, sd1.LINE_NO, sd1.UNIQUELN, 
							  case when @lcPartSrc = 'Internal' then i1.part_no when @lcPartSrc = 'Consigned' and i2.int_uniq IS NULL then i1.part_no else i2.custpartno end as Part_no,
							  case when @lcPartSrc = 'Internal' then i1.revision when @lcPartSrc = 'Consigned' and i2.int_uniq IS NULL then i1.revision else i2.custrev end as Rev,
							  i1.PART_CLASS, i1.PART_TYPE, i1.DESCRIPT, sd1.UOFMEAS
							  --,sp1.plpricelnk,sp1.descriptio, sp1.QUANTITY, sp1.PRICE, sp1.EXTENDED,
							  --case when sp1.quantity < 0.00 then cast(0.00 as numeric(12,2)) when c1.saledsctid = '' then cast(0.00 as numeric (12,2)) else sp1.extended*sdc1.discount end as dscext, 
							  --sp1.TAXABLE, sp1.FLAT  --04/21/2016 DRP:  removed all of the Pricing fields
							  , sd1.NOTE,s1.soextend, s1.soptax,s1.sostax,
							  --case when sp1.taxable = '1' and sb1.foreigntax <> '1' then cast (st1.tax_rate*sp1.extended/100 as numeric (12,2)) else cast (0.00 as numeric (12,2)) end as ShipTax,  --04/21/2016 DRP:  removed all of the Pricing fields
							  s1.sonote,s1.sofoot,s1.ord_type, s1.is_rma, cc1.LASTNAME as buyerlast, cc1.FIRSTNAME as buyerfirst, 
							  sb1.shipto as ShipTo
							  ,rtrim(sb1.Address1)+case when sb1.address2<> '' then char(13)+char(10)+rtrim(sb1.address2) else '' end+
							  -- 03/31/16 VL added Address3 and 4
							  case when sb1.address3<> '' then char(13)+char(10)+rtrim(sb1.address3) else '' end+
							  case when sb1.address4<> '' then char(13)+char(10)+rtrim(sb1.address4) else '' end+
								CASE WHEN sb1.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(sb1.City)+',  '+rtrim(sb1.State)+'      '+RTRIM(sb1.zip)  ELSE '' END +
								CASE WHEN sb1.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(sb1.Country) ELSE '' end+
								case when sb1.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(sb1.PHONE) else '' end+
								case when sb1.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(sb1.FAX) else '' end  as ShipToAddress
			--DRP 03/20/2013:  REPLACED BY ABOVE SupplierAddress.  Place all of the info below into one single Memo field. 		
							  --, sb1.ADDRESS1 as S_Add1, sb1.ADDRESS2 as S_Add2, sb1.CITY as S_city,sb1.STATE as S_State,sb1.ZIP as S_zip, 
							  --sb1.COUNTRY as S_country
							   -- 12/04/19 VL removed ForeignTax field, now no US tax and ForignTax difference in cube
							  --,sb1.FOREIGNTAX
							  ,sb1.BILLACOUNT
							  , sb2.SHIPTO as BillTo
							   ,rtrim(sb2.Address1)+case when sb2.address2<> '' then char(13)+char(10)+rtrim(sb2.address2) else '' end+
							   -- 03/31/16 VL added Address3 and 4
							   case when sb2.address3<> '' then char(13)+char(10)+rtrim(sb2.ADDRESS3) else '' end+
							   case when sb2.address4<> '' then char(13)+char(10)+rtrim(sb2.address4) else '' end+
								CASE WHEN sb2.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(sb2.City)+',  '+rtrim(sb2.State)+'      '+RTRIM(sb2.zip)  ELSE '' END +
								CASE WHEN sb2.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(sb2.Country) ELSE '' end+
								case when sb2.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(sb2.PHONE) else '' end+
								case when sb2.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(sb2.FAX) else '' end  as BillToAddress
			--DRP 03/20/2013:  REPLACED BY ABOVE SupplierAddress.  Place all of the info below into one single Memo field. 		
							  --, sb2.ADDRESS1 as B_Add1, sb2.ADDRESS2 as B_Add2, sb2.CITY as B_City, 
							  --sb2.STATE as B_State, sb2.ZIP as B_Zip, sb2.COUNTRY as B_Country
							  ,sd1.STATUS
			--DRP 03/20/2013:  ADDED MICSSYS LICENSE INFO TO THE PROCEDURE, instead of pulling it as a separate table on the reports. 	
			--04/21/216 DRP:  removed the micssys field below . . will use the GetCompanyAddress on report form. 				 
							 -- ,micssys.lic_name,rtrim(MICSSYS.LADDRESS1)+case when MICSSYS.LADDRESS2<> '' then char(13)+char(10)+rtrim(MICSSYS.laddress2) else '' end+
								--CASE WHEN MICSSYS.LCITY<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(MICSSYS.LCITY)+',  '+rtrim(MICSSYS.lState)+'      '+RTRIM(MICSSYS.lzip)  ELSE '' END ++
								--CASE WHEN MICSSYS.LCOUNTRY<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(MICSSYS.LCOUNTRY) ELSE '' END+
								--case when micssys.LPHONE <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(MICSSYS.LPHONE) else '' end+
								--case when micssys.LFAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(micssys.LFAX) else '' end  as LicAddress
							 -- ,micssys.AKSTD_FOOT,micssys.RMA_FOOT,micssys.field149
							 ,c1.SALEDSCTID,sc.ShipToCount,@lcShipTo as HeaderShipTo
							 --,sp1.recordtype	--04/21/2016 DRP:  removed all of the Pricing fields
							 ,@PTaxId AS PTaxId, @STaxId AS STaxID  
							 -- 12/04/19 VL removed the st1 field
							 --,st1.TAX_RATE	--04/21/2016 DRP:  added
							  ,sdc1.DISCOUNT as DiscRate	--06/16/17 DRP:  added
		                      
		                      
		FROM         dbo.CUSTOMER as c1 INNER JOIN
							  dbo.SOMAIN as s1 ON c1.CUSTNO = s1.CUSTNO INNER JOIN
							  dbo.SODETAIL as sd1 ON s1.SONO = sd1.SONO LEFT OUTER JOIN
							 -- dbo.SOPRICES as sp1 ON sd1.UNIQUELN = sp1.UNIQUELN LEFT OUTER JOIN	--04/21/2016 DRP:  removed all of the Pricing fields
							  dbo.INVENTOR as i1 ON sd1.UNIQ_KEY = i1.UNIQ_KEY left outer join
--10/21/2013 DRP:  I needed to add the "and i2.CUSTNO = plmain.CUSTNO" whern i2 is joined otherwise I was getting every Customer Part number record that existed for the inventory part regardless which customer was selected for the Order. 				
							  --dbo.inventor as i2 on i2.int_uniq = i1.uniq_key left outer join
							  dbo.inventor as i2 on i2.int_uniq = i1.uniq_key and i2.CUSTNO = s1.CUSTNO left outer join
							  dbo.saledsct as sdc1 on sdc1.saledsctid = c1.saledsctid left outer join
							  dbo.CCONTACT as cc1 on cc1.CID = s1.BUYER left outer join
							  dbo.SHIPBILL as sb2 on s1.CUSTNO = sb2.CUSTNO and s1.blinkadd = sb2.LINKADD left outer join
							  dbo.SHIPBILL as sb1 ON s1.CUSTNO = sb1.CUSTNO AND sd1.SLINKADD = sb1.LINKADD
							  -- 12/04/19 VL comment out next line, don't calculate shiptax anymore, just use soptax and sostax
							 -- left outer join SHIPTAX st1 on sd1.SLINKADD+'S' = st1.LINKADD +st1.taxtype
							  left outer join SALEDSCT on c1.SALEDSCTID = SALEDSCT.SALEDSCTID
							   cross join @ShipToCount as SC	--04/12/2016 DRP:  added to determine how many different ShipTo
							  --cross join micssys	--04/11/2016 DRP:  removed
							  
	--04/04/2013 DRP:  added code to filter out cancelled line items. 
		where		s1.sono = dbo.padl(@lcSoNo,10,'0')
					and sd1.STATUS <> 'Cancel'                     
		                       

		) t1 cross join dbo.shipbill as Hs1 where @lcShipTo = Hs1.LINKADD	--04/12/2016 DRP:  added for the HeaderShipTo information


		-- 02/09/16 VL added order by slinkadd
		order by sono, shipto,line_no,slinkadd
	END
ELSE
	-- FC installed
	BEGIN
		---- 03/31/16 VL realized that I need to add HC (Functional currency later)
		--DECLARE @FCurrency char(3) = ''
		---- 04/08/16 VL changed to get HC fcused_uniq from function
		--SELECT @FCurrency = Symbol FROM Fcused WHERE Fcused.Fcused_uniq = dbo.fn_GetHomeCurrency()


		select t1.CUSTNO, t1.CUSTNAME,t1.blinkadd, t1.slinkadd,t1.discount, t1.PONO, t1.ORDERDATE, t1.SONO, 
							  t1.SHIPNO, t1.TERMS, t1.FOB, t1.SHIPVIA, t1.LINE_NO, t1.UNIQUELN, 
							  t1.part_no, t1.REV, t1.PART_CLASS, t1.PART_TYPE, t1.DESCRIPT, 
							  t1.UOFMEAS
							  --,t1.plpricelnk,t1.descriptio, CASE WHEN ROW_NUMBER() OVER(Partition by sono,line_no, plpricelnk Order by orderdate)=1 Then quantity ELSE CAST(0.00 as Numeric(20,2)) END AS Quantity, 
							  --CASE WHEN ROW_NUMBER() OVER(Partition by sono,line_no, plpricelnk Order by orderdate)=1 Then price ELSE CAST(0.00 as Numeric(20,2)) END AS price, 
							  --CASE WHEN ROW_NUMBER() OVER(Partition by sono,line_no, plpricelnk Order by orderdate)=1 Then extended ELSE CAST(0.00 as Numeric(20,2)) END AS itemExt, 
							  --t1.dscext/100 as dscext,extended-dscext/100 as subtotal2,t1.TAXABLE,t1.FLAT	--04/21/2016 DRP:  removed all of the Pricing fields
							  ,t1.NOTE,
							  CASE WHEN ROW_NUMBER() OVER(Partition by sono Order by orderdate)=1 Then soextend ELSE CAST(0.00 as Numeric(20,2)) END AS SOEXTENDED,
							  CASE WHEN ROW_NUMBER() OVER(Partition by sono Order by orderdate)=1 Then soptax ELSE CAST(0.00 as Numeric(20,2)) END AS soptax,
							  CASE WHEN ROW_NUMBER() OVER(Partition by sono Order by orderdate)=1 Then sostax ELSE CAST(0.00 as Numeric(20,2)) END AS sostax,
			--DRP 03/20/2013:  If item was marked as taxable but no tax records existed for that customer a null value would be returned instead of 0.00.  Implemented the isnull(t1.shiptax,0.00) below to address that issue. 
							  --isnull(t1.shiptax,0.00) as shiptax
							  t1.sonote,t1.sofoot,t1.Ord_type,t1.is_rma, t1.buyerlast, t1.buyerfirst, t1.ShipTo,t1.ShipToAddress	--04/21/2016 DRP:  removed all of the Pricing fields
			--DRP 03/20/2013:  REPLACED BY ABOVE SupplierAddress.  Place all of the info below into one single Memo field. 		
							  --,t1.S_Add1, t1.S_Add2, t1.S_city, t1.S_State, t1.S_zip, t1.S_country
							  -- 12/04/19 VL removed ForeignTax field, now no US tax and ForignTax difference in cube
							  --, t1.FOREIGNTAX
							  , t1.billacount, t1.Billto,t1.BillToAddress
							  -- t1.B_Add1, t1.B_Add2, t1.B_city, t1.B_State, t1.B_zip, t1.B_country
							  ,t1.status
							  --,t1.lic_name,t1.LicAddress,t1.AKSTD_FOOT,t1.rma_foot,t1.field149
							  ,t1.saledsctid
							  ,t1.discountFC, 
		       --               CASE WHEN ROW_NUMBER() OVER(Partition by sono,line_no, plpricelnk Order by orderdate)=1 Then priceFC ELSE CAST(0.00 as Numeric(20,2)) END AS priceFC, 
							  --CASE WHEN ROW_NUMBER() OVER(Partition by sono,line_no, plpricelnk Order by orderdate)=1 Then extendedFC ELSE CAST(0.00 as Numeric(20,2)) END AS itemExtFC, 
							  --t1.dscextFC/100 as dscextFC,extendedFC-dscextFC/100 as subtotal2FC,	--04/21/2016 DRP:  removed all of the Pricing fields
							  CASE WHEN ROW_NUMBER() OVER(Partition by sono Order by orderdate)=1 Then soextendFC ELSE CAST(0.00 as Numeric(20,2)) END AS SOEXTENDEDFC,
							  CASE WHEN ROW_NUMBER() OVER(Partition by sono Order by orderdate)=1 Then soptaxFC ELSE CAST(0.00 as Numeric(20,2)) END AS soptaxFC,
							  CASE WHEN ROW_NUMBER() OVER(Partition by sono Order by orderdate)=1 Then sostaxFC ELSE CAST(0.00 as Numeric(20,2)) END AS sostaxFC,
			--DRP 03/20/2013:  If item was marked as taxable but no tax records existed for that customer a null value would be returned instead of 0.00.  Implemented the isnull(t1.shiptax,0.00) below to address that issue. 
							  --isnull(t1.shiptaxFC,0.00) as shiptaxFC	--04/21/2016 DRP:  removed all of the Pricing fields
							-- 10/05/16 VL added Transaction, Functional and Presentation symbol
							  t1.TSymbol, t1.FSymbol, t1.PSymbol
						--10/07/16 DRP:  Added the values for Presentation
							  ,t1.discountPR,
							  CASE WHEN ROW_NUMBER() OVER(Partition by sono Order by orderdate)=1 Then soextendPR ELSE CAST(0.00 as Numeric(20,2)) END AS SOEXTENDEDPR,
							  CASE WHEN ROW_NUMBER() OVER(Partition by sono Order by orderdate)=1 Then soptaxPR ELSE CAST(0.00 as Numeric(20,2)) END AS soptaxPR,
							  CASE WHEN ROW_NUMBER() OVER(Partition by sono Order by orderdate)=1 Then sostaxPR ELSE CAST(0.00 as Numeric(20,2)) END AS sostaxPR	  
							  
							  
							  ,t1.ShipToCount
							--,t1.recordtype	--04/21/2016 DRP:  removed all of the Pricing fields
							,t1.PTaxId, t1.STaxID
							-- 12/04/19 VL removed tax_rate because removed st1
							--,t1.TAX_RATE		--04/21/2016 DRP:  Added
							,hs1.shipto as HeaderShipTo
							,rtrim(hs1.Address1)+case when hs1.address2<> '' then char(13)+char(10)+rtrim(hs1.address2) else '' end+
							  case when hs1.address3<> '' then char(13)+char(10)+rtrim(hs1.address3) else '' end+
							  case when hs1.address4<> '' then char(13)+char(10)+rtrim(hs1.address4) else '' end+
								CASE WHEN hs1.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(hs1.City)+',  '+rtrim(hs1.State)+'      '+RTRIM(hs1.zip)  ELSE '' END +
								CASE WHEN hs1.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(hs1.Country) ELSE '' end+
								case when hs1.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(hs1.PHONE) else '' end+
								case when hs1.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(hs1.FAX) else '' end  as HeaderShipToAddress
								,t1.SALEDSCTID,t1.DiscRate	--06/16/17 DRP:  Added
							
							
		from(
		SELECT     TOP (100) PERCENT c1.CUSTNO, c1.CUSTNAME,s1.blinkadd,sd1.slinkadd,s1.SOAMTDSCT as Discount
								--, case when c1.saledsctid = '' then cast(0.00 as numeric (12,2)) else sdc1.discount end as discount
								, s1.PONO, s1.ORDERDATE, s1.SONO,s1.SHIPNO, s1.TERMS, sd1.FOB, sd1.SHIPVIA, sd1.LINE_NO, sd1.UNIQUELN, 
							  case when @lcPartSrc = 'Internal' then i1.part_no when @lcPartSrc = 'Consigned' and i2.int_uniq IS NULL then i1.part_no else i2.custpartno end as Part_no,
							  case when @lcPartSrc = 'Internal' then i1.revision when @lcPartSrc = 'Consigned' and i2.int_uniq IS NULL then i1.revision else i2.custrev end as Rev,
							  i1.PART_CLASS, i1.PART_TYPE, i1.DESCRIPT, sd1.UOFMEAS
							  --,sp1.plpricelnk,sp1.descriptio, sp1.QUANTITY, sp1.PRICE, sp1.EXTENDED,
							  --case when sp1.quantity < 0.00 then cast(0.00 as numeric(12,2)) when c1.saledsctid = '' then cast(0.00 as numeric (12,2)) else sp1.extended*sdc1.discount end as dscext, 
							  --sp1.TAXABLE, sp1.FLAT	--04/21/2016 DRP:  removed all of the Pricing fields
							  , sd1.NOTE,s1.soextend, s1.soptax,s1.sostax,
							  --case when sp1.taxable = '1' and sb1.foreigntax <> '1' then cast (st1.tax_rate*sp1.extended/100 as numeric (12,2)) else cast (0.00 as numeric (12,2)) end as ShipTax,	--04/21/2016 DRP:  removed all of the Pricing fields							  
							  s1.sonote,s1.sofoot,s1.ord_type, s1.is_rma, cc1.LASTNAME as buyerlast, cc1.FIRSTNAME as buyerfirst, 
							  sb1.shipto as ShipTo
							  ,rtrim(sb1.Address1)+case when sb1.address2<> '' then char(13)+char(10)+rtrim(sb1.address2) else '' end+
						  -- 03/31/16 VL added Address3 and 4
							  case when sb1.address3<> '' then char(13)+char(10)+rtrim(sb1.address3) else '' end+
							  case when sb1.address4<> '' then char(13)+char(10)+rtrim(sb1.address4) else '' end+
								CASE WHEN sb1.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(sb1.City)+',  '+rtrim(sb1.State)+'      '+RTRIM(sb1.zip)  ELSE '' END +
								CASE WHEN sb1.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(sb1.Country) ELSE '' end+
								case when sb1.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(sb1.PHONE) else '' end+
								case when sb1.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(sb1.FAX) else '' end  as ShipToAddress
			--DRP 03/20/2013:  REPLACED BY ABOVE SupplierAddress.  Place all of the info below into one single Memo field. 		
							  --, sb1.ADDRESS1 as S_Add1, sb1.ADDRESS2 as S_Add2, sb1.CITY as S_city,sb1.STATE as S_State,sb1.ZIP as S_zip, 
							  --sb1.COUNTRY as S_country
							  -- 12/04/19 VL removed ForeignTax field, now no US tax and ForignTax difference in cube
							  --,sb1.FOREIGNTAX
							  ,sb1.BILLACOUNT
							  , sb2.SHIPTO as BillTo
							   ,rtrim(sb2.Address1)+case when sb2.address2<> '' then char(13)+char(10)+rtrim(sb2.address2) else '' end+
							   -- 03/31/16 VL added Address3 and 4
							   case when sb2.address3<> '' then char(13)+char(10)+rtrim(sb2.address3) else '' end+
							   case when sb2.address4<> '' then char(13)+char(10)+rtrim(sb2.address4) else '' end+
								CASE WHEN sb2.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(sb2.City)+',  '+rtrim(sb2.State)+'      '+RTRIM(sb2.zip)  ELSE '' END +
								CASE WHEN sb2.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(sb2.Country) ELSE '' end+
								case when sb2.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(sb2.PHONE) else '' end+
								case when sb2.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(sb2.FAX) else '' end  as BillToAddress
			--DRP 03/20/2013:  REPLACED BY ABOVE SupplierAddress.  Place all of the info below into one single Memo field. 		
							  --, sb2.ADDRESS1 as B_Add1, sb2.ADDRESS2 as B_Add2, sb2.CITY as B_City, 
							  --sb2.STATE as B_State, sb2.ZIP as B_Zip, sb2.COUNTRY as B_Country
							  ,sd1.STATUS
			--DRP 03/20/2013:  ADDED MICSSYS LICENSE INFO TO THE PROCEDURE, instead of pulling it as a separate table on the reports. 	
							 -- ,micssys.lic_name,rtrim(MICSSYS.LADDRESS1)+case when MICSSYS.LADDRESS2<> '' then char(13)+char(10)+rtrim(MICSSYS.laddress2) else '' end+
								--CASE WHEN MICSSYS.LCITY<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(MICSSYS.LCITY)+',  '+rtrim(MICSSYS.lState)+'      '+RTRIM(MICSSYS.lzip)  ELSE '' END ++
								--CASE WHEN MICSSYS.LCOUNTRY<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(MICSSYS.LCOUNTRY) ELSE '' END+
								--case when micssys.LPHONE <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(MICSSYS.LPHONE) else '' end+
								--case when micssys.LFAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(micssys.LFAX) else '' end  as LicAddress
							  --,micssys.AKSTD_FOOT,micssys.RMA_FOOT,micssys.field149
							  ,c1.SALEDSCTID
							  ,SOAMTDSCTFC as DiscountFC
							  --, sp1.PRICEFC, sp1.EXTENDEDFC,			--04/21/2016 DRP:  removed all of the Pricing fields
							  --case when sp1.quantity < 0.00 then cast(0.00 as numeric(12,2)) when c1.saledsctid = '' then cast(0.00 as numeric (12,2)) else sp1.extendedFC*sdc1.discount end as dscextFC,	--04/21/2016 DRP:  removed all of the Pricing fields   
		                      ,s1.soextendFC, s1.soptaxFC,s1.sostaxFC
							  --case when sp1.taxable = '1' and sb1.foreigntax <> '1' then cast (st1.tax_rate*sp1.extendedFC/100 as numeric (12,2)) else cast (0.00 as numeric (12,2)) end as ShipTaxFC	--04/21/2016 DRP:  removed all of the Pricing fields
							-- 10/07/16 VL added Transaction, Functional and Presentation symbol
							  ,TF.Symbol AS TSymbol, FF.Symbol AS FSymbol, PF.Symbol AS PSymbol

						--10/07/16 DRP:  added the Presentation Values
							   ,SOAMTDSCTPR as DiscountPR,s1.SOEXTENDPR, s1.soptaxPR,s1.sostaxPR

							,sc.ShipToCount,@lcShipTo as HeaderShipTo
							--,sp1.recordtype	--04/21/2016 DRP:  removed all of the Pricing fields
							,@PTaxId AS PTaxId, @STaxId AS STaxID
							-- 12/04/19 VL removed st1 field
							--,st1.TAX_RATE		--04/21/2016 DRP:  Added
							 ,sdc1.DISCOUNT as DiscRate	--06/16/17 DRP:  added

							-- 03/31/16 VL added to join Fcused and Somain		 
				FROM         dbo.CUSTOMER as c1 INNER JOIN
							  dbo.SOMAIN as s1 ON c1.CUSTNO = s1.CUSTNO INNER JOIN 
							  -- 10/07/16  VL added Fcused 3 times to get 3 currencies
							  dbo.Fcused TF ON s1.Fcused_uniq = TF.Fcused_uniq INNER JOIN
							  dbo.Fcused FF ON s1.FUNCFCUSED_UNIQ = FF.Fcused_uniq INNER JOIN
							  dbo.Fcused PF ON s1.PRFcused_uniq = PF.Fcused_uniq INNER JOIN 
							  dbo.SODETAIL as sd1 ON s1.SONO = sd1.SONO LEFT OUTER JOIN
							  --dbo.SOPRICES as sp1 ON sd1.UNIQUELN = sp1.UNIQUELN LEFT OUTER JOIN	--04/21/2016 DRP:  removed all of the Pricing fields
							  dbo.INVENTOR as i1 ON sd1.UNIQ_KEY = i1.UNIQ_KEY left outer join
--10/21/2013 DRP:  I needed to add the "and i2.CUSTNO = plmain.CUSTNO" whern i2 is joined otherwise I was getting every Customer Part number record that existed for the inventory part regardless which customer was selected for the Order. 				
							  --dbo.inventor as i2 on i2.int_uniq = i1.uniq_key left outer join
							  dbo.inventor as i2 on i2.int_uniq = i1.uniq_key and i2.CUSTNO = s1.CUSTNO left outer join
							  dbo.saledsct as sdc1 on sdc1.saledsctid = c1.saledsctid left outer join
							  dbo.CCONTACT as cc1 on cc1.CID = s1.BUYER left outer join
							  dbo.SHIPBILL as sb2 on s1.CUSTNO = sb2.CUSTNO and s1.blinkadd = sb2.LINKADD left outer join
							  dbo.SHIPBILL as sb1 ON s1.CUSTNO = sb1.CUSTNO AND sd1.SLINKADD = sb1.LINKADD
							  -- 12/04/19 VL comment out next line, don't calculate shiptax anymore, just use soptax and sostax
							  --left outer join SHIPTAX st1 on sd1.SLINKADD+'S' = st1.LINKADD +st1.taxtype
							  left outer join SALEDSCT on c1.SALEDSCTID = SALEDSCT.SALEDSCTID
							  cross join @ShipToCount as SC
							  --cross join micssys

							  
	--04/04/2013 DRP:  added code to filter out cancelled line items. 
		where		s1.sono = dbo.padl(@lcSoNo,10,'0')
					and sd1.STATUS <> 'Cancel'                     
		                       

		) t1 cross join dbo.shipbill as Hs1 where @lcShipTo = Hs1.LINKADD	--04/12/2016 DRP:  added for the HeaderShipTo information



		order by sono,shipto,line_no,slinkadd
	END -- End of FC installed
END