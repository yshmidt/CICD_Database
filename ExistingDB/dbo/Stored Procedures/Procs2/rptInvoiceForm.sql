		
-- =============================================
-- Author:		<Debbie> 
-- Create date: <02/20/2012>
-- Description:	<compiles details for the Invoice form>

-- Reports:     <used on invoform.rpt>
-- Modified:	03/21/2012 DRP:  I previously had the PoNo field set to 10 characters.  It should have been set to 20 characters.
--				03/21/2012 DRP:
--				04/13/2012 DRP:	found that if there was a large number of misc items added to the packing list that exceeded 10 that it would then begin not sorting them as desired. 
--				04/18/2012 DRP: Modifications where made so that the printing of the invoice was no longer creating AR records, etc. . . 
--				10/22/2012 DRP: Changed the link to the ShipBill table that gathers the ShipTo information from an inner join to left outer join. 
--				11/02/2012 DRP:  needed to change the SOREPS from varchar(50) to varchar(max)
--				02/08/2013 DRP:	 User was experiencing truncated issue with one of their invoice.  Upon investigation found that the ShipAdd3 was the field that was being truncated. 
--								 As a precaution I went through and updated all of the ShipAdd and BillAdd fields from whatever character it had before to char(40) and that addressed the issue.
--				04/19/2013 DRP:  it was requested that we add the sales order balance at the time of the shipment to the invoice forms. 
--				04/24/2013 DRP:  upon request the users would like the option to display the serial numbers on the invoice similar as we do for the packing list.  The parameter will be added to the CR itself. 
--				08/26/2013 YS :  changed Attn to varchar(200), increased length of the ccontact fields.
--				10/21/2013 DRP:  I needed to add the "and i2.CUSTNO = plmain.CUSTNO" whern i2 is joined otherwise I was getting every Customer Part number record that existed for the inventory part regardless which customer was selected for the invoice. 				
--				01/15/2014 DRP:  added the @userid parameter for WebManex
--				03/12/2014 DRP:  increased the Line_no char(7) to Line_no char(10)
--				04/08/2014 DRP:  Needed to change [CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as bigint)] to [CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as numeric(30,0))] for users that had extremely large Serial Numbers entered into the system. 
--				02/13/2015 DRP:  Serial numbers we causing overflow of the Invoice on screen and I need to add a space after the comma to get the SN to break properly. 
--				03/30/2015 DRP:	 Added the uniqueln to the results.  in one particular user situation they could add the same line item Number multiple times and even for the same uniq_key.  In order to break them out on the report properly I needed to added the uniqueln to make the grouping unique. 
--				10/21/2015 DRP:  Needed to change  "PRICE numeric(12,2)" to be "PRICE numeric(14,5)"
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 07/16/18 VL changed custname from char(35) to char(50)
-- =============================================
		CREATE PROCEDURE [dbo].[rptInvoiceForm] 
--declare	
		@lcInvNo char(10) = ''
			,@userId uniqueidentifier=null
	    			
		as
		BEGIN

		declare @lcPacklistno char(10) = '', @llPrint_invo bit, @lcDisc_gl_no char(13)
