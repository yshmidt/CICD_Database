			-- =============================================
			-- Author:		Debbie
			-- Create date: 02/29/2012
			-- Description:	This Stored Procedure was created for the Purchae Order Form
			-- Reports Using Stored Procedure:  po.rpt, po2.rpt
			-- Modifications:  DRP 07/16/2012:  removed the filter to not include Cancelled Po Items in the results so that if the users selects a Cancelled purchase order I will display the PO Header information and have the Status Cancelled showing in RED
			--									But the cancelled items themselves will still remove suppressed. 
			--				   DRP 11/06/2012:  Needed to change the @lcPoNo parameter to @lcPoNum so that it would work with the Report Option screen
			--				   DRP 11/16/2012:  made adjustments to the OrdQty below so that if the order is Closed that it will display the original order qty instead of the balance of 0.00
			--									Also had to make changes to the formula for the Extended field.  For Closed orders it will now calculated off of the org. Ord qty.
			--				   DRP 03/19/2013:  Modified all of the address information to work as a Memo Fields as Yelena had suggested. 
			--									also added the MICSSYS and PODEFLTS to this procedure instead of pulling it through the Cyrstal Report	
			--				   DRP 06/13/2013:  Added the ConfirmTo email address to the results because this is the email tha should be defaulted in for Emailing the PO forms.
			--				   01/15/2014 DRP:  added the @userid parameter for WebManex 
			--				   09/16/2014 DRP:	created fnMfgNotOnPo and used that to get the Mfgrs listed in one record
			--									removed this join that used to be used for MfgrNoOnPO, it has been replaced the the fnMfgNotOnPO
			--									removed MICSSYS information since we can get all of this information from the GetCompanyAddress
			--									changed the @lcAllItems from just 'Y' or 'N' to 'Yes' or 'No' so that I can use an existing parameter already available within the tables. 
			--									added a filter at the end of the ZPOInfo to removed the items with 0.00 balance if @lcAllItems = "No".  so we no longer have to do the filter on the report form 
			--									added a filter to remove cancelled items from the results
			--					09/22/2014 DRP: needed to add  "when POSTATUS = 'Closed' then 1 " in the where section to make sure that Closed PO's will properly display all items. 
			--					09/25/2014 DRP:	Added the Req_Date also added Alloc field that will display project or work order allocation for schedule with Require Date (po2)
			--					10/13/14   YS: removed invtmfhd table 
			--					12/02/2014 DRP: Needed to add a filter to the Support Table in order to make sure that I was only linking on the PART_CLASS. 
			--									Without the Filter users could get duplicated results which would display as duplicated schedules on the report. 
			--					04/22/2015 VL:  Added 'FirstinBatch' parameter default 1, if it's 1, delete last batch, will update pomain.isinbatch at the end of this SP to save new last batch
			--                  06/16/2015 AK: Changed datattype for @lcPoNum as varchar (max) from char(15) for multiple PO list and added code to store it in temp table
			--                  06/17/2015 YS: modifed some changes done by AK
			--					02/09/2016 VL: Added FC code
			--					03/31/2016 VL:	Added TCurrency (Transaction Currency) and FCurrency (Functional Currency) fields and address3 and 4
			--					04/08/2016 VL:	Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
			--					08/18/16 DRP:	Added UnitPriceFcNotRnd to the FC results upon request of a user. which will take the CostEachFC * Ord_qty and it will not round it. 
