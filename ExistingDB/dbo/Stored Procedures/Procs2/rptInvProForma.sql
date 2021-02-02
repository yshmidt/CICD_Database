


-- =============================================
-- Author:		<Debbie> 
-- Create date: <02/14/2012>
-- Description:	<compiles details for the Pro-Forma Invoice>
-- Reports:     <used on invprfma.rpt>
-- Modified:	04/16/2012 DRP: found that if there was a large number of misc items added to the packing list that exceeded 10 that it would then begin not sorting them as desired. 
--				10/05/2012 DRP:  Found that if the users did not have a Shipping address selected that it would not pull the packing List detail forward at all.
--								 Change the Inner Join to Outer Join
--				08/26/13 YS   changed attn to varchar(200), increased length of the ccontact fields.
--				01/15/2014 DRP:  added the @userid parameter for WebManex
--				02/12/2016 VL:	 Added FC code
--				04/08/2016 VL:   Added TCurrency (Transaction Currency) and FCurrency (Functional Currency) fields and address3 and 4, also changed to use one field for address 
--								 Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--				08/11/16 DRP:	combined the individual address fields into one.  noticed that the grouped address fields were only applied to the non-FC section 
--				01/19/17  VL:   Added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[rptInvProForma] 
	@lcPackListNo char(10) = ' '
	,@userId uniqueidentifier=null
as
BEGIN

-- 02/12/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
-- 04/08/16 VL added TAx I
DECLARE @PTaxID char(8), @STaxID char(8)
SELECT @PTaxId = ISNULL((SELECT TOP 1 Tax_id FROM PLPRICESTAX WHERE Packlistno = @lcPacklistno AND TaxType = 'P' ORDER BY Tax_id), SPACE(8))
SELECT @STaxId = ISNULL((SELECT TOP 1 Tax_id FROM PLPRICESTAX WHERE Packlistno = @lcPacklistno AND TaxType = 'S' ORDER BY Tax_id), SPACE(8))