--08/26/2013 YS :  changed Attn to varchar(200), increased length of the ccontact fields.
		-- 07/16/18 VL changed custname from char(35) to char(50)
		declare @tresults table	(invoiceno char(10),packlistno char(10),CUSTNO char(10), CUSTNAME char(50),SONO char(10),PONO char(20),INVDATE smalldatetime,shipdate smalldatetime,ORDERDATE smalldatetime
								,TERMS char(15),INV_FOOT text
								,Line_no char (10) /*03/12/2014 DRP:  ,Line_No char(7)*/  
								--- 03/28/17 YS changed length of the part_no column from 25 to 35
								,sortby char(7),Uniq_key char(10),PartNO char(35),Rev char(8),Descript char(50),CustPartNo char(35),CustRev char(8),CDescript char(50)
								,UOFMEAS char(4),SHIPPEDQTY numeric (12,2),NOTE text,PLPRICELNK char(10),pDesc char(50),QUANTITY numeric (12,2),PRICE numeric(14,5),EXTENDED numeric(12,2)
								,TAXABLE char(1),FLAT char(1),RecordType char(1),TotalExt numeric(12,2),dsctamt numeric(12,2),TotalTaxExt numeric(12,2),FreightAmt numeric(12,2),FreightTaxAmt numeric(12,2)
								,PTax numeric(12,2),STax numeric(12,2),InvTotal numeric(12,2),Attn varchar(200),FOREIGNTAX bit,SHIPTO char(40),ShipAdd1 char(40),ShipAdd2 char(40)
								,ShipAdd3 char(40),ShipAdd4 char(40),pkfootnote text,BillTo Char(40),BillAdd1 char(40),BillAdd2 char(40),BillAdd3 char(40),BillAdd4 char(40),FOB char(15),SHIPVIA char(15)
								,BILLACOUNT char(20),WAYBILL char(20),IsRMA varchar(3),Soreps varchar(max),INFOOTNOTE text,print_invo bit,SoBalance numeric(9,2),SerialNo varchar (max),uniqueln char(10))

		SET @lcInvNo=dbo.PADL(@lcInvNo,10,'0')
		SELECT @lcPacklistno = Packlistno, @llPrint_invo = Print_invo 
			FROM PLMAIN 
			WHERE INVOICENO = @lcInvNo
		SELECT @lcDisc_gl_no = Disc_gl_no FROM ARSETUP


/*--04/24/2013 DRP:  BEGIN:  added the serial number information to the invoice as an option to display if desired */
		;
		with
		--this section will go through and compile any Serialno information
		PLSerial AS
			  (
/*04/08/2014 drp: SELECT CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as bigint) as iSerialno,ps.packlistno,PS.UNIQUELN  */
			  SELECT CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as numeric(30,0)) as iSerialno,ps.packlistno,PS.UNIQUELN   
			  FROM packlser PS 
			  where PS.PACKLISTNO = @lcPackListNo
			  AND PATINDEX('%[^0-9]%',PS.serialno)=0 
			  )
			  ,startingPoints as
			  (
			  select A.*, ROW_NUMBER() OVER(PARTITION BY A.packlistno,uniqueln ORDER BY iSerialno) AS rownum
			  FROM PLSerial AS A WHERE NOT EXISTS (SELECT 1 FROM PLSerial AS B WHERE B.iSerialno=A.iSerialno-1 and B.PACKLISTNO =A.PACKLISTNO and B.UNIQUELN=A.UNIQUELN )
			  )
			 --SELECT * FROM StartingPoints  
   			,
			EndingPoints AS
			(
			select A.*, ROW_NUMBER() OVER(PARTITION BY packlistno,uniqueln ORDER BY iSerialno) AS rownum
			FROM PLSerial AS A WHERE NOT EXISTS (SELECT 1 FROM PLSerial AS B WHERE B.iSerialno=A.iSerialno+1 and B.PACKLISTNO =A.PACKLISTNO and B.UNIQUELN=A.UNIQUELN) 
			)
			--SELECT * FROM EndingPoints
			,
			StartEndSerialno AS 
			(
			SELECT S.*,S.iSerialno AS start_range, E.iSerialno AS end_range
			FROM StartingPoints AS S
			JOIN EndingPoints AS E
			ON E.rownum = S.rownum and E.PACKLISTNO = S.PACKLISTNO and E.UNIQUELN =S.UNIQUELN 
			)
			,FinalSerialno AS
			(
			SELECT CASE WHEN A.start_range=A.End_range
					THEN CAST(RTRIM(CONVERT(char(30),A.start_range))  as varchar(MAX)) ELSE
					CAST(RTRIM(CONVERT(char(30),A.start_range))+'-'+RTRIM(CONVERT(char(30),A.End_range)) as varchar(MAX)) END as Serialno,
					packlistno,uniqueln
			FROM StartEndSerialno  A
			UNION 
			SELECT CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as varchar(max)) as Serialno,PS.packlistno,PS.UNIQUELN  
				from PACKLSER ps 
				where ps.PACKLISTNO = @lcPackListNo
				and (PS.Serialno LIKE '%[a-z]%' OR PATINDEX('%[^0-9A-Za-z]%',Ps.serialno)<>0) 
			)
			--select * from FinalSerialno