-- 06/20/17 VL changed fn_GetHomeCurrency to use fn_GetFunctionalCurrency
--08/01/17 YS moved part_class setup from "support" table to partClass table 
--08/01/17 YS removing quality spec from class setup
-- 02/18/20 VL added partmfgr full name because suppliers really don't have ideas what's the partmfgr code, request by Keltech
-- 04/09/20 VL Changed to use wmNoteRelationship and wmNotes
-- 06/02/20 VL Fixed inventory note and PO item note
-- 12/11/20 now the buyer is not saved in Pomain.Buyer linked to Buyerini, it's saved in Pomain.AspnetBuyer linked to aspnet_Users
-- 02/01/21 VL changed PoFooter to use wmNoteRelationship and wmNotes
			-- =============================================
			CREATE PROCEDURE [dbo].[rptPoForm]

				--@lcPoNum char(15) = ''
				 @lcPoNum as varchar (max) = null
				,@lcAllItems char (3) = 'No'	--With All Line Items and Schedule Qty's (Yes or No)
				,@userId uniqueidentifier= null
				,@firstinBatch bit = 1
			as 
			begin

			-- 04/22/15 added to clear out last PO print batch if @firstinBatch = 1
			IF @firstinBatch = 1
			BEGIN
				EXEC PoClearBatch
			END


   /* 06/16/2015 AK added code to store PO LIST in temp table */
   -- 06/17/2015 YS do not need 2 tables 
    DECLARE  @tPoNum as table (PoNum char (15))
	--declare @PoNum table(PoNum char(15))
	-- 06/17/2015 YS do not need 2 tables, move this code to if @lcPoNum='All'
	--insert into @tPoNum select ponum from pomain 
	
		IF @lcPoNum is not null and @lcPoNum <>'' and @lcPoNum<>'All'
			-- 06/17/2015 YS changed insert
			insert into @tPoNum select dbo.PADL(RTRIM(id),15,'0')  from dbo.[fn_simpleVarcharlistToTable](@lcPoNum,',')
					 
		ELSE

		IF  @lcPoNum='All'	
		BEGIN
			--INSERT INTO @PoNum SELECT PoNum FROM @tPoNum
			insert into @tPoNum select ponum from pomain 
		END

		-- 02/08/16 VL added for FC installed or not
		DECLARE @lFCInstalled bit
		-- 04/08/16 VL changed to get FC installed from function
		SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
		-- 02/08/16 VL added for FC installed or not
		if @lFCInstalled=0
		BEGIN
			--repopulates the parameter value to have the leading zero's, because we use it at the end to update the tables. 
			-- 06/17/2015 YS parameter is not used from this point on
			--SET @lcPoNum=dbo.PADL(@lcPoNum,15,'0')

			;
			with 
			ZPOInfo as	(
						SELECT	POMAIN.PONUM, PODATE, POSTATUS, CONUM, pomain.TERMS,pomain.FOB,pomain.SHIPVIA,POMAIN.UNIQSUPNO
						,UNIQLNNO,ITEMNO,poitems.poittype,POITEMS.UNIQ_KEY,case when poitems.uniq_key = '' then cast ('' as char(8))else inventor.PART_CLASS end as Part_class
						,case when poitems.uniq_key = '' then cast ('' as char(8)) else inventor.part_type end as PART_TYPE,CASE WHEN POITEMS.UNIQ_KEY = '' THEN POITEMS.PART_NO ELSE INVENTOR.PART_NO END AS PART_NO
						,case when poitems.UNIQ_KEY = '' then CAST ('' as CHAR(8)) else inventor.REVISION end as revision,case when poitems.UNIQ_KEY = '' then poitems.DESCRIPT else inventor.DESCRIPT end as DESCRIPT
						,poitems.uniqmfgrhd,poitems.PARTMFGR, poitems.MFGR_PT_NO, poitems.PACKAGE
						,case when (@lcAllItems = 'Yes' OR PoStatus = 'CLOSED' OR POITTYPE = 'In Store') then poitems.ORD_QTY else poitems.ORD_QTY-poitems.ACPT_QTY end as OrdQty
			--DRP 11/16/2012:  REPLACED BY ABOVE. --,case when @lcAllItems = 'Y' then poitems.ORD_QTY else poitems.ORD_QTY-poitems.ACPT_QTY end as OrdQty
						,poitems.ord_qty-poitems.acpt_qty as BalanceQty		
						,poitems.PUR_UOFM,poitems.COSTEACH
			--DRP 07/16/2012:  Added the following code so if a purcahse order is Cancelled and they run the report all of the items will be hidden but the purchase order header will display with Cancelled in the header. 
			--DRP 11/16/2012:  modified the code for the Extended field to calculate the Extended value in the case of a Closed Order
						,case when @lcAllItems = 'Yes' and LCANCEL <> 1 then ROUND(poitems.ord_qty*poitems.costeach,2)
								when @lcAllItems = 'Yes' and LCANCEL = 1 then 0.00
									when @lcAllItems = 'No' and LCANCEL <> 1 and pomain.POSTATUS<>'CLOSED' then round((poitems.ORD_QTY-poitems.ACPT_QTY)* poitems.COSTEACH,2)
										when @lcAllItems = 'No' and LCANCEL = 1 then 0.00
											when @lcAllItems = 'No' and Pomain.POSTATUS = 'CLOSED' then round(poitems.ord_qty*poitems.costeach,2) end as Extended
			--DRP 0/716/2012:  REPLACED BY ABOVE	--,case when @lcAllItems = 'Y' then ROUND(poitems.ord_qty*poitems.costeach,2) else round((poitems.ORD_QTY-poitems.ACPT_QTY)* poitems.COSTEACH,2) end as Extended
						,poitems.IS_TAX
						,pomain.SHIPCHG,case when IS_SCTAX = 1 then ROUND((pomain.sctaxpct*pomain.SHIPCHG)/100,2) else CAST(0.00 as numeric(20,2)) end as ShipTax
						---08/01/17 YS removing quality psec from class setup
						--,case when poitems.poittype <>'Invt Part' then cast ('' as char(10)) else cast(s1.TEXT4 as CHAR(10)) end as QualSpec
						,space(10) as QualSpec
						,case when poitems.POITTYPE<>'Invt Part' then CAST ('' as CHAR(10)) else CAST(m.matltype as CHAR(10)) end as MatlType
						,invtmfsp.SUPLPARTNO
						-- 04/09/20 VL Changed to use wmNoteRelationship and wmNotes
						--,poitems.NOTE1 AS ItemNote
						,ItemNote.Note AS ItemNote
						-- 06/02/20 VL changed to use wmNoteRelationShip and wmNotes
						--,inventor.INV_NOTE
						,InvtItemNote.Note AS INV_NOTE
						--,'MFgr: ' + rtrim(mfhd2.PARTMFGR) + ' MPN: '+ RTRIM(mfhd2.MFGR_PT_NO) + ' Matl Type: '+ rtrim(mfhd2.matltype) as MfgrNotOnPo	--09/16/2014 DRP:  created fnMfgNotOnPo and used that to get the Mfgrs listed in one record
						,isnull(dbo.fnMfgNotOnPo(poitems.uniqlnno),'') as MfgrNotOnPO 
						-- 02/01/21 VL changed to use wmNoteRelationship and wmNotes
						--,pomain.POFOOTER
						,PoFoot.Note AS POFOOTER
						,Sup1.SHIPTO as Sup, rtrim(sup1.Address1)+case when sup1.address2<> '' then char(13)+char(10)+rtrim(sup1.address2) else '' end+
						-- 03/31/16 VL added address3 and 4
						case when sup1.address3<> '' then char(13)+char(10)+rtrim(sup1.address3) else '' end+
						case when sup1.address4<> '' then char(13)+char(10)+rtrim(sup1.address4) else '' end+
							CASE WHEN sup1.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(sup1.City)+',  '+rtrim(sup1.State)+'      '+RTRIM(sup1.zip)  ELSE '' END +
							CASE WHEN sup1.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(sup1.Country) ELSE '' end+
							case when sup1.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(sup1.PHONE) else '' end+
							case when sup1.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(sup1.FAX) else '' end  as SupplierAddress					
			--DRP 03/18/2013:  REPLACED BY ABOVE SupplierAddress.  Place all of the info below into one single Memo field. 			
						--,case when sup1.ADDRESS1 = '' then  sup1.ADDRESS2 else sup1.ADDRESS1 end as SupA1
						--,case when sup1.ADDRESS1 = '' OR sup1.ADDRESS2 = '' then RTRIM(LTRIM(sup1.CITY))+' '+sup1.STATE+',  '+sup1.ZIP+'   '+sup1.COUNTRY else sup1.ADDRESS2 end as SupA2
						--,case when sup1.ADDRESS1 = '' OR sup1.ADDRESS2 = '' then '' else RTRIM(ltrim(sup1.CITY))+' '+sup1.STATE+',  '+sup1.ZIP+'   '+sup1.COUNTRY end as SupA3
						--,case when sup1.FAX = '' then 'Ph: ' + RTRIM(ltrim (sup1.PHONE)) else 'Fax:  ' + sup1.FAX + '' + 'Ph: '+rtrim(ltrim (sup1.phone))end as SupA4
						,ACCTNO
						,shipto1.linkadd,SHIPTO1.TAXEXEMPT,CONFNAME
						,shipto1.SHIPTO
						,rtrim(shipto1.Address1)+case when shipto1.address2<> '' then char(13)+char(10)+rtrim(shipto1.address2) else '' end+
						-- 03/31/16 VL added address3 and 4
						case when shipto1.address3<> '' then char(13)+char(10)+rtrim(shipto1.address3) else '' end+
						case when shipto1.address4<> '' then char(13)+char(10)+rtrim(shipto1.address4) else '' end+
							CASE WHEN shipto1.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(shipto1.City)+',  '+rtrim(shipto1.State)+'      '+RTRIM(shipto1.zip)  ELSE '' END +
							CASE WHEN shipto1.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(shipto1.Country) ELSE '' end+
							case when shipto1.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(shipto1.PHONE) else '' end+
							case when shipto1.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(shipto1.FAX) else '' end  as ShipToAddress
			--DRP 03/18/2013:  REPLACED BY ABOVE ShipToAddress.  Place all of the info below into one single Memo field. 			
						--,case when shipto1.ADDRESS1 = '' then shipto1.ADDRESS2 else shipto1.ADDRESS1 end as ShiptoA1
						--,case when shipto1.ADDRESS1 = '' OR shipto1.ADDRESS2 = '' then RTRIM(LTRIM(shipto1.city))+' '+shipto1.STATE+',  '+shipto1.ZIP else shipto1.ADDRESS2 end as ShiptoA2
						--,case when shipto1.ADDRESS1 = '' OR ShipTo1.ADDRESS2 = '' then shipto1.COUNTRY else RTRIM(ltrim(ShipTo1.CITY))+' '+shipto1.STATE+',  '+ShipTo1.ZIP end as ShiptoA3
						--,case when shipto1.ADDRESS1 = '' OR shipto1.ADDRESS2 = '' then '' else shipto1.COUNTRY end as ShiptoA4 
						,shipto1.BILLACOUNT,billto1.shipto as BillTo
						,rtrim(BillTo1.Address1)+case when BillTo1.address2<> '' then char(13)+char(10)+rtrim(BillTo1.address2) else '' end+
						-- 03/31/16 VL added address3 and 4
						case when BillTo1.address3<> '' then char(13)+char(10)+rtrim(BillTo1.address3) else '' end+
						case when BillTo1.address4<> '' then char(13)+char(10)+rtrim(BillTo1.address4) else '' end+
							CASE WHEN BillTo1.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(BillTo1.City)+',  '+rtrim(BillTo1.State)+'      '+RTRIM(BillTo1.zip)  ELSE '' END +
							CASE WHEN BillTo1.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(BillTo1.Country) ELSE '' end+
							case when BillTo1.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(BillTo1.PHONE) else '' end+
							case when BillTo1.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(BillTo1.FAX) else '' end  as BillToAddress
			--DRP 03/18/2013:  REPLACED BY ABOVE BilltoAddress.  Place all of the info below into one single Memo field. 			
						--,case when BillTo1.ADDRESS1 = '' then BillTo1.ADDRESS2 else BillTo1.ADDRESS1 end as BillToA1
						--,case when billto1.ADDRESS1 = '' OR Billto1.ADDRESS2 = '' then RTRIM(LTRIM(billto1.city))+' '+billto1.STATE+',  '+billto1.ZIP else billto1.ADDRESS2 end as BillToA2
						--,case when billto1.ADDRESS1 = '' OR billto1.ADDRESS2 = '' then billto1.COUNTRY else RTRIM(ltrim(billto1.CITY))+' '+billto1.STATE+',  '+billto1.ZIP end as BilltoA3
						--,case when billto1.ADDRESS1 = '' OR billto1.ADDRESS2 = '' then '' else billto1.country end as BilltoA4
						,case when @lcAllItems = 'No' and poitems.ORD_QTY-poitems.ACPT_QTY = 0.00 then '' else 
							case when @lcAllItems  = 'No' and poitems.ORD_QTY-poitems.ACPT_QTY > 0.00 then isnull(dbo.fnNoteClauses(poitems.uniqlnno),'') else	
								case when @lcAllItems = 'Yes' then isnull(dbo.fnNoteClauses(poitems.uniqlnno),'') else '' end end end as PoItemClause  
						,isnull(dbo.FnNoteClauses(pomain.POUNIQUE),'') as PoMainClause,case when (isnull(dbo.FnNoteClauses(pomain.POUNIQUE),'')) = '' then CAST(0 as numeric(1,0)) else CAST(1 as numeric(1,0)) end as MainClauseCnt
						,POMAIN.LFREIGHTINCLUDE,pomain.APPVNAME,pomain.FINALNAME,
						-- 12/11/20 now the buyer is not saved in Pomain.Buyer linked to Buyerini, it's saved in Pomain.AspnetBuyer linked to aspnet_Users
						--BUYERINI.BUYNAME AS BUYER
						ISNULL(aspnet_Users.UserName, SPACE(20)) AS BUYER
			--DRP 07/16/2012:  ADDED THE BELOW FIELD TO THE PROCEDURE
						,poitems.LCANCEL
			--DRP 06/13/2013:  Added the ConfirmTo email address to the results because this is the email tha should be defaulted in for Emailing the PO forms.
						,sup1.E_MAIL
						-- 02/18/20 VL added partmfgr full name because suppliers really don't have ideas what's the partmfgr code
						, ISNULL(LEFT(Support.Text,30),SPACE(30)) AS PartmfgrName
					FROM	POMAIN
							inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
							left outer join SHIPBILL as Sup1 on pomain.C_LINK = sup1.LINKADD
							left outer join SHIPBILL as ShipTo1 on pomain.I_LINK = ShipTo1.LINKADD
							left outer join SHIPBILL AS BillTo1 on pomain.B_LINK = BillTo1.LINKADD
							INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
							left outer join INVENTOR on poitems. UNIQ_KEY = inventor.UNIQ_KEY
							--left outer join SUPPORT on inventor.PART_CLASS = support.TEXT2	--12/02/2014 DRP:  replaced by the below
							--08/01/17 YS moved part_class setup from "support" table to partClass table 
							left outer join (SELECT part_class,classDescription FROM partClass) S1 on inventor.PART_CLASS = S1.part_class
							--	10/13/14   YS: removed invtmfhd table 
							--left outer join INVTMFHD on poitems.UNIQMFGRHD = invtmfhd.UNIQMFGRHD
							left outer join InvtMPNLink L on poitems.UNIQMFGRHD = L.UNIQMFGRHD
							LEFT OUTER JOIN MfgrMaster M ON l.mfgrMasterId=M.MfgrMasterId
							left outer join INVTMFSP on poitems.UNIQMFGRHD = invtmfsp.UNIQMFGRHD and supinfo.UNIQSUPNO = invtmfsp.uniqsupno and invtmfsp.PFDSUPL = 1 and invtmfsp.IS_DELETED <> 1
							--left outer join INVTMFHD as mfhd2 on poitems.UNIQ_KEY = mfhd2.UNIQ_KEY and POITEMS.UNIQMFGRHD <> mfhd2.UNIQMFGRHD	--09/16/2014 DRP: removed this join that used to be used for MfgrNoOnPO, it has been replaced the the fnMfgNotOnPO
							-- 12/11/20 now the buyer is not saved in Pomain.Buyer linked to Buyerini, it's saved in Pomain.AspnetBuyer linked to aspnet_Users
							--LEFT OUTER JOIN BUYERINI ON POMAIN.BUYER = BUYERINI.INI
							LEFT OUTER JOIN aspnet_Users ON Pomain.AspnetBuyer = aspnet_Users.UserId
							-- 02/18/20 VL added partmfgr full name because suppliers really don't have ideas what's the partmfgr code
							LEFT OUTER JOIN Support ON Poitems.Partmfgr = LEFT(Text2,8) AND Support.FIELDNAME = 'PARTMFGR'
							-- 04/09/20 VL Changed to use wmNoteRelationship and wmNotes
							-- 06/02/20 VL changed from RecordType = 'INVENTOR' to 'POItemNote' and w.RecordId = Poitems.Uniq_key to w.RecordId = Poitems.Uniqlnno for PO item note
							OUTER APPLY (SELECT TOP 1 r.* 
								FROM wmNoteRelationship r INNER JOIN wmNotes w ON r.FkNoteId = w.NoteID AND w.RecordType = 'POItemNote' AND w.RecordId = Poitems.UNIQLNNO
								ORDER BY r.CreatedDate DESC) ItemNote
							-- 06/02/20 VL added 
							OUTER APPLY (SELECT TOP 1 r.* 
								FROM wmNoteRelationship r INNER JOIN wmNotes w ON r.FkNoteId = w.NoteID AND w.RecordType = 'INVENTOR' AND w.RecordId = Poitems.Uniq_key
								ORDER BY r.CreatedDate DESC) InvtItemNote
							-- 02/01/21 VL changed to use wmNoteRelationship and wmNotes
							OUTER APPLY (SELECT TOP 1 r.* 
								FROM wmNoteRelationship r INNER JOIN wmNotes w ON r.FkNoteId = w.NoteID AND w.RecordType = 'POFootNote' AND w.RecordId = POMAIN.PONUM
								ORDER BY r.CreatedDate DESC) PoFoot
							
					--where	POMAIN.PONUM = dbo.padl(@lcPoNum,15,'0')
					-- 06/17/15 YS replace @PoNum with @tPoNum and remove padl - already done
					--where exists (select 1 from @PoNum p  where dbo.PADL(p.ponum,15,'0')=POMAIN.PONUM)
					where exists (select 1 from @tPoNum p  where p.ponum=POMAIN.PONUM)
			--DRP 07/16/2012:  REMOVED THE BELOW FILTER SO I COULD INDICATE TO THE USERS IF A ORDER WAS CANCELLED 
							--and poitems.LCANCEL <> 1
			--DRP 09/22/2014:	and 1 = case when @lcAllItems = 'Yes' then 1 when poitems.ord_qty-poitems.acpt_qty  > 0.00 then 1 else 0 end  --09/16/2014 DRP:  added this filter here instead of filtering out the items on the report itself.
							and 1 = case when @lcAllItems = 'Yes' then 1
								when POSTATUS = 'Closed' then 1 
									when poitems.ord_qty-poitems.acpt_qty  > 0.00 then 1 else 0 end  --09/22/2014 DRP:  needed to add when POStatus = 'Closed' in order to make sure that closed PO's come fwd properly or instore po's
							
			)
			--select * from ZPOInfo
			,
			--Below will gather the total Tax Rates that need to be applied to the order
			--Below will gather the total Tax Rates that need to be applied to the order
			-- 02/09/16 VL changed to link by PoitemsTax, group by uniqlnno
			--ZTaxRate as	(
			--			select linkadd,SUM(tax_rate) as TaxRate from SHIPTAX where RECORDTYPE = 'I' group by LINKADD
			--			)
			ZTaxRate as	(
						select Uniqlnno, SUM(tax_rate) as TaxRate from PoitemsTax 
							WHERE exists (select 1 from @tPoNum p  where p.ponum=PoitemsTax.PONUM)
							GROUP BY Uniqlnno
						)
			
						
			select	
			T1.PONUM, t1.PODATE, t1.POSTATUS, t1.CONUM, t1.TERMS,t1.FOB,t1.SHIPVIA,t1.UNIQSUPNO,t1.UNIQLNNO,t1.ITEMNO,t1.poittype,t1.UNIQ_KEY,t1.Part_class,t1.PART_TYPE,t1.PART_NO
					,t1.revision,t1.DESCRIPT,t1.uniqmfgrhd,t1.PARTMFGR,t1.MFGR_PT_NO,t1.PACKAGE
					,CASE WHEN ROW_NUMBER() OVER(Partition by uniqlnno Order by itemno)=1 Then t1.OrdQty ELSE CAST(0.00 as Numeric(20,2)) END AS OrdQty
					,case when ROW_NUMBER() over(PARTITION by uniqlnno order by itemno)=1 then t1.BalanceQty else CAST (0.00 as numeric (20,2)) end as BalanceQty
					,t1.PUR_UOFM,t1.COSTEACH
					,CASE WHEN ROW_NUMBER() OVER(Partition by uniqlnno Order by itemno)=1 Then t1.Extended ELSE CAST(0.00 as Numeric(20,2)) END AS UnitPrice
					,t1.IS_TAX,CASE WHEN ROW_NUMBER() OVER(Partition by uniqlnno Order by itemno)=1 and t1.IS_TAX = 1 Then t1.TaxRate ELSE CAST(0.00 as Numeric(20,2)) END AS TaxRate
					,case when row_number() over(partition by ponum order by ponum)=1 then t1.SHIPCHG else CAST (0.00 as numeric(20,2)) end as ShipChg
					,case when row_number() over(partition by ponum order by ponum)=1 then t1.ShipTax else CAST (0.00 as numeric(20,2)) end as ShipTax
					,t1.QualSpec,t1.MatlType,t1.SUPLPARTNO,t1.ItemNote,t1.INV_NOTE,t1.MfgrNotOnPo,t1.POFOOTER,t1.Sup,SupplierAddress