BEGIN
IF @lFCInstalled = 0
	BEGIN
	-- 04/08/16 VL remove ShipAdd1 char(40),ShipAdd2 char(40),ShipAdd3 char(40),ShipAdd4 char(40),BillAdd1 char(40),BillAdd2 char(40),BillAdd3 char(40),BillAdd4 char(40), and use one field ShipToaddress, BillToAddress Text to save all address line like PO form
	-- 04/08/16 VL added PTaxId char(8) and STaxId char(8)
	select	t1.packlistno,t1.CUSTNO, t1.CUSTNAME,T1.SONO,T1.PONO,T1.ORDERDATE,T1.TERMS,t1.Line_No,t1.sortby,t1.Uniq_key,PartNO,Rev,Descript,CustPartNo,CustRev,CDescript
			,t1.UOFMEAS,t1.SHIPPEDQTY,t1.NOTE,t1.PLPRICELNK,t1.pDesc,t1.QUANTITY,t1.PRICE,t1.EXTENDED,t1.TAXABLE,t1.FLAT,t1.RecordType,totexten AS TotalExt
			,dsctamt,TOTTAXE AS TotalTaxExt,FreightAmt,TOTTAXF AS FreightTaxAmt,PTax,STax,InvTotal,Attn,FOREIGNTAX,SHIPTO,ShipToAddress
			,BillTo,BilltoAddress,FOB,SHIPVIA,BILLACOUNT,WAYBILL,IsRMA,PTaxId, STaxID			
		
	--04/16/2012 DRP:	found that if there was a large number of misc items added to the packing list that exceeded 10 that it would then begin not sorting them as desired. 
	--					added the sortby field below to address this situation. 
		
	From	(
			select TOP (100) PERCENT	plmain.PACKLISTNO,PLMAIN.CUSTNO,CUSTNAME,PLMAIN.SONO,SOMAIN.PONO,SOMAIN.ORDERDATE,PLMAIN.TERMS
					,ISNULL(cast(sodetail.line_no as CHAR (10)),cast(PLDETAIL.uniqueln as CHAR (10))) as Line_No
					,ISNULL(sodetail.line_no,'X'+dbo.padl(rtrim(substring(pldetail.uniqueln,2,6)),6,'0')) as sortby
					,isnull(sodetail.uniq_key,space(10))as Uniq_key
					,isnull(inventor.PART_NO,SPACE(25)) as PartNO,ISNULL(inventor.revision,space(8)) as Rev,ISNULL(cast(inventor.descript as CHAR(45)),CAST(pldetail.cdescr as CHAR(45))) as Descript
					,ISNULL(i2.custpartno,SPACE(25)) as CustPartNo,ISNULL(i2.custrev,space(8)) as CustRev, ISNULL(cast(i2.DESCRIPT as CHAR (45)),cast (pldetail.cdescr as CHAR(45))) as CDescript
					,PLDETAIL.UOFMEAS,pldetail.SHIPPEDQTY,pldetail.NOTE,plp.PLPRICELNK,plp.DESCRIPT AS pDesc,plp.QUANTITY,plp.PRICE,plp.EXTENDED
					,case when plp.TAXABLE = 1 then CAST('Y' as CHAR(1)) else CAST('' as CHAR(1)) end as Taxable,plp.FLAT,plp.RECORDTYPE,plmain.TOTEXTEN,plmain.dsctamt
					,plmain.tottaxe,plmain.FREIGHTAMT,plmain.TOTTAXF,plmain.PTAX,plmain.STAX,plmain.INVTOTAL
					,isnull(cast (rtrim(ccontact.LASTNAME) + ', ' + RTRIM(ccontact.FIRSTNAME) as varCHAR (200)),cast('' as varCHAR(200))) as Attn
					,S.FOREIGNTAX,s.SHIPTO
					-- 04/08/16 VL: change shipadd1,shipadd2, shipadd3, shipadd4 into ShipToAddress one field
					--,s.ADDRESS1 as ShipAdd1,case when s.ADDRESS2 = '' then RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) else s.address2 end as ShipAdd2
					--,case when s.address2 = '' then s.country else RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) end as ShipAdd3
					--,case when s.address2 <> '' then s.country else '' end as ShipAdd4
					-- 04/08/16 VL changed to use one field
					,rtrim(s.Address1)+case when s.address2<> '' then char(13)+char(10)+rtrim(s.address2) else '' end+
					case when s.address3<> '' then char(13)+char(10)+rtrim(s.ADDRESS3) else '' end+
					case when s.address4<> '' then char(13)+char(10)+rtrim(s.address4) else '' end+
						CASE WHEN s.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.City)+',  '+rtrim(s.State)+'      '+RTRIM(s.zip)  ELSE '' END +
						CASE WHEN s.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.Country) ELSE '' end+
						case when s.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(s.PHONE) else '' end+
						case when s.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(s.FAX) else '' end  as ShipToAddress
					-- 04/08/16 VL End
					,s.PKFOOTNOTE
					,b.SHIPTO as BillTo
					-- 04/08/16 VL changed to use one field
					--,b.ADDRESS1 as BillAdd1,case when b.ADDRESS2 = '' then RTRIM(b.city) + ',  '+RTRIM(B.state)+'     '+RTRIM(b.zip) else b.address2 end as BillAdd2
					--,case when b.address2 = '' then b.country else RTRIM(b.city) + ',  '+RTRIM(b.state)+'     '+RTRIM(b.zip) end as BillAdd3
					--,case when b.address2 <> '' then b.country else '' end as BillAdd4
					-- 04/07/16 VL changed to use one field
					,rtrim(b.Address1)+case when b.address2<> '' then char(13)+char(10)+rtrim(b.address2) else '' end+
					case when b.address3<> '' then char(13)+char(10)+rtrim(b.ADDRESS3) else '' end+
					case when b.address4<> '' then char(13)+char(10)+rtrim(b.address4) else '' end+
						CASE WHEN b.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(b.City)+',  '+rtrim(b.State)+'      '+RTRIM(b.zip)  ELSE '' END +
						CASE WHEN b.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(b.Country) ELSE '' end+
						case when b.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(b.PHONE) else '' end+
						case when b.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(b.FAX) else '' end  as BillToAddress
					-- 04/08/16 VL End
					,plmain.FOB,plmain.SHIPVIA,plmain.BILLACOUNT,plmain.WAYBILL,case when somain.IS_RMA = 1 then 'RMA' else '' end as IsRMA
					-- 04/08/16 VL added PTaxId char(8) and STaxId char(8)
					,@PTaxId AS PTaxId, @STaxId AS STaxID							
				
					from	PLMAIN
					inner join CUSTOMER on plmain.CUSTNO = customer.CUSTNO
					LEFT OUTER JOIN SOMAIN ON PLMAIN.SONO = SOMAIN.SONO
					left outer join PLDETAIL on plmain.PACKLISTNO = pldetail.PACKLISTNO
					left outer join SODETAIL on pldetail.UNIQUELN = sodetail.UNIQUELN
					left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY
					left outer join INVENTOR as i2 on inventor.UNIQ_KEY = i2.INT_UNIQ
					left outer join CCONTACT on plmain.attention = ccontact.cid
					left outer join SHIPBILL as S on plmain.LINKADD = s.LINKADD
					left outer join SHIPBILL as B on Plmain.BLINKADD = B.LINKADD and plmain.CUSTNO = b.CUSTNO				
					left outer join PLPRICES as plp on PLDETAIL.UNIQUELN = PLP.UNIQUELN and pldetail.PACKLISTNO = plp.PACKLISTNO

				
					where plmain.PACKLISTNO = dbo.padl(@lcPackListNo,10,'0')
		
		      
			) 
			t1
	END