--04/24/2013 DRP:  END:

		--04/13/2012 DRP:	found that if there was a large number of misc items added to the packing list that exceeded 10 that it would then begin not sorting them as desired. 
		--					added the sortby field below to address this situation. 
		--08/26/2013 YS :  changed Attn to varchar(200), increased length of the ccontact fields.
		,
		
		Invoice as (	select	plmain.INVOICENO,plmain.PACKLISTNO,PLMAIN.CUSTNO,CUSTNAME,PLMAIN.SONO,SOMAIN.PONO,plmain.invdate,plmain.shipdate,SOMAIN.ORDERDATE
						,PLMAIN.TERMS,PLMAIN.INV_FOOT,ISNULL(cast(sodetail.line_no as CHAR (10)),cast(PLDETAIL.uniqueln as CHAR (10))) as Line_No
						,ISNULL(sodetail.line_no,'X'+dbo.padl(rtrim(substring(pldetail.uniqueln,2,6)),6,'0')) as sortby
						--- 03/28/17 YS changed length of the part_no column from 25 to 35
						,isnull(sodetail.uniq_key,space(10))as Uniq_key,isnull(inventor.PART_NO,SPACE(35)) as PartNO,ISNULL(inventor.revision,space(8)) as Rev
						,ISNULL(cast(inventor.descript as CHAR(50)),CAST(pldetail.cdescr as CHAR(50))) as Descript
						--- 03/28/17 YS changed length of the part_no column from 25 to 35
						,ISNULL(i2.custpartno,SPACE(35)) as CustPartNo,ISNULL(i2.custrev,space(8)) as CustRev, ISNULL(cast(i2.DESCRIPT as CHAR (50)),cast (pldetail.cdescr as CHAR(50))) as CDescript
						,PLDETAIL.UOFMEAS,pldetail.SHIPPEDQTY,pldetail.NOTE,plp.PLPRICELNK,plp.DESCRIPT AS pDesc,plp.QUANTITY,plp.PRICE,plp.EXTENDED
						,case when plp.TAXABLE = 1 then CAST('Y' as CHAR(1)) else CAST('' as CHAR(1)) end as Taxable,plp.FLAT,plp.RECORDTYPE,plmain.TOTEXTEN AS TotalExt,plmain.dsctamt
						,plmain.tottaxe as TotalTaxExt,plmain.FREIGHTAMT,plmain.TOTTAXF as FreightTaxAmt,plmain.PTAX,plmain.STAX,plmain.INVTOTAL
						,isnull(cast (rtrim(ccontact.LASTNAME) + ', ' + RTRIM(ccontact.FIRSTNAME) as varCHAR (200)),cast('' as varCHAR(200))) as Attn
						,S.FOREIGNTAX,s.SHIPTO,s.ADDRESS1 as ShipAdd1,case when s.ADDRESS2 = '' then RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) else s.address2 end as ShipAdd2
						,case when s.address2 = '' then s.country else RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) end as ShipAdd3
						,case when s.address2 <> '' then s.country else '' end as ShipAdd4,s.PKFOOTNOTE
						,b.SHIPTO as BillTo,b.ADDRESS1 as BillAdd1,case when b.ADDRESS2 = '' then RTRIM(b.city) + ',  '+RTRIM(B.state)+'     '+RTRIM(b.zip) else b.address2 end as BillAdd2
						,case when b.address2 = '' then b.country else RTRIM(b.city) + ',  '+RTRIM(b.state)+'     '+RTRIM(b.zip) end as BillAdd3
						,case when b.address2 <> '' then b.country else '' end as BillAdd4,plmain.FOB,plmain.SHIPVIA,plmain.BILLACOUNT
						,plmain.WAYBILL,case when somain.IS_RMA = 1 then 'RMA' else '' end as IsRMA
						,dbo.FnSoRep(plmain.sono) as Soreps ,B.INFOOTNOTE,PRINT_INVO,pldetail.SOBALANCE