--DRP 03/18/2013:  REPLACED BY ABOVE SupplierAddress.  Place all of the info below into one single Memo field. 			
					--,t1.SupA1,t1.SupA2,t1.SupA3,t1.SupA4
					,t1.ACCTNO,t1.TAXEXEMPT,t1.CONFNAME,t1.SHIPTO,t1.ShipToAddress
--DRP 03/18/2013:  REPLACED BY ABOVE ShipToAddress.  Place all of the info below into one single Memo field. 	
					--,t1.ShiptoA1,t1.ShiptoA2,t1.ShiptoA3,t1.ShiptoA4
					,t1.BILLACOUNT,t1.BillTo,t1.BillToAddress
--DRP 03/18/2013:  REPLACED BY ABOVE BillToAddress.  Place all of the info below into one single Memo field. 	
					--,t1.BillToA1,t1.BillToA2,t1.BilltoA3,t1.BilltoA4
					,t1.PoItemClause
					,case when (isnull(t1.PoItemClause,'')) = '' then CAST(0 as numeric(1,0)) else CAST(1 as numeric(1,0)) end as ItemClauseCnt
					,t1.PoMainClause,t1.MainClauseCnt,T1.LFREIGHTINCLUDE
					,t1.APPVNAME,t1.FINALNAME,T1.BUYER,t1.LCANCEL
					--,t1.lic_name,t1.LicAddress,t1.postd_foot,t1.field149	--09/16/2014 DRP:  removed since we can get all of this information from the GetCompanyAddress
					,t1.signatures,t1.SCHD_DATE,t1.REQ_DATE,t1.SCHD_QTY,t1.BALANCE,t1.Alloc
