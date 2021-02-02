
-- =============================================
-- Author:			Debbie
-- Create date:		01/21/2013
-- Description:		Created for the Credit Memo Form
-- Reports:			cmform.rpt
-- Modifications:   02/04/2013 DRP: VFP used to store the foreign tax values in the Ptax and Stax fields.  But in SQL it has been changed so that it does not populate those two fields.
--  				So the INVSTDTX table has been added to the code to sum the values when the tax types = GST or PST and then populate the Ptax or Stax fields within this stored procedure 	
--  02/08/2013 DRP:	 User was experiencing truncated issue with one of their PackingList/invoice.  Upon investigation found that the ShipAdd3 was the field that was being truncated. 
--  				As a precaution I went through and updated all of the ShipAdd and BillAdd fields from whatever character it had before to char(40) and that addressed the issue.
--  08/26/2013 YS :  changed Attn to varchar(200), increased length of the ccontact fields.
--  10/29/2013 DRP:	Modified all of the address information to work as a Memo Fields as Yelena had suggested.
--  				upon request I also added the Case when cmtype = 'M' that the ShipToAddress then be blank.
--  				removed the Lic_name and Lic address info . . . going to use the GetCompanyAddress procedure instead.  
--  02/24/2014 DRP: Upon request we added the @lcDisShipTo parameter, When "No" the report will not display the Ship to information. 
--  03/31/2014 DRP: Added new parameter @lcReasonDisp.  This will allow the users to display the first line of the CM Reason, all of it or None. 
--  09/02/15 DRP:  Needed to change <<SET @lcCmNo='CM'+dbo.PADL(@lcCmNo ,8,'0')>> to check to see if the user or system happen to pass the 'CM' in the Credit memo number or not.  If not passed the new script will populate it, if passed then it will not populate wiht the CM.  
--  02/10/16 VL:   Added FC fields
--  04/01/16 VL:   Added TCurrency and FCurrency
--  04/08/16 VL:   Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--  01/18/17 VL:   added functional currency code
--  03/06/17 DRP:  Found duplicated results if the inventory part happen to have more than one Customer part# associated with the internal part.
--- 03/28/17 YS changed length of the part_no column from 25 to 35
--  06/01/17 DRP:  for some reason this procedure still did not have the @userId parameter.  Also implemented the /*CUSTOMER LIST*/
-- 07/16/18 VL changed custname from char(35) to char(50)
--	10/03/19 VL:   Changed if sodetail.line_no is null, then take from cmdetail for manual PK item
-- =============================================
CREATE PROCEDURE [dbo].[rptCreditMemoForm]
			
		 @lcCmNo char(10) = ''
		 ,@lcDisShipTo char(3) = 'No'				--02/24/2014 DRP:  Default value is 'No' = Do Not Display the Ship To, the user can change to 'Yes' if they wish to see the Ship To
		 ,@lcReasonDisp char(8) = 'Original'		--03/31/2014 DRP:  Original:  would only display the first line from the cmreason field
													--All:  would display all of the cmreason
													--None:  would display none
		, @userId uniqueidentifier= null			--06/01/17 DRP:  found that this procedure still did not have @userId Parameter added to it 

		as 
		begin	