ELSE
-- FC installed
	BEGIN
	-- 01/19/17 VL comment out code that getting home currency, will get 3 currency symbols in SQL statement
	-- 04/01/16 VL realized that I need to add HC (Functional currency later)
	--DECLARE @FCurrency char(3) = ''
	-- 04/08/16 VL changed to use function
	--SELECT @FCurrency = Symbol FROM Fcused WHERE Fcused_uniq = dbo.fn_GetHomeCurrency()

	select	t1.packlistno,t1.CUSTNO, t1.CUSTNAME,T1.SONO,T1.PONO,T1.ORDERDATE,T1.TERMS,t1.Line_No,t1.sortby,t1.Uniq_key,PartNO,Rev,Descript,CustPartNo,CustRev,CDescript
			,t1.UOFMEAS,t1.SHIPPEDQTY,t1.NOTE,t1.PLPRICELNK,t1.pDesc,t1.QUANTITY,t1.PRICE,t1.EXTENDED,t1.TAXABLE,t1.FLAT,t1.RecordType,totexten AS TotalExt
			,dsctamt,TOTTAXE AS TotalTaxExt,FreightAmt,TOTTAXF AS FreightTaxAmt,PTax,STax,InvTotal,Attn,FOREIGNTAX,SHIPTO,ShipToAddress
			,BillTo,BillToAddress,FOB,SHIPVIA,BILLACOUNT,WAYBILL,IsRMA
			,t1.PRICEFC,t1.EXTENDEDFC,totextenFC AS TotalExtFC,dsctamtFC,TOTTAXEFC AS TotalTaxExtFC,FreightAmtFC,TOTTAXFFC AS FreightTaxAmtFC,PTaxFC,STaxFC,InvTotalFC
			--,TCurrency, FCurrency,PTaxId, STaxId,
			,t1.PRICEPR,t1.EXTENDEDPR,totextenPR AS TotalExtPR,dsctamtPR,TOTTAXEPR AS TotalTaxExtPR,FreightAmtPR,TOTTAXFPR AS FreightTaxAmtPR,PTaxPR,STaxPR,InvTotalPR
			,TSymbol, PSymbol, FSymbol, PTaxId, STaxId
		
	--04/16/2012 DRP:	found that if there was a large number of misc items added to the packing list that exceeded 10 that it would then begin not sorting them as desired. 
	--					added the sortby field below to address this situation. 
		
	From	(
			select TOP (100) PERCENT	plmain.PACKLISTNO,PLMAIN.CUSTNO,CUSTNAME,PLMAIN.SONO,SOMAIN.PONO,SOMAIN.ORDERDATE,PLMAIN.TERMS
					,ISNULL(cast(sodetail.line_no as CHAR (10)),cast(PLDETAIL.uniqueln as CHAR (10))) as Line_No
					,ISNULL(sodetail.line_no,'X'+dbo.padl(rtrim(substring(pldetail.uniqueln,2,6)),6,'0')) as sortby
					,isnull(sodetail.uniq_key,space(10))as Uniq_key
					,isnull(inventor.PART_NO,SPACE(25)) as PartNO,ISNULL(inventor.revision,space(8)) as Rev,ISNULL(cast(inventor.descript as CHAR(45)),CAST(pldetail.cdescr as CHAR(45))) as Descript
					,ISNULL(i2.custpartno,SPACE(25)) as CustPartNo,ISNULL(i2.custrev,space(8)) as CustRev, ISNULL(cast(i2.DESCRIPT as CHAR (45)),cast (pldetail.cdescr as CHAR(45))) as CDescript
					,PLDETAIL.UOFMEAS,pldetail.SHIPPEDQTY,pldetail.NOTE,plp.PLPRICELNK,plp.DESCRIPT AS pDesc,plp.QUANTITY,plp.PRICE,plp.EXTENDED
					,case when plp.TAXABLE = 1 then CAST('Y' as CHAR(1)) else CAST('' as CHAR(1)) end as Taxable,plp.FLAT,plp.RECORDTYPE,plmain.TOTEXTEN,plmain.dsctamt
					,plmain.tottaxe,plmain.FREIGHTAMT,plmain.TOTTAXF,plmain.PTAX,plmain.STAX,plmain.INVTOTAL
					,isnull(cast (rtrim(ccontact.LASTNAME) + ', ' + RTRIM(ccontact.FIRSTNAME) as varCHAR (200)),cast('' as varCHAR(200))) as Attn
					,S.FOREIGNTAX,s.SHIPTO
					,rtrim(s.Address1)+case when s.address2<> '' then char(13)+char(10)+rtrim(s.address2) else '' end+
					case when s.address3<> '' then char(13)+char(10)+rtrim(s.ADDRESS3) else '' end+
					case when s.address4<> '' then char(13)+char(10)+rtrim(s.address4) else '' end+
						CASE WHEN s.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.City)+',  '+rtrim(s.State)+'      '+RTRIM(s.zip)  ELSE '' END +
						CASE WHEN s.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.Country) ELSE '' end+
						case when s.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(s.PHONE) else '' end+
						case when s.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(s.FAX) else '' end  as ShipToAddress	--08/11/16 DRP:  added
					,s.PKFOOTNOTE
					,b.SHIPTO as BillTo
					,rtrim(b.Address1)+case when b.address2<> '' then char(13)+char(10)+rtrim(b.address2) else '' end+
					case when b.address3<> '' then char(13)+char(10)+rtrim(b.ADDRESS3) else '' end+
					case when b.address4<> '' then char(13)+char(10)+rtrim(b.address4) else '' end+
						CASE WHEN b.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(b.City)+',  '+rtrim(b.State)+'      '+RTRIM(b.zip)  ELSE '' END +
						CASE WHEN b.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(b.Country) ELSE '' end+
						case when b.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(b.PHONE) else '' end+
						case when b.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(b.FAX) else '' end  as BillToAddress	--08/11/16 DRP:  added
					,plmain.FOB,plmain.SHIPVIA,plmain.BILLACOUNT,plmain.WAYBILL,case when somain.IS_RMA = 1 then 'RMA' else '' end as IsRMA
					-- 02/12/16 VL added FC fields
					,plp.PRICEFC,plp.EXTENDEDFC,plmain.TOTEXTENFC,plmain.dsctamtFC,plmain.tottaxeFC,plmain.FREIGHTAMTFC,plmain.TOTTAXFFC,plmain.PTAXFC
					,plmain.STAXFC,plmain.INVTOTALFC
					-- 01/19/17 VL added functional currency codes
					,plp.PRICEPR,plp.EXTENDEDPR,plmain.TOTEXTENPR,plmain.dsctamtPR,plmain.tottaxePR,plmain.FREIGHTAMTPR,plmain.TOTTAXFPR,plmain.PTAXPR
					,plmain.STAXPR,plmain.INVTOTALPR
					-- 01/19/17 VL changed currency symbols
					-- 04/08/16 VL added TCurrency and FCurrency, PTaxId, STaxId
					--,Fcused.Symbol AS TCurrency, @FCurrency AS FCurrency
					,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
					,@PTaxId AS PTaxId, @STaxId AS STaxID		
									
					from PLMAIN
					-- 01/19/17 VL changed criteria to get 3 currencies
					INNER JOIN Fcused PF ON plmain.PrFcused_uniq = PF.Fcused_uniq
					INNER JOIN Fcused FF ON plmain.FuncFcused_uniq = FF.Fcused_uniq			
					INNER JOIN Fcused TF ON plmain.Fcused_uniq = TF.Fcused_uniq
					inner join CUSTOMER on plmain.CUSTNO = customer.CUSTNO
					LEFT OUTER JOIN SOMAIN ON PLMAIN.SONO = SOMAIN.SONO
					left outer join PLDETAIL on plmain.PACKLISTNO = pldetail.PACKLISTNO
					left outer join SODETAIL on pldetail.UNIQUELN = sodetail.UNIQUELN
					left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY
					left outer join INVENTOR as i2 on inventor.UNIQ_KEY = i2.INT_UNIQ
					left outer join CCONTACT on plmain.attention = ccontact.cid
					left outer join SHIPBILL as S on plmain.LINKADD = s.LINKADD
					left outer join SHIPBILL as B on Plmain.BLINKADD = B.LINKADD and plmain.CUSTNO = b.CUSTNO				
					left outer join PLPRICES as plp on PLDETAIL.UNIQUELN = PLP.UNIQUELN and pldetail.PACKLISTNO = plp.PACKLISTNO

				
					where plmain.PACKLISTNO = dbo.padl(@lcPackListNo,10,'0')
		
		      
			) 
			t1
	END-- end of FC installed
END -- End of IF FC istalled
end