--DRP 06/13/2013:  Added the ConfirmTo email address to the results because this is the email tha should be defaulted in for Emailing the PO forms.					
					,t1.e_mail
					-- 02/18/20 VL added partmfgr full name because suppliers really don't have ideas what's the partmfgr code
					,t1.PartmfgrName

			From	(select	Zpoinfo.*, ZTaxRate.TaxRate
							--09/16/2014 DRP:  removed the micssys because we can get that info on the report using the GetCompanyAddress
							--,micssys.lic_name,rtrim(MICSSYS.LADDRESS1)+case when MICSSYS.LADDRESS2<> '' then char(13)+char(10)+rtrim(MICSSYS.laddress2) else '' end+
							--CASE WHEN MICSSYS.LCITY<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(MICSSYS.LCITY)+',  '+rtrim(MICSSYS.lState)+'      '+RTRIM(MICSSYS.lzip)  ELSE '' END ++
							--CASE WHEN MICSSYS.LCOUNTRY<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(MICSSYS.LCOUNTRY) ELSE '' END+
							--case when micssys.LPHONE <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(MICSSYS.LPHONE) else '' end+
							--case when micssys.LFAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(micssys.LFAX) else '' end  as LicAddress,micssys.POSTD_FOOT,micssys.field149
							,podeflts.signatures,POITSCHD.SCHD_DATE,POITSCHD.SCHD_QTY,POITSCHD.REQ_DATE,POITSCHD.BALANCE
							,isnull(case when POITSCHD.REQUESTTP = 'WO Alloc' then 'Allocated to Work Order #: '+POITSCHD.WOPRJNUMBER 
											when POITSCHD.REQUESTTP = 'Prj Alloc' then 'Allocated to Project :  '+POITSCHD.WOPRJNUMBER end,'') as Alloc
				--			if {POITSCHD.REQUESTTP} = 'WO Alloc' then 'Allocated to Work Order # :   '+{POITSCHD.WOPRJNUMBER}
    --else if {POITSCHD.REQUESTTP} = 'Prj Alloc' then 'Allocated to Project :  '+{POITSCHD.WOPRJNUMBER}
							
					 from	ZPOInfo 
							left outer join ZTaxRate  on zpoinfo.uniqlnno = zTaxRate.uniqlnno
							left outer join POITSCHD on ZPOInfo.UNIQLNNO = POITSCHD.UNIQLNNO
							--cross join micssys
							cross join PODEFLTS ) T1 where LCANCEL = 0
						

			-- this will go through and update the tables to indicate that the purchase order has been printed. 
			-- 04/22/15 VL added to update isinbatch 
			--UPDATE POMAIN SET  is_printed = 1, isinbatch = 1 WHERE POMAIN.PONUM =@lcPoNum 
			