/*CUSTOMER LIST*/		--06/01/17 DRP:  Added
	DECLARE  @tCustomer as tCustomer
		--DECLARE @Customer TABLE (custno char(10))`--10/28/15 DRP:  we declared this but never really used it. 
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer

			

	---08/26/13 YS   changed attn to varchar(200), increased length of the ccontact fields.
	-- 07/16/18 VL changed custname, sname from char(35) to char(50)
		declare @tresults table	(cmemono char(10),InvNo char(10),packlistno char(10),CUSTNO char(10), SNAME char(50),SONO char(10),PONO char(20),CmDate smalldatetime,INVDATE smalldatetime
										,ORDERDATE smalldatetime,TERMS char(15),Rmar_Foot text,Line_No char(10),sortby char(7),Uniq_key char(10),
										--- 03/28/17 YS changed length of the part_no column from 25 to 35
										PartNO char(35),Rev char(8),Descript char(50)
										,CustPartNo char(35),CustRev char(8),CDescript char(50),UOFMEAS char(4),CMQTY numeric (12,2),PLPRICELNK char(10),pDesc char(50),QUANTITY numeric (12,2)
										,PRICE numeric(12,5),EXTENDED numeric(12,2),TAXABLE char(1),FLAT char(1),RecordType char(1),TotalExt numeric(12,2),dsctamt numeric(12,2)
										,TotalTaxExt numeric(12,2),FreightAmt numeric(12,2),FreightTaxAmt numeric(12,2),PST_Tax numeric(12,2),PST_TaxH char(8),GST_Tax numeric(12,2)
										,GST_TaxH char(8),InvTotal numeric(12,2),Attn varchar(200),FOREIGNTAX bit,SHIPTO char(40),ShipToAddress varchar(max)
					--10/29/2013 DRP: REMOVED THE BELOW AND REPLACED IT WITH THE ABOVE SINGLE FIELD. 
										--,ShipAdd1 char(40),ShipAdd2 char(40),ShipAdd3 char(40),ShipAdd4 char(40)
										,pkfootnote text,BillTo Char(40),BillToAddress varchar(max)
					--10/29/2013 DRP: REMOVED THE BELOW AND REPLACED IT WITH THE ABOVE SINGLE FIELD. 
										--,BillAdd1 char(40),BillAdd2 char(40),BillAdd3 char(40),BillAdd4 char(40)
										,FOB char(15),SHIPVIA char(15),CMREASON text,WAYBILL char(20),Soreps varchar(max),Status char(10))
					--10/29/2013 DRP: REMOVED THE BELOW . . . and going to use the GetCompanyAddress procedure on the report instead. 
										--,crstd_foot text,lic_name char(40),LADD1 CHAR(35),LADD2 CHAR(35),LADD3 CHAR(35),LADD4 CHAR(35),LPHONE CHAR(20),LFAX CHAR(20)
										--,FIELD149 TEXT)						
											
		--02/10/16 VL created with FC fields, tried not to touch original code
		-- 04/01/16 VL added TCurrency and FCurrency
		-- 01/18/17 VL added functional currency code
		-- 07/16/18 VL changed custname, sname from char(35) to char(50)
		declare @tresultsFC table	(cmemono char(10),InvNo char(10),packlistno char(10),CUSTNO char(10), SNAME char(50),SONO char(10),PONO char(20),CmDate smalldatetime,INVDATE smalldatetime
										,ORDERDATE smalldatetime,TERMS char(15),Rmar_Foot text,Line_No char(10),sortby char(7),Uniq_key char(10),
										--- 03/28/17 YS changed length of the part_no column from 25 to 35
										PartNO char(35),Rev char(8),Descript char(50)
										,CustPartNo char(35),CustRev char(8),CDescript char(50),UOFMEAS char(4),CMQTY numeric (12,2),PLPRICELNK char(10),pDesc char(50),QUANTITY numeric (12,2)
										,PRICE numeric(12,5),EXTENDED numeric(12,2),TAXABLE char(1),FLAT char(1),RecordType char(1),TotalExt numeric(12,2),dsctamt numeric(12,2)
										,TotalTaxExt numeric(12,2),FreightAmt numeric(12,2),FreightTaxAmt numeric(12,2),PST_Tax numeric(12,2),PST_TaxH char(8),GST_Tax numeric(12,2)
										,GST_TaxH char(8),InvTotal numeric(12,2),Attn varchar(200),FOREIGNTAX bit,SHIPTO char(40),ShipToAddress varchar(max)
					--10/29/2013 DRP: REMOVED THE BELOW AND REPLACED IT WITH THE ABOVE SINGLE FIELD. 
										--,ShipAdd1 char(40),ShipAdd2 char(40),ShipAdd3 char(40),ShipAdd4 char(40)
										,pkfootnote text,BillTo Char(40),BillToAddress varchar(max)
					--10/29/2013 DRP: REMOVED THE BELOW AND REPLACED IT WITH THE ABOVE SINGLE FIELD. 
										--,BillAdd1 char(40),BillAdd2 char(40),BillAdd3 char(40),BillAdd4 char(40)
										,FOB char(15),SHIPVIA char(15),CMREASON text,WAYBILL char(20),Soreps varchar(max),Status char(10)
										-- 02/10/16 VL added FC fields
										,PRICEFC numeric(12,5),EXTENDEDFC numeric(12,2),TotalExtFC numeric(12,2),dsctamtFC numeric(12,2)
										,TotalTaxExtFC numeric(12,2),FreightAmtFC numeric(12,2),FreightTaxAmtFC numeric(12,2),PST_TaxFC numeric(12,2)
										,GST_TaxFC numeric(12,2),InvTotalFC numeric(12,2)
										-- 01/18/17 VL added functional currency code
										,PRICEPR numeric(12,5),EXTENDEDPR numeric(12,2),TotalExtPR numeric(12,2),dsctamtPR numeric(12,2)
										,TotalTaxExtPR numeric(12,2),FreightAmtPR numeric(12,2),FreightTaxAmtPR numeric(12,2),PST_TaxPR numeric(12,2)
										,GST_TaxPR numeric(12,2),InvTotalPR numeric(12,2)
										-- 01/18/17 VL changed label names and added presentation currency
										,TSymbol char(3), PSymbol char(3), FSymbol char(3))
					--10/29/2013 DRP: REMOVED THE BELOW . . . and going to use the GetCompanyAddress procedure on the report instead. 
										--,crstd_foot text,lic_name char(40),LADD1 CHAR(35),LADD2 CHAR(35),LADD3 CHAR(35),LADD4 CHAR(35),LPHONE CHAR(20),LFAX CHAR(20)
										--,FIELD149 TEXT)						

		--SET @lcCmNo='CM'+dbo.PADL(@lcCmNo ,8,'0')	--09/02/15 DRP:  replaced with the below.	
		if left(@lcCmNo,2) = 'CM'
			Begin
			SET @lcCmNo=dbo.PADL(@lcCmNo ,8,'0')		
			End
		else
			Begin
			SET @lcCmNo='CM'+dbo.PADL(@lcCmNo ,8,'0')
			End

		
-- 02/10/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0
-- FC not installed	
	BEGIN
			---08/26/13 YS   changed attn to varchar(200), increased length of the ccontact fields.
						;
			with	
			ZCmemo as (	select	cmmain.cmemono,CMMAIN.INVOICENO,CMMAIN.PACKLISTNO,CMMAIN.CUSTNO,CUSTNAME,cmMAIN.SONO,SOMAIN.PONO,cmmain.cmdate,cmmain.invdate,SOMAIN.ORDERDATE
							,CMMAIN.TERMS,CMMAIN.Rmar_Foot
							-- 10/03/19 VL changed if sodetail.line_no is null, then take from cmdetail for manual PK item
							--,case when cmmain.CMTYPE = 'M' then CAST('1' as CHAR(10)) else CAST (sodetail.LINE_NO as CHAR(10)) end as Line_no
							,case when cmmain.CMTYPE = 'M' then CAST('1' as CHAR(10)) else ISNULL(cast(sodetail.line_no as CHAR (10)),cast(Cmdetail.uniqueln as CHAR (10))) end as Line_no
							,ISNULL(sodetail.line_no,'X'+dbo.padl(rtrim(substring(cmdetail.uniqueln,2,6)),6,'0')) as sortby
							,isnull(sodetail.uniq_key,space(10))as Uniq_key
							,isnull(inventor.PART_NO,SPACE(35)) as PartNO,ISNULL(inventor.revision,space(8)) as Rev
							,ISNULL(cast(inventor.descript as CHAR(50)),CAST(cmdetail.cmdescr as CHAR(50))) as Descript
							,ISNULL(i2.custpartno,SPACE(35)) as CustPartNo,ISNULL(i2.custrev,space(8)) as CustRev, ISNULL(cast(i2.DESCRIPT as CHAR (50)),cast (cmdetail.cmdescr as CHAR(50))) as CDescript
							,CMDETAIL.UOFMEAS,cmdetail.CMQTY,cmp.PLPRICELNK,cmp.DESCRIPT AS pDesc,cmp.CMQUANTITY,cmp.cmPRICE,cmp.cmEXTENDED
							,case when cmp.TAXABLE = 1 then CAST('Y' as CHAR(1)) else CAST('' as CHAR(1)) end as Taxable
							,cmp.FLAT,cmp.RECORDTYPE,CMMAIN.CMTOTEXTEN AS TotalExt,cmmain.dsctamt,cmmain.tottaxe as TotalTaxExt,CMMAIN.cm_frt,CMMAIN.cm_frt_tax as FreightTaxAmt
							,isnull(-PST.PST_TAX,0.00)as PST_Tax,isnull(pst.TAX_ID,'') as PST_TaxH ,isnull(-GST.GST_TAX,0.00) as GST_tax,isnull(GST.TAX_ID,'') as GST_taxH
							,cmmain.cmTOTAL,isnull(cast (rtrim(ccontact.LASTNAME) + ', ' + RTRIM(ccontact.FIRSTNAME) as varCHAR (200)),cast('' as varCHAR(200))) as Attn
							,S.FOREIGNTAX
/*02/24/2014 DRP:			--,case when cmtype = 'M' then '' else s.SHIPTO end as SHIPTO*/
							,case when cmtype = 'M' OR @lcDisShipTo = 'No' then '' else s.SHIPTO end as SHIPTO
/*02/24/2014 DRP:			--,CASE WHEN CMTYPE = 'M' THEN '' ELSE rtrim(s.Address1)+case when s.address2<> '' then char(13)+char(10)+rtrim(s.address2) else '' end+
							--	CASE WHEN s.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.City)+',  '+rtrim(s.State)+'      '+RTRIM(s.zip)  ELSE '' END +
							--	CASE WHEN s.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.Country) ELSE '' end END   as ShipToAddress */
							,CASE WHEN CMTYPE = 'M' OR @lcDisShipTo = 'No' THEN '' ELSE rtrim(s.Address1)+case when s.address2<> '' then char(13)+char(10)+rtrim(s.address2) else '' end+
								CASE WHEN s.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.City)+',  '+rtrim(s.State)+'      '+RTRIM(s.zip)  ELSE '' END +
								CASE WHEN s.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.Country) ELSE '' end END   as ShipToAddress
		--10/29/2013  REPLACED BY ABOVE SupplierAddress.  Place all of the info below into one single Memo field.						
							--,s.ADDRESS1 as ShipAdd1,case when s.ADDRESS2 = '' then RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) else s.address2 end as ShipAdd2
							--,case when s.address2 = '' then s.country else RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) end as ShipAdd3
							--,case when s.address2 <> '' then s.country else '' end as ShipAdd4
							,s.PKFOOTNOTE,b.SHIPTO as BillTo
							, rtrim(b.Address1)+case when b.address2<> '' then char(13)+char(10)+rtrim(b.address2) else '' end+
								CASE WHEN b.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(b.City)+',  '+rtrim(b.State)+'      '+RTRIM(b.zip)  ELSE '' END +
								CASE WHEN b.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(b.Country) ELSE '' end  as BillToAddress
							--,b.ADDRESS1 as BillAdd1,case when b.ADDRESS2 = '' then RTRIM(b.city) + ',  '+RTRIM(B.state)+'     '+RTRIM(b.zip) else b.address2 end as BillAdd2
							--,case when b.address2 = '' then b.country else RTRIM(b.city) + ',  '+RTRIM(b.state)+'     '+RTRIM(b.zip) end as BillAdd3
							--,case when b.address2 <> '' then b.country else '' end as BillAdd4
							,cmmain.FOB,cmmain.SHIPVIA
/*03/31/2014 DRP:			--,cmmain.CMREASON */
							,case when CHARINDEX(char(13),cmreason)<>0 and @lcReasonDisp='Original' then substring(cmreason,1,CHARINDEX(char(13),cmreason)-1)
									WHEN  CHARINDEX(char(13),cmreason)=0 OR @lcReasonDisp='All' THEN cmreason 
										when @lcReasonDisp='None' then CAST('' as varchar(max)) end cmreason
							,cmmain.WayBill,dbo.FnSoRep(CMmain.sono) as Soreps ,cmmain.CSTATUS
		--10/29/2013  removed the Lic_name and Lic address info . . . going to use the GetCompanyAddress procedure instead.	
							--,micssys.CRSTD_FOOT,micssys.LIC_NAME,micssys.LADDRESS1,case when MICSSYS.LADDRESS2 = '' then RTRIM(MICSSYS.Lcity) + ',  '+RTRIM(MICSSYS.Lstate)+'     '+RTRIM(MICSSYS.Lzip) else MICSSYS.LADDRESS2 end as lAdd2
							--,case when MICSSYS.LADDRESS2 = '' then MICSSYS.LCOUNTRY else RTRIM(MICSSYS.LCITY) + ',  '+RTRIM(MICSSYS.Lstate)+'     '+RTRIM(MICSSYS.LZIP) end as lADD3
							--,case when MICSSYS.laddress2 <> '' then mICSSYS.LCOUNTRY else '' end as lAdd4,MICSSYS.LPHONE,MICSSYS.LFAX
							--,MICSSYS.FIELD149

										
							from	cmmain
							inner join CUSTOMER on CMMAIN.CUSTNO = customer.CUSTNO
							LEFT OUTER JOIN SOMAIN ON cmMAIN.SONO = SOMAIN.SONO
							left outer join cmDETAIL on CMMAIN.CMEMONO = cmdetail.CMEMONO
							left outer join SODETAIL on cmdetail.UNIQUELN = sodetail.UNIQUELN
							left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY
							left outer join INVENTOR as i2 on inventor.UNIQ_KEY = i2.INT_UNIQ and i2.custno = cmmain.custno	--03/06/17 DRP:  added <<and i2.custno = cmmain.custno
							left outer join CCONTACT on CMMAIN.attention = ccontact.cid
							left outer join SHIPBILL as S on CMMAIN.LINKADD = s.LINKADD
							left outer join SHIPBILL as B on CMMAIN.BLINKADD = B.LINKADD and cmmain.CUSTNO = b.CUSTNO				
							left outer join CMPRICES as cmp on CMDETAIL.CMPRICELNK = cmp.CMPRICELNK and CMDETAIL.cmemono = cmp.CMEMONO
							left outer join SOPRSREP on cmDETAIL.UNIQUELN = soprsrep.UNIQUELN
							left outer join (select INVSTDTX.INVOICENO,invstdtx.TAX_ID,SUM(INVSTDTX.Tax_amt) as PST_Tax from INVSTDTX 
											 where	invstdtx.invoiceno =@lcCmNo
													and invstdtx.TXTYPEFORN = 'E'
											 group by INVOICENO,TAX_ID) as PST on cmmain.CMEMONO = PST.invoiceNo
							left outer join (select invstdtx.invoiceno,invstdtx.TAX_ID,SUM(invstdtx.tax_amt) as GST_Tax from INVSTDTX
											 where	invstdtx.INVOICENO = @lcCmNo
													and INVSTDTX.TXTYPEFORN = 'P'
											 group by INVOICENO,TAX_ID) as GST on Cmmain.CMEMONO = GST.invoiceNo
												
	--10/29/2013: removed	--cross join MICSSYS

							where cmmain.CMEMONO =@lcCmNo
							and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno)	--06/01/17 DRP:  added
					
					)  

		INSERT @tResults
				select * from ZCmemo

		select * from @tresults
	END
ELSE
-- FC installed
	BEGIN
	-- 04/01/16 VL realized that I need to add HC (Functional currency later)
			-- 01/18/17 VL comment out getting @FCurrency code will get in SQL statement
			--DECLARE @FCurrency char(3) = ''
			-- 04/08/16 VL changed to use function
			--SELECT @FCurrency = Symbol FROM Fcused WHERE Fcused_uniq = dbo.fn_GetHomeCurrency()
			---08/26/13 YS   changed attn to varchar(200), increased length of the ccontact fields.
			;with	
			ZCmemo as (	select	cmmain.cmemono,CMMAIN.INVOICENO,CMMAIN.PACKLISTNO,CMMAIN.CUSTNO,CUSTNAME,cmMAIN.SONO,SOMAIN.PONO,cmmain.cmdate,cmmain.invdate,SOMAIN.ORDERDATE
							,CMMAIN.TERMS,CMMAIN.Rmar_Foot
							-- 10/03/19 VL changed if sodetail.line_no is null, then take from cmdetail for manual PK item
							--,case when cmmain.CMTYPE = 'M' then CAST('1' as CHAR(10)) else CAST (sodetail.LINE_NO as CHAR(10)) end as Line_no
							,case when cmmain.CMTYPE = 'M' then CAST('1' as CHAR(10)) else ISNULL(cast(sodetail.line_no as CHAR (10)),cast(Cmdetail.uniqueln as CHAR (10))) end as Line_no							
							,ISNULL(sodetail.line_no,'X'+dbo.padl(rtrim(substring(cmdetail.uniqueln,2,6)),6,'0')) as sortby
							,isnull(sodetail.uniq_key,space(10))as Uniq_key
							,isnull(inventor.PART_NO,SPACE(35)) as PartNO,ISNULL(inventor.revision,space(8)) as Rev
							,ISNULL(cast(inventor.descript as CHAR(50)),CAST(cmdetail.cmdescr as CHAR(50))) as Descript
							,ISNULL(i2.custpartno,SPACE(35)) as CustPartNo,ISNULL(i2.custrev,space(8)) as CustRev, ISNULL(cast(i2.DESCRIPT as CHAR (50)),cast (cmdetail.cmdescr as CHAR(50))) as CDescript
							,CMDETAIL.UOFMEAS,cmdetail.CMQTY,cmp.PLPRICELNK,cmp.DESCRIPT AS pDesc,cmp.CMQUANTITY,cmp.cmPRICE,cmp.cmEXTENDED
							,case when cmp.TAXABLE = 1 then CAST('Y' as CHAR(1)) else CAST('' as CHAR(1)) end as Taxable
							,cmp.FLAT,cmp.RECORDTYPE,CMMAIN.CMTOTEXTEN AS TotalExt,cmmain.dsctamt,cmmain.tottaxe as TotalTaxExt,CMMAIN.cm_frt,CMMAIN.cm_frt_tax as FreightTaxAmt
							,isnull(-PST.PST_TAX,0.00)as PST_Tax,isnull(pst.TAX_ID,'') as PST_TaxH ,isnull(-GST.GST_TAX,0.00) as GST_tax,isnull(GST.TAX_ID,'') as GST_taxH
							,cmmain.cmTOTAL,isnull(cast (rtrim(ccontact.LASTNAME) + ', ' + RTRIM(ccontact.FIRSTNAME) as varCHAR (200)),cast('' as varCHAR(200))) as Attn
							,S.FOREIGNTAX
/*02/24/2014 DRP:			--,case when cmtype = 'M' then '' else s.SHIPTO end as SHIPTO*/
							,case when cmtype = 'M' OR @lcDisShipTo = 'No' then '' else s.SHIPTO end as SHIPTO
/*02/24/2014 DRP:			--,CASE WHEN CMTYPE = 'M' THEN '' ELSE rtrim(s.Address1)+case when s.address2<> '' then char(13)+char(10)+rtrim(s.address2) else '' end+
							--	CASE WHEN s.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.City)+',  '+rtrim(s.State)+'      '+RTRIM(s.zip)  ELSE '' END +
							--	CASE WHEN s.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.Country) ELSE '' end END   as ShipToAddress */
							,CASE WHEN CMTYPE = 'M' OR @lcDisShipTo = 'No' THEN '' ELSE rtrim(s.Address1)+case when s.address2<> '' then char(13)+char(10)+rtrim(s.address2) else '' end+
								CASE WHEN s.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.City)+',  '+rtrim(s.State)+'      '+RTRIM(s.zip)  ELSE '' END +
								CASE WHEN s.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.Country) ELSE '' end END   as ShipToAddress
		--10/29/2013  REPLACED BY ABOVE SupplierAddress.  Place all of the info below into one single Memo field.						
							--,s.ADDRESS1 as ShipAdd1,case when s.ADDRESS2 = '' then RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) else s.address2 end as ShipAdd2
							--,case when s.address2 = '' then s.country else RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) end as ShipAdd3
							--,case when s.address2 <> '' then s.country else '' end as ShipAdd4
							,s.PKFOOTNOTE,b.SHIPTO as BillTo
							, rtrim(b.Address1)+case when b.address2<> '' then char(13)+char(10)+rtrim(b.address2) else '' end+
								CASE WHEN b.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(b.City)+',  '+rtrim(b.State)+'      '+RTRIM(b.zip)  ELSE '' END +
								CASE WHEN b.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(b.Country) ELSE '' end  as BillToAddress
							--,b.ADDRESS1 as BillAdd1,case when b.ADDRESS2 = '' then RTRIM(b.city) + ',  '+RTRIM(B.state)+'     '+RTRIM(b.zip) else b.address2 end as BillAdd2
							--,case when b.address2 = '' then b.country else RTRIM(b.city) + ',  '+RTRIM(b.state)+'     '+RTRIM(b.zip) end as BillAdd3
							--,case when b.address2 <> '' then b.country else '' end as BillAdd4
							,cmmain.FOB,cmmain.SHIPVIA
/*03/31/2014 DRP:			--,cmmain.CMREASON */
							,case when CHARINDEX(char(13),cmreason)<>0 and @lcReasonDisp='Original' then substring(cmreason,1,CHARINDEX(char(13),cmreason)-1)
									WHEN  CHARINDEX(char(13),cmreason)=0 OR @lcReasonDisp='All' THEN cmreason 
										when @lcReasonDisp='None' then CAST('' as varchar(max)) end cmreason
							,cmmain.WayBill,dbo.FnSoRep(CMmain.sono) as Soreps ,cmmain.CSTATUS
		--10/29/2013  removed the Lic_name and Lic address info . . . going to use the GetCompanyAddress procedure instead.	
							--,micssys.CRSTD_FOOT,micssys.LIC_NAME,micssys.LADDRESS1,case when MICSSYS.LADDRESS2 = '' then RTRIM(MICSSYS.Lcity) + ',  '+RTRIM(MICSSYS.Lstate)+'     '+RTRIM(MICSSYS.Lzip) else MICSSYS.LADDRESS2 end as lAdd2
							--,case when MICSSYS.LADDRESS2 = '' then MICSSYS.LCOUNTRY else RTRIM(MICSSYS.LCITY) + ',  '+RTRIM(MICSSYS.Lstate)+'     '+RTRIM(MICSSYS.LZIP) end as lADD3
							--,case when MICSSYS.laddress2 <> '' then mICSSYS.LCOUNTRY else '' end as lAdd4,MICSSYS.LPHONE,MICSSYS.LFAX
							--,MICSSYS.FIELD149
							-- 02/10/16 VL added FC fields
							,cmp.cmPRICEFC,cmp.cmEXTENDEDFC,CMMAIN.CMTOTEXTENFC AS TotalExtFC,cmmain.dsctamtFC,cmmain.tottaxeFC as TotalTaxExtFC,CMMAIN.cm_frtFC
							,CMMAIN.cm_frt_taxFC as FreightTaxAmtFC
							,isnull(-PST.PST_TAXFC,0.00)as PST_TaxFC,isnull(-GST.GST_TAXFC,0.00) as GST_taxFC,cmmain.cmTOTALFC
							-- 01/18/17 VL added functional currency code
							,cmp.cmPRICEPR,cmp.cmEXTENDEDPR,CMMAIN.CMTOTEXTENPR AS TotalExtPR,cmmain.dsctamtPR,cmmain.tottaxePR as TotalTaxExtPR,CMMAIN.cm_frtPR
							,CMMAIN.cm_frt_taxPR as FreightTaxAmtPR
							,isnull(-PST.PST_TAXPR,0.00)as PST_TaxPR,isnull(-GST.GST_TAXPR,0.00) as GST_taxPR,cmmain.cmTOTALPR
							-- 01/18/17 VL added Presentation currency
							-- 04/01/16 VL added TCurrency and FCurrency
							--,Fcused.Symbol AS TCurrency, @FCurrency AS FCurrency
							,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
							FROM Cmmain
							-- 01/18/17 VL changed criteria to get 3 currencies
							INNER JOIN Fcused PF ON Cmmain.PrFcused_uniq = PF.Fcused_uniq
							INNER JOIN Fcused FF ON Cmmain.FuncFcused_uniq = FF.Fcused_uniq			
							INNER JOIN Fcused TF ON Cmmain.Fcused_uniq = TF.Fcused_uniq
							inner join CUSTOMER on CMMAIN.CUSTNO = customer.CUSTNO
							LEFT OUTER JOIN SOMAIN ON cmMAIN.SONO = SOMAIN.SONO
							left outer join cmDETAIL on CMMAIN.CMEMONO = cmdetail.CMEMONO
							left outer join SODETAIL on cmdetail.UNIQUELN = sodetail.UNIQUELN
							left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY
							left outer join INVENTOR as i2 on inventor.UNIQ_KEY = i2.INT_UNIQ and i2.custno = cmmain.custno	--03/06/17 DRP:  added <<and i2.custno = cmmain.custno
							left outer join CCONTACT on CMMAIN.attention = ccontact.cid
							left outer join SHIPBILL as S on CMMAIN.LINKADD = s.LINKADD
							left outer join SHIPBILL as B on CMMAIN.BLINKADD = B.LINKADD and cmmain.CUSTNO = b.CUSTNO				
							left outer join CMPRICES as cmp on CMDETAIL.CMPRICELNK = cmp.CMPRICELNK and CMDETAIL.cmemono = cmp.CMEMONO
							left outer join SOPRSREP on cmDETAIL.UNIQUELN = soprsrep.UNIQUELN
							-- 01/18/17 VL added functional currency code
							left outer join (select INVSTDTX.INVOICENO,invstdtx.TAX_ID,SUM(INVSTDTX.Tax_amt) as PST_Tax, SUM(INVSTDTX.Tax_amtFC) as PST_TaxFC, SUM(INVSTDTX.Tax_amtPR) as PST_TaxPR from INVSTDTX 
											 where	invstdtx.invoiceno =@lcCmNo
													and invstdtx.TXTYPEFORN = 'E'
											 group by INVOICENO,TAX_ID) as PST on cmmain.CMEMONO = PST.invoiceNo
							-- 01/18/17 VL added functional currency code
							left outer join (select invstdtx.invoiceno,invstdtx.TAX_ID,SUM(invstdtx.tax_amt) as GST_Tax, SUM(invstdtx.tax_amtFC) as GST_TaxFC, SUM(invstdtx.tax_amtPR) as GST_TaxPR from INVSTDTX
											 where	invstdtx.INVOICENO = @lcCmNo
													and INVSTDTX.TXTYPEFORN = 'P'
											 group by INVOICENO,TAX_ID) as GST on Cmmain.CMEMONO = GST.invoiceNo
												
	--10/29/2013: removed	--cross join MICSSYS

							where cmmain.CMEMONO =@lcCmNo
							and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno)	--06/01/17 DRP:  added
					
					)  

		INSERT @tResultsFC
				select * from ZCmemo

		select * from @tresultsFC
	END
END
				--	code to just indicate if the invoice has been printed 
				UPDATE CMMAIN SET  IS_CMPRN = 1,INV_DUPL = 1 WHERE CMMAIN.CMEMONO = @lcCmNo
		end
			

		