--04/23/2013 DRP:  added serianl number field
						--,CAST(stuff((select','+ps.Serialno	from FinalSerialno PS
						--							where	PS.PACKLISTNO = PLMAIN.PACKLISTNO
						--									AND PS.UNIQUELN = PLDETAIL.UNIQUELN
						--							ORDER BY SERIALNO FOR XML PATH ('')),1,1,'') AS VARCHAR (MAX)) AS Serialno	--02/13/2015 DRP:  Replaced with the below
						,CAST(stuff((select', '+ps.Serialno	from FinalSerialno PS
													where	PS.PACKLISTNO = PLMAIN.PACKLISTNO
															AND PS.UNIQUELN = PLDETAIL.UNIQUELN
													ORDER BY SERIALNO FOR XML PATH ('')),1,2,'') AS VARCHAR (MAX)) AS Serialno
						,pldetail.uniqueln
									
						from	PLMAIN
						inner join CUSTOMER on plmain.CUSTNO = customer.CUSTNO
						LEFT OUTER JOIN SOMAIN ON PLMAIN.SONO = SOMAIN.SONO
						left outer join PLDETAIL on plmain.PACKLISTNO = pldetail.PACKLISTNO
						left outer join SODETAIL on pldetail.UNIQUELN = sodetail.UNIQUELN
						left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY
--10/21/2013 DRP:  I needed to add the "and i2.CUSTNO = plmain.CUSTNO" whern i2 is joined otherwise I was getting every Customer Part number record that existed for the inventory part regardless which customer was selected for the invoice. 				
						--left outer join INVENTOR as i2 on inventor.UNIQ_KEY = i2.INT_UNIQ
						left outer join INVENTOR as i2 on inventor.UNIQ_KEY = i2.INT_UNIQ and i2.CUSTNO = plmain.CUSTNO
						left outer join CCONTACT on plmain.attention = ccontact.cid
						left outer join SHIPBILL as S on plmain.LINKADD = s.LINKADD
						left outer join SHIPBILL as B on Plmain.BLINKADD = B.LINKADD and plmain.CUSTNO = b.CUSTNO				
						left outer join PLPRICES as plp on PLDETAIL.UNIQUELN = PLP.UNIQUELN and pldetail.PACKLISTNO = plp.PACKLISTNO
						left outer join SOPRSREP on PLDETAIL.UNIQUELN = soprsrep.UNIQUELN

						
						where plmain.INVOICENO =@lcInvNo
				
				) 

		INSERT @tResults
		select * from Invoice

		Select * from @tResults

		--	04/18/2012 DRP: added the below code to just indicate if the invoice has been printed 
		UPDATE PLMAIN SET  is_InPrint = 1 WHERE PLMAIN.INVOICENO =@lcInvNo

		-- 04/18/2012 DRP:  removed the below code that created AR records upon invoice printing.
		--IF @llPrint_invo = 0
		--BEGIN
		--	-- Re-calculate invoice total
		--	EXEC sp_Invoice_Total @lcPacklistno
		--	UPDATE PLMAIN SET  is_invpost = 1, print_invo = 1, inv_dupl = 1, DISC_GL_NO = @lcDisc_gl_no, INV_INIT = @lcUser_id WHERE PLMAIN.INVOICENO =@lcInvNo 
		--	EXEC sp_InvoicePost @lcpacklistno                          				
		--END						
		   

		end