END -- if @lFCInstalled=0  02/08/16 VL added for FC installed or not
ELSE
BEGIN -- else if @lFCInstalled=0
	--repopulates the parameter value to have the leading zero's, because we use it at the end to update the tables. 
			-- 06/17/2015 YS parameter is not used from this point on
			--SET @lcPoNum=dbo.PADL(@lcPoNum,15,'0')
			-- 03/31/16 VL realized that I need to add HC (Functional currency later)
			DECLARE @FCurrency char(3) = ''
			-- 04/08/16 VL changed to use function
			-- 06/20/17 VL changed fn_GetHomeCurrency to use fn_GetFunctionalCurrency
			SELECT @FCurrency = Symbol FROM Fcused WHERE Fcused_uniq = dbo.fn_GetFunctionalCurrency()

			;
			with 
			ZPOInfo as	(
						SELECT	POMAIN.PONUM, PODATE, POSTATUS, CONUM, pomain.TERMS,pomain.FOB,pomain.SHIPVIA,POMAIN.UNIQSUPNO
						,UNIQLNNO,ITEMNO,poitems.poittype,POITEMS.UNIQ_KEY,case when poitems.uniq_key = '' then cast ('' as char(8))else inventor.PART_CLASS end as Part_class
						,case when poitems.uniq_key = '' then cast ('' as char(8)) else inventor.part_type end as PART_TYPE,CASE WHEN POITEMS.UNIQ_KEY = '' THEN POITEMS.PART_NO ELSE INVENTOR.PART_NO END AS PART_NO
						,case when poitems.UNIQ_KEY = '' then CAST ('' as CHAR(8)) else inventor.REVISION end as revision,case when poitems.UNIQ_KEY = '' then poitems.DESCRIPT else inventor.DESCRIPT end as DESCRIPT
						,poitems.uniqmfgrhd,poitems.PARTMFGR, poitems.MFGR_PT_NO, poitems.PACKAGE
						,case when (@lcAllItems = 'Yes' OR PoStatus = 'CLOSED' OR POITTYPE = 'In Store') then poitems.ORD_QTY else poitems.ORD_QTY-poitems.ACPT_QTY end as OrdQty
			--DRP 11/16/2012:  REPLACED BY ABOVE. --,case when @lcAllItems = 'Y' then poitems.ORD_QTY else poitems.ORD_QTY-poitems.ACPT_QTY end as OrdQty
						,poitems.ord_qty-poitems.acpt_qty as BalanceQty		
						,poitems.PUR_UOFM,poitems.COSTEACH
			--DRP 07/16/2012:  Added the following code so if a purcahse order is Cancelled and they run the report all of the items will be hidden but the purchase order header will display with Cancelled in the header. 
			--DRP 11/16/2012:  modified the code for the Extended field to calculate the Extended value in the case of a Closed Order
						,case when @lcAllItems = 'Yes' and LCANCEL <> 1 then ROUND(poitems.ord_qty*poitems.costeach,2)
								when @lcAllItems = 'Yes' and LCANCEL = 1 then 0.00
									when @lcAllItems = 'No' and LCANCEL <> 1 and pomain.POSTATUS<>'CLOSED' then round((poitems.ORD_QTY-poitems.ACPT_QTY)* poitems.COSTEACH,2)
										when @lcAllItems = 'No' and LCANCEL = 1 then 0.00
											when @lcAllItems = 'No' and Pomain.POSTATUS = 'CLOSED' then round(poitems.ord_qty*poitems.costeach,2) end as Extended
			--DRP 0/716/2012:  REPLACED BY ABOVE	--,case when @lcAllItems = 'Y' then ROUND(poitems.ord_qty*poitems.costeach,2) else round((poitems.ORD_QTY-poitems.ACPT_QTY)* poitems.COSTEACH,2) end as Extended
						,poitems.IS_TAX
						,pomain.SHIPCHG,case when IS_SCTAX = 1 then ROUND((pomain.sctaxpct*pomain.SHIPCHG)/100,2) else CAST(0.00 as numeric(20,2)) end as ShipTax
						--08/01/17 YS removing quality spec from class setup
						,space(10) as QualSpec
						--,case when poitems.poittype <>'Invt Part' then cast ('' as char(10)) else cast(s1.TEXT4 as CHAR(10)) end as QualSpec
						,case when poitems.POITTYPE<>'Invt Part' then CAST ('' as CHAR(10)) else CAST(m.matltype as CHAR(10)) end as MatlType
						,invtmfsp.SUPLPARTNO
						-- 04/09/20 VL Changed to use wmNoteRelationship and wmNotes
						--,poitems.NOTE1 AS ItemNote
						,ItemNote.Note AS ItemNote						
						-- 06/02/20 VL changed to use wmNoteRelationShip and wmNotes
						--,inventor.INV_NOTE
						,InvtItemNote.Note AS INV_NOTE
						--,'MFgr: ' + rtrim(mfhd2.PARTMFGR) + ' MPN: '+ RTRIM(mfhd2.MFGR_PT_NO) + ' Matl Type: '+ rtrim(mfhd2.matltype) as MfgrNotOnPo	--09/16/2014 DRP:  created fnMfgNotOnPo and used that to get the Mfgrs listed in one record
						,isnull(dbo.fnMfgNotOnPo(poitems.uniqlnno),'') as MfgrNotOnPO 
						-- 02/01/21 VL changed to use wmNoteRelationship and wmNotes
						--,pomain.POFOOTER
						,PoFoot.Note AS POFOOTER
						,Sup1.SHIPTO as Sup, rtrim(sup1.Address1)+case when sup1.address2<> '' then char(13)+char(10)+rtrim(sup1.address2) else '' end+
						-- 03/31/16 VL added address3 and 4
						case when sup1.address3<> '' then char(13)+char(10)+rtrim(sup1.address3) else '' end+
						case when sup1.address4<> '' then char(13)+char(10)+rtrim(sup1.address4) else '' end+
							CASE WHEN sup1.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(sup1.City)+',  '+rtrim(sup1.State)+'      '+RTRIM(sup1.zip)  ELSE '' END +
							CASE WHEN sup1.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(sup1.Country) ELSE '' end+
							case when sup1.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(sup1.PHONE) else '' end+
							case when sup1.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(sup1.FAX) else '' end  as SupplierAddress					
			--DRP 03/18/2013:  REPLACED BY ABOVE SupplierAddress.  Place all of the info below into one single Memo field. 			
						--,case when sup1.ADDRESS1 = '' then  sup1.ADDRESS2 else sup1.ADDRESS1 end as SupA1
						--,case when sup1.ADDRESS1 = '' OR sup1.ADDRESS2 = '' then RTRIM(LTRIM(sup1.CITY))+' '+sup1.STATE+',  '+sup1.ZIP+'   '+sup1.COUNTRY else sup1.ADDRESS2 end as SupA2
						--,case when sup1.ADDRESS1 = '' OR sup1.ADDRESS2 = '' then '' else RTRIM(ltrim(sup1.CITY))+' '+sup1.STATE+',  '+sup1.ZIP+'   '+sup1.COUNTRY end as SupA3
						--,case when sup1.FAX = '' then 'Ph: ' + RTRIM(ltrim (sup1.PHONE)) else 'Fax:  ' + sup1.FAX + '' + 'Ph: '+rtrim(ltrim (sup1.phone))end as SupA4
						,ACCTNO
						,shipto1.linkadd,SHIPTO1.TAXEXEMPT,CONFNAME
						,shipto1.SHIPTO
						,rtrim(shipto1.Address1)+case when shipto1.address2<> '' then char(13)+char(10)+rtrim(shipto1.address2) else '' end+
						-- 03/31/16 VL added address3 and 4
						case when shipto1.address3<> '' then char(13)+char(10)+rtrim(shipto1.address3) else '' end+
						case when shipto1.address4<> '' then char(13)+char(10)+rtrim(shipto1.address4) else '' end+
							CASE WHEN shipto1.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(shipto1.City)+',  '+rtrim(shipto1.State)+'      '+RTRIM(shipto1.zip)  ELSE '' END +
							CASE WHEN shipto1.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(shipto1.Country) ELSE '' end+
							case when shipto1.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(shipto1.PHONE) else '' end+
							case when shipto1.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(shipto1.FAX) else '' end  as ShipToAddress
			--DRP 03/18/2013:  REPLACED BY ABOVE ShipToAddress.  Place all of the info below into one single Memo field. 			
						--,case when shipto1.ADDRESS1 = '' then shipto1.ADDRESS2 else shipto1.ADDRESS1 end as ShiptoA1
						--,case when shipto1.ADDRESS1 = '' OR shipto1.ADDRESS2 = '' then RTRIM(LTRIM(shipto1.city))+' '+shipto1.STATE+',  '+shipto1.ZIP else shipto1.ADDRESS2 end as ShiptoA2
						--,case when shipto1.ADDRESS1 = '' OR ShipTo1.ADDRESS2 = '' then shipto1.COUNTRY else RTRIM(ltrim(ShipTo1.CITY))+' '+shipto1.STATE+',  '+ShipTo1.ZIP end as ShiptoA3
						--,case when shipto1.ADDRESS1 = '' OR shipto1.ADDRESS2 = '' then '' else shipto1.COUNTRY end as ShiptoA4 
						,shipto1.BILLACOUNT,billto1.shipto as BillTo
						,rtrim(BillTo1.Address1)+case when BillTo1.address2<> '' then char(13)+char(10)+rtrim(BillTo1.address2) else '' end+
						-- 03/31/16 VL added address3 and 4
						case when BillTo1.address3<> '' then char(13)+char(10)+rtrim(BillTo1.ADDRESS3) else '' end+
						case when BillTo1.address4<> '' then char(13)+char(10)+rtrim(BillTo1.address4) else '' end+
							CASE WHEN BillTo1.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(BillTo1.City)+',  '+rtrim(BillTo1.State)+'      '+RTRIM(BillTo1.zip)  ELSE '' END +
							CASE WHEN BillTo1.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(BillTo1.Country) ELSE '' end+
							case when BillTo1.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(BillTo1.PHONE) else '' end+
							case when BillTo1.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(BillTo1.FAX) else '' end  as BillToAddress
			--DRP 03/18/2013:  REPLACED BY ABOVE BilltoAddress.  Place all of the info below into one single Memo field. 			
						--,case when BillTo1.ADDRESS1 = '' then BillTo1.ADDRESS2 else BillTo1.ADDRESS1 end as BillToA1
						--,case when billto1.ADDRESS1 = '' OR Billto1.ADDRESS2 = '' then RTRIM(LTRIM(billto1.city))+' '+billto1.STATE+',  '+billto1.ZIP else billto1.ADDRESS2 end as BillToA2
						--,case when billto1.ADDRESS1 = '' OR billto1.ADDRESS2 = '' then billto1.COUNTRY else RTRIM(ltrim(billto1.CITY))+' '+billto1.STATE+',  '+billto1.ZIP end as BilltoA3
						--,case when billto1.ADDRESS1 = '' OR billto1.ADDRESS2 = '' then '' else billto1.country end as BilltoA4
						,case when @lcAllItems = 'No' and poitems.ORD_QTY-poitems.ACPT_QTY = 0.00 then '' else 
							case when @lcAllItems  = 'No' and poitems.ORD_QTY-poitems.ACPT_QTY > 0.00 then isnull(dbo.fnNoteClauses(poitems.uniqlnno),'') else	
								case when @lcAllItems = 'Yes' then isnull(dbo.fnNoteClauses(poitems.uniqlnno),'') else '' end end end as PoItemClause  
						,isnull(dbo.FnNoteClauses(pomain.POUNIQUE),'') as PoMainClause,case when (isnull(dbo.FnNoteClauses(pomain.POUNIQUE),'')) = '' then CAST(0 as numeric(1,0)) else CAST(1 as numeric(1,0)) end as MainClauseCnt
						,POMAIN.LFREIGHTINCLUDE,pomain.APPVNAME,pomain.FINALNAME,
						-- 12/11/20 now the buyer is not saved in Pomain.Buyer linked to Buyerini, it's saved in Pomain.AspnetBuyer linked to aspnet_Users
						--BUYERINI.BUYNAME AS BUYER
						ISNULL(aspnet_Users.UserName, SPACE(20)) AS BUYER
			--DRP 07/16/2012:  ADDED THE BELOW FIELD TO THE PROCEDURE
						,poitems.LCANCEL
			--DRP 06/13/2013:  Added the ConfirmTo email address to the results because this is the email tha should be defaulted in for Emailing the PO forms.
						,sup1.E_MAIL
						,poitems.COSTEACHFC
						,case when @lcAllItems = 'Yes' and LCANCEL <> 1 then ROUND(poitems.ord_qty*poitems.costeachFC,2)
								when @lcAllItems = 'Yes' and LCANCEL = 1 then 0.00
									when @lcAllItems = 'No' and LCANCEL <> 1 and pomain.POSTATUS<>'CLOSED' then round((poitems.ORD_QTY-poitems.ACPT_QTY)* poitems.COSTEACHFC,2)
										when @lcAllItems = 'No' and LCANCEL = 1 then 0.00
											when @lcAllItems = 'No' and Pomain.POSTATUS = 'CLOSED' then round(poitems.ord_qty*poitems.costeachFC,2) end as ExtendedFC
						,pomain.SHIPCHGFC,case when IS_SCTAX = 1 then ROUND((pomain.sctaxpct*pomain.SHIPCHGFC)/100,2) else CAST(0.00 as numeric(20,2)) end as ShipTaxFC
						-- 03/31/16 VL added TCurrency and FCurrency
						,Fcused.Symbol AS TCurrency, @FCurrency AS FCurrency
						-- 02/18/20 VL added partmfgr full name because suppliers really don't have ideas what's the partmfgr code
						, ISNULL(LEFT(Support.Text,30),SPACE(30)) AS PartmfgrName

							-- 03/31/16 VL added to join Fcused and Pomain		 
					FROM	Fcused INNER JOIN POMAIN
							ON Pomain.FcUsed_uniq = Fcused.Fcused_uniq 
							inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
							left outer join SHIPBILL as Sup1 on pomain.C_LINK = sup1.LINKADD
							left outer join SHIPBILL as ShipTo1 on pomain.I_LINK = ShipTo1.LINKADD
							left outer join SHIPBILL AS BillTo1 on pomain.B_LINK = BillTo1.LINKADD
							INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
							left outer join INVENTOR on poitems. UNIQ_KEY = inventor.UNIQ_KEY
							--left outer join SUPPORT on inventor.PART_CLASS = support.TEXT2	--12/02/2014 DRP:  replaced by the below
							-- 08/01/17 YS move part class setup from support table to partClass table
							left outer join (sELECT part_class,classdescription FROM partClass) S1 on inventor.PART_CLASS = S1.part_class 
							--	10/13/14   YS: removed invtmfhd table 
							--left outer join INVTMFHD on poitems.UNIQMFGRHD = invtmfhd.UNIQMFGRHD
							left outer join InvtMPNLink L on poitems.UNIQMFGRHD = L.UNIQMFGRHD
							LEFT OUTER JOIN MfgrMaster M ON l.mfgrMasterId=M.MfgrMasterId
							left outer join INVTMFSP on poitems.UNIQMFGRHD = invtmfsp.UNIQMFGRHD and supinfo.UNIQSUPNO = invtmfsp.uniqsupno and invtmfsp.PFDSUPL = 1 and invtmfsp.IS_DELETED <> 1
							-- 12/11/20 now the buyer is not saved in Pomain.Buyer linked to Buyerini, it's saved in Pomain.AspnetBuyer linked to aspnet_Users
							--LEFT OUTER JOIN BUYERINI ON POMAIN.BUYER = BUYERINI.INI
							LEFT OUTER JOIN aspnet_Users ON Pomain.AspnetBuyer = aspnet_Users.UserId
							-- 02/18/20 VL added partmfgr full name because suppliers really don't have ideas what's the partmfgr code
							LEFT OUTER JOIN Support ON Poitems.Partmfgr = LEFT(Text2,8) AND Support.FIELDNAME = 'PARTMFGR'
							-- 04/09/20 VL Changed to use wmNoteRelationship and wmNotes
							-- 06/02/20 VL changed from RecordType = 'INVENTOR' to 'POItemNote' and w.RecordId = Poitems.Uniq_key to w.RecordId = Poitems.Uniqlnno for PO item note
							OUTER APPLY (SELECT TOP 1 r.* 
								FROM wmNoteRelationship r INNER JOIN wmNotes w ON r.FkNoteId = w.NoteID AND w.RecordType = 'POItemNote' AND w.RecordId = Poitems.UNIQLNNO
								ORDER BY r.CreatedDate DESC) ItemNote
							-- 06/02/20 VL added 
							OUTER APPLY (SELECT TOP 1 r.* 
								FROM wmNoteRelationship r INNER JOIN wmNotes w ON r.FkNoteId = w.NoteID AND w.RecordType = 'INVENTOR' AND w.RecordId = Poitems.Uniq_key
								ORDER BY r.CreatedDate DESC) InvtItemNote
							-- 02/01/21 VL changed to use wmNoteRelationship and wmNotes
							OUTER APPLY (SELECT TOP 1 r.* 
								FROM wmNoteRelationship r INNER JOIN wmNotes w ON r.FkNoteId = w.NoteID AND w.RecordType = 'POFootNote' AND w.RecordId = POMAIN.PONUM
								ORDER BY r.CreatedDate DESC) PoFoot

					--where	POMAIN.PONUM = dbo.padl(@lcPoNum,15,'0')
					-- 06/17/15 YS replace @PoNum with @tPoNum and remove padl - already done
					--where exists (select 1 from @PoNum p  where dbo.PADL(p.ponum,15,'0')=POMAIN.PONUM)
					where exists (select 1 from @tPoNum p  where p.ponum=POMAIN.PONUM)
			--DRP 07/16/2012:  REMOVED THE BELOW FILTER SO I COULD INDICATE TO THE USERS IF A ORDER WAS CANCELLED 
							--and poitems.LCANCEL <> 1
			--DRP 09/22/2014:	and 1 = case when @lcAllItems = 'Yes' then 1 when poitems.ord_qty-poitems.acpt_qty  > 0.00 then 1 else 0 end  --09/16/2014 DRP:  added this filter here instead of filtering out the items on the report itself.
							and 1 = case when @lcAllItems = 'Yes' then 1
								when POSTATUS = 'Closed' then 1 
									when poitems.ord_qty-poitems.acpt_qty  > 0.00 then 1 else 0 end  --09/22/2014 DRP:  needed to add when POStatus = 'Closed' in order to make sure that closed PO's come fwd properly or instore po's
							
			)
			--select * from ZPOInfo
			,
			--Below will gather the total Tax Rates that need to be applied to the order
			-- 02/09/16 VL changed to link by PoitemsTax, group by uniqlnno
			--ZTaxRate as	(
			--			select linkadd,SUM(tax_rate) as TaxRate from SHIPTAX where RECORDTYPE = 'I' group by LINKADD
			--			)
			ZTaxRate as	(
						select Uniqlnno, SUM(tax_rate) as TaxRate from PoitemsTax 
							WHERE exists (select 1 from @tPoNum p  where p.ponum=PoitemsTax.PONUM)
							GROUP BY Uniqlnno
						)
			
						
			select	
			T1.PONUM, t1.PODATE, t1.POSTATUS, t1.CONUM, t1.TERMS,t1.FOB,t1.SHIPVIA,t1.UNIQSUPNO,t1.UNIQLNNO,t1.ITEMNO,t1.poittype,t1.UNIQ_KEY,t1.Part_class,t1.PART_TYPE,t1.PART_NO
					,t1.revision,t1.DESCRIPT,t1.uniqmfgrhd,t1.PARTMFGR,t1.MFGR_PT_NO,t1.PACKAGE
					,CASE WHEN ROW_NUMBER() OVER(Partition by uniqlnno Order by itemno)=1 Then t1.OrdQty ELSE CAST(0.00 as Numeric(20,2)) END AS OrdQty
					,case when ROW_NUMBER() over(PARTITION by uniqlnno order by itemno)=1 then t1.BalanceQty else CAST (0.00 as numeric (20,2)) end as BalanceQty
					,t1.PUR_UOFM,t1.COSTEACH
					,CASE WHEN ROW_NUMBER() OVER(Partition by uniqlnno Order by itemno)=1 Then t1.Extended ELSE CAST(0.00 as Numeric(20,2)) END AS UnitPrice
					,t1.IS_TAX,CASE WHEN ROW_NUMBER() OVER(Partition by uniqlnno Order by itemno)=1 and t1.IS_TAX = 1 Then t1.TaxRate ELSE CAST(0.00 as Numeric(20,2)) END AS TaxRate
					,case when row_number() over(partition by ponum order by ponum)=1 then t1.SHIPCHG else CAST (0.00 as numeric(20,2)) end as ShipChg
					,case when row_number() over(partition by ponum order by ponum)=1 then t1.ShipTax else CAST (0.00 as numeric(20,2)) end as ShipTax
					,t1.QualSpec,t1.MatlType,t1.SUPLPARTNO,t1.ItemNote,t1.INV_NOTE,t1.MfgrNotOnPo,t1.POFOOTER,t1.Sup,SupplierAddress
--DRP 03/18/2013:  REPLACED BY ABOVE SupplierAddress.  Place all of the info below into one single Memo field. 			
					--,t1.SupA1,t1.SupA2,t1.SupA3,t1.SupA4
					,t1.ACCTNO,t1.TAXEXEMPT,t1.CONFNAME,t1.SHIPTO,t1.ShipToAddress
--DRP 03/18/2013:  REPLACED BY ABOVE ShipToAddress.  Place all of the info below into one single Memo field. 	
					--,t1.ShiptoA1,t1.ShiptoA2,t1.ShiptoA3,t1.ShiptoA4
					,t1.BILLACOUNT,t1.BillTo,t1.BillToAddress
--DRP 03/18/2013:  REPLACED BY ABOVE BillToAddress.  Place all of the info below into one single Memo field. 	
					--,t1.BillToA1,t1.BillToA2,t1.BilltoA3,t1.BilltoA4
					,t1.PoItemClause
					,case when (isnull(t1.PoItemClause,'')) = '' then CAST(0 as numeric(1,0)) else CAST(1 as numeric(1,0)) end as ItemClauseCnt
					,t1.PoMainClause,t1.MainClauseCnt,T1.LFREIGHTINCLUDE
					,t1.APPVNAME,t1.FINALNAME,T1.BUYER,t1.LCANCEL
					--,t1.lic_name,t1.LicAddress,t1.postd_foot,t1.field149	--09/16/2014 DRP:  removed since we can get all of this information from the GetCompanyAddress
					,t1.signatures,t1.SCHD_DATE,t1.REQ_DATE,t1.SCHD_QTY,t1.BALANCE,t1.Alloc
--DRP 06/13/2013:  Added the ConfirmTo email address to the results because this is the email tha should be defaulted in for Emailing the PO forms.					
					,t1.e_mail
					,t1.COSTEACHFC
					,CASE WHEN ROW_NUMBER() OVER(Partition by uniqlnno Order by itemno)=1 Then t1.ExtendedFC ELSE CAST(0.00 as Numeric(20,2)) END AS UnitPriceFC
					,case when row_number() over(partition by ponum order by ponum)=1 then t1.SHIPCHGFC else CAST (0.00 as numeric(20,2)) end as ShipChgFC
					,case when row_number() over(partition by ponum order by ponum)=1 then t1.ShipTaxFC else CAST (0.00 as numeric(20,2)) end as ShipTaxFC
					-- 03/31/16 VL added TCurrency and FCurrency
					,t1.TCurrency, t1.FCurrency
					,t1.costeachfc*t1.OrdQty as UnitPriceFcNotRnd	--08/18/16 DRP:  added this field upon request
					-- 02/18/20 VL added partmfgr full name because suppliers really don't have ideas what's the partmfgr code
					,t1.PartmfgrName
			From	(select	Zpoinfo.*, ZTaxRate.TaxRate
							--09/16/2014 DRP:  removed the micssys because we can get that info on the report using the GetCompanyAddress
							--,micssys.lic_name,rtrim(MICSSYS.LADDRESS1)+case when MICSSYS.LADDRESS2<> '' then char(13)+char(10)+rtrim(MICSSYS.laddress2) else '' end+
							--CASE WHEN MICSSYS.LCITY<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(MICSSYS.LCITY)+',  '+rtrim(MICSSYS.lState)+'      '+RTRIM(MICSSYS.lzip)  ELSE '' END ++
							--CASE WHEN MICSSYS.LCOUNTRY<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(MICSSYS.LCOUNTRY) ELSE '' END+
							--case when micssys.LPHONE <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(MICSSYS.LPHONE) else '' end+
							--case when micssys.LFAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(micssys.LFAX) else '' end  as LicAddress,micssys.POSTD_FOOT,micssys.field149
							,podeflts.signatures,POITSCHD.SCHD_DATE,POITSCHD.SCHD_QTY,POITSCHD.REQ_DATE,POITSCHD.BALANCE
							,isnull(case when POITSCHD.REQUESTTP = 'WO Alloc' then 'Allocated to Work Order #: '+POITSCHD.WOPRJNUMBER 
											when POITSCHD.REQUESTTP = 'Prj Alloc' then 'Allocated to Project :  '+POITSCHD.WOPRJNUMBER end,'') as Alloc
				--			if {POITSCHD.REQUESTTP} = 'WO Alloc' then 'Allocated to Work Order # :   '+{POITSCHD.WOPRJNUMBER}
    --else if {POITSCHD.REQUESTTP} = 'Prj Alloc' then 'Allocated to Project :  '+{POITSCHD.WOPRJNUMBER}
							
					 from	ZPOInfo 
							-- 02/09/16 VL link by and uniqlnno
							--left outer join ZTaxRate  on zpoinfo.LINKADD = zTaxRate.LINKADD
							left outer join ZTaxRate  on zpoinfo.Uniqlnno = zTaxRate.Uniqlnno
							left outer join POITSCHD on ZPOInfo.UNIQLNNO = POITSCHD.UNIQLNNO
							--cross join micssys
							cross join PODEFLTS ) T1 where LCANCEL = 0
						



END -- else if @lFCInstalled=0
-- 06/17/15 YS replace @PoNum with @tPoNum and remove padl - already done
			UPDATE POMAIN SET  is_printed = 1, isinbatch = 1 where exists (select 1 from @tPoNum p  where p.ponum=POMAIN.PONUM) 

end
				
	
				